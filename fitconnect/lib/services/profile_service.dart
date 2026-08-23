import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch profile of current logged-in user
  Future<ProfileModel?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return getProfileById(user.id);
  }

  /// Fetch profile by user ID
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint("Error fetching profile for $userId: $e");
      return null;
    }
  }

  /// Fetch other athlete profiles for Discovery screen (excluding current user & already swiped users)
  Future<List<ProfileModel>> fetchOtherAthletes({int limit = 30}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    try {
      // 1. Fetch already swiped user IDs
      Set<String> swipedIds = {};
      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          final List<dynamic> swipedData = await _supabase
              .from('swipes')
              .select('target_user_id')
              .eq('user_id', currentUserId);
          swipedIds = swipedData.map((e) => e['target_user_id'].toString()).toSet();
        } catch (_) {
          // If swipes table doesn't exist yet, proceed gracefully
        }
      }

      final List<dynamic> data;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        data = await _supabase
            .from('profiles')
            .select()
            .neq('id', currentUserId)
            .limit(limit);
      } else {
        data = await _supabase
            .from('profiles')
            .select()
            .limit(limit);
      }

      return data
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .where((profile) =>
              profile.id != currentUserId &&
              !profile.isAdmin &&
              !swipedIds.contains(profile.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching athlete profiles for discovery: $e");
      return [];
    }
  }

  /// Update user profile details (supports partial updates)
  Future<void> updateProfile({
    String? name,
    String? location,
    String? sport,
    String? skill,
    String? tier,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    final Map<String, dynamic> updates = {
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (sport != null) 'sport': sport,
      if (skill != null) 'skill_level': skill,
      if (tier != null) 'tier': tier,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }
  }

  /// Convenience method to update user subscription tier
  Future<void> updateTier(String tier) async {
    await updateProfile(tier: tier);
  }

  /// Upload avatar image to Supabase Storage bucket ('avatars')
  Future<String> uploadAvatar(XFile image) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      await _supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
    } else {
      final file = File(image.path);
      await _supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
    }

    final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
    await _supabase.from('profiles').update({'image_url': publicUrl}).eq('id', user.id);

    return publicUrl;
  }

  /// Adjust reliability score (delta can be +3 for MVP, +2 for upvotes, -5 for late dropouts, -15 for no-shows)
  Future<int> adjustReliabilityScore(String userId, int delta) async {
    try {
      final current = await getProfileById(userId);
      final int currentScore = current?.reliabilityScore ?? 100;
      final int newScore = (currentScore + delta).clamp(0, 100);

      await _supabase.from('profiles').update({
        'reliability_score': newScore,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint("Successfully updated reliability score for $userId: $currentScore -> $newScore (delta: $delta)");
      return newScore;
    } catch (e) {
      debugPrint("Error adjusting reliability score for $userId: $e");
      return 100;
    }
  }

  /// Submit incident report against a player and apply penalty
  Future<void> submitPlayerReport({
    required String reportedUserId,
    required String reason,
    String? notes,
    String? lobbyId,
    int penalty = 10,
  }) async {
    final reporterId = _supabase.auth.currentUser?.id;

    // 1. Record incident in reports table if available
    try {
      await _supabase.from('reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'lobby_id': lobbyId,
        'reason': reason,
        'notes': notes,
        'penalty_applied': penalty,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Note: reports table not configured or insert error: $e");
    }

    // 2. Automatically adjust the reported user's reliability score
    if (penalty > 0) {
      await adjustReliabilityScore(reportedUserId, -penalty);
    }
  }
}

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

  /// Update user profile details
  Future<void> updateProfile({
    required String name,
    required String location,
    required String sport,
    String? skill,
    String? tier,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated.");

    final Map<String, dynamic> updates = {
      'name': name,
      'location': location,
      'sport': sport,
      if (skill != null) 'skill_level': skill,
      if (tier != null) 'tier': tier,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    await _supabase.from('profiles').update(updates).eq('id', user.id);
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
}

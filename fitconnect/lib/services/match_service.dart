import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class MatchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch user IDs that current user has already swiped on (to exclude from card deck)
  Future<List<String>> fetchSwipedUserIds() async {
    if (currentUserId == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('swipes')
          .select('target_user_id')
          .eq('user_id', currentUserId!);

      return data.map((item) => item['target_user_id'].toString()).toList();
    } catch (e) {
      debugPrint("Info: swipes table not created or error fetching swiped IDs: $e");
      return [];
    }
  }

  /// Records a swipe in Supabase and returns true if it's a mutual match
  Future<bool> recordSwipe({
    required String targetUserId,
    required String action, // 'like', 'superlike', 'pass'
  }) async {
    if (currentUserId == null) return false;

    try {
      // 1. If passing, just record pass in database
      if (action == 'pass') {
        await _supabase.from('swipes').upsert({
          'user_id': currentUserId,
          'target_user_id': targetUserId,
          'action': 'pass',
          'is_match': false,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, target_user_id');
        return false;
      }

      // 2. Check if the target user has ALREADY swiped right (like / superlike) on current user
      final List<dynamic> existingLikes = await _supabase
          .from('swipes')
          .select()
          .eq('user_id', targetUserId)
          .eq('target_user_id', currentUserId!)
          .neq('action', 'pass');

      final bool isMutual = existingLikes.isNotEmpty;
      debugPrint("Swipe check -> Me: $currentUserId | Target: $targetUserId | Is Mutual Match: $isMutual");

      // 3. Upsert current user's swipe record
      await _supabase.from('swipes').upsert({
        'user_id': currentUserId,
        'target_user_id': targetUserId,
        'action': action,
        'is_match': isMutual,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, target_user_id');

      // 4. If it's a mutual match, update target user's swipe record is_match flag to true as well
      if (isMutual) {
        await _supabase.from('swipes').update({
          'is_match': true,
        }).eq('user_id', targetUserId).eq('target_user_id', currentUserId!);
      }

      return isMutual;
    } catch (e) {
      debugPrint("Error recording swipe to Supabase: $e");
      return false;
    }
  }

  /// Delete last swipe record for undo functionality
  Future<void> undoSwipe(String targetUserId) async {
    if (currentUserId == null) return;
    try {
      await _supabase
          .from('swipes')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('target_user_id', targetUserId);
    } catch (e) {
      debugPrint("Error undoing swipe in Supabase: $e");
    }
  }

  /// Fetch all mutual matched athlete profiles for current user
  Future<List<ProfileModel>> fetchMatchedProfiles() async {
    if (currentUserId == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('swipes')
          .select('target_user_id, profiles!swipes_target_user_id_fkey(*)')
          .eq('user_id', currentUserId!)
          .eq('is_match', true);

      final List<ProfileModel> matches = [];
      for (final item in data) {
        if (item['profiles'] != null) {
          matches.add(ProfileModel.fromJson(item['profiles'] as Map<String, dynamic>));
        }
      }
      return matches;
    } catch (e) {
      debugPrint("Error fetching matched profiles: $e");
      return [];
    }
  }
}

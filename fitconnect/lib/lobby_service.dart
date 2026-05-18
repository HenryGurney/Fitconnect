import 'package:supabase_flutter/supabase_flutter.dart';

class LobbyService {
  final _supabase = Supabase.instance.client;

  /// Gets the current logged-in user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// 1. Fetches sports dropdown catalog from Supabase
  Future<List<String>> fetchSportsList() async {
    try {
      final List<dynamic> data = await _supabase
          .from('sports')
          .select('name')
          .order('name', ascending: true);

      return data
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      // Failed to fetch sports list, returning fallback defaults
      return ['Futsal', 'Badminton', 'Tennis', 'Basketball', 'Volleyball'];
    }
  }

  /// 2. Dispatches structured game room payloads directly to Supabase
  Future<void> createLobby({
    required String title,
    required String sport,
    required String locationName,
    required double lat,
    required double lng,
    required List<String> skills,
    required int maxParticipants,
  }) async {
    if (currentUserId == null) throw Exception("User must be logged in to host events.");

    await _supabase.from('lobbies').insert({
      'title': title,
      'sport': sport,
      'location_name': locationName,
      'latitude': lat,
      'longitude': lng,
      'skills': skills,
      'max_participants': maxParticipants,
      'host_id': currentUserId,
    });
  }

  /// 3. Submits an initial membership join request (Defaults to 'pending' state)
  Future<void> requestToJoinLobby(String lobbyId) async {
    if (currentUserId == null) throw Exception("User not logged in.");
    await _supabase.from('lobby_participants').insert({
      'lobby_id': lobbyId,
      'user_id': currentUserId,
      'status': 'pending'
    });
  }

  /// 4. Updates status variables for an entry (Executed by match host profiles)
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    await _supabase.from('lobby_participants').update({'status': newStatus}).eq('id', requestId);
  }

  /// 5. Pulls the status row data for a specific player's profile stream tracker
  Stream<List<Map<String, dynamic>>> getUserRequestStream(String lobbyId) {
    if (currentUserId == null) return const Stream.empty();
    return _supabase
        .from('lobby_participants')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId);
  }

  /// 6. Pulls all player requests matching an event lobby container footprint
  Stream<List<Map<String, dynamic>>> getAllLobbyRequestsStream(String lobbyId) {
    return _supabase
        .from('lobby_participants')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId);
  }

/// 7. Helper to fetch profile details asynchronously for applicant reviews
  Future<Map<String, dynamic>?> fetchPlayerProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      // Error fetching profile review data
      return null;
    }
  }
}
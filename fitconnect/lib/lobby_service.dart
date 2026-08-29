import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/models.dart';

class LobbyService {
  final _supabase = Supabase.instance.client;

  /// Gets the current logged-in user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// 1. Fetches sports dropdown catalog from Supabase
  Future<List<String>> fetchSportsList() async {
    const defaultSports = [
      'Futsal',
      'Football',
      'Badminton',
      'Tennis',
      'Pickleball',
      'Basketball',
      'Volleyball',
      'Running'
    ];

    try {
      final List<dynamic> data = await _supabase
          .from('sports')
          .select('name')
          .order('name', ascending: true);

      final dbSports = data
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (dbSports.isEmpty) {
        return defaultSports;
      }

      // Merge database sports with default catalog to guarantee all sports appear
      final Set<String> merged = {...defaultSports, ...dbSports};
      return merged.toList();
    } catch (e) {
      debugPrint("Error fetching sports list: $e");
      return defaultSports;
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
    String? matchDate,
    String? matchTime,
    String? courtFee,
    bool hasReferee = false,
    bool isSpotlight = false,
  }) async {
    if (currentUserId == null) throw Exception("User must be logged in to host events.");

    // Attach fee badge & referee tag to title
    String finalTitle = title;
    if (courtFee != null && courtFee.trim().isNotEmpty && courtFee != 'Free (Casual)') {
      final cleanFee = courtFee.trim();
      finalTitle = '$finalTitle • $cleanFee';
    }
    if (hasReferee) {
      finalTitle = '$finalTitle • [Referee]';
    }

    final payload = <String, dynamic>{
      'title': finalTitle,
      'sport': sport,
      'location_name': locationName,
      'latitude': lat,
      'longitude': lng,
      'skills': skills,
      'max_participants': maxParticipants,
      'host_id': currentUserId,
      'has_referee': hasReferee,
      if (matchDate != null) 'match_date': matchDate,
      if (matchTime != null) 'match_time': matchTime,
    };

    try {
      await _supabase.from('lobbies').insert(payload);
    } catch (e) {
      // Fallback if has_referee column is not in Postgres yet
      payload.remove('has_referee');
      await _supabase.from('lobbies').insert(payload);
    }
  }

  /// 3. Submits an initial membership join request (Defaults to 'pending' state)
  Future<void> requestToJoinLobby(String lobbyId, {String role = 'player'}) async {
    if (currentUserId == null) throw Exception("User not logged in.");
    try {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': lobbyId,
        'user_id': currentUserId,
        'status': 'pending',
        'role': role,
      });
    } catch (e) {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': lobbyId,
        'user_id': currentUserId,
        'status': 'pending',
      });
    }
  }

  /// 3b. Apply or claim the dedicated match referee slot (requires host approval if not host)
  Future<void> claimRefereeSlot(String lobbyId, {bool isHost = false}) async {
    if (currentUserId == null) throw Exception("User not logged in.");
    final dynamic targetLobbyId = int.tryParse(lobbyId) ?? lobbyId;
    final initialStatus = isHost ? 'approved' : 'pending';

    try {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': targetLobbyId,
        'user_id': currentUserId,
        'status': initialStatus,
        'role': 'referee',
      });
    } catch (e) {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': targetLobbyId,
        'user_id': currentUserId,
        'status': initialStatus,
      });
    }
  }

  /// 4. Updates status variables for an entry (Executed by match host profiles)
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final dynamic targetId = int.tryParse(requestId) ?? requestId;
    await _supabase.from('lobby_participants').update({'status': newStatus}).eq('id', targetId);
  }

  /// 4b. Removes or kicks a participant from the lobby roster
  Future<void> removeParticipant(String requestId) async {
    final dynamic targetId = int.tryParse(requestId) ?? requestId;
    await _supabase.from('lobby_participants').delete().eq('id', targetId);
  }

  /// 5. Stream of raw lobbies mapped to LobbyModel objects (excluding admin hosted lobbies)
  Stream<List<LobbyModel>> getLobbiesStream() {
    return _supabase
        .from('lobbies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list
            .map((json) => LobbyModel.fromJson(json))
            .where((lobby) {
              final hostName = lobby.hostProfile?.name.toLowerCase() ?? '';
              final isHostAdmin = lobby.hostProfile?.isAdmin ?? false;
              return !isHostAdmin && !hostName.contains('admin');
            })
            .toList());
  }

  /// 6. Stream of lobbies hosted by the logged-in user mapped to LobbyModel
  Stream<List<LobbyModel>> getMyLobbiesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _supabase
        .from('lobbies')
        .stream(primaryKey: ['id'])
        .eq('host_id', currentUserId!)
        .order('created_at', ascending: false)
        .map((list) => list.map((json) => LobbyModel.fromJson(json)).toList());
  }

  /// 7. Stream of requests for a specific user inside a lobby
  Stream<List<LobbyParticipantModel>> getUserRequestStream(String lobbyId) {
    if (currentUserId == null) return const Stream.empty();
    return _supabase
        .from('lobby_participants')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId)
        .map((list) => list.map((json) => LobbyParticipantModel.fromJson(json)).toList());
  }

  /// 8. Stream of all player requests matching a lobby
  Stream<List<LobbyParticipantModel>> getAllLobbyRequestsStream(String lobbyId) {
    return _supabase
        .from('lobby_participants')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId)
        .map((list) => list.map((json) => LobbyParticipantModel.fromJson(json)).toList());
  }

  /// 9. Helper to fetch profile details asynchronously for applicant reviews
  Future<ProfileModel?> fetchPlayerProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint("Error fetching profile for applicant: $e");
      return null;
    }
  }

  /// 10. Delete a lobby by ID (handles int/string IDs and checks for Supabase RLS permission issues)
  Future<void> deleteLobby(String lobbyId) async {
    final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;

    try {
      await _supabase
          .from('lobby_participants')
          .delete()
          .eq('lobby_id', targetId);
    } catch (e) {
      debugPrint("Warning deleting participants: $e");
    }

    // Perform delete and return affected rows to verify RLS permission
    final List<dynamic> response = await _supabase
        .from('lobbies')
        .delete()
        .eq('id', targetId)
        .select();

    if (response.isEmpty) {
      // Fallback try with string representation
      final List<dynamic> stringRetry = await _supabase
          .from('lobbies')
          .delete()
          .eq('id', lobbyId)
          .select();

      if (stringRetry.isEmpty) {
        throw Exception(
          "Supabase RLS Policy check: 0 rows deleted. "
          "Please verify that your Supabase 'lobbies' table has a DELETE policy for authenticated hosts.",
        );
      }
    }
  }

  /// 11. Allows a player to withdraw/cancel their join request for a lobby
  Future<void> leaveLobby(String lobbyId) async {
    if (currentUserId == null) return;
    final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;
    await _supabase
        .from('lobby_participants')
        .delete()
        .eq('lobby_id', targetId)
        .eq('user_id', currentUserId!);
  }

  /// 12. Stream of participant records for the current user (joined or requested matches)
  Stream<List<LobbyParticipantModel>> getMyJoinedRequestsStream() {
    if (currentUserId == null) return const Stream.empty();
    return _supabase
        .from('lobby_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .map((list) => list.map((json) => LobbyParticipantModel.fromJson(json)).toList());
  }

  /// 13. Helper to fetch single lobby details by ID
  Future<LobbyModel?> fetchLobbyById(String lobbyId) async {
    try {
      final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;
      final data = await _supabase
          .from('lobbies')
          .select()
          .eq('id', targetId)
          .maybeSingle();

      if (data == null) return null;
      return LobbyModel.fromJson(data);
    } catch (e) {
      debugPrint("Error fetching lobby by ID ($lobbyId): $e");
      return null;
    }
  }

  /// 14. Update existing lobby details
  Future<LobbyModel?> updateLobby({
    required String lobbyId,
    required String title,
    required String locationName,
    required int maxParticipants,
    bool? hasReferee,
  }) async {
    final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;

    var updatedTitle = title.replaceAll('• [Referee]', '').replaceAll('[Referee]', '').trim();
    if (hasReferee == true) {
      updatedTitle = "$updatedTitle • [Referee]";
    }

    final Map<String, dynamic> updateData = {
      'title': updatedTitle,
      'location_name': locationName,
      'max_participants': maxParticipants,
    };
    if (hasReferee != null) {
      updateData['has_referee'] = hasReferee;
    }

    dynamic responseData;
    try {
      final res = await _supabase.from('lobbies').update(updateData).eq('id', targetId).select();
      if (res.isNotEmpty) {
        responseData = res.first;
      }
    } catch (e) {
      // Fallback if has_referee column is not yet present in Supabase
      updateData.remove('has_referee');
      try {
        final res = await _supabase.from('lobbies').update(updateData).eq('id', targetId).select();
        if (res.isNotEmpty) responseData = res.first;
      } catch (_) {
        await _supabase.from('lobbies').update(updateData).eq('id', lobbyId);
      }
    }

    if (responseData != null) {
      return LobbyModel.fromJson(responseData as Map<String, dynamic>);
    }
    return null;
  }

  /// 15. Host can remove or unassign a referee from the match
  Future<void> removeRefereeSlot(String lobbyId, String refereeUserId) async {
    final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;
    await _supabase
        .from('lobby_participants')
        .delete()
        .eq('lobby_id', targetId)
        .eq('user_id', refereeUserId);
  }

  /// 16. Host can assign a specific user as the match referee
  Future<void> assignReferee(String lobbyId, String targetUserId) async {
    final dynamic targetId = int.tryParse(lobbyId) ?? lobbyId;
    try {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': targetId,
        'user_id': targetUserId,
        'status': 'approved',
        'role': 'referee',
      });
    } catch (_) {
      await _supabase.from('lobby_participants').insert({
        'lobby_id': targetId,
        'user_id': targetUserId,
        'status': 'approved',
      });
    }
  }
}
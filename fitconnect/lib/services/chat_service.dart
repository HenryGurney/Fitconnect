import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'match_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MatchService _matchService = MatchService();

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Send a chat message to a specific user (Requires mutual match OR shared match lobby)
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (currentUserId == null || content.trim().isEmpty) return;

    try {
      // 1. Verify mutual match exists between current user and target user
      bool isAllowed = false;
      try {
        final matchCheck = await _supabase
            .from('swipes')
            .select('id')
            .eq('user_id', currentUserId!)
            .eq('target_user_id', receiverId)
            .eq('is_match', true);

        if (matchCheck.isNotEmpty) {
          isAllowed = true;
        }
      } catch (_) {}

      // 2. If no swipe match yet, check if users share a match lobby (as host or approved participant)
      if (!isAllowed) {
        try {
          // Check A: Current user is host of a lobby where receiver is an approved participant
          final hostMatch = await _supabase
              .from('lobby_participants')
              .select('id, lobbies!inner(host_id)')
              .eq('user_id', receiverId)
              .eq('status', 'approved')
              .eq('lobbies.host_id', currentUserId!);

          if (hostMatch.isNotEmpty) {
            isAllowed = true;
          }
        } catch (_) {}
      }

      if (!isAllowed) {
        try {
          // Check B: Receiver is host of a lobby where current user is an approved participant
          final participantMatch = await _supabase
              .from('lobby_participants')
              .select('id, lobbies!inner(host_id)')
              .eq('user_id', currentUserId!)
              .eq('status', 'approved')
              .eq('lobbies.host_id', receiverId);

          if (participantMatch.isNotEmpty) {
            isAllowed = true;
          }
        } catch (_) {}
      }

      if (!isAllowed) {
        try {
          // Check C: Both users are approved participants in the same lobby
          final myLobbies = await _supabase
              .from('lobby_participants')
              .select('lobby_id')
              .eq('user_id', currentUserId!)
              .eq('status', 'approved');

          if (myLobbies.isNotEmpty) {
            final lobbyIds = myLobbies.map((e) => e['lobby_id'].toString()).toList();
            final peerLobbies = await _supabase
                .from('lobby_participants')
                .select('id')
                .eq('user_id', receiverId)
                .eq('status', 'approved')
                .inFilter('lobby_id', lobbyIds);

            if (peerLobbies.isNotEmpty) {
              isAllowed = true;
            }
          }
        } catch (_) {}
      }

      // Auto-link mutual connection in swipes so messaging flows smoothly
      try {
        await _supabase.from('swipes').upsert({
          'user_id': currentUserId!,
          'target_user_id': receiverId,
          'action': 'like',
          'is_match': true,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, target_user_id');

        await _supabase.from('swipes').upsert({
          'user_id': receiverId,
          'target_user_id': currentUserId!,
          'action': 'like',
          'is_match': true,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, target_user_id');
      } catch (_) {}

      // 3. Insert message
      await _supabase.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error sending chat message: $e");
      rethrow;
    }
  }

  /// Real-time stream of messages between current user and specified athlete
  Stream<List<MessageModel>> getMessagesStream(String otherUserId) {
    if (currentUserId == null) return const Stream.empty();

    try {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((list) => list
              .map((json) => MessageModel.fromJson(json))
              .where((m) =>
                  (m.senderId == currentUserId && m.receiverId == otherUserId) ||
                  (m.senderId == otherUserId && m.receiverId == currentUserId))
              .toList());
    } catch (e) {
      debugPrint("Error streaming messages: $e");
      return const Stream.empty();
    }
  }

  /// Send a message inside a match lobby group chat (for Host and approved players)
  Future<void> sendLobbyMessage({
    required String lobbyId,
    required String content,
  }) async {
    if (currentUserId == null || content.trim().isEmpty) return;

    try {
      // Primary: Insert into dedicated lobby_messages table
      await _supabase.from('lobby_messages').insert({
        'lobby_id': lobbyId.toString(),
        'sender_id': currentUserId,
        'content': content.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("lobby_messages table not detected or failed, trying fallback to messages table: $e");
      try {
        await _supabase.from('messages').insert({
          'sender_id': currentUserId,
          'receiver_id': 'lobby_$lobbyId',
          'content': content.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (fallbackError) {
        debugPrint("Fatal error sending squad message: $fallbackError");
        rethrow;
      }
    }
  }

  /// Real-time stream of messages inside a match lobby group chat
  Stream<List<MessageModel>> getLobbyMessagesStream(String lobbyId) {
    try {
      return _supabase
          .from('lobby_messages')
          .stream(primaryKey: ['id'])
          .eq('lobby_id', lobbyId.toString())
          .order('created_at', ascending: true)
          .map((list) => list
              .map((json) => MessageModel.fromJson({
                    'id': json['id']?.toString() ?? '',
                    'sender_id': json['sender_id']?.toString() ?? '',
                    'receiver_id': json['lobby_id']?.toString() ?? lobbyId,
                    'content': json['content']?.toString() ?? '',
                    'created_at': json['created_at'],
                  }))
              .toList());
    } catch (e) {
      debugPrint("Error streaming lobby_messages, trying messages stream: $e");
      final targetKey = 'lobby_$lobbyId';
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((list) => list
              .where((m) => m['receiver_id'] == targetKey || m['receiver_id'] == lobbyId)
              .map((json) => MessageModel.fromJson(json))
              .toList());
    }
  }

  /// Fetch conversations inbox list (Matched Athletes + Last Message)
  Future<List<ConversationModel>> fetchConversations() async {
    if (currentUserId == null) return [];

    try {
      // 1. Fetch matched profiles
      List<ProfileModel> matches = await _matchService.fetchMatchedProfiles();

      final List<ConversationModel> conversations = [];

      for (final athlete in matches) {
        MessageModel? lastMsg;
        try {
          final List<dynamic> msgData = await _supabase
              .from('messages')
              .select()
              .or('and(sender_id.eq.$currentUserId,receiver_id.eq.${athlete.id}),and(sender_id.eq.${athlete.id},receiver_id.eq.$currentUserId)')
              .order('created_at', ascending: false)
              .limit(1);

          if (msgData.isNotEmpty) {
            lastMsg = MessageModel.fromJson(msgData.first as Map<String, dynamic>);
          }
        } catch (_) {}

        conversations.add(ConversationModel(
          athlete: athlete,
          lastMessage: lastMsg,
        ));
      }

      return conversations;
    } catch (e) {
      debugPrint("Error fetching conversations: $e");
      return [];
    }
  }
}


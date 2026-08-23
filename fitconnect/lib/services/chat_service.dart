import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'match_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MatchService _matchService = MatchService();

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Send a chat message to a specific user (Requires mutual match)
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (currentUserId == null || content.trim().isEmpty) return;

    try {
      // 1. Verify mutual match exists between current user and target user
      final matchCheck = await _supabase
          .from('swipes')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('target_user_id', receiverId)
          .eq('is_match', true);

      if (matchCheck.isEmpty) {
        throw Exception("You can only message athletes you have mutually matched with!");
      }

      // 2. Insert message
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


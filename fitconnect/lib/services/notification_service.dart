import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _msgStreamSub;

  final StreamController<int> _unreadController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadController.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  GlobalKey<ScaffoldMessengerState>? rootScaffoldMessengerKey;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Initialize real-time notification engine
  void init({GlobalKey<ScaffoldMessengerState>? messengerKey}) {
    if (messengerKey != null) {
      rootScaffoldMessengerKey = messengerKey;
    }
    _refreshUnreadCount();
    _startRealtimeListeners();
  }

  /// Manually refresh unread messages count
  Future<void> _refreshUnreadCount() async {
    if (_currentUserId == null) return;
    try {
      final List<dynamic> data = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', _currentUserId!);

      _unreadCount = data.length > 5 ? 5 : data.length;
      _unreadController.add(_unreadCount);
    } catch (e) {
      debugPrint("Warning fetching unread message count: $e");
    }
  }

  /// Mark all messages as read or reset badge on chat screen visit
  void clearUnreadBadge() {
    _unreadCount = 0;
    _unreadController.add(0);
  }

  /// Set up Supabase Realtime listeners for incoming messages, match invites, and lobby events
  void _startRealtimeListeners() {
    if (_currentUserId == null) return;

    try {
      // 1. Listen for new direct messages
      _msgStreamSub?.cancel();
      _msgStreamSub = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .listen((messages) {
        if (messages.isNotEmpty) {
          final last = messages.last;
          if (last['receiver_id'] == _currentUserId) {
            _handleIncomingMessage(
              senderId: last['sender_id']?.toString() ?? '',
              content: last['content']?.toString() ?? '',
            );
          }
        }
      });

      // 2. Realtime Broadcast Channel for Match Events & Lobby Join Requests
      _realtimeChannel = _supabase.channel('user_notifications_$_currentUserId');
      _realtimeChannel
          ?.onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord['receiver_id'] == _currentUserId) {
                _handleIncomingMessage(
                  senderId: newRecord['sender_id']?.toString() ?? '',
                  content: newRecord['content']?.toString() ?? '',
                );
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'lobby_participants',
            callback: (payload) {
              _showLobbyAlert("⚽ New squad player joined your match lobby!");
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'swipes',
            callback: (payload) {
              final rec = payload.newRecord;
              if (rec['target_user_id'] == _currentUserId && rec['is_match'] == true) {
                _showMatchAlert("⚡ You have a new workout match! Check your inbox.");
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Realtime Notification error: $e");
    }
  }

  void _handleIncomingMessage({required String senderId, required String content}) async {
    _unreadCount += 1;
    _unreadController.add(_unreadCount);

    // Audio & Haptic Feedback Alert
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    // Fetch sender name
    String senderName = "New Message";
    try {
      final prof = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', senderId)
          .maybeSingle();
      if (prof != null && prof['name'] != null) {
        senderName = prof['name'].toString();
      }
    } catch (_) {}

    _showInAppBanner(
      title: senderName,
      message: content.length > 50 ? "${content.substring(0, 50)}..." : content,
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF39FF14),
    );
  }

  void _showLobbyAlert(String text) {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}

    _showInAppBanner(
      title: "Match Lobby Update",
      message: text,
      icon: Icons.sports_soccer_rounded,
      color: const Color(0xFF00E5FF),
    );
  }

  void _showMatchAlert(String text) {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _showInAppBanner(
      title: "New Match! ⚡",
      message: text,
      icon: Icons.flash_on_rounded,
      color: const Color(0xFFFFD700),
    );
  }

  void _showInAppBanner({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    if (rootScaffoldMessengerKey?.currentState == null) return;

    rootScaffoldMessengerKey!.currentState!.clearSnackBars();
    rootScaffoldMessengerKey!.currentState!.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void dispose() {
    _msgStreamSub?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    _unreadController.close();
  }
}

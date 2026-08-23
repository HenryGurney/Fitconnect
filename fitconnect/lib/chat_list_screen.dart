import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/models.dart';
import 'services/chat_service.dart';
import 'services/match_service.dart';
import 'lobby_service.dart';
import 'chat_detail_screen.dart';
import 'lobby_group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final MatchService _matchService = MatchService();
  final LobbyService _lobbyService = LobbyService();
  late TabController _tabController;

  StreamSubscription? _messageSub;
  bool _isLoading = true;
  List<ProfileModel> _newMatches = [];
  List<ConversationModel> _conversations = [];

  final Map<String, LobbyModel?> _lobbyCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessagesData();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    try {
      _messageSub = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .listen((_) {
        if (mounted) _loadMessagesData();
      });
    } catch (e) {
      debugPrint("Realtime inbox listener warning: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessagesData() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _matchService.fetchMatchedProfiles();
      final convos = await _chatService.fetchConversations();

      if (mounted) {
        setState(() {
          _newMatches = matches;
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading messages data: $e");
      if (mounted) {
        setState(() {
          _newMatches = [];
          _conversations = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<LobbyModel?> _getOrFetchLobby(String lobbyId) async {
    if (_lobbyCache.containsKey(lobbyId)) {
      return _lobbyCache[lobbyId];
    }
    final lobby = await _lobbyService.fetchLobbyById(lobbyId);
    _lobbyCache[lobbyId] = lobby;
    return lobby;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "CHATS",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF39FF14)),
            onPressed: _loadMessagesData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: Colors.white.withValues(alpha: 0.08),
          tabs: const [
            Tab(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
              text: "DIRECT MESSAGES",
            ),
            Tab(
              icon: Icon(Icons.groups_3_rounded, size: 18),
              text: "MATCH SQUADS",
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 1-on-1 Direct Messages
                _buildDirectMessagesTab(),

                // Tab 2: Match Squad Group Chats
                _buildMatchSquadChatsTab(),
              ],
            ),
    );
  }

  Widget _buildDirectMessagesTab() {
    return RefreshIndicator(
      color: const Color(0xFF39FF14),
      onRefresh: _loadMessagesData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Section 1: New Matches Horizontal Carousel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFF39FF14), size: 16),
                const SizedBox(width: 6),
                Text(
                  "NEW ATHLETE MATCHES (${_newMatches.length})",
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _newMatches.length,
              itemBuilder: (context, index) {
                final athlete = _newMatches[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(athlete: athlete),
                      ),
                    ).then((_) => _loadMessagesData());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF39FF14), Color(0xFF00E5FF)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1E1E1E),
                            child: ClipOval(
                              child: _buildAvatarImage(athlete.imageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          athlete.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white10),
          ),
          const SizedBox(height: 8),

          // Section 2: Messages Inbox List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "CONVERSATIONS",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),

          if (_conversations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    const Text(
                      "No direct messages yet. Swipe and match with athletes to start chatting!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._conversations.map((convo) {
              final athlete = convo.athlete;
              final lastMsg = convo.lastMessage;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(athlete: athlete),
                      ),
                    ).then((_) => _loadMessagesData());
                  },
                  leading: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: ClipOval(
                          child: _buildAvatarImage(athlete.imageUrl),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF121212), width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        athlete.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          athlete.sport.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      lastMsg != null ? lastMsg.content : "Tap to send a message",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: lastMsg != null ? Colors.white70 : Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMatchSquadChatsTab() {
    final currentUserId = _lobbyService.currentUserId;

    return StreamBuilder<List<LobbyModel>>(
      stream: _lobbyService.getMyLobbiesStream(),
      builder: (context, hostedSnapshot) {
        return StreamBuilder<List<LobbyParticipantModel>>(
          stream: _lobbyService.getMyJoinedRequestsStream(),
          builder: (context, joinedSnapshot) {
            if (hostedSnapshot.connectionState == ConnectionState.waiting &&
                joinedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
            }

            final hostedLobbies = hostedSnapshot.data ?? [];
            final approvedRequests = (joinedSnapshot.data ?? []).where((p) => p.status == 'approved').toList();

            if (hostedLobbies.isEmpty && approvedRequests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF39FF14).withValues(alpha: 0.05),
                          border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.groups_3_rounded, size: 52, color: Color(0xFF39FF14)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "NO MATCH SQUADS YET",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "When you host a match or get accepted into one, your squad group chat will automatically appear here!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // 1. Hosted Squad Chats
                if (hostedLobbies.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "MATCHES YOU'RE HOSTING",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...hostedLobbies.map((lobby) => _buildSquadChatTile(lobby, isHost: true)),
                  const SizedBox(height: 12),
                ],

                // 2. Joined Squad Chats
                if (approvedRequests.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer_rounded, color: Color(0xFF39FF14), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "JOINED MATCH SQUADS",
                          style: TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...approvedRequests.map((req) {
                    return FutureBuilder<LobbyModel?>(
                      future: _getOrFetchLobby(req.lobbyId),
                      builder: (context, snap) {
                        final lobby = snap.data;
                        // Avoid showing lobbies where current user is the host in the joined section
                        if (lobby == null || lobby.hostId == currentUserId) return const SizedBox.shrink();
                        return _buildSquadChatTile(lobby, isHost: false);
                      },
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSquadChatTile(LobbyModel lobby, {required bool isHost}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isHost ? const Color(0xFF131912) : const Color(0xFF101010),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHost
              ? const Color(0xFF39FF14).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyGroupChatScreen(lobby: lobby),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF39FF14).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.groups_rounded, color: Color(0xFF39FF14), size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                lobby.cleanTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            if (isHost) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("👑 HOST", style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                lobby.sport.toUpperCase(),
                style: const TextStyle(color: Color(0xFF39FF14), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${lobby.matchDate ?? ''} • ${lobby.locationName}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF39FF14).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF39FF14), size: 16),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? imgPath) {
    if (imgPath != null && imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        width: 50, height: 50,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14)),
      );
    } else if (imgPath != null && imgPath.isNotEmpty) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        width: 50, height: 50,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14)),
      );
    }
    return const Icon(Icons.person, color: Color(0xFF39FF14));
  }
}

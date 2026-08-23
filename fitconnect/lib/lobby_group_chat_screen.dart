import 'package:flutter/material.dart';
import 'models/models.dart';
import 'services/chat_service.dart';
import 'lobby_service.dart';
import 'lobby_details_page.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';
import 'widgets/report_player_modal.dart';

class LobbyGroupChatScreen extends StatefulWidget {
  final LobbyModel lobby;

  const LobbyGroupChatScreen({super.key, required this.lobby});

  @override
  State<LobbyGroupChatScreen> createState() => _LobbyGroupChatScreenState();
}

class _LobbyGroupChatScreenState extends State<LobbyGroupChatScreen> {
  final ChatService _chatService = ChatService();
  final LobbyService _lobbyService = LobbyService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, ProfileModel?> _profileCache = {};

  String _pinnedAnnouncement = "📌 Court details: Please arrive 15m early with turf shoes!";
  bool _isAnnouncementExpanded = true;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<ProfileModel?> _getSenderProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    final profile = await _lobbyService.fetchPlayerProfile(userId);
    _profileCache[userId] = profile;
    return profile;
  }

  Future<void> _handleSendMessage([String? prefilled]) async {
    final text = (prefilled ?? _msgController.text).trim();
    if (text.isEmpty) return;

    if (prefilled == null) {
      _msgController.clear();
    }

    try {
      await _chatService.sendLobbyMessage(
        lobbyId: widget.lobby.id,
        content: text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSquadRosterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StreamBuilder<List<LobbyParticipantModel>>(
        stream: _lobbyService.getAllLobbyRequestsStream(widget.lobby.id),
        builder: (context, snapshot) {
          final participants = snapshot.data ?? [];
          final approvedList = participants.where((p) => p.status == 'approved').toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MATCH SQUAD (${1 + approvedList.length}/${widget.lobby.maxParticipants})",
                      style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: widget.lobby)),
                        );
                      },
                      child: const Text("MATCH INFO >", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Host Entry
                Builder(
                  builder: (context) {
                    final currentUserId = _chatService.currentUserId;
                    final isMeHost = widget.lobby.hostId == currentUserId;
                    final hostName = widget.lobby.hostProfile?.name ?? "Host Organizer";

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showPlayerProfilePeekSheet(widget.lobby.hostProfile, isMe: isMeHost, isHost: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMeHost ? const Color(0xFF141E10) : const Color(0xFF1C1910),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMeHost
                                ? const Color(0xFF39FF14).withValues(alpha: 0.5)
                                : const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFFFD700),
                              child: widget.lobby.hostProfile?.imageUrl != null && widget.lobby.hostProfile!.imageUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: _buildAvatarImage(widget.lobby.hostProfile!.imageUrl),
                                    )
                                  : const Icon(Icons.star_rounded, color: Colors.black, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        hostName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (isMeHost) ...[
                                        const SizedBox(width: 5),
                                        const Text(
                                          "(You)",
                                          style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Match Organizer • ${widget.lobby.sport.toUpperCase()} • Tap for Bio",
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isMeHost
                                    ? const Color(0xFF39FF14).withValues(alpha: 0.2)
                                    : const Color(0xFFFFD700).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isMeHost ? "👑 YOU (HOST)" : "👑 HOST",
                                style: TextStyle(
                                  color: isMeHost ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Approved Players List
                if (approvedList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("No other players have joined yet.", style: TextStyle(color: Colors.white38, fontSize: 13)),
                  )
                else
                  ...approvedList.map((p) {
                    final currentUserId = _chatService.currentUserId;
                    final isMe = p.userId == currentUserId;

                    return FutureBuilder<ProfileModel?>(
                      future: _getSenderProfile(p.userId),
                      builder: (context, profileSnap) {
                        final player = profileSnap.data;
                        final playerName = player?.name ?? "Teammate";

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showPlayerProfilePeekSheet(player, isMe: isMe, isHost: false);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF141E10) : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: isMe
                                  ? Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF333333),
                                  child: player?.imageUrl != null && player!.imageUrl!.isNotEmpty
                                      ? ClipOval(child: _buildAvatarImage(player.imageUrl))
                                      : Text(
                                          playerName.isNotEmpty ? playerName[0].toUpperCase() : 'A',
                                          style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            playerName,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 5),
                                            const Text(
                                              "(You)",
                                              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (player?.sport != null || player?.skill != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            "${player?.sport ?? ''} • ${player?.skill ?? 'Player'} • Tap for Bio".trim(),
                                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isMe ? "YOU" : "CONFIRMED",
                                    style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditAnnouncementDialog() {
    final currentUserId = _chatService.currentUserId;
    if (widget.lobby.hostId != currentUserId) return;

    final editController = TextEditingController(text: _pinnedAnnouncement);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.push_pin_rounded, color: Color(0xFFFFD700), size: 20),
            SizedBox(width: 8),
            Text("Edit Pinned Notice", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "e.g. Court 3, wear dark jerseys!",
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF222222),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black),
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  _pinnedAnnouncement = newText;
                });
                _handleSendMessage("📌 PINNED ANNOUNCEMENT: $newText");
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text("PIN & BROADCAST", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlayerProfilePeekSheet(ProfileModel? profile, {required bool isMe, required bool isHost}) {
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isHost ? const Color(0xFFFFD700) : const Color(0xFF39FF14),
                    child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                        ? ClipOval(child: _buildAvatarImage(profile.imageUrl))
                        : Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isMe ? "${profile.name} (You)" : profile.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                            if (isHost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text("👑 HOST", style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(profile.location, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sport & Skill Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile.sport.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Level: ${profile.skill}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Reliability Score Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF39FF14), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Player Reliability", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text("${profile.reliabilityScore}%", style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: profile.reliabilityScore / 100.0,
                              minHeight: 5,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39FF14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action: 1-on-1 Chat or View My Profile
              if (!isMe) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(athlete: profile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      "DIRECT MESSAGE ${profile.name.toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ReportPlayerModal.show(context, reportedAthlete: profile, lobbyId: widget.lobby.id);
                    },
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text(
                      "REPORT ATHLETE / NO-SHOW",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF39FF14),
                      side: const BorderSide(color: Color(0xFF39FF14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text("VIEW & EDIT MY PROFILE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;
    final isHost = widget.lobby.hostId == currentUserId;

    final quickReplies = isHost
        ? [
            "📢 Welcome to the match squad!",
            "📍 Court/Field # updated!",
            "💵 Fee: ${widget.lobby.feePerPax ?? 'Free'}",
            "⏰ Kickoff in 30 mins!",
            "👟 Bring dark & light jerseys",
          ]
        : [
            "⚽ Ready to play!",
            "📍 What's the court number?",
            "⏰ On my way!",
            "🚗 Just parked, heading in",
            "👍 See you guys there!",
          ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _showSquadRosterSheet,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_3_rounded, color: Color(0xFF39FF14), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lobby.cleanTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                    ),
                    Text(
                      "${widget.lobby.sport.toUpperCase()} SQUAD CHAT • TAP FOR ROSTER",
                      style: const TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            tooltip: "Match Squad & Info",
            onPressed: _showSquadRosterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Match Venue & Time Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF39FF14)),
                const SizedBox(width: 6),
                Text(
                  widget.lobby.matchDate ?? 'Upcoming',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (widget.lobby.matchTime != null) ...[
                  const SizedBox(width: 6),
                  Text("• ${widget.lobby.matchTime}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.lobby.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 📌 Collapsible Pinned Announcement Banner
          if (_pinnedAnnouncement.isNotEmpty)
            GestureDetector(
              onTap: isHost ? _showEditAnnouncementDialog : () => setState(() => _isAnnouncementExpanded = !_isAnnouncementExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF241F0E),
                  border: Border(bottom: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin_rounded, color: Color(0xFFFFD700), size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pinnedAnnouncement,
                        maxLines: _isAnnouncementExpanded ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFE082), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("EDIT", style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900)),
                      )
                    else
                      Icon(
                        _isAnnouncementExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFFFFD700),
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),

          // Messages Stream
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getLobbyMessagesStream(widget.lobby.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF39FF14).withValues(alpha: 0.05),
                              border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Color(0xFF39FF14)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "SQUAD DISCUSSION ROOM",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Discuss arrival time, court numbers, tactics, or gear with everyone in this match squad!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMsgMe = msg.senderId == currentUserId;
                    final isMsgHost = msg.senderId == widget.lobby.hostId;

                    return _buildMessageItem(msg, isMsgMe, isMsgHost);
                  },
                );
              },
            ),
          ),

          // Quick Preset Chips (Host vs Player Contextual)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: quickReplies.length,
              itemBuilder: (context, index) {
                final reply = quickReplies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF141414),
                    side: BorderSide(color: isHost ? const Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    label: Text(
                      reply,
                      style: TextStyle(
                        color: isHost ? const Color(0xFFFFD700) : Colors.white70,
                        fontSize: 11,
                        fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onPressed: () => _handleSendMessage(reply),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Message the match squad...",
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF39FF14),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    onPressed: () => _handleSendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageModel msg, bool isMe, bool isHost) {
    final timeStr = "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}";

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF39FF14),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<ProfileModel?>(
      future: _getSenderProfile(msg.senderId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final senderName = isHost
            ? (widget.lobby.hostProfile?.name ?? profile?.name ?? "Host")
            : (profile?.name ?? "Teammate");

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showPlayerProfilePeekSheet(profile, isMe: false, isHost: isHost),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isHost
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : const Color(0xFF222222),
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isHost ? const Color(0xFFFFD700) : const Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showPlayerProfilePeekSheet(profile, isMe: false, isHost: isHost),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (isHost) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "👑 HOST",
                                style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        msg.content,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(timeStr, style: const TextStyle(color: Colors.white24, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage(String? imgPath) {
    if (imgPath != null && imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14), size: 18),
      );
    } else if (imgPath != null && imgPath.isNotEmpty) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF39FF14), size: 18),
      );
    }
    return const Icon(Icons.person, color: Color(0xFF39FF14), size: 18);
  }
}

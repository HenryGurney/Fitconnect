import 'package:flutter/material.dart';
import 'lobby_service.dart';
import 'models/models.dart';
import 'lobby_details_page.dart';
import 'create_lobby_page.dart';
import 'lobby_group_chat_screen.dart';
import 'widgets/pro_badge_widget.dart';

class MyLobbiesScreen extends StatefulWidget {
  const MyLobbiesScreen({super.key});

  @override
  State<MyLobbiesScreen> createState() => _MyLobbiesScreenState();
}

class _MyLobbiesScreenState extends State<MyLobbiesScreen> with SingleTickerProviderStateMixin {
  final LobbyService _lobbyService = LobbyService();
  late TabController _tabController;
  final Map<String, LobbyModel?> _lobbyCache = {};

  Stream<List<LobbyModel>> get _myHostedLobbiesStream => _lobbyService.getMyLobbiesStream();
  Stream<List<LobbyParticipantModel>> get _myJoinedRequestsStream => _lobbyService.getMyJoinedRequestsStream();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _lobbyCache.clear();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  Future<LobbyModel?> _getOrFetchLobby(String lobbyId) async {
    if (_lobbyCache.containsKey(lobbyId)) {
      return _lobbyCache[lobbyId];
    }
    final lobby = await _lobbyService.fetchLobbyById(lobbyId);
    _lobbyCache[lobbyId] = lobby;
    return lobby;
  }

  Future<void> _deleteLobby(String lobbyId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text("Cancel Match?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel '$title'? All players registered in this match will be notified and removed.",
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("KEEP MATCH", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B0F0F),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CANCEL MATCH", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _lobbyService.deleteLobby(lobbyId);
      if (mounted) {
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Match cancelled and deleted successfully."),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Failed to delete match: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _leaveMatch(String lobbyId, String matchTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text("Leave Match?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Text(
          "Are you sure you want to withdraw and leave '$matchTitle'?",
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("STAY IN MATCH", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B0F0F),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("LEAVE MATCH", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _lobbyService.leaveLobby(lobbyId);
      if (mounted) {
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Withdrew from match."),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Error leaving match: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showEditLobbySheet(LobbyModel lobby) {
    final titleCtrl = TextEditingController(text: lobby.cleanTitle);
    final locationCtrl = TextEditingController(text: lobby.locationName);
    final maxPlayersCtrl = TextEditingController(text: lobby.maxParticipants.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "EDIT MATCH DETAILS",
              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            _buildInputField("Match Title", titleCtrl, Icons.sports_rounded),
            const SizedBox(height: 10),
            _buildInputField("Venue / Location", locationCtrl, Icons.location_on_outlined),
            const SizedBox(height: 10),
            _buildInputField("Max Players", maxPlayersCtrl, Icons.groups_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  try {
                    await _lobbyService.updateLobby(
                      lobbyId: lobby.id,
                      title: titleCtrl.text.trim(),
                      locationName: locationCtrl.text.trim(),
                      maxParticipants: int.tryParse(maxPlayersCtrl.text.trim()) ?? 10,
                    );

                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text("Match updated successfully!"),
                          backgroundColor: const Color(0xFF1E1E1E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      setState(() {});
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error updating match: $e"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          "MY MATCH SQUADS",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Host New Match",
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF39FF14), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF39FF14),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "HOSTED BY ME"),
                Tab(text: "JOINED MATCHES"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHostedTab(),
          _buildJoinedTab(),
        ],
      ),
    );
  }

  /// 1. Hosted Matches Tab
  Widget _buildHostedTab() {
    return RefreshIndicator(
      color: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF141414),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<LobbyModel>>(
        stream: _myHostedLobbiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }

          final lobbies = snapshot.data ?? [];

          if (lobbies.isEmpty) {
            return _buildEmptyState(
              icon: Icons.sports_soccer_rounded,
              title: "NO HOSTED MATCHES",
              subtitle: "You haven't organized any match lobbies yet.\nLaunch one to bring players together!",
              buttonText: "HOST A MATCH",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: lobbies.length,
            itemBuilder: (context, index) {
              final lobby = lobbies[index];
              return _buildHostedCard(lobby);
            },
          );
        },
      ),
    );
  }

  Widget _buildHostedCard(LobbyModel lobby) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF39FF14).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sport tag, Organizer badge, Capacity
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lobby.sport.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "YOUR MATCH",
                  style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              if (lobby.hasReferee) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_rounded, color: Color(0xFFFFD700), size: 10),
                      SizedBox(width: 3),
                      Text("REFEREED", style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              StreamBuilder<List<LobbyParticipantModel>>(
                stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
                builder: (context, snapshot) {
                  final participants = snapshot.data ?? [];
                  final approvedCount = participants.where((p) => p.status == 'approved').length;
                  final totalFilled = 1 + approvedCount;
                  final isFull = totalFilled >= lobby.maxParticipants;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.redAccent.withValues(alpha: 0.15) : const Color(0xFF39FF14).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$totalFilled/${lobby.maxParticipants} Joined",
                      style: TextStyle(
                        color: isFull ? Colors.redAccent : const Color(0xFF39FF14),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Pro Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  lobby.cleanTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lobby.hostProfile?.isPremium ?? false) ...[
                const SizedBox(width: 6),
                const ProBadgeWidget(isCompact: true),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Joined Players Facepile
          StreamBuilder<List<LobbyParticipantModel>>(
            stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
            builder: (context, snapshot) {
              final participants = snapshot.data ?? [];
              final approved = participants.where((p) => p.status == 'approved').toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Host Avatar
                          FutureBuilder<ProfileModel?>(
                            future: _lobbyService.fetchPlayerProfile(lobby.hostId),
                            builder: (context, hSnap) {
                              final h = hSnap.data ?? lobby.hostProfile;
                              return _buildAvatar(
                                imageUrl: h?.imageUrl,
                                name: h?.name ?? 'Host',
                                radius: 10,
                                borderColor: const Color(0xFFFFD700),
                              );
                            },
                          ),
                          // Up to 4 approved players
                          ...approved.take(4).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: FutureBuilder<ProfileModel?>(
                                future: _lobbyService.fetchPlayerProfile(p.userId),
                                builder: (context, pSnap) {
                                  final player = pSnap.data;
                                  return _buildAvatar(
                                    imageUrl: player?.imageUrl,
                                    name: player?.name ?? 'P',
                                    radius: 10,
                                    borderColor: const Color(0xFF39FF14),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        approved.isEmpty
                            ? "Waiting for squad players"
                            : "${approved.length + 1} players in squad",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lobby.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Schedule & Fee
          Row(
            children: [
              if (lobby.matchDate != null || lobby.matchTime != null) ...[
                const Icon(Icons.schedule_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  "${lobby.matchDate ?? ''} ${lobby.matchTime != null ? '• ${lobby.matchTime}' : ''}".trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
              const Spacer(),
              if (lobby.feePerPax != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lobby.feePerPax!,
                    style: const TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),

          // Pending Requests Alert
          StreamBuilder<List<LobbyParticipantModel>>(
            stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
            builder: (context, snapshot) {
              final participants = snapshot.data ?? [];
              final pendingList = participants.where((p) => p.status == 'pending').toList();

              if (pendingList.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${pendingList.length} pending athlete request${pendingList.length > 1 ? 's' : ''}",
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const Text("Review", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 11)),
                    const Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 14),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
                    );
                  },
                  icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                  label: const Text("MANAGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                tooltip: "Squad Group Chat",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LobbyGroupChatScreen(lobby: lobby)),
                  );
                },
                icon: const Icon(Icons.forum_rounded, color: Color(0xFF39FF14), size: 16),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                tooltip: "Edit Match Details",
                onPressed: () => _showEditLobbySheet(lobby),
                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                tooltip: "Cancel Match",
                onPressed: () => _deleteLobby(lobby.id, lobby.cleanTitle),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Joined Matches Tab
  Widget _buildJoinedTab() {
    return RefreshIndicator(
      color: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF141414),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<LobbyParticipantModel>>(
        stream: _myJoinedRequestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _buildEmptyState(
              icon: Icons.groups_rounded,
              title: "NO JOINED MATCHES",
              subtitle: "You haven't requested or joined any matches yet.\nExplore the lobby feed to jump into a game!",
              buttonText: "EXPLORE MATCHES",
              onTap: () => Navigator.pop(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return FutureBuilder<LobbyModel?>(
                future: _getOrFetchLobby(req.lobbyId),
                builder: (context, lobbySnap) {
                  final lobby = lobbySnap.data;
                  if (lobby == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildJoinedCard(lobby, req);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJoinedCard(LobbyModel lobby, LobbyParticipantModel participant) {
    final status = participant.status;
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isReferee = participant.role == 'referee';

    Color statusColor = Colors.grey;
    String statusText = status.toUpperCase();

    if (isApproved) {
      statusColor = const Color(0xFF39FF14);
      statusText = isReferee ? "MATCH REFEREE" : "JOINED SQUAD";
    } else if (isPending) {
      statusColor = Colors.amber;
      statusText = "PENDING APPROVAL";
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusText = "DECLINED";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved ? const Color(0xFF39FF14).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sport tag, Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lobby.sport.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved ? (isReferee ? Icons.sports_rounded : Icons.check_circle_rounded) : (isPending ? Icons.hourglass_top_rounded : Icons.cancel_rounded),
                      color: statusColor,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Pro Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  lobby.cleanTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lobby.hostProfile?.isPremium ?? false) ...[
                const SizedBox(width: 6),
                const ProBadgeWidget(isCompact: true),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Host Profile row
          FutureBuilder<ProfileModel?>(
            future: _lobbyService.fetchPlayerProfile(lobby.hostId),
            builder: (context, hostSnap) {
              final hostProfile = hostSnap.data ?? lobby.hostProfile;
              final hostName = hostProfile?.name ?? 'Match Host';
              final hostImg = hostProfile?.imageUrl;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    _buildAvatar(
                      imageUrl: hostImg,
                      name: hostName,
                      radius: 10,
                      borderColor: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        "Hosted by $hostName",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "HOST",
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Joined Players Facepile
          StreamBuilder<List<LobbyParticipantModel>>(
            stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
            builder: (context, snapshot) {
              final participants = snapshot.data ?? [];
              final approved = participants.where((p) => p.status == 'approved').toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<ProfileModel?>(
                            future: _lobbyService.fetchPlayerProfile(lobby.hostId),
                            builder: (context, hSnap) {
                              final h = hSnap.data ?? lobby.hostProfile;
                              return _buildAvatar(
                                imageUrl: h?.imageUrl,
                                name: h?.name ?? 'Host',
                                radius: 10,
                                borderColor: const Color(0xFFFFD700),
                              );
                            },
                          ),
                          ...approved.take(4).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: FutureBuilder<ProfileModel?>(
                                future: _lobbyService.fetchPlayerProfile(p.userId),
                                builder: (context, pSnap) {
                                  final player = pSnap.data;
                                  return _buildAvatar(
                                    imageUrl: player?.imageUrl,
                                    name: player?.name ?? 'P',
                                    radius: 10,
                                    borderColor: const Color(0xFF39FF14),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        approved.isEmpty
                            ? "Host + waiting for players"
                            : "${approved.length + 1} athletes in squad",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lobby.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Schedule & Fee
          Row(
            children: [
              if (lobby.matchDate != null || lobby.matchTime != null) ...[
                const Icon(Icons.schedule_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  "${lobby.matchDate ?? ''} ${lobby.matchTime != null ? '• ${lobby.matchTime}' : ''}".trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
              const Spacer(),
              if (lobby.feePerPax != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lobby.feePerPax!,
                    style: const TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
                    );
                  },
                  child: const Text("VIEW DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              if (isApproved) ...[
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                    ),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: "Squad Group Chat",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LobbyGroupChatScreen(lobby: lobby)),
                    );
                  },
                  icon: const Icon(Icons.forum_rounded, color: Color(0xFF39FF14), size: 16),
                ),
              ],
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                tooltip: isPending ? "Withdraw Request" : "Leave Match",
                onPressed: () => _leaveMatch(lobby.id, lobby.cleanTitle),
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
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
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.15)),
                    ),
                    child: Icon(icon, size: 40, color: const Color(0xFF39FF14)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onTap,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String? imageUrl,
    required String name,
    required double radius,
    required Color borderColor,
  }) {
    Widget imageWidget;

    if (imageUrl != null && imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(name, radius),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.asset(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(name, radius),
      );
    } else {
      imageWidget = _buildFallbackInitial(name, radius);
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        color: borderColor.withValues(alpha: 0.12),
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _buildFallbackInitial(String name, double radius) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
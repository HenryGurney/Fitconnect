import 'package:flutter/material.dart';
import 'lobby_service.dart';
import 'models/models.dart';
import 'lobby_details_page.dart';
import 'create_lobby_page.dart';
import 'lobby_group_chat_screen.dart';

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
            Text("Cancel Match?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel and delete '$title'? All players registered in this match will be notified and removed.",
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
            duration: const Duration(seconds: 5),
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
            Text("Leave Match?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
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
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.all(Radius.circular(10))))),
            const SizedBox(height: 20),
            const Text("EDIT MATCH DETAILS", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            _buildInputField("Match Title", titleCtrl, Icons.sports),
            const SizedBox(height: 12),
            _buildInputField("Location / Venue", locationCtrl, Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildInputField("Max Players", maxPlayersCtrl, Icons.groups_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Update error: $e"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "MY LOBBIES",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
              icon: Icon(Icons.star_rounded, size: 18),
              text: "HOSTED BY ME",
            ),
            Tab(
              icon: Icon(Icons.groups_rounded, size: 18),
              text: "JOINED MATCHES",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Hosted by Me
          _buildHostedByMeTab(),

          // Tab 2: Joined Matches
          _buildJoinedMatchesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
          );
        },
        icon: const Icon(Icons.add, size: 22),
        label: const Text("HOST A MATCH", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  /// Tab 1: Lobbies Hosted by Current User
  Widget _buildHostedByMeTab() {
    return RefreshIndicator(
      color: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF0F0F0F),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<LobbyModel>>(
        stream: _myHostedLobbiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading your lobbies: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final myLobbies = snapshot.data ?? [];

          if (myLobbies.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD700).withValues(alpha: 0.05),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.sports_kabaddi, size: 52, color: Color(0xFFFFD700)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "YOU HAVEN'T HOSTED ANY MATCHES",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Create a sports game room to invite players!",
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("CREATE FIRST MATCH", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: myLobbies.length,
            itemBuilder: (context, index) {
              final lobby = myLobbies[index];
              return _buildHostedLobbyCard(lobby);
            },
          );
        },
      ),
    );
  }

  Widget _buildHostedLobbyCard(LobbyModel lobby) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141912),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39FF14).withValues(alpha: 0.05),
              blurRadius: 16,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges & Live Capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lobby.sport.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                            SizedBox(width: 3),
                            Text(
                              "ORGANIZER",
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Live Capacity Stream Badge
                StreamBuilder<List<LobbyParticipantModel>>(
                  stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
                  builder: (context, snapshot) {
                    final participants = snapshot.data ?? [];
                    final approvedCount = participants.where((p) => p.status == 'approved').length;
                    final totalFilled = 1 + approvedCount;
                    final slotsLeft = (lobby.maxParticipants - totalFilled).clamp(0, lobby.maxParticipants);
                    final isFull = totalFilled >= lobby.maxParticipants;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFull
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : const Color(0xFF39FF14).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFull
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : const Color(0xFF39FF14).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isFull ? "FULL ($totalFilled/${lobby.maxParticipants})" : "$totalFilled/${lobby.maxParticipants} • $slotsLeft LEFT",
                        style: TextStyle(
                          color: isFull ? Colors.redAccent : const Color(0xFF39FF14),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Match Title
            Text(
              lobby.cleanTitle,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            // Venue Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lobby.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date, Time, Fee
            Row(
              children: [
                if (lobby.matchDate != null || lobby.matchTime != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF39FF14), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${lobby.matchDate ?? ''} ${lobby.matchTime != null ? '• ${lobby.matchTime}' : ''}".trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lobby.feePerPax != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_rounded, color: Color(0xFF39FF14), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          lobby.feePerPax!,
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Pending Join Requests Alert Banner
            StreamBuilder<List<LobbyParticipantModel>>(
              stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
              builder: (context, snapshot) {
                final participants = snapshot.data ?? [];
                final pendingList = participants.where((p) => p.status == 'pending').toList();

                if (pendingList.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${pendingList.length} pending player request${pendingList.length > 1 ? 's' : ''}",
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Review",
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("MANAGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                    ),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(38, 38),
                  ),
                  tooltip: "Squad Group Chat",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LobbyGroupChatScreen(lobby: lobby)),
                    );
                  },
                  icon: const Icon(Icons.forum_rounded, color: Color(0xFF39FF14), size: 18),
                ),
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(38, 38),
                  ),
                  tooltip: "Edit Match Details",
                  onPressed: () => _showEditLobbySheet(lobby),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(38, 38),
                  ),
                  onPressed: () => _deleteLobby(lobby.id, lobby.title),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  tooltip: "Cancel Match",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 2: Lobbies the User has Requested / Joined
  Widget _buildJoinedMatchesTab() {
    return RefreshIndicator(
      color: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF0F0F0F),
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<LobbyParticipantModel>>(
        stream: _myJoinedRequestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading joined matches: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final joinedRequests = snapshot.data ?? [];

          if (joinedRequests.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
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
                          "NO JOINED MATCHES YET",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Explore active lobbies and request to join upcoming games!",
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: joinedRequests.length,
            itemBuilder: (context, index) {
              final req = joinedRequests[index];
              return FutureBuilder<LobbyModel?>(
                future: _getOrFetchLobby(req.lobbyId),
                builder: (context, lobbySnapshot) {
                  final lobby = lobbySnapshot.data;
                  if (lobby == null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  return _buildJoinedLobbyCard(req, lobby);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJoinedLobbyCard(LobbyParticipantModel req, LobbyModel lobby) {
    final status = req.status; // 'approved', 'pending', 'rejected'
    final isApproved = status == 'approved';
    final isPending = status == 'pending';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isApproved
                ? const Color(0xFF39FF14).withValues(alpha: 0.35)
                : (isPending ? Colors.amber.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status & Sport Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lobby.sport.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFF0F2B12)
                        : (isPending ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFF2B0F0F)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isApproved
                          ? const Color(0xFF39FF14).withValues(alpha: 0.4)
                          : (isPending ? Colors.amber.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved ? Icons.check_circle : (isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined),
                        size: 13,
                        color: isApproved ? const Color(0xFF39FF14) : (isPending ? Colors.amber : Colors.redAccent),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? "SQUAD MEMBER" : (isPending ? "PENDING REVIEW" : "DECLINED"),
                        style: TextStyle(
                          color: isApproved ? const Color(0xFF39FF14) : (isPending ? Colors.amber : Colors.redAccent),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              lobby.cleanTitle,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lobby.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date / Time / Fee
            Row(
              children: [
                if (lobby.matchDate != null || lobby.matchTime != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF39FF14), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${lobby.matchDate ?? ''} ${lobby.matchTime != null ? '• ${lobby.matchTime}' : ''}".trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lobby.feePerPax != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_rounded, color: Color(0xFF39FF14), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          lobby.feePerPax!,
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 18),

            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("VIEW MATCH", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ),
                if (isApproved) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                      ),
                      padding: const EdgeInsets.all(10),
                      minimumSize: const Size(38, 38),
                    ),
                    tooltip: "Squad Group Chat",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LobbyGroupChatScreen(lobby: lobby)),
                      );
                    },
                    icon: const Icon(Icons.forum_rounded, color: Color(0xFF39FF14), size: 18),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(38, 38),
                  ),
                  tooltip: isApproved ? "Leave Match" : "Withdraw Request",
                  onPressed: () => _leaveMatch(lobby.id, lobby.cleanTitle),
                  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
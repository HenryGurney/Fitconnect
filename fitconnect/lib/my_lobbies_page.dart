import 'package:flutter/material.dart';
import 'lobby_service.dart';
import 'models/models.dart';

class MyLobbiesScreen extends StatefulWidget {
  const MyLobbiesScreen({super.key});

  @override
  State<MyLobbiesScreen> createState() => _MyLobbiesScreenState();
}

class _MyLobbiesScreenState extends State<MyLobbiesScreen> {
  final LobbyService _lobbyService = LobbyService();

  Stream<List<LobbyModel>> get _myLobbiesStream => _lobbyService.getMyLobbiesStream();

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  Future<void> _deleteLobby(String lobbyId, String title) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("CANCEL MATCH?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text("Are you sure you want to delete '$title'? This action cannot be undone.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("KEEP LOBBY", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _lobbyService.deleteLobby(lobbyId);
      if (mounted) {
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Lobby deleted successfully.", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF39FF14),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Failed to delete lobby: $e"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditLobbySheet(LobbyModel lobby) {
    final titleCtrl = TextEditingController(text: lobby.title);
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
            const Text("EDIT LOBBY DETAILS", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            _buildInputField("Match Title", titleCtrl, Icons.sports),
            const SizedBox(height: 12),
            _buildInputField("Location / Venue", locationCtrl, Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildInputField("Max Players", maxPlayersCtrl, Icons.groups_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
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

                    if (context.mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text("Lobby updated cleanly!"),
                          backgroundColor: const Color(0xFF39FF14),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
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
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF39FF14),
        backgroundColor: const Color(0xFF0F0F0F),
        onRefresh: _handleRefresh,
        child: StreamBuilder<List<LobbyModel>>(
          stream: _myLobbiesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
              );
            }

            final myLobbies = snapshot.data ?? [];

            if (myLobbies.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Text(
                        "You haven't created any matches yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: myLobbies.length,
              itemBuilder: (context, index) {
                final lobby = myLobbies[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Text(
                            "LIMIT: ${lobby.maxParticipants} PLYRS",
                            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lobby.title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
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
                      if (lobby.matchDate != null || lobby.matchTime != null) ...[
                        const SizedBox(height: 8),
                        Row(
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
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showEditLobbySheet(lobby),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text("EDIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                                ),
                              ),
                              onPressed: () => _deleteLobby(lobby.id, lobby.title),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
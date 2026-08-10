import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lobby_service.dart';
import 'models/models.dart';

class LobbyDetailsPage extends StatefulWidget {
  final LobbyModel? lobby;
  final Map<String, dynamic>? lobbyData;

  const LobbyDetailsPage({
    super.key,
    this.lobby,
    this.lobbyData,
  });

  @override
  State<LobbyDetailsPage> createState() => _LobbyDetailsPageState();
}

class _LobbyDetailsPageState extends State<LobbyDetailsPage> {
  final LobbyService _lobbyService = LobbyService();
  bool _isProcessing = false;

  late final LobbyModel _lobby;

  @override
  void initState() {
    super.initState();
    if (widget.lobby != null) {
      _lobby = widget.lobby!;
    } else if (widget.lobbyData != null) {
      _lobby = LobbyModel.fromJson(widget.lobbyData!);
    } else {
      _lobby = const LobbyModel(
        id: '',
        title: 'Casual Match',
        sport: 'Futsal',
        locationName: 'Unknown Venue',
        latitude: 3.1390,
        longitude: 101.6869,
        skills: ['Open to All'],
        maxParticipants: 10,
        hostId: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lobbyId = _lobby.id;
    final String hostId = _lobby.hostId;
    final bool isHost = _lobbyService.currentUserId == hostId;

    final LatLng venueLocation = LatLng(_lobby.latitude, _lobby.longitude);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _lobby.sport.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lobby.title,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF39FF14), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lobby.locationName,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_lobby.matchDate != null || _lobby.matchTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF39FF14), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${_lobby.matchDate ?? 'Upcoming'} ${_lobby.matchTime != null ? 'at ${_lobby.matchTime}' : ''}",
                      style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 25),

            const Text(
              "TARGET SKILL LEVELS",
              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _lobby.skills.map((skill) => Chip(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                label: Text(skill, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              )).toList(),
            ),
            const SizedBox(height: 25),

            const Text(
              "VENUE MAP PREVIEW",
              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: venueLocation, zoom: 15.0),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: {Marker(markerId: const MarkerId('venue'), position: venueLocation)},
                ),
              ),
            ),
            const SizedBox(height: 30),

            isHost ? _buildHostApprovalDashboard(lobbyId) : _buildPlayerRequestPanel(lobbyId),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRequestPanel(String lobbyId) {
    return StreamBuilder<List<LobbyParticipantModel>>(
      stream: _lobbyService.getUserRequestStream(lobbyId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final myRequest = requests.where((r) => r.userId == _lobbyService.currentUserId).toList();

        if (myRequest.isEmpty) {
          return GestureDetector(
            onTap: _isProcessing ? null : () async {
              setState(() => _isProcessing = true);
              
              final messenger = ScaffoldMessenger.of(context);
              
              try {
                await _lobbyService.requestToJoinLobby(lobbyId);
                
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(
                    content: Text("Join request sent successfully!"),
                    backgroundColor: Color(0xFF39FF14),
                  ));
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text("Error: $e"), 
                  backgroundColor: Colors.redAccent,
                ));
              } finally {
                if (mounted) {
                  setState(() => _isProcessing = false);
                }
              }
            },
            child: Container(
              height: 55, width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF39FF14), borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("REQUEST TO JOIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          );
        }

        final String status = myRequest.first.status;

        return Column(
          children: [
            Container(
              height: 55, width: double.infinity,
              decoration: BoxDecoration(
                color: status == 'approved'
                    ? const Color(0xFF0F2B12)
                    : (status == 'pending' ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF2B0F0F)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: status == 'approved'
                      ? const Color(0xFF39FF14).withValues(alpha: 0.3)
                      : (status == 'pending' ? Colors.white24 : Colors.redAccent.withValues(alpha: 0.3)),
                ),
              ),
              child: Center(
                child: Text(
                  status == 'pending'
                      ? "PENDING HOST APPROVAL"
                      : (status == 'approved' ? "YOU'RE IN! REQUEST ACCEPTED" : "REQUEST DECLINED BY HOST"),
                  style: TextStyle(
                    color: status == 'approved'
                        ? const Color(0xFF39FF14)
                        : (status == 'pending' ? Colors.amber : Colors.redAccent),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _lobbyService.leaveLobby(lobbyId);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Withdrew join request."), backgroundColor: Colors.white24),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error withdrawing request: $e"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.white38, size: 18),
                label: const Text("WITHDRAW REQUEST", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHostApprovalDashboard(String lobbyId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PENDING REVIEWS",
          style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<LobbyParticipantModel>>(
          stream: _lobbyService.getAllLobbyRequestsStream(lobbyId),
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            final pendingRequests = requests.where((r) => r.status == 'pending').toList();

            if (pendingRequests.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No pending join requests to review.", style: TextStyle(color: Colors.white38, fontSize: 14)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final req = pendingRequests[index];

                return FutureBuilder<ProfileModel?>(
                  future: _lobbyService.fetchPlayerProfile(req.userId),
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data;
                    final String displayName = profile?.name ?? "Loading Player...";

                    return GestureDetector(
                      onTap: profile == null ? null : () => _showReviewBottomSheet(context, displayName, req.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, color: Color(0xFF39FF14), size: 36),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    const Text("Tap row to review profile", style: TextStyle(color: Colors.white24, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _lobbyService.updateRequestStatus(req.id, 'rejected'),
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 26),
                                ),
                                IconButton(
                                  onPressed: () => _lobbyService.updateRequestStatus(req.id, 'approved'),
                                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF39FF14), size: 26),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        )
      ],
    );
  }

  void _showReviewBottomSheet(BuildContext context, String name, String requestId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_martial_arts, color: Color(0xFF39FF14), size: 32),
                  const SizedBox(width: 12),
                  Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("APPLICANT RECORD VERIFICATION", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "This player is requesting to fill a slot inside your match. You can approve their entry to append them to your live roster list, or decline the request.",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B0F0F),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _lobbyService.updateRequestStatus(requestId, 'rejected');
                        Navigator.pop(context);
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text("DECLINE PLAYER", style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _lobbyService.updateRequestStatus(requestId, 'approved');
                        Navigator.pop(context);
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text("APPROVE ENTRY", style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
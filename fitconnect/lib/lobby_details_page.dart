import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lobby_service.dart';
import 'models/models.dart';
import 'lobby_group_chat_screen.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';
import 'services/profile_service.dart';
import 'widgets/report_player_modal.dart';

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
  final Map<String, ProfileModel?> _profileCache = {};
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

  Future<ProfileModel?> _getOrFetchProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    final profile = await _lobbyService.fetchPlayerProfile(userId);
    _profileCache[userId] = profile;
    return profile;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700)),
            tooltip: "Vote Match MVP & Reliability",
            onPressed: () => _showMvpVotingSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            tooltip: "Share Match",
            onPressed: _shareMatchInfo,
          ),
        ],
      ),
      body: StreamBuilder<List<LobbyParticipantModel>>(
        stream: _lobbyService.getAllLobbyRequestsStream(lobbyId),
        builder: (context, snapshot) {
          final allRequests = snapshot.data ?? [];
          final approvedParticipants = allRequests.where((r) => r.status == 'approved').toList();
          final pendingRequests = allRequests.where((r) => r.status == 'pending').toList();

          // Total filled = 1 host + all approved participants
          final int totalFilled = 1 + approvedParticipants.length;
          final int maxCapacity = _lobby.maxParticipants;
          final int slotsRemaining = (maxCapacity - totalFilled).clamp(0, maxCapacity);
          final bool isFull = totalFilled >= maxCapacity;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Title
                Text(
                  _lobby.cleanTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),

                // Location
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
                const SizedBox(height: 14),

                // Info Badges (Date/Time, Fee, Gender Restriction)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_lobby.matchDate != null || _lobby.matchTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF39FF14), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              "${_lobby.matchDate ?? 'Upcoming'} ${_lobby.matchTime != null ? 'at ${_lobby.matchTime}' : ''}",
                              style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (_lobby.feePerPax != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_rounded, color: Color(0xFF39FF14), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              "Fee: ${_lobby.feePerPax!}",
                              style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (_lobby.genderRestriction != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          _lobby.genderRestriction == 'Male Only' ? '👨 Male Only' : '👩 Female Only',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // ==================== CAPACITY OVERVIEW CARD ====================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color: isFull ? Colors.redAccent : const Color(0xFF39FF14),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "SLOT CAPACITY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                  : const Color(0xFF39FF14).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFull
                                    ? Colors.redAccent.withValues(alpha: 0.4)
                                    : const Color(0xFF39FF14).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isFull ? "MATCH FULL" : "$slotsRemaining SLOTS LEFT",
                              style: TextStyle(
                                color: isFull ? Colors.redAccent : const Color(0xFF39FF14),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (totalFilled / maxCapacity).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull ? Colors.redAccent : const Color(0xFF39FF14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$totalFilled of $maxCapacity players joined",
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "${((totalFilled / maxCapacity) * 100).round()}% filled",
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== MATCH SQUAD / ROSTER ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "MATCH SQUAD & ROSTER (TAP PROFILE)",
                      style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    Text(
                      "$totalFilled/$maxCapacity PLAYERS",
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Host Card
                _buildHostRosterCard(hostId),

                // 2. Approved Participants Cards
                ...approvedParticipants.map((participant) => _buildApprovedParticipantCard(
                  participant: participant,
                  isHost: isHost,
                  lobbyId: lobbyId,
                )),

                // 3. Open slots indicator
                 if (slotsRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3), width: 1.5),
                            color: const Color(0xFF39FF14).withValues(alpha: 0.05),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Color(0xFF39FF14), size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$slotsRemaining Open Slot${slotsRemaining > 1 ? 's' : ''} Available",
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Text(
                                "Waiting for players to join this match",
                                style: TextStyle(color: Colors.white24, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ==================== MATCH SQUAD GROUP CHAT BUTTON ====================
                if (isHost || approvedParticipants.any((p) => p.userId == _lobbyService.currentUserId)) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF39FF14).withValues(alpha: 0.15),
                          const Color(0xFF1E2F1E).withValues(alpha: 0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LobbyGroupChatScreen(lobby: _lobby),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.forum_rounded, color: Color(0xFF39FF14), size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "MATCH SQUAD GROUP CHAT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Discuss arrival time, gear, and tactics with teammates",
                                      style: TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF39FF14), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Target Skill Levels
                const Text(
                  "TARGET SKILL LEVELS",
                  style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _lobby.skills.map((skill) => Chip(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    label: Text(skill, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  )).toList(),
                ),
                const SizedBox(height: 28),

                // Venue Map
                const Text(
                  "VENUE LOCATION & NAVIGATION",
                  style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
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
                const SizedBox(height: 12),

                // 🗺️ GPS Directions & 📅 Calendar Sync Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39FF14),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _openGpsNavigation,
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text(
                          "DIRECTIONS (GPS)",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _addToGoogleCalendar,
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF39FF14)),
                        label: const Text(
                          "ADD TO CALENDAR",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ==================== HOST OR PLAYER CONTROLS ====================
                if (isHost)
                  _buildHostPendingReviewSection(lobbyId, pendingRequests, isFull)
                else
                  _buildPlayerRequestPanel(lobbyId, allRequests, isFull, slotsRemaining),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Host item in the roster
  Widget _buildHostRosterCard(String hostId) {
    final currentUserId = _lobbyService.currentUserId;
    final isMeHost = hostId == currentUserId;

    return FutureBuilder<ProfileModel?>(
      future: _getOrFetchProfile(hostId),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _lobby.hostProfile;
        final name = profile?.name ?? (isMeHost ? "You" : "Host");
        final skill = profile?.skill ?? "Player";
        final sport = profile?.sport ?? _lobby.sport;

        return GestureDetector(
          onTap: () => _showPlayerProfilePeekSheet(profile, isMe: isMeHost, isHost: true),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMeHost ? const Color(0xFF141E10) : const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMeHost
                    ? const Color(0xFF39FF14).withValues(alpha: 0.45)
                    : const Color(0xFFFFD700).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(
                  imageUrl: profile?.imageUrl,
                  name: name,
                  radius: 20,
                  borderColor: isMeHost ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                  isHost: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMeHost ? "$name (You)" : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMeHost ? const Color(0xFF39FF14) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMeHost
                                  ? const Color(0xFF39FF14).withValues(alpha: 0.15)
                                  : const Color(0xFFFFD700).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isMeHost
                                    ? const Color(0xFF39FF14).withValues(alpha: 0.4)
                                    : const Color(0xFFFFD700).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMeHost ? Icons.star_rounded : Icons.star,
                                  color: isMeHost ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isMeHost ? "YOU (HOST)" : "HOST",
                                  style: TextStyle(
                                    color: isMeHost ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$sport • Skill: $skill • Tap for bio",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ContainerTag(
                  label: isMeHost ? "ORGANIZER" : "ORGANIZER",
                  color: isMeHost ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Approved participant item in the roster
  Widget _buildApprovedParticipantCard({
    required LobbyParticipantModel participant,
    required bool isHost,
    required String lobbyId,
  }) {
    final currentUserId = _lobbyService.currentUserId;
    final isMe = participant.userId == currentUserId;

    return FutureBuilder<ProfileModel?>(
      future: _getOrFetchProfile(participant.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? participant.userProfile;
        final name = profile?.name ?? "Athlete";
        final skill = profile?.skill ?? "Intermediate";
        final sport = profile?.sport ?? _lobby.sport;

        return GestureDetector(
          onTap: () => _showPlayerProfilePeekSheet(profile, isMe: isMe, isHost: false),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF141E10) : const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMe
                    ? const Color(0xFF39FF14).withValues(alpha: 0.4)
                    : const Color(0xFF39FF14).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(
                  imageUrl: profile?.imageUrl,
                  name: name,
                  radius: 20,
                  borderColor: const Color(0xFF39FF14),
                  isHost: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMe ? "$name (You)" : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe ? const Color(0xFF39FF14) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$sport • Skill: $skill • Tap for bio",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isHost)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                    tooltip: "Remove from squad",
                    onPressed: () => _confirmRemoveParticipant(participant, name),
                  )
                else
                  ContainerTag(
                    label: isMe ? "YOU" : "CONFIRMED",
                    color: const Color(0xFF39FF14),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveParticipant(LobbyParticipantModel participant, String playerName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Manage Player Squad Removal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          "How would you like to handle removing $playerName from this squad?",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _lobbyService.removeParticipant(participant.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$playerName was removed from the squad."),
                      backgroundColor: const Color(0xFF1E1E1E),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text("JUST REMOVE"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _lobbyService.removeParticipant(participant.id);
                await ProfileService().submitPlayerReport(
                  reportedUserId: participant.userId,
                  reason: 'No-Show / Unattended Match',
                  lobbyId: _lobby.id,
                  penalty: 15,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ $playerName removed and marked as No-Show (-15% Reliability applied)."),
                      backgroundColor: const Color(0xFF2C1414),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text("MARK NO-SHOW (-15%)"),
          ),
        ],
      ),
    );
  }

  /// Host pending reviews section
  Widget _buildHostPendingReviewSection(
    String lobbyId,
    List<LobbyParticipantModel> pendingRequests,
    bool isFull,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PENDING JOIN REQUESTS",
              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
            ),
            if (pendingRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${pendingRequests.length} PENDING",
                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (isFull && pendingRequests.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your match is currently full. Approving more players will exceed maximum capacity.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        if (pendingRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: const Center(
              child: Text(
                "No pending join requests to review.",
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final req = pendingRequests[index];

              return FutureBuilder<ProfileModel?>(
                future: _getOrFetchProfile(req.userId),
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
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.1),
                                backgroundImage: (profile?.imageUrl != null && profile!.imageUrl!.isNotEmpty)
                                    ? NetworkImage(profile.imageUrl!)
                                    : null,
                                child: (profile?.imageUrl == null || profile!.imageUrl!.isEmpty)
                                    ? const Icon(Icons.account_circle, color: Color(0xFF39FF14), size: 26)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile?.skill != null ? "Skill: ${profile!.skill}" : "Tap row to review",
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _updateStatusWithFeedback(req.id, 'rejected', displayName),
                                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 26),
                                tooltip: "Decline",
                              ),
                              IconButton(
                                onPressed: () => _updateStatusWithFeedback(req.id, 'approved', displayName),
                                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF39FF14), size: 26),
                                tooltip: "Approve Entry",
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
          ),
      ],
    );
  }

  /// Player action section (Request to join, status, leave)
  Widget _buildPlayerRequestPanel(
    String lobbyId,
    List<LobbyParticipantModel> allRequests,
    bool isFull,
    int slotsRemaining,
  ) {
    final currentUserId = _lobbyService.currentUserId;
    final myRequests = allRequests.where((r) => r.userId == currentUserId).toList();

    if (myRequests.isEmpty) {
      if (isFull) {
        return Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.white38, size: 18),
                SizedBox(width: 8),
                Text(
                  "MATCH IS FULL (0 SLOTS LEFT)",
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

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
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF39FF14),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : Text(
                    "REQUEST TO JOIN ($slotsRemaining SLOTS LEFT)",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
          ),
        ),
      );
    }

    final String status = myRequests.first.status;

    return Column(
      children: [
        Container(
          height: 55,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: status == 'approved'
                ? const Color(0xFF0F2B12)
                : (status == 'pending' ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF2B0F0F)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: status == 'approved'
                  ? const Color(0xFF39FF14).withValues(alpha: 0.4)
                  : (status == 'pending' ? Colors.amber.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4)),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'approved'
                      ? Icons.verified
                      : (status == 'pending' ? Icons.hourglass_top_rounded : Icons.cancel_outlined),
                  color: status == 'approved'
                      ? const Color(0xFF39FF14)
                      : (status == 'pending' ? Colors.amber : Colors.redAccent),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'pending'
                      ? "PENDING HOST APPROVAL"
                      : (status == 'approved' ? "YOU'RE ON THE MATCH ROSTER!" : "REQUEST DECLINED BY HOST"),
                  style: TextStyle(
                    color: status == 'approved'
                        ? const Color(0xFF39FF14)
                        : (status == 'pending' ? Colors.amber : Colors.redAccent),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
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
                    SnackBar(
                      content: Text(status == 'approved' ? "Left the match roster." : "Withdrew join request."),
                      backgroundColor: Colors.white24,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.white38, size: 18),
            label: Text(
              status == 'approved' ? "LEAVE MATCH" : "WITHDRAW REQUEST",
              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatusWithFeedback(String requestId, String status, String playerName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _lobbyService.updateRequestStatus(requestId, status);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'approved' ? Icons.check_circle : Icons.cancel,
                color: status == 'approved' ? const Color(0xFF39FF14) : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == 'approved'
                      ? "$playerName was approved and added to the roster! ⚡"
                      : "Declined request from $playerName.",
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error updating request: $e"), backgroundColor: Colors.redAccent),
      );
    }
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
                "This player is requesting to fill a slot inside your match. Approving their entry will add them to your live roster list.",
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
                        Navigator.pop(context);
                        _updateStatusWithFeedback(requestId, 'rejected', name);
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
                        Navigator.pop(context);
                        _updateStatusWithFeedback(requestId, 'approved', name);
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

  Widget _buildAvatarWidget({
    required String? imageUrl,
    required String name,
    required double radius,
    required Color borderColor,
    required bool isHost,
  }) {
    Widget child;

    if (imageUrl != null && imageUrl.startsWith('http')) {
      child = Image.network(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(name, isHost, radius),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      child = Image.asset(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(name, isHost, radius),
      );
    } else {
      child = _buildFallbackInitial(name, isHost, radius);
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        color: borderColor.withValues(alpha: 0.15),
      ),
      child: ClipOval(child: child),
    );
  }

  Widget _buildFallbackInitial(String name, bool isHost, double radius) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : (isHost ? 'H' : 'P');
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: isHost ? const Color(0xFFFFD700) : const Color(0xFF39FF14),
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }

  /// 1. 🧭 Open Turn-by-Turn GPS Navigation (Google Maps / Apple Maps / Waze)
  Future<void> _openGpsNavigation() async {
    final lat = _lobby.latitude;
    final lng = _lobby.longitude;
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        final geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(_lobby.locationName)})");
        await launchUrl(geoUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Venue Coordinates: $lat, $lng (${_lobby.locationName})"),
            backgroundColor: const Color(0xFF1E1E1E),
          ),
        );
      }
    }
  }

  /// 2. 📅 Add Match to Google/Device Calendar
  Future<void> _addToGoogleCalendar() async {
    final title = Uri.encodeComponent("⚽ Match: ${_lobby.cleanTitle} (${_lobby.sport.toUpperCase()})");
    final location = Uri.encodeComponent(_lobby.locationName);
    final details = Uri.encodeComponent("Match organized via FitConnect.\nSport: ${_lobby.sport}\nVenue: ${_lobby.locationName}\nFee: ${_lobby.feePerPax ?? 'N/A'}");

    // Format dates (default to next upcoming hour if date is unspecified)
    final now = DateTime.now();
    final startIso = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}T090000Z";
    final endIso = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}T110000Z";

    final calUrl = Uri.parse("https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$startIso/$endIso&details=$details&location=$location");

    try {
      await launchUrl(calUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Match scheduled for: ${_lobby.matchDate ?? 'Upcoming'} at ${_lobby.matchTime ?? 'TBD'}"),
            backgroundColor: const Color(0xFF1E1E1E),
          ),
        );
      }
    }
  }

  /// 3. 🔗 Share Match Info
  void _shareMatchInfo() {
    final text = "⚽ Join my match '${_lobby.cleanTitle}' on FitConnect!\n📍 ${_lobby.locationName}\n🗓️ ${_lobby.matchDate ?? 'Upcoming'} ${_lobby.matchTime != null ? 'at ${_lobby.matchTime}' : ''}\n💵 Fee: ${_lobby.feePerPax ?? 'Free'}";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: "DISMISS", textColor: const Color(0xFF39FF14), onPressed: () {}),
      ),
    );
  }

  /// 4. 👤 Interactive Player Profile Peek BottomSheet
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
                  _buildAvatarWidget(
                    imageUrl: profile.imageUrl,
                    name: profile.name,
                    radius: 32,
                    borderColor: isHost ? const Color(0xFFFFD700) : const Color(0xFF39FF14),
                    isHost: isHost,
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
                      ReportPlayerModal.show(context, reportedAthlete: profile, lobbyId: _lobby.id);
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

  /// 5. 🏆 Post-Match MVP & Reliability Voting Sheet
  void _showMvpVotingSheet() {
    String? selectedMvpUserId;
    bool punctualityThumbsUp = true;
    bool sportsmanshipThumbsUp = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return StreamBuilder<List<LobbyParticipantModel>>(
              stream: _lobbyService.getAllLobbyRequestsStream(_lobby.id),
              builder: (context, snapshot) {
                final participants = snapshot.data ?? [];
                final approved = participants.where((p) => p.status == 'approved').toList();

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

                      // Title
                      const Row(
                        children: [
                          Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 24),
                          SizedBox(width: 8),
                          Text(
                            "MATCH MVP & SQUAD RATING",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Vote for the match MVP and upvote teammate sportsmanship to boost their Reliability Score!",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      // MVP Candidate Selection
                      const Text("SELECT MATCH MVP 🌟", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 10),

                      if (approved.isEmpty && _lobby.hostId == _lobbyService.currentUserId)
                        const Text("No teammates to vote for yet.", style: TextStyle(color: Colors.white24, fontSize: 12))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Host candidate
                            ChoiceChip(
                              label: Text(_lobby.hostProfile?.name ?? "Host Organizer"),
                              selected: selectedMvpUserId == _lobby.hostId,
                              selectedColor: const Color(0xFFFFD700),
                              labelStyle: TextStyle(
                                color: selectedMvpUserId == _lobby.hostId ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (_) => setSheetState(() => selectedMvpUserId = _lobby.hostId),
                            ),
                            // Teammate candidates
                            ...approved.map((p) {
                              return FutureBuilder<ProfileModel?>(
                                future: _getOrFetchProfile(p.userId),
                                builder: (context, pSnap) {
                                  final name = pSnap.data?.name ?? "Teammate";
                                  final isSelected = selectedMvpUserId == p.userId;

                                  return ChoiceChip(
                                    label: Text(name),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF39FF14),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    onSelected: (_) => setSheetState(() => selectedMvpUserId = p.userId),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Sportsmanship & Punctuality Thumbs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Squad Punctuality", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          IconButton(
                            icon: Icon(
                              punctualityThumbsUp ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                              color: punctualityThumbsUp ? const Color(0xFF39FF14) : Colors.white38,
                            ),
                            onPressed: () => setSheetState(() => punctualityThumbsUp = !punctualityThumbsUp),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Fair Play & Sportsmanship", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          IconButton(
                            icon: Icon(
                              sportsmanshipThumbsUp ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                              color: sportsmanshipThumbsUp ? const Color(0xFF39FF14) : Colors.white38,
                            ),
                            onPressed: () => setSheetState(() => sportsmanshipThumbsUp = !sportsmanshipThumbsUp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(sheetCtx);
                            final profileService = ProfileService();

                            // 1. Award MVP +3% reliability
                            if (selectedMvpUserId != null && selectedMvpUserId!.isNotEmpty) {
                              await profileService.adjustReliabilityScore(selectedMvpUserId!, 3);
                            }

                            // 2. Upvote teammates reliability if thumbs up
                            if (punctualityThumbsUp || sportsmanshipThumbsUp) {
                              final int boost = (punctualityThumbsUp ? 1 : 0) + (sportsmanshipThumbsUp ? 1 : 0);
                              for (final p in approved) {
                                if (p.userId != selectedMvpUserId) {
                                  await profileService.adjustReliabilityScore(p.userId, boost);
                                }
                              }
                            }

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("🏆 MVP vote submitted & Reliability scores (+3%) synced live!"),
                                backgroundColor: Color(0xFF1E2F1E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text("SUBMIT MVP & SQUAD RATING", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ContainerTag extends StatelessWidget {
  final String label;
  final Color color;
  const ContainerTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
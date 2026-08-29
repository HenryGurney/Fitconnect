import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'lobby_details_page.dart';
import 'create_lobby_page.dart';
import 'lobby_service.dart';
import 'models/models.dart';
import 'widgets/pro_badge_widget.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final LobbyService _lobbyService = LobbyService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSport = 'ALL';
  String _selectedScope = 'ALL'; // 'ALL', 'MINE', 'OPEN'
  String _selectedRadius = 'ALL'; // 'ALL', '10KM', '25KM', '50KM'
  String _searchQuery = '';
  Position? _userPosition;

  static const Map<String, String> _sportIcons = {
    'ALL': '🔥',
    'FUTSAL': '⚽',
    'FOOTBALL': '⚽',
    'BADMINTON': '🏸',
    'TENNIS': '🎾',
    'BASKETBALL': '🏀',
    'VOLLEYBALL': '🏐',
    'PICKLEBALL': '🏓',
    'RUNNING': '🏃',
  };

  final List<String> _sportsList = const [
    'ALL',
    'FUTSAL',
    'FOOTBALL',
    'BADMINTON',
    'TENNIS',
    'BASKETBALL',
    'VOLLEYBALL',
    'PICKLEBALL',
    'RUNNING',
  ];

  Stream<List<LobbyModel>> get _lobbiesStream => _lobbyService.getLobbiesStream();

  @override
  void initState() {
    super.initState();
    _fetchUserPosition();
  }

  Future<void> _fetchUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 4)),
      );
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (e) {
      debugPrint("Info: could not fetch GPS position for lobby radius filter: $e");
    }
  }

  double? _calculateDistanceKm(double lat, double lng) {
    if (_userPosition == null || lat == 0 || lng == 0) return null;
    final meters = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, lat, lng);
    return meters / 1000.0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fetchUserPosition();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _lobbyService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_soccer, color: Color(0xFF39FF14), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "MATCH LOBBIES",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Create Match",
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF39FF14), size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search matches by venue or title...",
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Scope Filter Chips (All, My Lobbies, Open Spots)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildScopeFilterChip("ALL MATCHES", 'ALL', Icons.all_inclusive_rounded),
                const SizedBox(width: 8),
                _buildScopeFilterChip("HOSTED BY ME", 'MINE', Icons.star_rounded, isGold: true),
                const SizedBox(width: 8),
                _buildScopeFilterChip("OPEN SPOTS", 'OPEN', Icons.group_add_rounded),
              ],
            ),
          ),

          // 2.5 Distance Radius Filter Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRadiusChip("🌐 ALL DISTANCE", 'ALL'),
                const SizedBox(width: 6),
                _buildRadiusChip("📍 < 10 KM", '10KM'),
                const SizedBox(width: 6),
                _buildRadiusChip("📍 < 25 KM", '25KM'),
                const SizedBox(width: 6),
                _buildRadiusChip("📍 < 50 KM", '50KM'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 3. Sport Category Filter Bar
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sportsList.length,
              itemBuilder: (context, index) {
                final sport = _sportsList[index];
                final isSelected = _selectedSport == sport;
                final icon = _sportIcons[sport] ?? '⚽';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Text(icon, style: const TextStyle(fontSize: 13)),
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSport = sport);
                      }
                    },
                    selectedColor: const Color(0xFF39FF14),
                    backgroundColor: const Color(0xFF121212),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.08),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 4. Lobbies Stream List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF39FF14),
              backgroundColor: const Color(0xFF0F0F0F),
              onRefresh: _handleRefresh,
              child: StreamBuilder<List<LobbyModel>>(
                stream: _lobbiesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF39FF14)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading lobbies: ${snapshot.error}",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final allLobbies = snapshot.data ?? [];

                  // Apply Filtering
                  final filteredLobbies = allLobbies.where((lobby) {
                    // Scope filter
                    if (_selectedScope == 'MINE' && lobby.hostId != currentUserId) {
                      return false;
                    }

                    // Sport filter
                    if (_selectedSport != 'ALL' && lobby.sport.toUpperCase() != _selectedSport) {
                      return false;
                    }

                    // Distance Radius filter
                    if (_selectedRadius != 'ALL') {
                      final distKm = _calculateDistanceKm(lobby.latitude, lobby.longitude);
                      if (distKm != null) {
                        if (_selectedRadius == '10KM' && distKm > 10.0) return false;
                        if (_selectedRadius == '25KM' && distKm > 25.0) return false;
                        if (_selectedRadius == '50KM' && distKm > 50.0) return false;
                      }
                    }

                    // Text Search filter
                    if (_searchQuery.isNotEmpty) {
                      final titleMatch = lobby.title.toLowerCase().contains(_searchQuery);
                      final locationMatch = lobby.locationName.toLowerCase().contains(_searchQuery);
                      final sportMatch = lobby.sport.toLowerCase().contains(_searchQuery);
                      if (!titleMatch && !locationMatch && !sportMatch) return false;
                    }

                    return true;
                  }).toList();

                  if (filteredLobbies.isEmpty) {
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
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF39FF14).withValues(alpha: 0.05),
                                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.15)),
                                    ),
                                    child: const Icon(Icons.sports_score_rounded, size: 48, color: Color(0xFF39FF14)),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    "NO MATCHES FOUND",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedScope == 'MINE'
                                        ? "You haven't hosted any matches yet.\nTap below to launch one!"
                                        : "No active matches match your current filters.\nTry adjusting radius, sports or host your own match!",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 22),
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
                                    label: const Text("HOST A MATCH", style: TextStyle(fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Sorting: PRO Pinning & User's own lobbies at top
                  final sortedLobbies = List<LobbyModel>.from(filteredLobbies)..sort((a, b) {
                    final aMine = a.hostId == currentUserId;
                    final bMine = b.hostId == currentUserId;
                    if (aMine && !bMine) return -1;
                    if (!aMine && bMine) return 1;

                    final aPro = a.hostProfile?.isPremium ?? false;
                    final bPro = b.hostProfile?.isPremium ?? false;
                    if (aPro && !bPro) return -1;
                    if (!aPro && bPro) return 1;
                    return 0;
                  });

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 4, bottom: 100),
                    itemCount: sortedLobbies.length,
                    itemBuilder: (context, index) {
                      final lobby = sortedLobbies[index];
                      final distKm = _calculateDistanceKm(lobby.latitude, lobby.longitude);
                      return LobbyCardWidget(lobby: lobby, distanceKm: distKm);
                    },
                  );
                },
              ),
            ),
          ),
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
        label: const Text("HOST MATCH", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildRadiusChip(String label, String value) {
    final isSelected = _selectedRadius == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRadius = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildScopeFilterChip(String label, String value, IconData icon, {bool isGold = false}) {
    final isSelected = _selectedScope == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedScope = value),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? (isGold ? const Color(0xFFFFD700) : const Color(0xFF39FF14))
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isGold ? const Color(0xFFFFD700).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.black
                    : (isGold ? const Color(0xFFFFD700) : Colors.white60),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : (isGold ? const Color(0xFFFFD700) : Colors.white70),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LobbyCardWidget extends StatelessWidget {
  final LobbyModel lobby;
  final double? distanceKm;
  final LobbyService _lobbyService = LobbyService();

  LobbyCardWidget({super.key, required this.lobby, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final currentUserId = _lobbyService.currentUserId;
    final isMyLobby = lobby.hostId == currentUserId;
    final isHostPro = lobby.hostProfile?.isPremium ?? false;
    final fee = lobby.feePerPax;
    final gender = lobby.genderRestriction;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isMyLobby
              ? const Color(0xFF131912)
              : (isHostPro ? const Color(0xFF141208) : const Color(0xFF101010)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMyLobby
                ? const Color(0xFF39FF14).withValues(alpha: 0.5)
                : (isHostPro ? const Color(0xFFFFD700).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.05)),
            width: isMyLobby ? 1.5 : (isHostPro ? 1.4 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isMyLobby
                  ? const Color(0xFF39FF14).withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Badges & Live Capacity Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Sport tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lobby.sport.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      // "YOUR LOBBY" Badge
                      if (isMyLobby) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Color(0xFF39FF14), size: 12),
                              SizedBox(width: 2),
                              Text(
                                "YOUR MATCH",
                                style: TextStyle(
                                  color: Color(0xFF39FF14),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isHostPro) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded, color: Color(0xFFFFD700), size: 10),
                              SizedBox(width: 2),
                              Text(
                                "PINNED",
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

                      // Referee Badge
                      if (lobby.hasReferee) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_rounded, color: Color(0xFFFFD700), size: 10),
                              SizedBox(width: 3),
                              Text(
                                "REFEREED",
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

                      if (gender != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gender == 'Male Only' ? '👨 Male' : '👩 Female',
                            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
                            : const Color(0xFF39FF14).withValues(alpha: 0.12),
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

            // 2. Title & Pro Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    lobby.cleanTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (lobby.hostProfile?.isPremium ?? false) ...[
                  const SizedBox(width: 8),
                  const ProBadgeWidget(isCompact: true),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // 3. Organizer Profile Row (Asynchronously fetched to guarantee real avatar & name)
            FutureBuilder<ProfileModel?>(
              future: _lobbyService.fetchPlayerProfile(lobby.hostId),
              builder: (context, hostSnap) {
                final hostProfile = hostSnap.data ?? lobby.hostProfile;
                final hostName = hostProfile?.name ?? (isMyLobby ? 'You' : 'Match Host');
                final hostImg = hostProfile?.imageUrl;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isMyLobby
                        ? const Color(0xFF39FF14).withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMyLobby
                          ? const Color(0xFF39FF14).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAvatarCircle(
                        imageUrl: hostImg,
                        name: hostName,
                        radius: 12,
                        borderColor: isMyLobby ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                        isHost: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                isMyLobby ? "$hostName (Organizer)" : hostName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMyLobby ? const Color(0xFF39FF14) : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isMyLobby
                                    ? const Color(0xFF39FF14).withValues(alpha: 0.15)
                                    : const Color(0xFFFFD700).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isMyLobby ? "YOU" : "HOST",
                                style: TextStyle(
                                  color: isMyLobby ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 4. Joined Squad Preview (Live Real Facepile)
            StreamBuilder<List<LobbyParticipantModel>>(
              stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
              builder: (context, snapshot) {
                final participants = snapshot.data ?? [];
                final approved = participants.where((p) => p.status == 'approved').toList();

                return Row(
                  children: [
                    // Mini avatar stack
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Host mini avatar
                          FutureBuilder<ProfileModel?>(
                            future: _lobbyService.fetchPlayerProfile(lobby.hostId),
                            builder: (context, hSnap) {
                              final h = hSnap.data ?? lobby.hostProfile;
                              return _buildAvatarCircle(
                                imageUrl: h?.imageUrl,
                                name: h?.name ?? 'H',
                                radius: 11,
                                borderColor: const Color(0xFFFFD700),
                                isHost: true,
                              );
                            },
                          ),
                          // Up to 3 approved players
                          ...approved.take(3).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: FutureBuilder<ProfileModel?>(
                                future: _lobbyService.fetchPlayerProfile(p.userId),
                                builder: (context, pSnap) {
                                  final player = pSnap.data;
                                  return _buildAvatarCircle(
                                    imageUrl: player?.imageUrl,
                                    name: player?.name ?? 'P',
                                    radius: 11,
                                    borderColor: const Color(0xFF39FF14),
                                    isHost: false,
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
                            ? "Host waiting for players to join"
                            : "${approved.length + 1} player${approved.length + 1 > 1 ? 's' : ''} in squad",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // 4. Venue Location & Distance Tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 15),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    lobby.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
                if (distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: Color(0xFF00E5FF), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          "${distanceKm!.toStringAsFixed(1)} km",
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // 5. Match Schedule & Fee
            Row(
              children: [
                if (lobby.matchDate != null || lobby.matchTime != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: Color(0xFF39FF14), size: 14),
                        const SizedBox(width: 5),
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
                if (fee != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_rounded, color: Color(0xFF39FF14), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          fee,
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
            const SizedBox(height: 14),

            // 6. Action Button Bar
            Container(
              height: 38,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isMyLobby
                    ? const Color(0xFF39FF14).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMyLobby
                      ? const Color(0xFF39FF14).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isMyLobby ? "MANAGE SQUAD" : "VIEW MATCH",
                      style: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF39FF14), size: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle({
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
}
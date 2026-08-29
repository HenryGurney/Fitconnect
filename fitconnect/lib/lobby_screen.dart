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

  static const Map<String, IconData> _sportIcons = {
    'ALL': Icons.sports_rounded,
    'FUTSAL': Icons.sports_soccer_rounded,
    'FOOTBALL': Icons.sports_soccer_rounded,
    'BADMINTON': Icons.sports_tennis_rounded,
    'TENNIS': Icons.sports_tennis_rounded,
    'BASKETBALL': Icons.sports_basketball_rounded,
    'VOLLEYBALL': Icons.sports_volleyball_rounded,
    'PICKLEBALL': Icons.sports_baseball_rounded,
    'RUNNING': Icons.directions_run_rounded,
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
      debugPrint("Info: GPS position fetch: $e");
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                  "FILTER MATCHES",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                const Text("DISTANCE RADIUS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildRadiusOption("Any Distance", 'ALL', setSheetState),
                    _buildRadiusOption("Within 10 km", '10KM', setSheetState),
                    _buildRadiusOption("Within 25 km", '25KM', setSheetState),
                    _buildRadiusOption("Within 50 km", '50KM', setSheetState),
                  ],
                ),
                const SizedBox(height: 18),
                const Text("MATCH SCOPE", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildScopeOption("All Matches", 'ALL', setSheetState),
                    _buildScopeOption("Hosted by Me", 'MINE', setSheetState),
                    _buildScopeOption("Has Open Spots", 'OPEN', setSheetState),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text("APPLY FILTERS", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusOption(String label, String value, StateSetter setSheetState) {
    final isSelected = _selectedRadius == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setSheetState(() => _selectedRadius = value);
        setState(() => _selectedRadius = value);
      },
      selectedColor: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF1E1E1E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildScopeOption(String label, String value, StateSetter setSheetState) {
    final isSelected = _selectedScope == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setSheetState(() => _selectedScope = value);
        setState(() => _selectedScope = value);
      },
      selectedColor: const Color(0xFF39FF14),
      backgroundColor: const Color(0xFF1E1E1E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _lobbyService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          "MATCH LOBBIES",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Host Match",
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
      ),
      body: Column(
        children: [
          // 1. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search matches or venue...",
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedScope = _selectedScope == 'MINE' ? 'ALL' : 'MINE';
                    });
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _selectedScope == 'MINE' ? const Color(0xFF1E2818) : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedScope == 'MINE' ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: _selectedScope == 'MINE' ? const Color(0xFF39FF14) : Colors.white38, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Mine",
                          style: TextStyle(
                            color: _selectedScope == 'MINE' ? const Color(0xFF39FF14) : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: (_selectedRadius != 'ALL' || _selectedScope != 'ALL')
                          ? const Color(0xFF1E2818)
                          : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_selectedRadius != 'ALL' || _selectedScope != 'ALL')
                            ? const Color(0xFF39FF14)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: (_selectedRadius != 'ALL' || _selectedScope != 'ALL')
                              ? const Color(0xFF39FF14)
                              : Colors.white70,
                          size: 18,
                        ),
                        if (_selectedRadius != 'ALL' || _selectedScope != 'ALL') ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF39FF14)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Sport Category Selector
          Container(
            height: 42,
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sportsList.length,
              itemBuilder: (context, index) {
                final sport = _sportsList[index];
                final isSelected = _selectedSport == sport;
                final iconData = _sportIcons[sport] ?? Icons.sports_rounded;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(
                      iconData,
                      size: 14,
                      color: isSelected ? Colors.black : const Color(0xFF39FF14),
                    ),
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSport = sport);
                    },
                    selectedColor: const Color(0xFF39FF14),
                    backgroundColor: const Color(0xFF141414),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.06),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),

          // 3. Lobbies Stream List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF39FF14),
              backgroundColor: const Color(0xFF141414),
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

                  // Apply Filters
                  final filteredLobbies = allLobbies.where((lobby) {
                    if (_selectedScope == 'MINE' && lobby.hostId != currentUserId) return false;
                    if (_selectedSport != 'ALL' && lobby.sport.toUpperCase() != _selectedSport) return false;

                    if (_selectedRadius != 'ALL') {
                      final distKm = _calculateDistanceKm(lobby.latitude, lobby.longitude);
                      if (distKm != null) {
                        if (_selectedRadius == '10KM' && distKm > 10.0) return false;
                        if (_selectedRadius == '25KM' && distKm > 25.0) return false;
                        if (_selectedRadius == '50KM' && distKm > 50.0) return false;
                      }
                    }

                    if (_searchQuery.isNotEmpty) {
                      final titleMatch = lobby.title.toLowerCase().contains(_searchQuery);
                      final locMatch = lobby.locationName.toLowerCase().contains(_searchQuery);
                      final sportMatch = lobby.sport.toLowerCase().contains(_searchQuery);
                      if (!titleMatch && !locMatch && !sportMatch) return false;
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
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF39FF14).withValues(alpha: 0.05),
                                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.15)),
                                    ),
                                    child: const Icon(Icons.sports_soccer_rounded, size: 40, color: Color(0xFF39FF14)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "NO MATCHES FOUND",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedScope == 'MINE'
                                        ? "You haven't hosted any matches yet."
                                        : "No active matches match your current filters.",
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
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                    label: const Text("HOST A MATCH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    itemCount: filteredLobbies.length,
                    itemBuilder: (context, index) {
                      final lobby = filteredLobbies[index];
                      final distanceKm = _calculateDistanceKm(lobby.latitude, lobby.longitude);
                      return LobbyCardWidget(lobby: lobby, distanceKm: distanceKm);
                    },
                  );
                },
              ),
            ),
          ),
        ],
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LobbyDetailsPage(lobby: lobby)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isMyLobby ? const Color(0xFF0D170C) : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMyLobby
                ? const Color(0xFF39FF14).withValues(alpha: 0.6)
                : (isHostPro ? const Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
            width: isMyLobby ? 1.5 : (isHostPro ? 1.2 : 1.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Tags & Status
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
                if (isMyLobby) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: Color(0xFF39FF14), size: 11),
                        SizedBox(width: 3),
                        Text(
                          "HOSTED BY YOU",
                          style: TextStyle(color: Color(0xFF39FF14), fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ] else if (isHostPro) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "PINNED",
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
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
                        Text(
                          "REFEREED",
                          style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900),
                        ),
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
                        color: isFull
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : const Color(0xFF39FF14).withValues(alpha: 0.1),
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

            // 2. Title & Pro Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    lobby.cleanTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
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

            // 3. Host Profile Info
            FutureBuilder<ProfileModel?>(
              future: _lobbyService.fetchPlayerProfile(lobby.hostId),
              builder: (context, hostSnap) {
                final hostProfile = hostSnap.data ?? lobby.hostProfile;
                final hostName = hostProfile?.name ?? (isMyLobby ? 'You' : 'Match Host');
                final hostImg = hostProfile?.imageUrl;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      _buildAvatar(
                        imageUrl: hostImg,
                        name: hostName,
                        radius: 10,
                        borderColor: isMyLobby ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          isMyLobby ? "Hosted by You (Organizer)" : "Hosted by $hostName",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMyLobby ? const Color(0xFF39FF14) : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isMyLobby
                              ? const Color(0xFF39FF14).withValues(alpha: 0.2)
                              : const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: isMyLobby ? Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.4)) : null,
                        ),
                        child: Text(
                          isMyLobby ? "YOU • HOST" : "HOST",
                          style: TextStyle(
                            color: isMyLobby ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 4. Joined Squad Player Avatars (Facepile)
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
                                      name: player?.name ?? 'Player',
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
                              ? "Waiting for squad to join"
                              : "${approved.length + 1} athlete${approved.length + 1 > 1 ? 's' : ''} in squad",
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

            // 5. Location & Distance
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
                if (distanceKm != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    "${distanceKm!.toStringAsFixed(1)} km",
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // 5. Date & Fee Row
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
                if (fee != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fee,
                      style: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),

            // Referee Info Banner
            StreamBuilder<List<LobbyParticipantModel>>(
              stream: _lobbyService.getAllLobbyRequestsStream(lobby.id),
              builder: (context, snapshot) {
                final participants = snapshot.data ?? [];
                final ref = participants.where((p) => p.role == 'referee' && p.status == 'approved').firstOrNull;

                if (!lobby.hasReferee && ref == null) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_rounded, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ref != null
                            ? FutureBuilder<ProfileModel?>(
                                future: _lobbyService.fetchPlayerProfile(ref.userId),
                                builder: (context, rSnap) {
                                  final rProfile = rSnap.data;
                                  return Text(
                                    "Official Referee: ${rProfile?.name ?? 'Assigned'} 🟡",
                                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11),
                                  );
                                },
                              )
                            : const Text(
                                "Referee Slot: Available • Tap to Claim",
                                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                      ),
                      if (ref == null)
                        const Text(
                          "CLAIM",
                          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
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
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'H';
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
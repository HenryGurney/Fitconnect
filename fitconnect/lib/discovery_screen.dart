import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'create_lobby_page.dart';
import 'chat_detail_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'models/models.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'widgets/pro_badge_widget.dart';
import 'widgets/premium_upgrade_modal.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final CardSwiperController controller = CardSwiperController();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();

  static const int maxFreeDailySwipes = 10;

  bool _isLoading = true;
  ProfileModel? _userProfile;
  List<ProfileModel> _athleteProfiles = [];
  String _selectedSportFilter = 'ALL';
  int _todaySwipeCount = 0;

  final List<String> _sportFilters = const [
    'ALL',
    'FUTSAL',
    'FOOTBALL',
    'TENNIS',
    'BADMINTON',
    'PICKLEBALL',
    'BASKETBALL',
    'VOLLEYBALL',
    'RUNNING',
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryData() async {
    setState(() => _isLoading = true);
    try {
      final currentProf = await _profileService.getCurrentProfile();
      final otherAthletes = await _profileService.fetchOtherAthletes();
      int todaySwipes = 0;
      if (!(currentProf?.isPremium ?? false)) {
        todaySwipes = await _matchService.fetchTodaySwipeCount();
      }

      if (mounted) {
        setState(() {
          _userProfile = currentProf;
          _athleteProfiles = otherAthletes;
          _todaySwipeCount = todaySwipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading discovery data: $e");
      if (mounted) {
        setState(() {
          _athleteProfiles = [];
          _isLoading = false;
        });
      }
    }
  }

  List<ProfileModel> get _filteredAthletes {
    if (_selectedSportFilter == 'ALL') return _athleteProfiles;
    return _athleteProfiles
        .where((p) => p.sport.toUpperCase() == _selectedSportFilter)
        .toList();
  }

  Future<void> _handleResetSwipes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFF39FF14), size: 22),
            SizedBox(width: 10),
            Text(
              "Reset Discovery Swipes",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "This will reset your previous passes and allow you to discover and match with all athletes in your area again.",
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("RESET SWIPES", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _matchService.resetAllSwipes();
        await _loadDiscoveryData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✨ Swipes reset! All nearby athletes re-populated."),
              backgroundColor: Color(0xFF1E2F1E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error resetting swipes: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              "Log Out",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out of your session? You will need to sign in again to access your matches and messages.",
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B0F0F),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("LOG OUT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _authService.signOut();
      
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      messenger.showSnackBar(
        SnackBar(content: Text("Logout failed: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final activeDeck = _filteredAthletes;
    if (activeDeck.isEmpty) return true;
    final safeIndex = previousIndex % activeDeck.length;
    final athlete = activeDeck[safeIndex];

    final isPro = _userProfile?.isPremium ?? false;

    // 1. Free User 10-Swipe Limit Enforcement
    if (!isPro && _todaySwipeCount >= maxFreeDailySwipes) {
      PremiumUpgradeModal.show(context, onUpgradeSuccess: () {
        _loadDiscoveryData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You've used today's 10 free swipes! Upgrade to FitConnect PRO for Unlimited Swipes ⚡",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false; // Blocks any further swiping!
    }

    String action = 'pass';
    if (direction == CardSwiperDirection.right) {
      action = 'like';
    } else if (direction == CardSwiperDirection.top) {
      // SuperConnect PRO exclusivity check
      if (!isPro) {
        PremiumUpgradeModal.show(context, onUpgradeSuccess: () {
          _loadDiscoveryData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "SuperConnect is an exclusive FitConnect PRO feature! ⭐",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return false; // Prevents swipe for non-pro users
      }
      action = 'superlike';
    }

    if (!isPro) {
      setState(() => _todaySwipeCount++);
    }

    if (action != 'pass') {
      _matchService.recordSwipe(targetUserId: athlete.id, action: action).then((isMutualMatch) {
        if (isMutualMatch && mounted) {
          _showMatchDialog(athlete, isSuperMatch: action == 'superlike');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Connection request sent to ${athlete.name}!"),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: const Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });
    } else {
      _matchService.recordSwipe(targetUserId: athlete.id, action: 'pass');
    }
    return true;
  }

  void _showMatchDialog(ProfileModel athlete, {required bool isSuperMatch}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSuperMatch ? const Color(0xFF00E5FF) : const Color(0xFF39FF14),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSuperMatch ? const Color(0xFF00E5FF) : const Color(0xFF39FF14))
                    .withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: 2,
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuperMatch ? Icons.star_rounded : Icons.flash_on_rounded,
                  color: isSuperMatch ? const Color(0xFF00E5FF) : const Color(0xFF39FF14),
                  size: 60,
                ),
                const SizedBox(height: 8),
                Text(
                  isSuperMatch ? "SUPER MATCH!" : "IT'S A MATCH!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isSuperMatch ? const Color(0xFF00E5FF) : const Color(0xFF39FF14),
                  ),
                ),
                const SizedBox(height: 14),

                // Side-by-side Dual Avatars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _avatarRing(_userProfile?.imageUrl, _userProfile?.name ?? 'You'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.bolt, color: Colors.white54, size: 24),
                    ),
                    _avatarRing(athlete.imageUrl, athlete.name),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  "You and ${athlete.name} are ready for a ${athlete.sport} session!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Quick Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuperMatch ? const Color(0xFF00E5FF) : const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: const Text("SEND MESSAGE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(athlete: athlete),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text("CREATE MATCH LOBBY", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("KEEP SWIPING", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarRing(String? url, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF39FF14), Color(0xFF00E5FF)],
            ),
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF1E1E1E),
            child: ClipOval(
              child: _buildAthleteImage(url),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  void _showProfileDetailsSheet(ProfileModel athlete) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Photo Header
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildAthleteImage(athlete.imageUrl)),
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        athlete.name,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (athlete.isPremium) ...[
                                      const SizedBox(width: 8),
                                      const ProBadgeWidget(),
                                    ],
                                  ],
                                ),
                                Text(
                                  athlete.sport.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF39FF14),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.verified_rounded,
                          label: "RELIABILITY",
                          value: "${athlete.reliabilityScore}%",
                          accentColor: const Color(0xFF39FF14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.fitness_center_rounded,
                          label: "SKILL TIER",
                          value: athlete.skill,
                          accentColor: const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF39FF14), size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PREFERRED LOCATION", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(athlete.location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio & Availability Section
                  const Text("ABOUT ATHLETE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    "Enthusiastic ${athlete.sport} player based in ${athlete.location}. Looking to match for friendly games, casual tournament training, and weekend sessions.",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons in Sheet
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            controller.swipe(CardSwiperDirection.left);
                          },
                          child: const Text("PASS", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            controller.swipe(CardSwiperDirection.right);
                          },
                          child: const Text("CONNECT ⚡", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _userProfile?.imageUrl;
    final activeDeck = _filteredAthletes;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((_) => _loadDiscoveryData());
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: (_userProfile?.isPremium ?? false)
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF1A1A1A),
                  child: CircleAvatar(
                    radius: (_userProfile?.isPremium ?? false) ? 18 : 19,
                    child: ClipOval(
                      child: _isLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF39FF14)),
                            )
                          : (avatarUrl != null && avatarUrl.startsWith('http')
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 40, height: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, color: Color(0xFF39FF14)),
                                )
                              : Image.asset(
                                  'assets/images/me.jpg',
                                  fit: BoxFit.cover,
                                  width: 40, height: 40,
                                  errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.person, color: Color(0xFF39FF14)),
                                )),
                    ),
                  ),
                ),
              ),
              Container(
                height: 12, width: 12,
                decoration: BoxDecoration(
                  color: (_userProfile?.isPremium ?? false)
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF39FF14),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF080808), width: 2),
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'FITCONNECT', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!(_userProfile?.isPremium ?? false))
            IconButton(
              tooltip: "FitConnect PRO",
              icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700)),
              onPressed: () {
                PremiumUpgradeModal.show(
                  context,
                  onUpgradeSuccess: () => _loadDiscoveryData(),
                );
              },
            ),
          IconButton(
            onPressed: _handleLogout, 
            icon: const Icon(Icons.logout, color: Color(0xFF39FF14)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
          : Column(
              children: [
                // Sport Category Filter Chips Bar
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sportFilters.length,
                    itemBuilder: (context, index) {
                      final sport = _sportFilters[index];
                      final isSelected = _selectedSportFilter == sport;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSportFilter = sport);
                            }
                          },
                          selectedColor: const Color(0xFF39FF14),
                          backgroundColor: const Color(0xFF141414),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF39FF14)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Free vs PRO Swipe Quota Indicator Pill
                _buildSwipeQuotaBar(),

                const SizedBox(height: 6),

                // Card Swiper Engine
                Expanded(
                  child: activeDeck.isEmpty
                      ? Center(
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
                                child: const Icon(Icons.radar_rounded, size: 64, color: Color(0xFF39FF14)),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "NO ATHLETES NEARBY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try switching your sport filter or rewind cards.",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF39FF14),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _handleResetSwipes,
                                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                                    label: const Text("RESET SWIPES & START OVER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () {
                                      setState(() => _selectedSportFilter = 'ALL');
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text("RESET FILTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : CardSwiper(
                          controller: controller,
                          cardsCount: activeDeck.length,
                          numberOfCardsDisplayed: activeDeck.length < 3 ? activeDeck.length : 3,
                          backCardOffset: const Offset(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                          onSwipe: _onSwipe,
                          isLoop: true,
                          allowedSwipeDirection: const AllowedSwipeDirection.only(
                            left: true,
                            right: true,
                            up: true,
                          ),
                          cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
                            final player = activeDeck[index % activeDeck.length];
                            bool isSwipingRight = horizontalThreshold > 20;  
                            bool isSwipingLeft = horizontalThreshold < -20;
                            bool isSwipingTop = verticalThreshold < -20;

                            return GestureDetector(
                              onTap: () => _showProfileDetailsSheet(player),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  children: [
                                    // Athlete Image
                                    Positioned.fill(
                                      child: _buildAthleteImage(player.imageUrl),
                                    ),

                                    // Gradient Shadow Overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black12,
                                              Colors.black87,
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Info Overlay Card Text
                                    Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFF39FF14)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.verified, size: 12, color: Color(0xFF39FF14)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "RELIABILITY ${player.reliabilityScore}%",
                                                      style: const TextStyle(
                                                        color: Color(0xFF39FF14),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              // Tap Info Hint Icon
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white30),
                                                ),
                                                child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  player.name,
                                                  style: const TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    height: 1.1,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (player.isPremium) ...[
                                                const SizedBox(width: 8),
                                                const ProBadgeWidget(isCompact: true),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            player.sport.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF39FF14),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 15, color: Colors.white60),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  player.location,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  player.skill,
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Dynamic Swipe Stamp Overlays
                                    if (isSwipingRight)
                                      Positioned(
                                        top: 40,
                                        left: 20,
                                        child: Transform.rotate(
                                          angle: -0.2,
                                          child: _stamp("CONNECT ⚡", const Color(0xFF39FF14)),
                                        ),
                                      ),
                                    if (isSwipingLeft)
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: Transform.rotate(
                                          angle: 0.2,
                                          child: _stamp("PASS ✖", Colors.redAccent),
                                        ),
                                      ),
                                    if (isSwipingTop)
                                      Positioned(
                                        bottom: 120,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Transform.rotate(
                                            angle: 0.0,
                                            child: _stamp("SUPER CONNECT ⭐", const Color(0xFF00E5FF)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Tinder-Style 5-Button Control Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. REWIND / UNDO
                      _controlBtn(
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFFFB74D),
                        onTap: () => controller.undo(),
                        size: 44,
                      ),
                      // 2. PASS (LEFT)
                      _controlBtn(
                        icon: Icons.close_rounded,
                        color: Colors.redAccent,
                        onTap: () => _triggerManualSwipe(CardSwiperDirection.left),
                        size: 52,
                      ),
                      // 3. SUPER CONNECT (TOP)
                      _controlBtn(
                        icon: Icons.star_rounded,
                        color: const Color(0xFF00E5FF),
                        onTap: () {
                          if (!(_userProfile?.isPremium ?? false)) {
                            PremiumUpgradeModal.show(context, onUpgradeSuccess: () {
                              _loadDiscoveryData();
                            });
                          } else {
                            _triggerManualSwipe(CardSwiperDirection.top);
                          }
                        },
                        size: 44,
                        badge: !(_userProfile?.isPremium ?? false)
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // 4. CONNECT (RIGHT - PRIMARY)
                      _controlBtn(
                        icon: Icons.bolt_rounded,
                        color: Colors.black,
                        backgroundColor: const Color(0xFF39FF14),
                        onTap: () => _triggerManualSwipe(CardSwiperDirection.right),
                        size: 56,
                        isPrimary: true,
                      ),
                      // 5. PROFILE INFO
                      _controlBtn(
                        icon: Icons.info_outline_rounded,
                        color: const Color(0xFFB388FF),
                        onTap: () {
                          if (activeDeck.isNotEmpty) {
                            _showProfileDetailsSheet(activeDeck.first);
                          }
                        },
                        size: 44,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _triggerManualSwipe(CardSwiperDirection dir) {
    final isPro = _userProfile?.isPremium ?? false;
    if (!isPro && _todaySwipeCount >= maxFreeDailySwipes) {
      PremiumUpgradeModal.show(context, onUpgradeSuccess: () {
        _loadDiscoveryData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You've used today's 10 free swipes! Upgrade to FitConnect PRO for Unlimited Swipes ⚡",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    controller.swipe(dir);
  }

  Widget _buildSwipeQuotaBar() {
    final isPro = _userProfile?.isPremium ?? false;
    final remaining = (maxFreeDailySwipes - _todaySwipeCount).clamp(0, maxFreeDailySwipes);

    return GestureDetector(
      onTap: isPro
          ? null
          : () {
              PremiumUpgradeModal.show(context, onUpgradeSuccess: () {
                _loadDiscoveryData();
              });
            },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPro
              ? const Color(0xFFFFD700).withValues(alpha: 0.1)
              : (remaining <= 2
                  ? Colors.redAccent.withValues(alpha: 0.12)
                  : const Color(0xFF161616)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPro
                ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                : (remaining <= 2
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPro
                  ? Icons.workspace_premium_rounded
                  : (remaining == 0 ? Icons.lock_clock_rounded : Icons.bolt_rounded),
              size: 14,
              color: isPro
                  ? const Color(0xFFFFD700)
                  : (remaining <= 2 ? Colors.redAccent : const Color(0xFF39FF14)),
            ),
            const SizedBox(width: 6),
            Text(
              isPro
                  ? "PRO: UNLIMITED SWIPES"
                  : "$remaining / $maxFreeDailySwipes Free Swipes Left Today",
              style: TextStyle(
                color: isPro
                    ? const Color(0xFFFFD700)
                    : (remaining <= 2 ? Colors.redAccent : Colors.white70),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (!isPro) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios, size: 9, color: Color(0xFFFFD700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteImage(String? imgPath) {
    if (imgPath != null && imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF141414),
          child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
        ),
      );
    } else if (imgPath != null && imgPath.isNotEmpty) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF141414),
          child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
        ),
      );
    }
    return Container(
      color: const Color(0xFF141414),
      child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
    );
  }

  Widget _stamp(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: color, width: 3.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
    Color? backgroundColor,
    bool isPrimary = false,
    Widget? badge,
  }) {
    final btn = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF161616),
        shape: BoxShape.circle,
        border: isPrimary
            ? null
            : Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: size * 0.52),
      ),
    );

    if (badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          btn,
          Positioned(
            top: -2,
            right: -2,
            child: badge,
          ),
        ],
      );
    }

    return btn;
  }
}
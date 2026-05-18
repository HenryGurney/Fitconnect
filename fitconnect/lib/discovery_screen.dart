import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; // Import to link your Athlete Profile Settings

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final CardSwiperController controller = CardSwiperController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoadingImage = true;
  String? _profileImageUrl; // Holds the dynamic user avatar link

  final List<Map<String, String>> athletes = [
    {
      'name': 'Aiman',
      'sport': 'Futsal',
      'skill': 'Intermediate',
      'loc': 'Kuala Lumpur',
      'img': 'assets/images/aiman.jpg'
    },
    {
      'name': 'Aina',
      'sport': 'Tennis',
      'skill': 'Advanced',
      'loc': 'Subang Jaya',
      'img': 'assets/images/aina.jpg'
    },
    {
      'name': 'Harith',
      'sport': 'Futsal',
      'skill': 'Beginner',
      'loc': 'Shah Alam',
      'img': 'assets/images/harith.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // --- NEW: FETCH USER AVATAR FROM SUPABASE ---
  Future<void> _loadUserProfileImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select('image_url')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profileImageUrl = data['image_url'];
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching avatar: $e");
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  // LOGOUT FUNCTION
  Future<void> _handleLogout() async {
    // Capture messenger and navigator before async operations execute
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _supabase.auth.signOut();
      
      if (mounted) {
        // Clear entire navigation stack on manual logout
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
    final safeIndex = previousIndex % athletes.length;
    
    if (direction == CardSwiperDirection.right) {
      final matchedPlayer = athletes[safeIndex]['name'];
      if (matchedPlayer != null) {
        _showMatchDialog(matchedPlayer);
      }
    }
    return true;
  }

  void _showMatchDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF39FF14), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF39FF14), size: 80),
              const Text("IT'S A MATCH!", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF39FF14))),
              const SizedBox(height: 10),
              Text("You and $name are ready for a session.", textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(context),
                child: const Text("SEND MESSAGE", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  // Route out to Profile Settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((_) {
                    // Synchronize state and pull down new image string upon return path
                    _loadUserProfileImage();
                  });
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1A1A1A),
                  child: ClipOval(
                    child: _isLoadingImage
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF39FF14)),
                          )
                        : (_profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
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
              Container(
                height: 12, width: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF080808), width: 2),
                ),
              ),
            ],
          ),
        ),
        title: const Text('FITCONNECT', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout, 
            icon: const Icon(Icons.logout, color: Color(0xFF39FF14))
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: athletes.length,
              numberOfCardsDisplayed: 3,
              backCardOffset: const Offset(0, 40),
              padding: const EdgeInsets.all(20.0),
              onSwipe: _onSwipe,
              isLoop: true,
              allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true),
              cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
                final player = athletes[index % athletes.length];
                bool isSwipingRight = horizontalThreshold > 20;  
                bool isSwipingLeft = horizontalThreshold < -20;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(player['img']!, fit: BoxFit.cover),
                      ),
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
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF39FF14)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Color(0xFF39FF14)),
                                  SizedBox(width: 4),
                                  Text("TOP RELIABILITY", style: TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(player['name']!, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(player['sport']!.toUpperCase(), style: const TextStyle(fontSize: 18, color: Color(0xFF39FF14), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(player['loc']!, style: const TextStyle(color: Colors.white70)),
                                const Spacer(),
                                Chip(
                                  label: Text(player['skill']!), 
                                  backgroundColor: Colors.white24, 
                                  side: BorderSide.none,
                                  labelStyle: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSwipingRight)
                        Center(child: Transform.rotate(angle: -0.2, child: _stamp("CONNECT", const Color(0xFF39FF14)))),
                      if (isSwipingLeft)
                        Center(child: Transform.rotate(angle: 0.2, child: _stamp("PASS", Colors.redAccent))),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundBtn(Icons.close, Colors.redAccent, () => controller.swipe(CardSwiperDirection.left), 50),
                _roundBtn(Icons.flash_on, Colors.black, () => controller.swipe(CardSwiperDirection.right), 50, isPrimary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stamp(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 4), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.w900)),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback t, double size, {bool isPrimary = false}) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A),
        shape: BoxShape.circle,
      ),
      child: IconButton(onPressed: t, icon: Icon(icon, color: color, size: size * 0.5)),
    );
  }
}
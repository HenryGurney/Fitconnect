import 'package:flutter/material.dart';
import 'discovery_screen.dart';
import 'lobby_screen.dart';
import 'chat_list_screen.dart';
import 'my_lobbies_page.dart';
import 'services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = const [
    DiscoveryScreen(),
    LobbyScreen(),
    ChatListScreen(),
    MyLobbiesScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      _notificationService.clearUnreadBadge();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_currentIndex >= 0 && _currentIndex < _pages.length)
        ? _currentIndex
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: IndexedStack(
        index: safeIndex,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _notificationService.unreadCountStream,
        initialData: _notificationService.unreadCount,
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;

          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: _onTabTapped,
              backgroundColor: const Color(0xFF0D0D0D),
              selectedItemColor: const Color(0xFF39FF14),
              unselectedItemColor: Colors.white38,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.flash_on_outlined),
                  activeIcon: Icon(Icons.flash_on, color: Color(0xFF39FF14)),
                  label: 'DISCOVER',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.groups_rounded),
                  activeIcon: Icon(Icons.groups, color: Color(0xFF39FF14)),
                  label: 'LOBBIES',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor: const Color(0xFF39FF14),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor: const Color(0xFF39FF14),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF39FF14)),
                  ),
                  label: 'MESSAGES',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer_outlined),
                  activeIcon: Icon(Icons.sports_soccer, color: Color(0xFF39FF14)),
                  label: 'MY LOBBIES',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
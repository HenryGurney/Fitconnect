import 'package:flutter/material.dart';
import 'discovery_screen.dart';
import 'lobby_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoveryScreen(),
    const LobbyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Persists state so swiping cards aren't reset
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0D0D0D),
          selectedItemColor: const Color(0xFF39FF14),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on_outlined),
              activeIcon: Icon(Icons.flash_on, color: Color(0xFF39FF14)),
              label: 'DISCOVER',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              activeIcon: Icon(Icons.groups, color: Color(0xFF39FF14)),
              label: 'LOBBIES',
            ),
          ],
        ),
      ),
    );
  }
}
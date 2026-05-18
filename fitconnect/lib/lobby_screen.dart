import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lobby_details_page.dart';
import 'create_lobby_page.dart'; // FIX: Resolves the missing CreateLobbyPage error!

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "DISCOVER MATCHES",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('lobbies').stream(primaryKey: ['id']).order('created_at', ascending: false),
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

          final lobbies = snapshot.data ?? [];

          if (lobbies.isEmpty) {
            return const Center(
              child: Text(
                "No active sports lobbies found.\nTap '+' to launch the first one!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: lobbies.length,
            itemBuilder: (context, index) {
              final lobby = lobbies[index];
              return LobbyCardWidget(lobbyData: lobby);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLobbyPage()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class LobbyCardWidget extends StatelessWidget {
  final Map<String, dynamic> lobbyData;
  const LobbyCardWidget({super.key, required this.lobbyData});

  @override
  Widget build(BuildContext context) {
    final String title = lobbyData['title'] ?? 'Casual Match';
    final String sport = lobbyData['sport'] ?? 'Futsal';
    final String location = lobbyData['location_name'] ?? 'Unknown Venue';
    final int maxParticipants = lobbyData['max_participants'] ?? 10;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyDetailsPage(lobbyData: lobbyData),
          ),
        );
      },
      child: Container(
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
                    sport.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                  ),
                ),
                Text(
                  "LIMIT: $maxParticipants PLYRS",
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "VIEW FULL DETAILS",
                  style: TextStyle(color: Color(0xFF39FF14), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class FreeDiscovery extends StatelessWidget {
  final List<Map<String, dynamic>> gameRequests;
  final Future<void> Function() onRefresh;

  const FreeDiscovery({super.key, required this.gameRequests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (gameRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text("NO ACTIVE LOBBIES", style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF39FF14),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gameRequests.length,
        itemBuilder: (context, index) {
          final req = gameRequests[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(req['sport'].toString().toUpperCase(), style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 10)),
                    Text("BY ${req['profiles']?['name']?.toString().toUpperCase() ?? 'ATHLETE'}", style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(req['description'] ?? "Looking for a match!", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(req['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {}, 
                      child: const Text("JOIN", style: TextStyle(fontWeight: FontWeight.w900)),
                    )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'models/models.dart';
import 'widgets/pro_badge_widget.dart';

class FreeDiscovery extends StatelessWidget {
  final List<LobbyModel> lobbies;
  final Future<void> Function() onRefresh;
  final Function(LobbyModel)? onLobbySelected;

  const FreeDiscovery({
    super.key,
    required this.lobbies,
    required this.onRefresh,
    this.onLobbySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (lobbies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              "NO ACTIVE LOBBIES",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF39FF14),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lobbies.length,
        itemBuilder: (context, index) {
          final lobby = lobbies[index];
          final hostName = lobby.hostProfile?.name ?? 'ATHLETE';

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
                    Text(
                      lobby.sport.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "BY ${hostName.toUpperCase()}",
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (lobby.hostProfile?.isPremium ?? false) ...[
                          const SizedBox(width: 4),
                          const ProBadgeWidget(isCompact: true),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lobby.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lobby.locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (onLobbySelected != null) {
                          onLobbySelected!(lobby);
                        }
                      }, 
                      child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.w900)),
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
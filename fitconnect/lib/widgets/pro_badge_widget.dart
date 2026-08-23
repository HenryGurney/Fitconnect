import 'package:flutter/material.dart';

class ProBadgeWidget extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onTap;

  const ProBadgeWidget({
    super.key,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFF39FF14), // FitConnect Neon Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39FF14).withValues(alpha: 0.35),
            blurRadius: isCompact ? 6 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: Colors.black,
            size: isCompact ? 11 : 14,
          ),
          const SizedBox(width: 3),
          Text(
            "PRO",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: isCompact ? 9 : 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}

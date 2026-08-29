import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/profile_service.dart';
import '../services/subscription_service.dart';
import 'pro_badge_widget.dart';
import 'payment_gateway_modal.dart';

class PremiumUpgradeModal extends StatefulWidget {
  final VoidCallback? onUpgradeSuccess;

  const PremiumUpgradeModal({
    super.key,
    this.onUpgradeSuccess,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onUpgradeSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumUpgradeModal(onUpgradeSuccess: onUpgradeSuccess),
    );
  }

  @override
  State<PremiumUpgradeModal> createState() => _PremiumUpgradeModalState();
}

class _PremiumUpgradeModalState extends State<PremiumUpgradeModal> {
  final ProfileService _profileService = ProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  int _selectedPlanIndex = 1; // Default to Annual Plan (Best Value)
  bool _isUpgrading = false;
  bool _isRestoring = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'MONTHLY',
      'price': 'RM 9.99',
      'period': '/ month',
      'badge': null,
      'savings': null,
      'package': null,
    },
    {
      'title': 'ANNUAL',
      'price': 'RM 79.99',
      'period': '/ year',
      'badge': 'BEST VALUE',
      'savings': 'SAVE 33%',
      'package': null,
    },
  ];

  final List<Map<String, dynamic>> _perks = [
    {
      'icon': Icons.bolt_rounded,
      'title': 'Unlimited Swipes & Rewinds',
      'desc': 'Never run out of athlete cards and easily undo accidental passes.',
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'title': 'Exclusive PRO Crown Badge',
      'desc': 'Stand out in discovery, matchmaking lists, and sports lobbies.',
    },
    {
      'icon': Icons.push_pin_rounded,
      'title': 'Spotlight / Pinned Lobbies',
      'desc': 'Your created lobbies stay pinned to the top of everyone\'s feed.',
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Advanced Precision Filters',
      'desc': 'Filter athletes by skill tier, verified reliability score, and radius.',
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Unlimited Emergency SOS Alerts',
      'desc': 'Need +1 player fast? Broadcast instant alerts to nearby athletes.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await _subscriptionService.getOfferings();
    if (offerings != null && offerings.current != null && mounted) {
      setState(() {
        final monthlyPkg = offerings.current!.monthly;
        final annualPkg = offerings.current!.annual;

        if (monthlyPkg != null) {
          String price = monthlyPkg.storeProduct.priceString;
          price = price.replaceAll(r'$', 'RM ');
          _plans[0]['price'] = price;
          _plans[0]['package'] = monthlyPkg;
        }
        if (annualPkg != null) {
          String price = annualPkg.storeProduct.priceString;
          price = price.replaceAll(r'$', 'RM ');
          _plans[1]['price'] = price;
          _plans[1]['package'] = annualPkg;
        }
      });
    }
  }

  Future<void> _handleUpgrade() async {
    final selectedPlan = _plans[_selectedPlanIndex];
    final double amount = _selectedPlanIndex == 0 ? 19.90 : 149.00;

    PaymentGatewayModal.show(
      context,
      itemName: "FitConnect PRO (${selectedPlan['title']})",
      itemDescription: "Unlimited Swipes, Pinned Lobbies & Golden Crown",
      amount: amount,
      onPaymentSuccess: () async {
        setState(() => _isUpgrading = true);
        try {
          final package = selectedPlan['package'] as Package?;
          if (package != null && _subscriptionService.isConfigured) {
            await _subscriptionService.purchasePackage(package);
          } else {
            await _profileService.updateTier('premium');
          }

          if (!mounted) return;

          Navigator.pop(context); // Close bottom sheet

          if (widget.onUpgradeSuccess != null) {
            widget.onUpgradeSuccess!();
          }

          // Show congratulations celebration dialog
          _showSuccessCelebration(context);
        } catch (e) {
          debugPrint("Upgrade error: $e");
        } finally {
          if (mounted) setState(() => _isUpgrading = false);
        }
      },
    );
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isRestoring = true);

    try {
      final isPro = await _subscriptionService.restorePurchases();

      if (!mounted) return;
      setState(() => _isRestoring = false);

      if (isPro) {
        Navigator.pop(context);
        if (widget.onUpgradeSuccess != null) {
          widget.onUpgradeSuccess!();
        }
        _showSuccessCelebration(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No previous active PRO subscriptions found."),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      debugPrint("Restore error: $e");
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Restore failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessCelebration(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFF39FF14), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFF39FF14)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "WELCOME TO PRO!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "All FitConnect PRO perks are now unlocked for your account. Enjoy unlimited matchmaking & spotlight lobbies!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              const ProBadgeWidget(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "START PLAYING ⚡",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0xFF39FF14), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Crown Header Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD700),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "FITCONNECT ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      ProBadgeWidget(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Supercharge Your Athlete Network & Lobbies",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Plans Selector (Monthly vs Annual)
                  Row(
                    children: List.generate(_plans.length, (index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPlanIndex == index;
                      final hasBadge = plan['badge'] != null;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlanIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == 0 ? 8 : 0,
                              left: index == 1 ? 8 : 0,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1C281A)
                                  : const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF39FF14)
                                    : Colors.white12,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan['title'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF39FF14)
                                            : Colors.white70,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    if (hasBadge)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          plan['badge'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  plan['price'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  plan['period'],
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                if (plan['savings'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    plan['savings'],
                                    style: const TextStyle(
                                      color: Color(0xFF39FF14),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Perks List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: _perks.map((perk) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  perk['icon'] as IconData,
                                  color: const Color(0xFF39FF14),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      perk['title'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      perk['desc'] as String,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upgrade Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF39FF14).withValues(alpha: 0.4),
                      ),
                      onPressed: _isUpgrading ? null : _handleUpgrade,
                      child: _isUpgrading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt_rounded, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  "UNLOCK FITCONNECT PRO ⚡",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Restore Purchases & Trust info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isRestoring ? null : _handleRestorePurchases,
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                              )
                            : const Icon(Icons.restore, size: 14, color: Colors.white54),
                        label: const Text(
                          "Restore Purchases",
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "Cancel anytime. Subscriptions auto-renew via Google Play / App Store.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentGatewayModal extends StatefulWidget {
  final String itemName;
  final String itemDescription;
  final double amount;
  final VoidCallback onPaymentSuccess;

  const PaymentGatewayModal({
    super.key,
    required this.itemName,
    required this.itemDescription,
    required this.amount,
    required this.onPaymentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required String itemDescription,
    required double amount,
    required VoidCallback onPaymentSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentGatewayModal(
        itemName: itemName,
        itemDescription: itemDescription,
        amount: amount,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<PaymentGatewayModal> createState() => _PaymentGatewayModalState();
}

class _PaymentGatewayModalState extends State<PaymentGatewayModal> {
  int _currentStep = 0; // 0: Select Bank/Method, 1: Bank Auth/OTP, 2: Processing, 3: Success Receipt
  String _selectedMethod = 'Maybank2u';
  String _referenceId = '';
  final TextEditingController _otpController = TextEditingController(text: '782910');

  final List<Map<String, dynamic>> _banks = [
    {
      'id': 'Maybank2u',
      'name': 'Maybank2u',
      'category': 'FPX',
      'code': 'MBB',
      'color': const Color(0xFFFFCC00),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'CIMB Clicks',
      'name': 'CIMB Clicks',
      'category': 'FPX',
      'code': 'CIMB',
      'color': const Color(0xFFED1C24),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'Bank Islam',
      'name': 'Bank Islam',
      'category': 'FPX',
      'code': 'BIMB',
      'color': const Color(0xFF00897B),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'Public Bank',
      'name': 'Public Bank',
      'category': 'FPX',
      'code': 'PBB',
      'color': const Color(0xFFDE1F27),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'RHB Now',
      'name': 'RHB Now',
      'category': 'FPX',
      'code': 'RHB',
      'color': const Color(0xFF0067B1),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'TNG eWallet',
      'name': 'Touch \'n Go eWallet',
      'category': 'eWallet',
      'code': 'TNG',
      'color': const Color(0xFF005BAA),
      'icon': Icons.phone_android_rounded,
    },
    {
      'id': 'Card',
      'name': 'Credit / Debit Card',
      'category': 'Card',
      'code': 'VISA/MC',
      'color': const Color(0xFF39FF14),
      'icon': Icons.credit_card_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateTxnId();
  }

  void _generateTxnId() {
    final rand = Random().nextInt(899999) + 100000;
    final now = DateTime.now();
    _referenceId = "TXN-FC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand";
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _proceedToAuth() {
    setState(() => _currentStep = 1);
  }

  void _submitAuthorization() async {
    setState(() => _currentStep = 2);

    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    // Simulate gateway authorization processing
    await Future.delayed(const Duration(milliseconds: 1600));

    if (mounted) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
      setState(() => _currentStep = 3);
    }
  }

  void _completeTransaction() {
    Navigator.pop(context);
    widget.onPaymentSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      padding: EdgeInsets.only(
        bottom: bottomInset + 16,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF39FF14), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentStepWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildSelectBankStep();
      case 1:
        return _buildBankAuthStep();
      case 2:
        return _buildProcessingStep();
      case 3:
        return _buildReceiptStep();
      default:
        return _buildSelectBankStep();
    }
  }

  /// Step 0: Method Selection & Order Summary
  Widget _buildSelectBankStep() {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF39FF14), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FPX ONLINE BANKING & CARD GATEWAY",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Text(
                    "PayNet FPX Secure Payment Integration",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Order Summary Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.itemName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "RM ${widget.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.itemDescription,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("SST / Fee: RM 0.00", style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          "SELECT PAYMENT METHOD",
          style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),

        // List of Banks & eWallets
        ..._banks.map((b) {
          final isSelected = _selectedMethod == b['id'];
          final IconData iconData = b['icon'] as IconData;
          final Color iconColor = b['color'] as Color;
          final String code = b['code'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMethod = b['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E2818) : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.06),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Action Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _proceedToAuth,
          child: Text(
            "PAY RM ${widget.amount.toStringAsFixed(2)} VIA $_selectedMethod",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  /// Step 1: Bank Simulation & TAC/OTP Authorization
  Widget _buildBankAuthStep() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
              onPressed: () => setState(() => _currentStep = 0),
            ),
            Text(
              "$_selectedMethod Authorization",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Merchant:", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text("FITCONNECT SDN BHD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Amount:", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text("RM ${widget.amount.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ref No:", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text(_referenceId, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Enter 6-Digit SMS TAC / OTP to Authorize",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF39FF14), letterSpacing: 8, fontSize: 22, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _submitAuthorization,
          icon: const Icon(Icons.lock_outline_rounded, size: 18),
          label: const Text("CONFIRM & AUTHORIZE PAYMENT", style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  /// Step 2: Processing Spinner
  Widget _buildProcessingStep() {
    return const Column(
      key: ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 30),
        SizedBox(
          width: 54,
          height: 54,
          child: CircularProgressIndicator(
            color: Color(0xFF39FF14),
            strokeWidth: 4,
          ),
        ),
        SizedBox(height: 24),
        Text(
          "Authorizing Payment with Bank...",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        SizedBox(height: 6),
        Text(
          "Please do not close or refresh this window",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  /// Step 3: Verified Receipt Screen
  Widget _buildReceiptStep() {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF39FF14).withValues(alpha: 0.15),
            border: Border.all(color: const Color(0xFF39FF14), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF39FF14), size: 36),
        ),
        const SizedBox(height: 14),
        const Text(
          "PAYMENT SUCCESSFUL",
          style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        const Text("Your transaction has been approved by the gateway.", style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 18),

        // Receipt Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildReceiptRow("Amount Paid:", "RM ${widget.amount.toStringAsFixed(2)}", isGreen: true),
              const Divider(color: Colors.white10, height: 16),
              _buildReceiptRow("Item:", widget.itemName),
              const SizedBox(height: 6),
              _buildReceiptRow("Channel:", _selectedMethod),
              const SizedBox(height: 6),
              _buildReceiptRow("Reference ID:", _referenceId),
              const SizedBox(height: 6),
              _buildReceiptRow("Date & Time:", dateStr),
              const SizedBox(height: 6),
              _buildReceiptRow("Status:", "APPROVED / COMPLETED"),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _completeTransaction,
          child: const Text("DONE & ACTIVATE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? const Color(0xFF39FF14) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isGreen ? 14 : 12,
          ),
        ),
      ],
    );
  }
}

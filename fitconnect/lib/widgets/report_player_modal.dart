import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/profile_service.dart';

class ReportPlayerModal extends StatefulWidget {
  final ProfileModel reportedAthlete;
  final String? lobbyId;

  const ReportPlayerModal({
    super.key,
    required this.reportedAthlete,
    this.lobbyId,
  });

  static Future<void> show(BuildContext context, {required ProfileModel reportedAthlete, String? lobbyId}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ReportPlayerModal(
        reportedAthlete: reportedAthlete,
        lobbyId: lobbyId,
      ),
    );
  }

  @override
  State<ReportPlayerModal> createState() => _ReportPlayerModalState();
}

class _ReportPlayerModalState extends State<ReportPlayerModal> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reasons = [
    {
      'title': 'No-Show / Unattended Match',
      'subtitle': 'Confirmed player did not show up without notice',
      'penalty': 15,
      'icon': Icons.person_off_rounded,
      'color': Colors.redAccent,
    },
    {
      'title': 'Last-Minute Cancellation',
      'subtitle': 'Dropped out less than 2 hours before match kickoff',
      'penalty': 5,
      'icon': Icons.timer_off_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'title': 'Unsportsmanlike / Toxic Conduct',
      'subtitle': 'Aggressive, dangerous play, or abusive speech',
      'penalty': 10,
      'icon': Icons.warning_amber_rounded,
      'color': Colors.amber,
    },
    {
      'title': 'Payment Refusal / Fee Evasion',
      'subtitle': 'Refused to pay pitch booking share or match fee',
      'penalty': 15,
      'icon': Icons.money_off_rounded,
      'color': Colors.redAccent,
    },
    {
      'title': 'Harassment / Inappropriate Behavior',
      'subtitle': 'Unwanted messages, spam, or hostile harassment',
      'penalty': 10,
      'icon': Icons.block_rounded,
      'color': Colors.purpleAccent,
    },
  ];

  int _selectedReasonIndex = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitReport() async {
    setState(() => _isSubmitting = true);
    final reasonData = _reasons[_selectedReasonIndex];
    final String reason = reasonData['title'] as String;
    final int penalty = reasonData['penalty'] as int;
    final String notes = _notesController.text.trim();

    try {
      await _profileService.submitPlayerReport(
        reportedUserId: widget.reportedAthlete.id,
        reason: reason,
        notes: notes.isNotEmpty ? notes : null,
        lobbyId: widget.lobbyId,
        penalty: penalty,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚩 Report submitted for ${widget.reportedAthlete.name}. Player reliability adjusted (-$penalty%).",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2C1414),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit report: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final athlete = widget.reportedAthlete;
    final selectedReason = _reasons[_selectedReasonIndex];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "REPORT ATHLETE / NO-SHOW",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                      ),
                      Text(
                        "Flagging ${athlete.name} for match violations",
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Violation Reasons List
            const Text(
              "SELECT VIOLATION TYPE",
              style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            ...List.generate(_reasons.length, (index) {
              final r = _reasons[index];
              final isSelected = _selectedReasonIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedReasonIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF221616) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(r['icon'] as IconData, color: r['color'] as Color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r['subtitle'] as String,
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "-${r['penalty']}%",
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Optional Incident Notes
            const Text(
              "INCIDENT DETAILS (OPTIONAL)",
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Add specific context or match details...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _handleSubmitReport,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        "SUBMIT REPORT (-${selectedReason['penalty']}%)",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

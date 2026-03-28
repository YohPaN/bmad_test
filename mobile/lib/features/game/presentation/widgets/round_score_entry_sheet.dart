import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/event_repository.dart';

// ────────────────────────────────────────────────────────────────────────────
// RoundScoreEntrySheet
// ────────────────────────────────────────────────────────────────────────────

/// Modal bottom sheet for entering VP Primaires / VP Secondaires for a round.
///
/// Shows a numeric keyboard automatically and prevents keyboard overlap via
/// [isScrollControlled] + [MediaQuery.viewInsets].
class RoundScoreEntrySheet extends StatefulWidget {
  final int roundNumber;
  final String playerName;
  final Color playerColor;
  final int? vpPrimInitial;
  final int? vpSecInitial;
  final Future<void> Function(int vpPrim, int vpSec) onConfirm;

  const RoundScoreEntrySheet({
    super.key,
    required this.roundNumber,
    required this.playerName,
    required this.playerColor,
    this.vpPrimInitial,
    this.vpSecInitial,
    required this.onConfirm,
  });

  /// Convenience factory that shows the sheet via [showModalBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required int roundNumber,
    required String playerName,
    required Color playerColor,
    int? vpPrimInitial,
    int? vpSecInitial,
    required Future<void> Function(int vpPrim, int vpSec) onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161920),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: RoundScoreEntrySheet(
              roundNumber: roundNumber,
              playerName: playerName,
              playerColor: playerColor,
              vpPrimInitial: vpPrimInitial,
              vpSecInitial: vpSecInitial,
              onConfirm: onConfirm,
            ),
          ),
    );
  }

  @override
  State<RoundScoreEntrySheet> createState() => _RoundScoreEntrySheetState();
}

class _RoundScoreEntrySheetState extends State<RoundScoreEntrySheet> {
  late final TextEditingController _vpPrimController;
  late final TextEditingController _vpSecController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _vpPrimController = TextEditingController(
      text: widget.vpPrimInitial?.toString() ?? '',
    );
    _vpSecController = TextEditingController(
      text: widget.vpSecInitial?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _vpPrimController.dispose();
    _vpSecController.dispose();
    super.dispose();
  }

  int _parseVp(String text) {
    if (text.isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  Future<void> _handleConfirm() async {
    final vpPrim = _parseVp(_vpPrimController.text);
    final vpSec = _parseVp(_vpSecController.text);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(vpPrim, vpSec);
      if (mounted) Navigator.of(context).pop();
    } on GameException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUND ${widget.roundNumber} — ${widget.playerName}'.toUpperCase(),
            style: GoogleFonts.robotoCondensed(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF5C6478),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vpPrimController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'VP Primaires',
              labelStyle: const TextStyle(color: Color(0xFF5C6478)),
              filled: true,
              fillColor: const Color(0xFF1E2330),
              contentPadding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 56),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vpSecController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'VP Secondaires',
              labelStyle: const TextStyle(color: Color(0xFF5C6478)),
              filled: true,
              fillColor: const Color(0xFF1E2330),
              contentPadding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 56),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF44336)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.playerColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: _isLoading ? null : _handleConfirm,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                      : Text('Confirmer Round ${widget.roundNumber}'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

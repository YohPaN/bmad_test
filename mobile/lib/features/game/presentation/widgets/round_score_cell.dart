import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ────────────────────────────────────────────────────────────────────────────
// RoundCellState
// ────────────────────────────────────────────────────────────────────────────

enum RoundCellState { empty, active, filled, locked, future }

// ────────────────────────────────────────────────────────────────────────────
// RoundScoreCell
// ────────────────────────────────────────────────────────────────────────────

/// Displays a single score cell for a given round and player.
///
/// Visual behaviour is driven by [state]:
/// - [RoundCellState.empty]  — placeholder `—` in muted colour, tappable.
/// - [RoundCellState.active] — coloured 1px border, tappable.
/// - [RoundCellState.filled] — VP Prim + VP Sec + total in Roboto Mono.
/// - [RoundCellState.locked] — lock icon at 12 sp / 0.3 opacity (UX-DR16).
/// - [RoundCellState.future] — fully greyed out, non-interactive.
class RoundScoreCell extends StatelessWidget {
  final RoundCellState state;
  final int roundNumber;
  final int? vpPrim;
  final int? vpSec;
  final Color playerColor;
  final VoidCallback? onTap;

  static const Color _textMuted = Color(0xFF5C6478);
  static const Color _textPrimary = Color(0xFFE8EAF0);
  static const Color _surfaceCard = Color(0xFF161920);
  static const double _minTouchSize = 48.0;
  static const double _borderRadius = 4.0;

  const RoundScoreCell({
    super.key,
    required this.state,
    required this.roundNumber,
    required this.playerColor,
    this.vpPrim,
    this.vpSec,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isInteractive ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _minTouchSize,
          minHeight: _minTouchSize,
        ),
        child: _buildCell(),
      ),
    );
  }

  bool get _isInteractive =>
      state == RoundCellState.empty ||
      state == RoundCellState.active ||
      state == RoundCellState.locked;

  Widget _buildCell() {
    switch (state) {
      case RoundCellState.empty:
        return _cellContainer(
          border: Border.all(color: Colors.transparent),
          child: Center(
            child: Text(
              '—',
              style: GoogleFonts.robotoMono(fontSize: 14, color: _textMuted),
            ),
          ),
        );

      case RoundCellState.active:
        return _cellContainer(
          border: Border.all(color: playerColor, width: 1),
          child: const SizedBox.shrink(),
        );

      case RoundCellState.filled:
        final prim = vpPrim ?? 0;
        final sec = vpSec ?? 0;
        final total = prim + sec;
        return _cellContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'P:$prim',
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'S:$sec',
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'T:$total',
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );

      case RoundCellState.locked:
        return _cellContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Opacity(
                  opacity: 0.3,
                  child: Icon(Icons.lock, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        );

      case RoundCellState.future:
        return _cellContainer(
          child: Center(
            child: Text(
              '—',
              style: GoogleFonts.robotoMono(fontSize: 14, color: _textMuted),
            ),
          ),
        );
    }
  }

  Widget _cellContainer({required Widget child, Border? border}) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCard,
        border: border,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: child,
    );
  }
}

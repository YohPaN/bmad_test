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
///
/// When [flashOnUpdate] is `true` and the cell is in [RoundCellState.filled],
/// a 200ms opacity flash in [playerColor] is triggered whenever [vpPrim] or
/// [vpSec] changes (UX-DR13).
class RoundScoreCell extends StatefulWidget {
  final RoundCellState state;
  final int roundNumber;
  final int? vpPrim;
  final int? vpSec;
  final Color playerColor;
  final VoidCallback? onTap;
  final bool flashOnUpdate;

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
    this.flashOnUpdate = false,
  });

  @override
  State<RoundScoreCell> createState() => _RoundScoreCellState();
}

class _RoundScoreCellState extends State<RoundScoreCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flashOpacity = Tween<double>(
      begin: 0.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoundScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashOnUpdate &&
        widget.state == RoundCellState.filled &&
        (widget.vpPrim != oldWidget.vpPrim ||
            widget.vpSec != oldWidget.vpSec)) {
      _flashController.forward(from: 0.0).then((_) {
        if (mounted) _flashController.reverse();
      });
    }
  }

  bool get _isInteractive =>
      widget.state == RoundCellState.empty ||
      widget.state == RoundCellState.active ||
      widget.state == RoundCellState.locked;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashOpacity,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (_flashController.isAnimating || _flashController.value > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: widget.playerColor.withValues(
                    alpha: _flashOpacity.value,
                  ),
                ),
              ),
          ],
        );
      },
      child: GestureDetector(
        onTap: _isInteractive ? widget.onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: RoundScoreCell._minTouchSize,
            minHeight: RoundScoreCell._minTouchSize,
          ),
          child: _buildCell(),
        ),
      ),
    );
  }

  Widget _buildCell() {
    switch (widget.state) {
      case RoundCellState.empty:
        return _cellContainer(
          border: Border.all(color: Colors.transparent),
          child: Center(
            child: Text(
              '—',
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                color: RoundScoreCell._textMuted,
              ),
            ),
          ),
        );

      case RoundCellState.active:
        return _cellContainer(
          border: Border.all(color: widget.playerColor, width: 1),
          child: const SizedBox.shrink(),
        );

      case RoundCellState.filled:
        final prim = widget.vpPrim ?? 0;
        final sec = widget.vpSec ?? 0;
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
                    color: RoundScoreCell._textPrimary,
                  ),
                ),
                Text(
                  'S:$sec',
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: RoundScoreCell._textPrimary,
                  ),
                ),
                Text(
                  'T:$total',
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: RoundScoreCell._textPrimary,
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
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                color: RoundScoreCell._textMuted,
              ),
            ),
          ),
        );
    }
  }

  Widget _cellContainer({required Widget child, Border? border}) {
    return Container(
      decoration: BoxDecoration(
        color: RoundScoreCell._surfaceCard,
        border: border,
        borderRadius: BorderRadius.circular(RoundScoreCell._borderRadius),
      ),
      child: child,
    );
  }
}

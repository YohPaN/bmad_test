import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ────────────────────────────────────────────────────────────────────────────
// ResourceCounter
// ────────────────────────────────────────────────────────────────────────────

/// Displays a labelled numeric counter with `+` and `−` tap targets.
///
/// When [onIncrement] or [onDecrement] is `null` the corresponding button
/// renders in a locked (greyed-out) state and tapping it is a no-op.
///
/// [HapticFeedback.lightImpact()] is intentionally NOT called here — the
/// caller (MatchScreen._handleCpAdjust) fires haptic so this widget remains
/// a pure, side-effect-free stateless widget that's easy to unit-test.
class ResourceCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color playerColor;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ResourceCounter({
    super.key,
    required this.label,
    required this.value,
    required this.playerColor,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(
          icon: Icons.remove,
          onTap: onDecrement,
          semanticsLabel:
              onDecrement != null ? '$label - 1' : '$label bouton verrouillé',
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.robotoCondensed(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: const Color(0xFF5C6478),
              ),
            ),
            Text(
              '$value',
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: playerColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _CounterButton(
          icon: Icons.add,
          onTap: onIncrement,
          semanticsLabel:
              onIncrement != null ? '$label + 1' : '$label bouton verrouillé',
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _CounterButton (file-private)
// ────────────────────────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticsLabel;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
          child: ColoredBox(
            color: const Color(0xFF161920),
            child: Center(
              child: Icon(
                icon,
                color: onTap != null ? Colors.white : const Color(0xFF5C6478),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

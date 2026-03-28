import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ────────────────────────────────────────────────────────────────────────────
// OwnershipLockFeedback
// ────────────────────────────────────────────────────────────────────────────

/// Provides haptic + visual feedback when a player tries to mutate a cell
/// that does not belong to them (nor are they the room owner).
abstract final class OwnershipLockFeedback {
  /// Fires a selection-click haptic and shows a floating [SnackBar].
  static void trigger(BuildContext context) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous ne pouvez pas modifier cette cellule'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2A2F3E),
      ),
    );
  }
}

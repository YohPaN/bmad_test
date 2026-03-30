import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/color_utils.dart';
import '../../../room/domain/models.dart';
import '../../domain/game_rules.dart';

// ────────────────────────────────────────────────────────────────────────────
// ScoreHeroBar
// ────────────────────────────────────────────────────────────────────────────

/// Displays both players' cumulative VP totals side by side at the top of the
/// match screen.
///
/// VP totals are always derived via [vpTotal] — never stored as scalars.
/// Updates automatically when the parent rebuilds from the Firestore stream.
class ScoreHeroBar extends StatelessWidget {
  final PlayerModel player1;
  final PlayerModel player2;

  static const Color _borderSubtle = Color(0xFF2A2F3E);

  const ScoreHeroBar({super.key, required this.player1, required this.player2});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildScorePanel(player1)),
          Container(width: 1, color: _borderSubtle),
          Expanded(child: _buildScorePanel(player2)),
        ],
      ),
    );
  }

  Widget _buildScorePanel(PlayerModel player) {
    return Container(
      color: const Color(0xFF161920),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: '${player.name}: ${vpTotal(player.vpByRound)} points',
            child: Text(
              '${vpTotal(player.vpByRound)}',
              style: GoogleFonts.robotoMono(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: colorFromHex(player.color),
              ),
            ),
          ),
          Text(
            player.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.robotoCondensed(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF5C6478),
            ),
          ),
        ],
      ),
    );
  }
}

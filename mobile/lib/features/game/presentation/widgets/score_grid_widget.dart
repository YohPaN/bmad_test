import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../room/domain/models.dart';
import 'round_score_cell.dart';

// ────────────────────────────────────────────────────────────────────────────
// ScoreGridWidget
// ────────────────────────────────────────────────────────────────────────────

/// Full 5-round score grid for two players.
///
/// Columns: Round | P1 Prim | P1 Sec | P2 Prim | P2 Sec | P1 Total | P2 Total
/// Fits in ≤360dp without horizontal scrolling (UX-DR2).
class ScoreGridWidget extends StatelessWidget {
  final List<PlayerModel> players;
  final int activeRound;
  final String currentUserId;
  final bool isOwner;
  final void Function(String playerId, int round)? onCellTap;

  static const Color _surfaceCard = Color(0xFF161920);
  static const Color _borderSubtle = Color(0xFF2A2F3E);
  static const Color _textMuted = Color(0xFF5C6478);

  const ScoreGridWidget({
    super.key,
    required this.players,
    required this.activeRound,
    required this.currentUserId,
    required this.isOwner,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    if (players.length < 2) return const SizedBox.shrink();
    final p1 = players[0];
    final p2 = players[1];

    return Container(
      color: _surfaceCard,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(36), // Round label
          1: FlexColumnWidth(1), // P1 Prim
          2: FlexColumnWidth(1), // P1 Sec
          3: FlexColumnWidth(1), // P2 Prim
          4: FlexColumnWidth(1), // P2 Sec
          5: FixedColumnWidth(50), // P1 Total
          6: FixedColumnWidth(50), // P2 Total
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(
          color: _borderSubtle,
          width: 1,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        children: [
          _buildHeaderRow(p1, p2),
          for (int round = 1; round <= 5; round++) _buildDataRow(round, p1, p2),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow(PlayerModel p1, PlayerModel p2) {
    final style = GoogleFonts.robotoCondensed(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
      color: _textMuted,
    );
    return TableRow(
      children: [
        _headerCell('R', style),
        _headerCell('${_playerInitial(p1)}P', style),
        _headerCell('${_playerInitial(p1)}S', style),
        _headerCell('${_playerInitial(p2)}P', style),
        _headerCell('${_playerInitial(p2)}S', style),
        _headerCell(_playerInitial(p1), style),
        _headerCell(_playerInitial(p2), style),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Center(
        child: Text(
          text.toUpperCase(),
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _playerInitial(PlayerModel player) =>
      player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P';

  TableRow _buildDataRow(int round, PlayerModel p1, PlayerModel p2) {
    // Per-round totals derived from vpByRound — NEVER a stored scalar
    final p1RoundData = p1.vpByRound[round.toString()];
    final p2RoundData = p2.vpByRound[round.toString()];
    final p1RoundTotal =
        (p1RoundData?['prim'] ?? 0) + (p1RoundData?['sec'] ?? 0);
    final p2RoundTotal =
        (p2RoundData?['prim'] ?? 0) + (p2RoundData?['sec'] ?? 0);

    return TableRow(
      children: [
        // Round label
        Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              '$round',
              style: GoogleFonts.robotoCondensed(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _textMuted,
              ),
            ),
          ),
        ),
        // P1 Prim
        _buildPlayerCell(round, p1, vpKey: 'prim'),
        // P1 Sec
        _buildPlayerCell(round, p1, vpKey: 'sec'),
        // P2 Prim
        _buildPlayerCell(round, p2, vpKey: 'prim'),
        // P2 Sec
        _buildPlayerCell(round, p2, vpKey: 'sec'),
        // P1 round total
        _totalCell(p1RoundTotal, _colorFromHex(p1.color)),
        // P2 round total
        _totalCell(p2RoundTotal, _colorFromHex(p2.color)),
      ],
    );
  }

  Widget _buildPlayerCell(
    int round,
    PlayerModel player, {
    required String vpKey,
  }) {
    final roundData = player.vpByRound[round.toString()];
    final hasData = roundData != null;
    final vpValue = roundData?[vpKey];

    final state = _cellState(
      round: round,
      activeRound: activeRound,
      playerId: player.id,
      currentUserId: currentUserId,
      isOwner: isOwner,
      hasData: hasData,
    );

    return Padding(
      padding: const EdgeInsets.all(1),
      child: RoundScoreCell(
        state: state,
        roundNumber: round,
        playerColor: _colorFromHex(player.color),
        vpPrim: vpKey == 'prim' ? vpValue : null,
        vpSec: vpKey == 'sec' ? vpValue : null,
        onTap:
            _isInteractiveState(state)
                ? () => onCellTap?.call(player.id, round)
                : null,
      ),
    );
  }

  Widget _totalCell(int total, Color color) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          '$total',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  bool _isInteractiveState(RoundCellState state) {
    return state == RoundCellState.empty ||
        state == RoundCellState.active ||
        state == RoundCellState.locked;
  }

  static RoundCellState _cellState({
    required int round,
    required int activeRound,
    required String playerId,
    required String currentUserId,
    required bool isOwner,
    required bool hasData,
  }) {
    if (round > activeRound) return RoundCellState.future;
    if (round < activeRound) {
      return hasData ? RoundCellState.filled : RoundCellState.empty;
    }
    // round == activeRound
    if (currentUserId == playerId || isOwner) return RoundCellState.active;
    return RoundCellState.locked;
  }

  static Color _colorFromHex(String hex) {
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    final buffer = StringBuffer();
    if (normalized.length == 6) buffer.write('ff');
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

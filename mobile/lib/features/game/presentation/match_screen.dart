import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/color_utils.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/models.dart';
import '../data/event_repository.dart';
import '../domain/game_rules.dart';
import 'widgets/ownership_lock_feedback.dart';
import 'widgets/resource_counter.dart';
import 'widgets/round_score_entry_sheet.dart';
import 'widgets/score_grid_widget.dart';
import 'widgets/score_hero_bar.dart';

// ────────────────────────────────────────────────────────────────────────────
// MatchScreen
// ────────────────────────────────────────────────────────────────────────────

/// Top-level screen for an active match.
///
/// Streams both [RoomModel] and [List<PlayerModel>] from Firestore, then
/// renders [ScoreGridWidget] once both are available.
class MatchScreen extends StatelessWidget {
  final String roomId;
  final String currentUserId;

  static const Color _surfaceBg = Color(0xFF0D0F14);

  const MatchScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = RoomRepository();

    return StreamBuilder<RoomModel?>(
      stream: repo.streamRoom(roomId),
      builder: (context, roomSnap) {
        return StreamBuilder<List<PlayerModel>>(
          stream: repo.streamPlayers(roomId),
          builder: (context, playersSnap) {
            final room = roomSnap.data;
            final players = playersSnap.data;

            if (room == null || players == null || players.length < 2) {
              return const Scaffold(
                backgroundColor: _surfaceBg,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isOwner = room.createdBy == currentUserId;

            return Scaffold(
              backgroundColor: _surfaceBg,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScoreHeroBar(player1: players[0], player2: players[1]),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Builder(
                          builder:
                              (innerContext) => ScoreGridWidget(
                                players: players,
                                activeRound: room.currentRound,
                                currentUserId: currentUserId,
                                isOwner: isOwner,
                                onCellTap:
                                    (playerId, round) => _handleCellTap(
                                      innerContext,
                                      playerId,
                                      round,
                                      room,
                                      players,
                                    ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // CP strip — always visible
                    Builder(
                      builder:
                          (innerContext) => _CpStrip(
                            players: players,
                            currentUserId: currentUserId,
                            isOwner: isOwner,
                            onIncrement:
                                (player) => _handleCpAdjust(
                                  context: innerContext,
                                  room: room,
                                  player: player,
                                  delta: 1,
                                ),
                            onDecrement:
                                (player) => _handleCpAdjust(
                                  context: innerContext,
                                  room: room,
                                  player: player,
                                  delta: -1,
                                ),
                          ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder:
                            (innerContext) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    room.currentRound < kMatchRounds
                                        ? () => _handleTurnAdvance(
                                          context: innerContext,
                                          room: room,
                                          players: players,
                                        )
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E2330),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Avancer le round (${room.currentRound})',
                                ),
                              ),
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCpAdjust({
    required BuildContext context,
    required RoomModel room,
    required PlayerModel player,
    required int delta,
  }) {
    if (!canMutate(currentUserId, room.createdBy, player.id)) {
      OwnershipLockFeedback.trigger(context);
      return;
    }
    HapticFeedback.lightImpact();
    EventRepository().submitCpAdjust(
      roomId: room.id,
      actorId: currentUserId,
      targetPlayerId: player.id,
      beforeCp: player.cp,
      afterCp: player.cp + delta,
    );
  }

  void _handleTurnAdvance({
    required BuildContext context,
    required RoomModel room,
    required List<PlayerModel> players,
  }) {
    if (room.createdBy != currentUserId) {
      OwnershipLockFeedback.trigger(context);
      return;
    }
    final cpChanges =
        players
            .map(
              (p) => (
                playerId: p.id,
                beforeCp: p.cp,
                afterCp: autoIncrementCp(p).cp,
              ),
            )
            .toList();
    EventRepository().submitTurnAdvance(
      roomId: room.id,
      currentRound: room.currentRound,
      actorId: currentUserId,
      cpChanges: cpChanges,
    );
  }

  void _handleCellTap(
    BuildContext context,
    String playerId,
    int round,
    RoomModel room,
    List<PlayerModel> players,
  ) {
    if (!canMutate(currentUserId, room.createdBy, playerId)) {
      OwnershipLockFeedback.trigger(context);
      return;
    }

    final player = players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw StateError('Player $playerId not found in room'),
    );
    final roundKey = round.toString();
    final roundData = player.vpByRound[roundKey];

    RoundScoreEntrySheet.show(
      context,
      roundNumber: round,
      playerName: player.name,
      playerColor: colorFromHex(player.color),
      vpPrimInitial: roundData?['prim'],
      vpSecInitial: roundData?['sec'],
      onConfirm:
          (vpPrim, vpSec) => EventRepository().submitScoreUpdate(
            roomId: room.id,
            actorId: currentUserId,
            targetPlayerId: playerId,
            round: round,
            beforeVp:
                roundData != null
                    ? {
                      'prim': roundData['prim'] ?? 0,
                      'sec': roundData['sec'] ?? 0,
                    }
                    : null,
            vpPrimAfter: vpPrim,
            vpSecAfter: vpSec,
          ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _CpStrip (file-private)
// ────────────────────────────────────────────────────────────────────────────

class _CpStrip extends StatelessWidget {
  final List<PlayerModel> players;
  final String currentUserId;
  final bool isOwner;
  final void Function(PlayerModel) onIncrement;
  final void Function(PlayerModel) onDecrement;

  const _CpStrip({
    required this.players,
    required this.currentUserId,
    required this.isOwner,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161920),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            players.map((player) {
              final canEdit = isOwner || player.id == currentUserId;
              return ResourceCounter(
                label: 'CP',
                value: player.cp,
                playerColor: colorFromHex(player.color),
                onIncrement: canEdit ? () => onIncrement(player) : null,
                onDecrement: canEdit ? () => onDecrement(player) : null,
              );
            }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/utils/color_utils.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/models.dart';
import '../data/event_repository.dart';
import '../domain/game_rules.dart';
import 'widgets/ownership_lock_feedback.dart';
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
                  ],
                ),
              ),
            );
          },
        );
      },
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

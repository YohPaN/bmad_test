import 'package:flutter/material.dart';

import '../../room/data/room_repository.dart';
import '../../room/domain/models.dart';
import 'widgets/score_grid_widget.dart';

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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ScoreGridWidget(
                    players: players,
                    activeRound: room.currentRound,
                    currentUserId: currentUserId,
                    isOwner: isOwner,
                    onCellTap: (playerId, round) {
                      debugPrint('Cell tapped: $playerId round $round');
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

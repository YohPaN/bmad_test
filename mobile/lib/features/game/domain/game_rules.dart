// Pure business-rule functions for the game feature.
// ZERO Firestore/Firebase imports — this file must remain pure Dart.

import '../../room/domain/models.dart';

// ────────────────────────────────────────────────────────────────────────────
// Mutation guard
// ────────────────────────────────────────────────────────────────────────────

/// Returns `true` when [actorId] is allowed to mutate [targetPlayerId]'s data.
///
/// Rules (FR11, FR19):
/// - A player may always mutate their own data (`actorId == targetPlayerId`).
/// - The room owner may mutate any player's data (`actorId == roomCreatedBy`).
bool canMutate(String actorId, String roomCreatedBy, String targetPlayerId) {
  if (actorId.isEmpty) return false;
  return actorId == targetPlayerId || actorId == roomCreatedBy;
}

// ────────────────────────────────────────────────────────────────────────────
// VP computation
// ────────────────────────────────────────────────────────────────────────────

/// Sums all `prim` and `sec` values across every round in [vpByRound].
///
/// Returns `0` for an empty map. Rounds that contain only a `prim` key
/// (no `sec`) are handled gracefully.
int vpTotal(Map<String, Map<String, int>> vpByRound) {
  return vpByRound.values.fold(
    0,
    (acc, roundMap) => acc + roundMap.values.fold(0, (a, v) => a + v),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// CP increment
// ────────────────────────────────────────────────────────────────────────────

/// Returns a new [PlayerModel] with `cp` incremented by 1.
///
/// Pure function — no side effects, no Firestore interaction.
PlayerModel autoIncrementCp(PlayerModel player) {
  return player.copyWith(cp: player.cp + 1);
}

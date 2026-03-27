import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models.dart';

// ────────────────────────────────────────────────────────────────────────────
// RoomException
// ────────────────────────────────────────────────────────────────────────────

class RoomException implements Exception {
  final String message;
  const RoomException(this.message);

  @override
  String toString() => 'RoomException: $message';
}

// ────────────────────────────────────────────────────────────────────────────
// RoomRepository
// ────────────────────────────────────────────────────────────────────────────

class RoomRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the new room document ID.
  Future<String> createRoom(String ownerName) async {
    try {
      final uid = _auth.currentUser!.uid;
      final code = _generateRoomCode();

      final roomRef = await FirestorePaths.rooms().add({
        'code': code,
        'status': 'waiting',
        'currentRound': 1,
        'createdBy': uid,
        'createdAt': Timestamp.now(),
      });

      await FirestorePaths.player(roomRef.id, uid).set({
        'name': ownerName,
        'role': 'owner',
        'cp': 0,
        'vpByRound': {},
        'connected': true,
        'color': '#4FC3F7',
      });

      return roomRef.id;
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to create room: $e');
    }
  }

  /// Returns the room document ID.
  Future<String> joinRoom(String code, String playerName) async {
    try {
      final uid = _auth.currentUser!.uid;

      final snapshot =
          await FirestorePaths.rooms()
              .where('code', isEqualTo: code)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        throw const RoomException('Room introuvable');
      }

      final roomDoc = snapshot.docs.first;
      final roomStatus = RoomStatus.fromString(
        roomDoc.data()['status'] as String? ?? '',
      );

      if (roomStatus == RoomStatus.active) {
        throw const RoomException('Match déjà en cours');
      } else if (roomStatus == RoomStatus.closed) {
        throw const RoomException('Room fermée');
      } else if (roomStatus != RoomStatus.waiting) {
        throw const RoomException('Room non disponible');
      }

      await FirestorePaths.player(roomDoc.id, uid).set({
        'name': playerName,
        'role': 'player',
        'cp': 0,
        'vpByRound': {},
        'connected': true,
        'color': '#EF5350',
      });

      return roomDoc.id;
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to join room: $e');
    }
  }

  Stream<RoomModel?> streamRoom(String roomId) {
    return FirestorePaths.room(roomId).snapshots().map(
      (snap) => snap.exists ? RoomModel.fromFirestore(snap) : null,
    );
  }

  Stream<List<PlayerModel>> streamPlayers(String roomId) {
    return FirestorePaths.players(roomId).snapshots().map(
      (snap) => snap.docs.map(PlayerModel.fromFirestore).toList(),
    );
  }

  // ── Current user ──────────────────────────────────────────────────────────

  /// Returns the current authenticated user's UID, or null if unauthenticated.
  String? get currentUserId => _auth.currentUser?.uid;

  // ── Match lifecycle ───────────────────────────────────────────────────────

  /// Updates the room status to active, setting currentRound to 1.
  /// Throws [RoomException] if the update fails.
  Future<void> startMatch(String roomId) async {
    try {
      await FirestorePaths.room(
        roomId,
      ).update({'status': 'active', 'currentRound': 1});
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to start match: $e');
    }
  }

  // ── Ownership transfer ────────────────────────────────────────────────────

  /// Transfers ownership from the current user to [newOwnerUid].
  /// Atomically updates room.createdBy, old owner's role → player,
  /// new owner's role → owner, in a single Firestore batch.
  /// Throws [RoomException] if the update fails.
  Future<void> transferOwnership(String roomId, String newOwnerUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw RoomException('User not authenticated');
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(FirestorePaths.room(roomId), {'createdBy': newOwnerUid});
      batch.update(FirestorePaths.player(roomId, uid), {'role': 'player'});
      batch.update(FirestorePaths.player(roomId, newOwnerUid), {
        'role': 'owner',
      });
      await batch.commit();
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to transfer ownership: $e');
    }
  }

  // ── Room closure ──────────────────────────────────────────────────────────

  /// Closes the room by setting its status to 'closed'.
  /// Firestore Security Rules enforce that only the room owner can do this.
  /// Throws [RoomException] if the update fails.
  Future<void> closeRoom(String roomId) async {
    try {
      await FirestorePaths.room(roomId).update({'status': 'closed'});
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to close room: $e');
    }
  }

  // ── Room departure ────────────────────────────────────────────────────────

  /// Marks the current player as disconnected without closing the room.
  /// Safe to call by non-owners to leave a session gracefully.
  /// Throws [RoomException] if the update fails.
  Future<void> leaveRoom(String roomId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirestorePaths.player(roomId, uid).update({'connected': false});
    } on RoomException {
      rethrow;
    } catch (e) {
      throw RoomException('Failed to leave room: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

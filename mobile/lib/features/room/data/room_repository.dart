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
        throw const RoomException('Room not found');
      }

      final roomDoc = snapshot.docs.first;
      final roomStatus = RoomStatus.fromString(
        roomDoc.data()['status'] as String? ?? '',
      );

      if (roomStatus != RoomStatus.waiting) {
        throw const RoomException('Room is not open for joining');
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

  // ── Private helpers ───────────────────────────────────────────────────────

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

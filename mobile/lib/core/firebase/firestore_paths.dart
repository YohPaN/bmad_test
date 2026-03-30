import 'package:cloud_firestore/cloud_firestore.dart';

/// Central repository of all Firestore collection and document paths.
/// This is the ONLY file in the project permitted to contain Firestore path strings.
class FirestorePaths {
  FirestorePaths._(); // Prevent instantiation

  static CollectionReference<Map<String, dynamic>> rooms() =>
      FirebaseFirestore.instance.collection('rooms');

  static DocumentReference<Map<String, dynamic>> room(String roomId) =>
      rooms().doc(roomId);

  static CollectionReference<Map<String, dynamic>> players(String roomId) =>
      room(roomId).collection('players');

  static DocumentReference<Map<String, dynamic>> player(
    String roomId,
    String uid,
  ) => players(roomId).doc(uid);

  static CollectionReference<Map<String, dynamic>> events(String roomId) =>
      room(roomId).collection('events');

  static DocumentReference<Map<String, dynamic>> event(
    String roomId,
    String eventId,
  ) => events(roomId).doc(eventId);

  // ── Injectable overloads (for testing with FakeFirebaseFirestore) ────────

  static DocumentReference<Map<String, dynamic>> roomWith(
    FirebaseFirestore fs,
    String roomId,
  ) => fs.collection('rooms').doc(roomId);

  static DocumentReference<Map<String, dynamic>> playerWith(
    FirebaseFirestore fs,
    String roomId,
    String uid,
  ) => fs.collection('rooms').doc(roomId).collection('players').doc(uid);

  static CollectionReference<Map<String, dynamic>> eventsWith(
    FirebaseFirestore fs,
    String roomId,
  ) => fs.collection('rooms').doc(roomId).collection('events');
}

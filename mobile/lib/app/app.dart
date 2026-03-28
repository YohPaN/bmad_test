import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/game/presentation/match_screen.dart';

import '../features/room/data/room_repository.dart';
import '../features/room/domain/models.dart';
import '../features/room/presentation/lobby_screen.dart';
import '../features/room/presentation/players_screen.dart';
import '../features/room/presentation/room_management_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WH40K Match Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D0F14),
          brightness: Brightness.dark,
        ).copyWith(surface: const Color(0xFF0D0F14)),
      ),
      home: const LobbyScreen(),
    );
  }
}

class AppShell extends StatefulWidget {
  final String roomId;
  const AppShell({super.key, required this.roomId});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _repo = RoomRepository();
  int _currentIndex = 0;
  bool _navigationTriggered = false;

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) _navigationTriggered = false;
  }

  static const List<String> _tabLabels = [
    'Match',
    'Historique',
    'Joueurs',
    'Room',
  ];

  static const List<IconData> _tabIcons = [
    Icons.sports_esports,
    Icons.history,
    Icons.people,
    Icons.meeting_room,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomModel?>(
      stream: _repo.streamRoom(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Erreur de connexion à la room.')),
          );
        }

        final room = snapshot.data;

        // ── Navigate ALL clients back to home when room is closed ──────────
        if (room != null && room.status == RoomStatus.closed) {
          if (!_navigationTriggered) {
            _navigationTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LobbyScreen()),
                  (route) => false,
                );
              }
            });
          }
          return const SizedBox.shrink();
        }
        // ──────────────────────────────────────────────────────────────────

        return Scaffold(
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: List.generate(
              _tabLabels.length,
              (i) => BottomNavigationBarItem(
                icon: Icon(_tabIcons[i]),
                label: _tabLabels[i],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MatchScreen(roomId: widget.roomId, currentUserId: uid);
      case 1:
        return const Center(child: Text('Historique — coming soon'));
      case 2:
        return PlayersScreen(roomId: widget.roomId);
      case 3:
        return RoomManagementScreen(roomId: widget.roomId);
      default:
        return const SizedBox.shrink();
    }
  }
}

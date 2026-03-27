import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/models.dart';
import 'widgets/player_presence_badge.dart';

class PlayersScreen extends StatefulWidget {
  final String roomId;
  // Overrides the live stream; use only in tests.
  final Stream<List<PlayerModel>>? playersStream;
  const PlayersScreen({super.key, required this.roomId, this.playersStream});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  RoomRepository? _repo;

  @override
  void initState() {
    super.initState();
    if (widget.playersStream == null) _repo = RoomRepository();
  }

  static Color _hexToColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlayerModel>>(
      stream: widget.playersStream ?? _repo!.streamPlayers(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erreur de chargement des joueurs.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const _SkeletonPlayerList();
        }

        final players = snapshot.data!;

        if (players.isEmpty) {
          return const Center(
            child: Text(
              'Aucun joueur connecté.',
              style: TextStyle(color: Color(0xFF8A9BB8)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: players.length,
          separatorBuilder:
              (_, __) => const Divider(color: Color(0xFF2A2F3E), height: 1),
          itemBuilder: (context, index) {
            final player = players[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PlayerPresenceBadge(
                playerName: player.name,
                playerColor: _hexToColor(player.color),
                isOnline: player.connected,
                isOwner: player.role == RoleEnum.owner,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Skeleton shimmer (UX-DR17: no blocking spinners) ─────────────────────────

class _SkeletonPlayerList extends StatefulWidget {
  const _SkeletonPlayerList();

  @override
  State<_SkeletonPlayerList> createState() => _SkeletonPlayerListState();
}

class _SkeletonPlayerListState extends State<_SkeletonPlayerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.55).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 3,
          separatorBuilder:
              (_, __) => const Divider(color: Color(0xFF2A2F3E), height: 1),
          itemBuilder:
              (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Opacity(
                  opacity: _opacity.value,
                  child: const Row(
                    children: [
                      // Avatar placeholder
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF2A2F3E),
                      ),
                      SizedBox(width: 12),
                      // Name placeholder
                      _SkeletonBar(),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3E),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

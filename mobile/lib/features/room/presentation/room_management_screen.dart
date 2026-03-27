import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/models.dart';
import 'lobby_screen.dart';
import 'widgets/player_presence_badge.dart';

class RoomManagementScreen extends StatefulWidget {
  final String roomId;
  const RoomManagementScreen({super.key, required this.roomId});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final _repo = RoomRepository();

  static Color _hexToColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ── Owner: Transfer Ownership ─────────────────────────────────────────────

  Future<void> _confirmTransferOwnership(
    String newOwnerUid,
    String newOwnerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2330),
            title: const Text(
              'Transférer la propriété',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
            content: Text(
              'Transférer la propriété à $newOwnerName ?',
              style: const TextStyle(color: Color(0xFFE8EAF0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF0D0F14),
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _repo.transferOwnership(widget.roomId, newOwnerUid);
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('transferOwnership unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de transférer la propriété.')),
      );
    }
  }

  // ── Owner: Close Room ─────────────────────────────────────────────────────

  Future<void> _confirmCloseRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2330),
            title: const Text(
              'Terminer le match',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
            content: const Text(
              'Confirmer la fin du match ?\nTous les joueurs seront renvoyés à l\'accueil.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terminer'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _repo.closeRoom(widget.roomId);
      // AppShell's streamRoom listener handles navigation for ALL clients.
      // No local Navigator call needed here.
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('closeRoom unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de terminer le match.')),
      );
    }
  }

  // ── Non-owner: Leave Room ────────────────────────────────────────────────

  Future<void> _confirmLeaveRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2330),
            title: const Text(
              'Quitter la room',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
            content: const Text(
              'Quitter la room ?\nLes autres joueurs continueront le match.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Quitter'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _repo.leaveRoom(widget.roomId);
      if (!mounted) return;
      // Only this client navigates — others are unaffected (room not closed).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
        (route) => false,
      );
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('leaveRoom unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de quitter la room.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomModel?>(
      stream: _repo.streamRoom(widget.roomId),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (roomSnapshot.hasError) {
          debugPrint('RoomManagement streamRoom error: ${roomSnapshot.error}');
          return const Center(
            child: Text(
              'Erreur de connexion à la room.',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          );
        }
        final room = roomSnapshot.data;
        if (room == null) {
          return const Center(
            child: Text(
              'La room a été supprimée.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
          );
        }

        final isOwner = room.createdBy == _repo.currentUserId;

        return StreamBuilder<List<PlayerModel>>(
          stream: _repo.streamPlayers(widget.roomId),
          builder: (context, playersSnapshot) {
            final players = playersSnapshot.data ?? [];

            return Scaffold(
              backgroundColor: const Color(0xFF0D0F14),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Section header ────────────────────────────────
                      const Text(
                        'GESTION DE ROOM',
                        style: TextStyle(
                          fontFamily: 'RobotoCondensed',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF5C6478),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Player list ───────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161920),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2A2F3E)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'JOUEURS CONNECTÉS',
                                  style: TextStyle(
                                    fontFamily: 'RobotoCondensed',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF5C6478),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Color(0xFF2A2F3E), height: 1),
                            // Player rows
                            if (players.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Aucun joueur.',
                                  style: TextStyle(color: Color(0xFF5C6478)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: players.length,
                                separatorBuilder:
                                    (_, __) => const Divider(
                                      color: Color(0xFF2A2F3E),
                                      height: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final player = players[index];
                                  final isThisPlayerOwner =
                                      player.id == room.createdBy;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        // Badge
                                        PlayerPresenceBadge(
                                          playerName: player.name,
                                          playerColor: _hexToColor(
                                            player.color,
                                          ),
                                          isOnline: player.connected,
                                          isOwner: isThisPlayerOwner,
                                        ),
                                        const Spacer(),
                                        // Transfer button — owner only, for non-owner players
                                        if (isOwner && !isThisPlayerOwner)
                                          Semantics(
                                            label:
                                                'Transférer la propriété à ${player.name}',
                                            child: TextButton(
                                              onPressed:
                                                  () =>
                                                      _confirmTransferOwnership(
                                                        player.id,
                                                        player.name,
                                                      ),
                                              child: const Text(
                                                'TRANSFÉRER',
                                                style: TextStyle(
                                                  fontFamily: 'RobotoCondensed',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: Color(0xFF5C6478),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Owner actions ─────────────────────────────────
                      if (isOwner) ...[
                        const Text(
                          'ACTIONS OWNER',
                          style: TextStyle(
                            fontFamily: 'RobotoCondensed',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF5C6478),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _confirmCloseRoom,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF44336),
                              side: const BorderSide(color: Color(0xFFF44336)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Terminer le match'),
                          ),
                        ),
                      ],

                      // ── Non-owner actions ─────────────────────────────
                      if (!isOwner) ...[
                        const Text(
                          'ACTIONS',
                          style: TextStyle(
                            fontFamily: 'RobotoCondensed',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF5C6478),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _confirmLeaveRoom,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5C6478),
                              side: const BorderSide(color: Color(0xFF5C6478)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Quitter la room'),
                          ),
                        ),
                      ],
                    ],
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

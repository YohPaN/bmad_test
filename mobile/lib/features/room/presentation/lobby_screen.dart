import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app.dart';
import '../data/room_repository.dart';
import '../domain/models.dart';
import 'widgets/player_presence_badge.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomId;
  bool _isLoading = false;
  String? _errorMessage;
  final _nameController = TextEditingController();
  final _repo = RoomRepository();

  // Fields for join section:
  bool _isJoinLoading = false;
  String? _joinErrorMessage;
  final _codeController = TextEditingController();
  final _joinNameController = TextEditingController();

  bool _isStartLoading = false;
  bool _navigationTriggered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _joinNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre nom.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final id = await _repo.createRoom(name);
      if (!mounted) return;
      setState(() {
        _roomId = id;
        _isLoading = false;
      });
    } on RoomException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('createRoom unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue.';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    if (_isJoinLoading) return;
    final code = _codeController.text.trim().toUpperCase();
    final name = _joinNameController.text.trim();

    if (code.isEmpty) {
      setState(() => _joinErrorMessage = 'Veuillez entrer le code de la room.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _joinErrorMessage = 'Veuillez entrer votre nom.');
      return;
    }

    setState(() {
      _isJoinLoading = true;
      _joinErrorMessage = null;
    });

    try {
      final id = await _repo.joinRoom(code, name);
      if (!mounted) return;
      setState(() {
        _roomId = id;
        _isJoinLoading = false;
      });
    } on RoomException catch (e) {
      if (!mounted) return;
      setState(() {
        _joinErrorMessage = e.message;
        _isJoinLoading = false;
      });
    } catch (e) {
      debugPrint('joinRoom unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _joinErrorMessage = 'Une erreur inattendue est survenue.';
        _isJoinLoading = false;
      });
    }
  }

  Future<void> _startMatch() async {
    final roomId = _roomId;
    if (roomId == null) return;
    setState(() => _isStartLoading = true);
    try {
      await _repo.startMatch(roomId);
      // Navigation handled by StreamBuilder reaction (Task 4).
      // Safety timeout: reset loading state if stream never delivers active status.
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isStartLoading) {
          setState(() => _isStartLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le match tarde à démarrer. Réessayez.'),
            ),
          );
        }
      });
    } on RoomException catch (e) {
      if (!mounted) return;
      setState(() => _isStartLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('startMatch unexpected error: $e');
      if (!mounted) return;
      setState(() => _isStartLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer le match.')),
      );
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: _roomId == null ? _buildHomePhase() : _buildLobbyPhase(),
      ),
    );
  }

  // ── Home phase ────────────────────────────────────────────────────────────

  Widget _buildHomePhase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'WH40K MATCH COMPANION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'RobotoCondensed',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFF5C6478),
            ),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _createRoom(),
            decoration: InputDecoration(
              labelText: 'Votre nom',
              labelStyle: const TextStyle(color: Color(0xFF5C6478)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 56),
            ),
            style: const TextStyle(color: Color(0xFFE8EAF0)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                      onPressed: _createRoom,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: const Color(0xFF0D0F14),
                      ),
                      child: const Text('Créer une room'),
                    ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF44336), fontSize: 14),
            ),
          ],
          // ── OR separator ─────────────────────────────────────
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF2A2F3E))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFF5C6478),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFF2A2F3E))),
            ],
          ),
          // ── Join section ──────────────────────────────────────
          const SizedBox(height: 32),
          const Text(
            'CODE DE ROOM',
            style: TextStyle(
              fontFamily: 'RobotoCondensed',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFF5C6478),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_UpperCaseTextFormatter()],
            maxLength: 6,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Code de la room',
              labelStyle: const TextStyle(color: Color(0xFF5C6478)),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 56),
            ),
            style: const TextStyle(color: Color(0xFFE8EAF0)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _joinNameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _joinRoom(),
            decoration: InputDecoration(
              labelText: 'Votre nom',
              labelStyle: const TextStyle(color: Color(0xFF5C6478)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF2A2F3E)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 56),
            ),
            style: const TextStyle(color: Color(0xFFE8EAF0)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child:
                _isJoinLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                      onPressed: _joinRoom,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: const Color(0xFF0D0F14),
                      ),
                      child: const Text('Rejoindre'),
                    ),
          ),
          if (_joinErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _joinErrorMessage!,
              style: const TextStyle(color: Color(0xFFF44336), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  // ── Lobby phase ───────────────────────────────────────────────────────────

  Widget _buildLobbyPhase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<RoomModel?>(
        stream: _repo.streamRoom(_roomId!),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (roomSnapshot.hasError) {
            debugPrint('streamRoom error: ${roomSnapshot.error}');
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

          // ── Auto-navigate when match starts ────────────────────────────
          if (room.status == RoomStatus.active) {
            if (!_navigationTriggered) {
              _navigationTriggered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppShell()),
                  );
                }
              });
            }
            return const SizedBox.shrink();
          }
          // ───────────────────────────────────────────────────────────────

          return StreamBuilder<List<PlayerModel>>(
            stream: _repo.streamPlayers(_roomId!),
            builder: (context, playersSnapshot) {
              if (playersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (playersSnapshot.hasError) {
                debugPrint('streamPlayers error: ${playersSnapshot.error}');
                return const Center(
                  child: Text(
                    'Erreur de chargement des joueurs.',
                    style: TextStyle(color: Color(0xFFF44336)),
                  ),
                );
              }
              final players = playersSnapshot.data ?? [];
              final connectedCount = players.where((p) => p.connected).length;
              final isOwner = room.createdBy == _repo.currentUserId;
              final canStart =
                  isOwner && connectedCount >= 2 && !_isStartLoading;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    // Room code section
                    const Text(
                      'CODE DE ROOM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'RobotoCondensed',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFF5C6478),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2A2F3E)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            room.code,
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Color(0xFF4FC3F7),
                            ),
                            tooltip: 'Copier le code',
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: room.code),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copié !')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Players section
                    const Text(
                      'JOUEURS',
                      style: TextStyle(
                        fontFamily: 'RobotoCondensed',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFF5C6478),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2A2F3E)),
                      ),
                      child: ListView.separated(
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: PlayerPresenceBadge(
                              playerName: player.name,
                              playerColor: _hexToColor(player.color),
                              isOnline: player.connected,
                              isOwner: player.role == RoleEnum.owner,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Player count label
                    Text(
                      '$connectedCount joueur(s) connecté(s)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFFE8EAF0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Launch button — owner only
                    if (isOwner)
                      Opacity(
                        opacity: canStart ? 1.0 : 0.38,
                        child: SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: canStart ? _startMatch : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4FC3F7),
                              foregroundColor: const Color(0xFF0D0F14),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child:
                                _isStartLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0D0F14),
                                      ),
                                    )
                                    : const Text('Lancer le match'),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Private input formatter ───────────────────────────────────────────────────

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

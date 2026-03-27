import 'package:flutter/material.dart';

class PlayerPresenceBadge extends StatelessWidget {
  final String playerName;
  final Color playerColor;
  final bool isOnline;
  final bool isOwner;

  const PlayerPresenceBadge({
    super.key,
    required this.playerName,
    required this.playerColor,
    required this.isOnline,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = playerName.trim();
    final initials =
        trimmed.isNotEmpty
            ? trimmed
                .split(' ')
                .where((w) => w.isNotEmpty)
                .map((w) => w[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    return Semantics(
      label:
          '$playerName, ${isOwner ? 'propriétaire, ' : ''}${isOnline ? 'en ligne' : 'hors ligne'}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: playerColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Online/Offline dot
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            isOnline
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF5C6478),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D0F14),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name and optional owner label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playerName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFFE8EAF0),
                    ),
                  ),
                  if (isOwner)
                    const Text(
                      'OWNER',
                      style: TextStyle(
                        fontFamily: 'RobotoCondensed',
                        fontSize: 11,
                        color: Color(0xFF5C6478),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

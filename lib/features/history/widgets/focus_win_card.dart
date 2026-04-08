import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../../../shared/theme/color_tokens.dart';
import '../../../features/games/game_router.dart';

class FocusWinCard extends StatelessWidget {
  final ChallengeHistoryEntry entry;

  const FocusWinCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.outcome == 'success';
    final gameType = GameTypeExtension.fromDbKey(entry.gameType);
    final playedAt = DateTime.fromMillisecondsSinceEpoch(entry.playedAt);
    final timeAgo = _getTimeAgo(playedAt);

    return Container(
      decoration: BoxDecoration(
        color: kSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // App icon placeholder
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: (isSuccess ? kAccentGreen : kAccentRed)
                    .withValues(alpha: 0.1),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? kAccentGreen : kAccentRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.appName,
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isSuccess ? kAccentGreen : kAccentRed)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isSuccess ? 'WIN' : 'FAIL',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? kAccentGreen : kAccentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(gameType.icon, size: 12, color: kTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        gameType.displayName,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Solved in ${(entry.durationMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 10,
                          color: kTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (entry.focusPoints > 0)
                        Text(
                          '+${entry.focusPoints} pts',
                          style: const TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: kAccentCyan,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: kTextSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

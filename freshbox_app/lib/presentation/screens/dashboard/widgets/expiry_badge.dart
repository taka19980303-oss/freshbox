import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/date_utils.dart';

class ExpiryBadge extends StatelessWidget {
  final int daysUntilExpiry;
  final bool compact;

  const ExpiryBadge({
    super.key,
    required this.daysUntilExpiry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ExpiryUtils.statusColor(daysUntilExpiry);
    final label = ExpiryUtils.statusLabel(daysUntilExpiry);
    final emoji = ExpiryUtils.statusEmoji(daysUntilExpiry);
    final isUrgent = daysUntilExpiry <= 2;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (isUrgent && daysUntilExpiry >= 0) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 800.ms)
          .then()
          .fadeOut(duration: 800.ms);
    }

    return badge;
  }
}

/// 賞味期限の日数を大きく表示するウィジェット
class ExpiryDaysDisplay extends StatelessWidget {
  final int days;

  const ExpiryDaysDisplay({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final color = ExpiryUtils.statusColor(days);
    if (days < 0) {
      return Text(
        '期限切れ',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ExpiryUtils.statusColor(days),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '残り',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '$days',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          TextSpan(
            text: '日',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

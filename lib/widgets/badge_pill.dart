import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum BadgeType {
  success,
  warning,
  danger,
  info,
  neutral;

  Color get color {
    switch (this) {
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.danger:
        return AppColors.danger;
      case BadgeType.info:
        return AppColors.info;
      case BadgeType.neutral:
        return AppColors.textSecondary;
    }
  }
}

class BadgePill extends StatelessWidget {
  final String text;
  final BadgeType type;
  final IconData? icon;

  const BadgePill({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = type.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}


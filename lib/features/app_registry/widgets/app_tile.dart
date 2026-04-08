import 'package:flutter/material.dart';
import '../../../shared/theme/color_tokens.dart';

class AppTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final bool isBlocked;
  final void Function(bool) onToggle;

  const AppTile({
    super.key,
    required this.appName,
    required this.packageName,
    required this.isBlocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isBlocked
            ? kAccentRed.withValues(alpha: 0.05)
            : kSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked
              ? kAccentRed.withValues(alpha: 0.2)
              : kDivider,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getAppColor(appName).withValues(alpha: 0.3),
                _getAppColor(appName).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: Text(
              appName[0].toUpperCase(),
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getAppColor(appName),
              ),
            ),
          ),
        ),
        title: Text(
          appName,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        subtitle: Text(
          packageName,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: kTextSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch(
          value: isBlocked,
          onChanged: (value) => onToggle(value),
        ),
      ),
    );
  }

  Color _getAppColor(String name) {
    final colors = [
      kAccentCyan,
      kAccentAmber,
      kAccentGreen,
      kAccentRed,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

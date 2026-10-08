import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';

/// OWNER: Member C (design lead). Expand with text styles and button themes.
class AppTheme {
  static const Color seed = Color(0xFF1F3864);

  static const Color _onTrack = Color(0xFF1E6B30);
  static const Color _atRisk = Color(0xFF8F4E00);
  static const Color _overdue = Color(0xFFB3261E);
  static const Color _completed = Color(0xFF475A66);

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  /// One color per SLA status, used by StatusChip and anywhere else.
  static Color colorFor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return _onTrack;
      case SlaStatus.atRisk:
        return _atRisk;
      case SlaStatus.overdue:
        return _overdue;
      case SlaStatus.completed:
        return _completed;
    }
  }

  static Color backgroundFor(SlaStatus status) =>
      colorFor(status).withValues(alpha: 0.12);

  static IconData iconFor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return Icons.schedule;
      case SlaStatus.atRisk:
        return Icons.warning_amber_rounded;
      case SlaStatus.overdue:
        return Icons.error_outline;
      case SlaStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  static Color priorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return _overdue;
      case Priority.medium:
        return _atRisk;
      case Priority.low:
        return const Color(0xFF4A6572);
    }
  }
}

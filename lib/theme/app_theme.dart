import 'package:flutter/material.dart';

import '../models/sla_status.dart';

/// OWNER: Member B (design lead). Expand with text styles, card and button themes.
class AppTheme {
  static const Color seed = Color(0xFF1F3864);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      );

  /// One color per SLA status, used by StatusChip and anywhere else.
  static Color colorFor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return Colors.green;
      case SlaStatus.atRisk:
        return Colors.amber.shade800;
      case SlaStatus.overdue:
        return Colors.red;
      case SlaStatus.completed:
        return Colors.blueGrey;
    }
  }
}

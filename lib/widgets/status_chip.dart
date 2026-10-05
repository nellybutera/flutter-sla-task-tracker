import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../theme/app_theme.dart';

/// OWNER: Member C. Basic version so every screen can use it; polish as needed.
class StatusChip extends StatelessWidget {
  final SlaStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFor(status);
    return Chip(
      label: Text(status.label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

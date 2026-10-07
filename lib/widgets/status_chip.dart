import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../theme/app_theme.dart';

/// OWNER: Member C.
class StatusChip extends StatelessWidget {
  final SlaStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundFor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppTheme.iconFor(status), size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

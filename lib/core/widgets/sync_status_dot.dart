import 'package:flutter/material.dart';
import 'package:openlist/core/models/sync_status.dart';
import 'package:openlist/core/theme/theme.dart';

class SyncStatusDot extends StatelessWidget {
  final SyncStatus status;
  final double size;
  final bool showTooltip;

  const SyncStatusDot({
    super.key,
    required this.status,
    this.size = 8,
    this.showTooltip = true,
  });

  Color _getColor() {
    switch (status) {
      case SyncStatus.synced:
        return AppColors.success;
      case SyncStatus.pending:
        return AppColors.warning;
      case SyncStatus.conflict:
        return AppColors.danger;
    }
  }

  String _getLabel() {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: _getLabel(),
        child: dot,
      );
    }

    return dot;
  }
}

import 'package:flutter/material.dart';

/// Reusable Info Row
Widget infoRow(BuildContext context, IconData icon, String title, String value) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title, 
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}

/// Reusable Tag Chip
Widget tagChip(BuildContext context, String label) {
  final theme = Theme.of(context);
  return Chip(
    label: Text(
      label, 
      style: TextStyle(color: theme.colorScheme.primary),
    ),
    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
    side: BorderSide.none,
    shape: const StadiumBorder(),
  );
}

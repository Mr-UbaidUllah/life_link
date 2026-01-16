  import 'package:flutter/material.dart';

/// Reusable Info Row
  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
    /// Reusable Tag Chip
  Widget tagChip(String label) {
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.red)),
      backgroundColor: Colors.red.withOpacity(0.1),
      shape: StadiumBorder(),
    );
  }
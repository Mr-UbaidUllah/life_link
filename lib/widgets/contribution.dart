import 'package:flutter/material.dart';

class ContributionItem {
  final String number;
  final String title;
  final Color bgColor;
  final Color textColor;

  ContributionItem({
    required this.number,
    required this.title,
    required this.bgColor,
    required this.textColor,
  });
}

// These are base colors. In a real app, you might want to pass context to get theme-specific versions.
// However, since these are often used for "colorful" cards, we can keep them or adjust them.
final List<ContributionItem> contributionData = [
  ContributionItem(
    number: '1.2K',
    title: 'Active Donors',
    bgColor: const Color(0xFFE3F2FD),
    textColor: Colors.blue.shade700,
  ),
  ContributionItem(
    number: '850',
    title: 'Successful Donations',
    bgColor: const Color(0xFFE8F5E9),
    textColor: Colors.green.shade700,
  ),
  ContributionItem(
    number: '42',
    title: 'Urgent Requests',
    bgColor: const Color(0xFFFFF3E0),
    textColor: Colors.orange.shade700,
  ),
  ContributionItem(
    number: '15',
    title: 'Partner Hospitals',
    bgColor: const Color(0xFFF3E5F5),
    textColor: Colors.purple.shade700,
  ),
  ContributionItem(
    number: '120',
    title: 'Volunteers',
    bgColor: const Color(0xFFE0F7FA),
    textColor: Colors.teal.shade700,
  ),
  ContributionItem(
    number: '24/7',
    title: 'Support Available',
    bgColor: const Color(0xFFFFEBEE),
    textColor: Colors.red.shade700,
  ),
];

class ContributionCard extends StatelessWidget {
  final String number;
  final String title;
  final Color bgColor;
  final Color textColor;

  const ContributionCard({
    super.key,
    required this.number,
    required this.title,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // If dark mode, we make the background slightly more transparent to blend better
              color: isDark ? bgColor.withOpacity(0.1) : bgColor.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? textColor.withOpacity(0.9) : textColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

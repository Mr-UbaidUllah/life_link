import 'package:flutter/material.dart';

class ReusableButton extends StatelessWidget {
  final String label;
  const ReusableButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          label, 
          style: const TextStyle(
            fontSize: 16, 
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

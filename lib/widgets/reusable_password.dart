import 'package:flutter/material.dart';

class ReuseablePasswordfield extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final TextEditingController controller;

  const ReuseablePasswordfield({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // MediaQuery dimensions
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.01),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: TextStyle(fontSize: width * 0.04, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontSize: width * 0.04,
          ),
          prefixIcon: Icon(prefixIcon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: width * 0.06),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: width * 0.06)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.018,
          ),
        ),
      ),
    );
  }
}

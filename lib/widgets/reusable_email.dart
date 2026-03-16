import 'package:flutter/material.dart';

class ReusableTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final IconData? sufixIcon;
  final bool obscureText;
  final TextEditingController controller;

  const ReusableTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.sufixIcon,
    this.obscureText = false,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // MediaQuery values
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.005),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: width * 0.04, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontSize: width * 0.04,
          ),

          prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: width * 0.06),
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

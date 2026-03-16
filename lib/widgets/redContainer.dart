import 'package:flutter/material.dart';

class redContainer extends StatelessWidget {
  const redContainer({super.key, required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height * 0.37,
      width: width,
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        children: [
          SizedBox(height: height * 0.06),
          Image.asset('assets/images/water 1.png', height: height * 0.10),
          Text(
            'Life Link',
            style: TextStyle(fontSize: 23, color: theme.colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

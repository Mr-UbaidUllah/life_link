import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ReusableButton extends StatelessWidget {
  String label;
  ReusableButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

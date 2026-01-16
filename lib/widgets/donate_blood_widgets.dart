import 'package:flutter/material.dart';

Widget userTile(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class header extends StatelessWidget {
  String name;
  header({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: height * 0.003,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: height * 0.004),

          Container(
            height: height * 0.05,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Center(
              child: TextFormField(
                textInputAction: TextInputAction.next,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: height * 0.016,
                    horizontal: width * 0.03,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

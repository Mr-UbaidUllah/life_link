import 'package:flutter/material.dart';

// ignore: must_be_immutable
class header extends StatelessWidget {
  String name;
  header({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.004),

          Container(
            height: height * 0.05,
            // width: width * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.black),
            ),
            child: Center(
              child: TextFormField(
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: height * 0.016,
                    horizontal: width * 0.03,
                  ), // aligns text vertically
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

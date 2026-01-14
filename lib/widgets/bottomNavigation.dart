import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Contactscontainer extends StatefulWidget {
  const Contactscontainer({super.key});

  @override
  State<Contactscontainer> createState() => _ContactscontainerState();
}

class _ContactscontainerState extends State<Contactscontainer> {
  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 5.h),
      child: Container(
        height: 100.h,
        // width: 400.w,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(height: 15.h),

            Row(
              children: [
                Container(
                  height: 55.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red),

                    // borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 10.h),

                          Image.asset('assets/images/drop.png', height: 35.h),
                          Text(
                            bloodGroups[2],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency B+ Blood Needed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10.h),

                    Row(
                      children: [
                        Icon(Icons.call, color: Colors.red),
                        Text('+92308880098'),
                      ],
                    ),

                    // Row(
                    //   children: [
                    //     Icon(Icons.timer_outlined, color: Colors.red),
                    //     Text('12 Feb 2025'),
                    //   ],
                    // ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:blood_donation/Provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class UserDonateBlood extends StatefulWidget {
  const UserDonateBlood({super.key});

  @override
  State<UserDonateBlood> createState() => _UserDonateBloodState();
}

class _UserDonateBloodState extends State<UserDonateBlood> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Donate Blood')),

      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(28.h),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Container(
                  height: 150.h,

                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        'Are You Sure willing to Donate\n blood with your profile information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        activeColor: Colors.red,
                        value: provider.isWilling,
                        onChanged: (val) {
                          provider.toggleDonate(val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 49.h),

                if (provider.isLoading) CircularProgressIndicator(),

                if (provider.isWilling && provider.user != null)
                  Column(
                    children: [
                      userTile('Name', provider.user!.name.toString()),
                      userTile(
                        'Blood Group',
                        provider.user!.bloodGroup.toString(),
                      ),
                      userTile('Phone', provider.user!.phone.toString()),
                      userTile('city', provider.user!.city.toString()),
                      userTile('Country', provider.user!.country.toString()),
                      userTile('Email', provider.user!.email.toString()),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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

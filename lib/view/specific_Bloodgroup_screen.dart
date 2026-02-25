import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodGroup_provider.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpecificBloodgroupScreen extends StatelessWidget {
  final String? bloodGroup;

  const SpecificBloodgroupScreen({super.key, this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bloodGroup ?? "All Requests")),

      body: Consumer<BloodGroupRequestProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<BloodRequestModel>>(
            stream: provider.postsByBloodGroup(bloodGroup!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No $bloodGroup requests found"));
              }

              final requests = snapshot.data!;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];

                  return HomeContainer(
                    bloodGroup: req.bloodGroup,
                    title: req.title,
                    hospital: req.hospital,
                    date: req.createdAt.toLocal().toString().split(' ')[0],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

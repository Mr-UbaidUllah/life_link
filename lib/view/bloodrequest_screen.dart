import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/view/home/home_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/dropdownheader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodrequestScreen extends StatefulWidget {
  const BloodrequestScreen({super.key});

  @override
  State<BloodrequestScreen> createState() => _BloodrequestScreenState();
}

class _BloodrequestScreenState extends State<BloodrequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Blood Request'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            child: Dropdownheader(name: 'Blood Request'),
          ),
          Consumer<BloodrequestProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<List<BloodRequestModel>>(
                stream: provider.requests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No requests found"));
                  }
                    final requests = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailsScreen(request: req),
                            ),
                          );
                        },
                        child: homeContainer(
                          bloodGroup: req.bloodGroup,
                          title: req.title,
                          hospital: req.hospital,
                          date: req.createdAt.toLocal().toString().split(
                            ' ',
                          )[0],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/view/add_ambulence.dart';
import 'package:blood_donation/widgets/ambulence_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Consumer<AmbulanceProvider>(
              builder:
                  (
                    BuildContext context,
                    AmbulanceProvider ambulance,
                    Widget? child,
                  ) {
                    return StreamBuilder<List<AmbulanceModel>>(
                      stream: ambulance.ambulanceRequest,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Something went wrong'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No ambulances found'));
                        }
                        final requests = snapshot.data!;

                        return Expanded(
                          child: ListView.builder(
                            // shrinkWrap: true,
                            itemCount: requests.length,
                            itemBuilder: (BuildContext context, index) {
                              final req = requests[index];

                              return AmbulenceCard(
                                image: req.imageUrl,
                                name: req.hospitalName,
                                address: req.address,
                                phone: req.phoneNumber,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAmbulence()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:blood_donation/add_ambulence.dart';
import 'package:blood_donation/widgets/ambulence_card.dart';
import 'package:flutter/material.dart';

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
      body: Column(
        children: [
          AmbulenceCard(
            image: '',
            name: 'waris',
            address: 'address',
            phone: 'phone',
          ),
        ],
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

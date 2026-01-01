import 'package:blood_donation/Provider/organization_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/organization_model.dart';

class AddOrganizationScreen extends StatelessWidget {
  const AddOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Organization')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: countryCtrl,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),

            const SizedBox(height: 20),

            Consumer<OrganizationProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final org = OrganizationModel(
                            id: '',
                            name: nameCtrl.text.trim(),
                            country: countryCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            image: '',
                          );

                          await provider.addOraganization(org);
                          Navigator.pop(context);
                        },
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Organization'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

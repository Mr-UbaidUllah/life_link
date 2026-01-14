import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/view/add_organization_screen.dart';
import 'package:blood_donation/widgets/organization_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrganizationScreen extends StatelessWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donat Organization'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Country & City dropdowns (STATIC)
              // Row(
              //   children: [
              //     // Expanded(
              //     //   child: DropdownButtonFormField<String>(
              //     //     hint: const Text('Country'),
              //     //     items: const [
              //     //       DropdownMenuItem(
              //     //         value: 'Bangladesh',
              //     //         child: Text('Bangladesh'),
              //     //       ),
              //     //       DropdownMenuItem(
              //     //         value: 'Pakistan',
              //     //         child: Text('Pakistan'),
              //     //       ),
              //     //     ],
              //     //     onChanged: (_) {},
              //     //   ),
              //     // ),
              //     // const SizedBox(width: 12),
              //     // Expanded(
              //     //   child: DropdownButtonFormField<String>(
              //     //     hint: const Text('City'),
              //     //     items: const [
              //     //       DropdownMenuItem(value: 'Dhaka', child: Text('Dhaka')),
              //     //       DropdownMenuItem(
              //     //         value: 'Lahore',
              //     //         child: Text('Lahore'),
              //     //       ),
              //     //     ],
              //     //     onChanged: (_) {},
              //     //   ),
              //     // ),
              //   ],
              // ),
              const SizedBox(height: 20),

              // Organization list
              // Expanded(
              //   child: ListView(
              //     children: [
              //       OrganizationCard(
              //         image:
              //             'https://images.unsplash.com/photo-1529429617124-95b109e86bb8',
              //         name: 'Organization name',
              //         address: '6391 Elgin St. Celina, Delaware 10299',
              //         phone: '(406) 555-0120',
              //       ),
              //       OrganizationCard(
              //         image:
              //             'https://images.unsplash.com/photo-1497366216548-37526070297c',
              //         name: 'Organization name',
              //         address: '2464 Royal Ln. Mesa, New Jersey',
              //         phone: '(239) 555-0108',
              //       ),
              //       OrganizationCard(
              //         image:
              //             'https://images.unsplash.com/photo-1501183638710-841dd1904471',
              //         name: 'Organization name',
              //         address: '2464 Royal Ln. Mesa, New Jersey',
              //         phone: '(219) 555-0114',
              //       ),
              //     ],
              //   ),
              // ),
              Consumer<OrganizationProvider>(
                builder: (context, provider, _) {
                  return StreamBuilder(
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
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final req = requests[index];

                          return OrganizationCard(
                            image: req.image,
                            name: req.name,
                            address: req.address,
                            phone: req.phone,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

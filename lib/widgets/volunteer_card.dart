import 'package:flutter/material.dart';

class VolunteerCard extends StatelessWidget {
  final String image;
  final String name;
  final String description;
  // final String phone;

  const VolunteerCard({
    super.key,
    required this.image,
    required this.name,
    required this.description,
    // required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: .7,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  // column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name
                        // Text(
                        //   name,
                        //   style: const TextStyle(
                        //     fontWeight: FontWeight.bold,
                        //     fontSize: 18,
                        //   ),
                        // ),
                        const SizedBox(height: 4),

                        // location
                        Row(
                          children: [
                            const Icon(
                              Icons.person_4_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(description),

                        const SizedBox(height: 4),

                        // // phone
                        // Row(
                        //   children: [
                        //     const Icon(
                        //       Icons.location_on_sharp,
                        //       size: 14,
                        //       color: Colors.red,
                        //     ),
                        //     const SizedBox(width: 4),
                        //     // Text(phone, style: const TextStyle(fontSize: 12)),
                        //     SizedBox(width: 54.w),
                        //   ],
                        // ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // button
                  SizedBox(
                    width: 100,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: Center(
                        child: const Text(
                          'Chat Now',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

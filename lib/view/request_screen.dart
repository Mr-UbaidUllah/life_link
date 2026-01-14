import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedBloodGroup;
  String? selectedCountry;
  String? selectedCity;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Create Request",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _inputField("Post Title", "Type title", titleController),

            _dropdownField(
              label: "Select Group",
              value: selectedBloodGroup,
              items: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
              onChanged: (val) => setState(() => selectedBloodGroup = val),
            ),

            _inputField(
              "Amount of Request Blood",
              "Type how much",
              amountController,
              keyboard: TextInputType.number,
            ),

            _dateField(),

            _inputField(
              "Hospital Name",
              "Type hospital name",
              hospitalController,
            ),

            _inputField(
              "Why do you need blood?",
              "Type why",
              reasonController,
              maxLines: 3,
            ),

            _inputField("Contact person Name", "Type name", contactController),

            _inputField(
              "Mobile number",
              "Type mobile number",
              phoneController,
              keyboard: TextInputType.phone,
            ),

            _dropdownField(
              label: "Country",
              value: selectedCountry,
              items: ["Pakistan", "India", "USA"],
              onChanged: (val) => setState(() => selectedCountry = val),
            ),

            _dropdownField(
              label: "City",
              value: selectedCity,
              items: ["Lahore", "Karachi", "Islamabad"],
              onChanged: (val) => setState(() => selectedCity = val),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<BloodrequestProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) return;

                              final bags = int.tryParse(amountController.text);
                              if (bags == null) return;

                              final request = BloodRequestModel(
                                id: '',
                                title: titleController.text.trim(),
                                bloodGroup: selectedBloodGroup ?? '',
                                bags: bags,
                                hospital: hospitalController.text.trim(),
                                reason: reasonController.text.trim(),
                                contactName: contactController.text.trim(),
                                phone: phoneController.text.trim(),
                                country: selectedCountry ?? '',
                                city: selectedCity ?? '',
                                userId: user.uid,
                                createdAt: DateTime.now(),
                              );

                              try {
                                await provider.bloodRequest(request);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Request submitted"),
                                  ),
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Get Started"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- WIDGETS ----------

  Widget _inputField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(label),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Date", style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => selectedDate = date);
              }
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    style: TextStyle(
                      color: selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

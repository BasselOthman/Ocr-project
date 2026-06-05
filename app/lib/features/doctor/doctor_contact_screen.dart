import 'package:flutter/material.dart';

class DoctorContact extends StatefulWidget {
  const DoctorContact({super.key});

  @override
  State<DoctorContact> createState() => _DoctorContactState();
}

class _DoctorContactState extends State<DoctorContact> {
  final phoneController = TextEditingController(text: '+20 100 123 4567');
  final clinicController = TextEditingController(text: 'Nasr City Clinic');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Information')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clinicController,
              decoration: const InputDecoration(labelText: 'Clinic Address'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact info updated')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

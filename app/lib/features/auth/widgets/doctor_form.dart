import 'package:flutter/material.dart';

class DoctorAuthForm extends StatelessWidget {
  const DoctorAuthForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'Email')),
          TextField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Medical License ID'),
          ),
          TextField(decoration: InputDecoration(labelText: 'Specialty')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: call doctor login/register + verification
            },
            child: const Text('Continue as Doctor'),
          ),
        ],
      ),
    );
  }
}

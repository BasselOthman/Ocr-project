import 'package:flutter/material.dart';

class ClientAuthForm extends StatelessWidget {
  const ClientAuthForm({super.key});

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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: call client login/register
            },
            child: const Text('Continue as Client'),
          ),
        ],
      ),
    );
  }
}

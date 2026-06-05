import 'package:flutter/material.dart';

class DoctorRatingsScreen extends StatelessWidget {
  const DoctorRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ratings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _RatingHeader(),
          const SizedBox(height: 20),
          _ratingTile('Rita J.', 5, 'Very professional and kind.'),
          _ratingTile('Islam H.', 4, 'Explained everything clearly.'),
          _ratingTile('Eman M.', 5, 'Highly recommended!'),
        ],
      ),
    );
  }

  Widget _ratingTile(String name, int stars, String comment) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(comment),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            stars,
            (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
          ),
        ),
      ),
    );
  }
}

class _RatingHeader extends StatelessWidget {
  const _RatingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('4.8',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        Text('Average Rating'),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gp_app/routes/app_routes.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              context,
              icon: Icons.person,
              title: 'My Profile',
              route: AppRoutes.doctorProfile,
            ),
            _buildCard(
              context,
              icon: Icons.star,
              title: 'My Ratings',
              route: AppRoutes.doctorRatings,
            ),
            _buildCard(
              context,
              icon: Icons.contact_phone,
              title: 'Contact Info',
              route: AppRoutes.doctorContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon, required String title, required String route}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

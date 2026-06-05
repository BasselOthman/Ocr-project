import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/common/app_colors.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.health_and_safety, size: 88, color: Colors.white),
            SizedBox(height: 16),
            Text('LabSense', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('AI-based Lab Results', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

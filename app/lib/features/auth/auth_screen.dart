import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../features/common/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showLoginPage = true;

  // This function allows children to toggle the view
  void toggleView() {
    setState(() => showLoginPage = !showLoginPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Common background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text(
              "Welcome to The GP App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            
            // Conditionally show Login or Register
            Expanded(
              child: showLoginPage 
                ? LoginScreen(onRegisterTap: toggleView) 
                : RegisterScreen(onLoginTap: toggleView),
            ),
          ],
        ),
      ),
    );
  }
}
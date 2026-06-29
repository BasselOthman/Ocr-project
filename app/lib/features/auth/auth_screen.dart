import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showLoginPage = true;

  void toggleView() {
    setState(() => showLoginPage = !showLoginPage);
  }

  @override
  Widget build(BuildContext context) {
    // Removed the outer Scaffold so that LoginScreen and RegisterScreen
    // are truly full screen and not layered inside another Scaffold.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showLoginPage
          ? LoginScreen(key: const ValueKey('login'), onRegisterTap: toggleView)
          : RegisterScreen(
              key: const ValueKey('register'),
              onLoginTap: toggleView,
            ),
    );
  }
}

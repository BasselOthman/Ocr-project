import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gp_app/routes/app_routes.dart';
import 'package:gp_app/features/common/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onRegisterTap;
  const LoginScreen({super.key, required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Immersive Deep Blue Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.meshGradient,
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Text
                      Text(
                        AppLocalizations.of(context)!.welcomeBack,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        AppLocalizations.of(context)!.signInToAccess,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight.withValues(alpha: 0.8),
                        ),
                      ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 48),

                      // Reusable Glassmorphism Card
                      GlassCard(
                        padding: const EdgeInsets.all(24.0),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              // Styled TabBar inside the glass card
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TabBar(
                                  indicator: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white70,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  splashBorderRadius: BorderRadius.circular(25),
                                  dividerColor: Colors.transparent,
                                  tabs: [
                                    Tab(text: AppLocalizations.of(context)!.patient, height: 44), 
                                    Tab(text: AppLocalizations.of(context)!.doctor, height: 44)
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Tab Views containing Forms
                              SizedBox(
                                height: 420, // Increased height for header
                                child: TabBarView(
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _LoginForm(userType: "Patient", onRegisterTap: onRegisterTap),
                                    _LoginForm(userType: "Doctor", onRegisterTap: onRegisterTap),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(duration: 800.ms, delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final String userType;
  final VoidCallback onRegisterTap;

  const _LoginForm({required this.userType, required this.onRegisterTap});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context, 
          widget.userType == 'Patient' ? AppRoutes.clientHome : AppRoutes.doctorHome,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.loginFailed, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.emailAddress,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.8)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
            ),
            validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterEmail : null,
          ),
          const SizedBox(height: 16),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.8)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
            ),
            validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterPassword : null,
          ),
          
          const SizedBox(height: 12),
          
          // Forgot Password (Dummy)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                AppLocalizations.of(context)!.forgotPassword,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Login Scale Button
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : AnimatedScaleButton(
                onTap: _handleLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(AppLocalizations.of(context)!.logIn, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
          const SizedBox(height: 24),
          
          // Sign Up
          Center(
            child: TextButton(
              onPressed: widget.onRegisterTap,
              child: RichText(
                text: TextSpan(
                  text: AppLocalizations.of(context)!.dontHaveAccount,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.signUp, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gp_app/features/common/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';

class RegisterScreen extends StatelessWidget {
  final VoidCallback onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});

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
                        AppLocalizations.of(context)!.createAccount,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        AppLocalizations.of(context)!.joinUsToOrganize,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight.withValues(alpha: 0.8),
                        ),
                      ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 48),

                      // Glass Card Container
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
                              
                              // Tab Views containing Forms (Height adjusted for extra fields)
                              SizedBox(
                                height: 580, // Fixed height for register forms
                                child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _RegisterForm(isDoctor: false, onLoginTap: onLoginTap),
                                    _RegisterForm(isDoctor: true, onLoginTap: onLoginTap),
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

class _RegisterForm extends StatefulWidget {
  final bool isDoctor;
  final VoidCallback onLoginTap;

  const _RegisterForm({required this.isDoctor, required this.onLoginTap});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog(AppLocalizations.of(context)!.registrationFailed, AppLocalizations.of(context)!.passwordsDoNotMatch);
        return;
      }

      setState(() => _isLoading = true);
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        String route = widget.isDoctor ? AppRoutes.doctorHome : AppRoutes.clientHome;
        Navigator.pushReplacementNamed(context, route);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showErrorDialog(AppLocalizations.of(context)!.registrationFailed, e.message ?? AppLocalizations.of(context)!.unknownErrorOccurred);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.okay, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.8)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          _buildGlassInput(
            controller: _nameController,
            labelText: AppLocalizations.of(context)!.fullName,
            prefixIcon: Icons.person_outline,
            validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterName : null,
          ),
          const SizedBox(height: 12),
          
          // Age
          _buildGlassInput(
            controller: _ageController,
            labelText: AppLocalizations.of(context)!.age,
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pleaseEnterAge : null,
          ),
          const SizedBox(height: 12),

          // Email
          _buildGlassInput(
            controller: _emailController,
            labelText: AppLocalizations.of(context)!.emailAddress,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterEmail;
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return AppLocalizations.of(context)!.enterValidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Doctor Specific Fields conditionally
          if (widget.isDoctor) ...[
            _buildGlassInput(
              controller: _licenseController,
              labelText: AppLocalizations.of(context)!.medicalLicenseId,
              prefixIcon: Icons.badge_outlined,
              validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.licenseIdRequired : null,
            ),
            const SizedBox(height: 12),
            _buildGlassInput(
              controller: _specialtyController,
              labelText: AppLocalizations.of(context)!.specialty,
              prefixIcon: Icons.local_hospital_outlined,
              validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.specialtyRequired : null,
            ),
            const SizedBox(height: 12),
          ],

          // Password
          _buildGlassInput(
            controller: _passwordController,
            labelText: AppLocalizations.of(context)!.password,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
               if (value == null || value.isEmpty) return AppLocalizations.of(context)!.passwordRequired;
               if (value.length < 6) return AppLocalizations.of(context)!.atLeast6Chars;
               return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm Password
          _buildGlassInput(
            controller: _confirmPasswordController,
            labelText: AppLocalizations.of(context)!.confirmPassword,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return AppLocalizations.of(context)!.confirmYourPassword;
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Action Button
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : AnimatedScaleButton(
                onTap: _handleRegister,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isDoctor ? AppLocalizations.of(context)!.registerAsDoctor : AppLocalizations.of(context)!.registerAsPatient, 
                    style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

          const SizedBox(height: 16),

          // Sign In
          Center(
            child: TextButton(
              onPressed: widget.onLoginTap,
              child: RichText(
                text: TextSpan(
                  text: AppLocalizations.of(context)!.alreadyHaveAccount,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.loginHere, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
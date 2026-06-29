import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../common/widgets/animated_scale_button.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final List<String> _specialties = [
    'Cardiology & Vascular Disease',
    'Cardiology and Vascular Disease (Heart)',
    'Diabetes & Endocrinology',
    'Dietitian & Nutrition',
    'Gastroenterology',
    'Hematology',
    'Hepatology',
    'Internal Medicine',
    'Nephrology',
    'Nutrition',
    'Obesity',
  ];
  String? _selectedSpecialty;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog(
          AppLocalizations.of(context)!.registrationFailed,
          AppLocalizations.of(context)!.passwordsDoNotMatch,
        );
        return;
      }

      setState(() => _isLoading = true);
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': _nameController.text.trim(),
                'email': email,
                'age': int.tryParse(_ageController.text.trim()) ?? 0,
                'role': 'doctor',
                'createdAt': FieldValue.serverTimestamp(),
                'licenseId': _licenseController.text.trim(),
                'specialty': _selectedSpecialty ?? '',
              });

          await user.updateDisplayName(_nameController.text.trim());
        }

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.doctorHome,
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showErrorDialog(
          AppLocalizations.of(context)!.registrationFailed,
          e.message ?? AppLocalizations.of(context)!.unknownErrorOccurred,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(context)!.okay,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);
    final inputFillColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final inputBorderColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(prefixIcon, color: hintColor),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Text
                    Text(
                          "Doctor Registration",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fade(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 8),

                    Text(
                          "Join us as a medical professional",
                          style: TextStyle(fontSize: 16, color: hintColor),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fade(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 48),

                    // Full Name
                    _buildInput(
                      controller: _nameController,
                      labelText: AppLocalizations.of(context)!.fullName,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value!.isEmpty
                          ? AppLocalizations.of(context)!.pleaseEnterName
                          : null,
                    ).animate().fade(duration: 800.ms, delay: 300.ms).slideX(),
                    const SizedBox(height: 12),

                    // Age
                    _buildInput(
                      controller: _ageController,
                      labelText: AppLocalizations.of(context)!.age,
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty
                          ? AppLocalizations.of(context)!.pleaseEnterAge
                          : null,
                    ).animate().fade(duration: 800.ms, delay: 400.ms).slideX(),
                    const SizedBox(height: 12),

                    // License
                    _buildInput(
                      controller: _licenseController,
                      labelText: AppLocalizations.of(context)!.medicalLicenseId,
                      prefixIcon: Icons.badge_outlined,
                      validator: (value) => value!.isEmpty
                          ? AppLocalizations.of(context)!.licenseIdRequired
                          : null,
                    ).animate().fade(duration: 800.ms, delay: 450.ms).slideX(),
                    const SizedBox(height: 12),

                    // Specialty
                    Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        dropdownColor: theme.scaffoldBackgroundColor,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.specialty,
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(
                            Icons.local_hospital_outlined,
                            color: hintColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: TextStyle(color: textColor),
                        initialValue: _selectedSpecialty,
                        items: _specialties
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSpecialty = val),
                        validator: (value) => value == null
                            ? AppLocalizations.of(context)!.specialtyRequired
                            : null,
                      ),
                    ).animate().fade(duration: 800.ms, delay: 500.ms).slideX(),
                    const SizedBox(height: 12),

                    // Email
                    _buildInput(
                      controller: _emailController,
                      labelText: AppLocalizations.of(context)!.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterEmail;
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return AppLocalizations.of(context)!.enterValidEmail;
                        }
                        return null;
                      },
                    ).animate().fade(duration: 800.ms, delay: 550.ms).slideX(),
                    const SizedBox(height: 12),

                    // Password
                    _buildInput(
                      controller: _passwordController,
                      labelText: AppLocalizations.of(context)!.password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.passwordRequired;
                        }
                        if (value.length < 6) {
                          return AppLocalizations.of(context)!.atLeast6Chars;
                        }
                        return null;
                      },
                    ).animate().fade(duration: 800.ms, delay: 600.ms).slideX(),
                    const SizedBox(height: 12),

                    // Confirm Password
                    _buildInput(
                      controller: _confirmPasswordController,
                      labelText: AppLocalizations.of(context)!.confirmPassword,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.confirmYourPassword;
                        }
                        return null;
                      },
                    ).animate().fade(duration: 800.ms, delay: 650.ms).slideX(),
                    const SizedBox(height: 24),

                    // Action Button
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : AnimatedScaleButton(
                                onTap: _handleRegister,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.registerAsDoctor,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fade(duration: 800.ms, delay: 700.ms)
                              .scale(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

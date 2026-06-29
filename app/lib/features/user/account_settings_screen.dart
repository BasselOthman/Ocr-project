import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme_provider.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/animated_scale_button.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  String _role = 'patient';

  bool _isLoading = true;
  bool _isSaving = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? "";
      _emailController.text = user.email ?? "";

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (_nameController.text.isEmpty) {
            _nameController.text = data['name'] ?? "";
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = data['email'] ?? "";
          }
          _ageController.text = (data['age'] ?? "").toString();
          _phoneController.text = data['phone'] ?? "";
          _role = data['role'] ?? "patient";
          if (_role == "doctor") {
            _specialtyController.text = data['specialty'] ?? "";
            _licenseController.text = data['licenseId'] ?? "";
          }
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // Update email in FirebaseAuth if it changed
      String newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        // user.verifyBeforeUpdateEmail(newEmail) is recommended, but for simplicity we will try updateEmail
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A verification email has been sent to the new address.',
                ),
                backgroundColor: AppColors.accent,
              ),
            );
          }
        } catch (e) {
          debugPrint("Email update requires re-authentication or failed: $e");
        }
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': newEmail,
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_role == "doctor") 'specialty': _specialtyController.text.trim(),
        if (_role == "doctor") 'licenseId': _licenseController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profileUpdatedSuccessfully,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorUpdatingProfile} $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSettings),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Theme Mode",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          DropdownButton<ThemeMode>(
                            value: themeProvider.themeMode,
                            underline: const SizedBox(),
                            dropdownColor: theme.colorScheme.surface,
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text("System"),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text("Light"),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text("Dark"),
                              ),
                            ],
                            onChanged: (ThemeMode? mode) {
                              if (mode != null) {
                                themeProvider.setThemeMode(mode);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      AppLocalizations.of(context)!.personalInformation,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            AppLocalizations.of(context)!.fullName,
                            _nameController,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            AppLocalizations.of(context)!.emailAddress,
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            AppLocalizations.of(context)!.age,
                            _ageController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            AppLocalizations.of(context)!.phoneNumber,
                            _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          if (_role == "doctor") ...[
                            const SizedBox(height: 16),
                            _buildField(
                              AppLocalizations.of(context)!.specialty,
                              _specialtyController,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              AppLocalizations.of(context)!.medicalLicenseId,
                              _licenseController,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    AnimatedScaleButton(
                      onTap: _isSaving ? () {} : _saveData,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.saveChanges,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);
    final inputFillColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hintColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

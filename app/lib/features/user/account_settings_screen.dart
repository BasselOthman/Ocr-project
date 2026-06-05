import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/locale_provider.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  
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
      
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (_nameController.text.isEmpty) {
             _nameController.text = data['name'] ?? "";
          }
          _phoneController.text = data['phone'] ?? "";
          _dobController.text = data['dob'] ?? "";
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
      await user.updateDisplayName(_nameController.text);
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccessfully, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorUpdatingProfile} $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSettings, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.meshGradient)),
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.personalInformation, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 24),
                        _buildField(AppLocalizations.of(context)!.fullName, _nameController),
                        const SizedBox(height: 16),
                        _buildField(AppLocalizations.of(context)!.phoneNumber, _phoneController),
                        const SizedBox(height: 16),
                        _buildField(AppLocalizations.of(context)!.dateOfBirth, _dobController),
                        const SizedBox(height: 32),
                        AnimatedScaleButton(
                          onTap: _isSaving 
                              ? () {} 
                              : () {
                                  _saveData();
                                },
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isSaving ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(AppLocalizations.of(context)!.saveChanges, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          )
        ],
      )
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
      ],
    );
  }
}

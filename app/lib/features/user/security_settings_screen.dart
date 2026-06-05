import 'package:flutter/material.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  Future<void> _resetPassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.passwordResetSent, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorPrefix} $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.securityTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.meshGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.authentication, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    Text(AppLocalizations.of(context)!.needChangePassword, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    AnimatedScaleButton(
                      onTap: () => _resetPassword(context),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.secondary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(AppLocalizations.of(context)!.sendPasswordReset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(AppLocalizations.of(context)!.dataPrivacy, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
                      title: Text(AppLocalizations.of(context)!.dataSecured, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(AppLocalizations.of(context)!.dataLocalized, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      )
    );
  }
}

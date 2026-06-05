import 'package:flutter/material.dart';
import '../../features/common/app_colors.dart';
import '../../routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/locale_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? AppLocalizations.of(context)!.notLoggedIn;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('USER PROFILE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.meshGradient),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Profile Header GlassCard
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Icon(Icons.person, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userEmail.split('@').first.toUpperCase(), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail, 
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Text(AppLocalizations.of(context)!.patientRecord, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Settings Buttons Stack
                  _buildGlassTile(
                    context: context,
                    icon: Icons.settings,
                    title: AppLocalizations.of(context)!.accountSettings,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.clientAccount),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTile(
                    context: context,
                    icon: Icons.notifications,
                    title: AppLocalizations.of(context)!.notificationPreferences,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.clientNotifications),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTile(
                    context: context,
                    icon: Icons.lock_outline,
                    title: AppLocalizations.of(context)!.security,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.clientSecurity),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTile(
                    context: context,
                    icon: Icons.folder_open,
                    title: AppLocalizations.of(context)!.reportsHistory,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.clientHistory),
                  ),
                  const SizedBox(height: 12),
                  
                  // Language Toggle Tile
                  Consumer<LocaleProvider>(
                    builder: (context, provider, child) {
                      final isArabic = provider.locale?.languageCode == 'ar';
                      return _buildGlassTile(
                        context: context,
                        icon: Icons.language,
                        title: isArabic ? AppLocalizations.of(context)!.languageArabic : AppLocalizations.of(context)!.languageEnglish,
                        onTap: () {
                          provider.setLocale(Locale(isArabic ? 'en' : 'ar'));
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Logout Button
                  AnimatedScaleButton(
                    onTap: () {
                       FirebaseAuth.instance.signOut();
                       Navigator.pushReplacementNamed(context, AppRoutes.auth);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.power_settings_new, color: Colors.white.withValues(alpha: 0.8), size: 24),
                          const SizedBox(width: 16),
                          Text(AppLocalizations.of(context)!.logOut, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildGlassTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        borderRadius: 16,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)
              )
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

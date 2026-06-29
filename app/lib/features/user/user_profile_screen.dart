import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final textMuted = textColor?.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'USER PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Profile Header
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userEmail.split('@').first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.patientRecord,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Settings Buttons Stack
              _buildTile(
                context: context,
                icon: Icons.settings,
                title: AppLocalizations.of(context)!.accountSettings,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.clientAccount),
              ),
              const SizedBox(height: 12),
              _buildTile(
                context: context,
                icon: Icons.notifications,
                title: AppLocalizations.of(context)!.notificationPreferences,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.clientNotifications),
              ),
              const SizedBox(height: 12),
              _buildTile(
                context: context,
                icon: Icons.lock_outline,
                title: AppLocalizations.of(context)!.security,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.clientSecurity),
              ),
              const SizedBox(height: 12),
              _buildTile(
                context: context,
                icon: Icons.folder_open,
                title: AppLocalizations.of(context)!.reportsHistory,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.clientHistory),
              ),
              const SizedBox(height: 12),

              // Language Toggle Tile
              Consumer<LocaleProvider>(
                builder: (context, provider, child) {
                  final isArabic = provider.locale?.languageCode == 'ar';
                  return _buildTile(
                    context: context,
                    icon: Icons.language,
                    title: isArabic
                        ? AppLocalizations.of(context)!.languageArabic
                        : AppLocalizations.of(context)!.languageEnglish,
                    onTap: () {
                      provider.setLocale(Locale(isArabic ? 'en' : 'ar'));
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Logout Button
              AnimatedScaleButton(
                onTap: () async {
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.auth,
                      (route) => false,
                    );
                  }
                  await FirebaseAuth.instance.signOut();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context)!.logOut,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final iconColor = theme.colorScheme.primary;

    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassCard(
        // Using the modified GlassCard which is now a flat ModernCard
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        borderRadius: 16,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor?.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.meshGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.pushNotifications, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(AppLocalizations.of(context)!.alertsNewPredictions, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                      value: _pushEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) => setState(() => _pushEnabled = val),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.soundVibration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      value: _soundEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) => setState(() => _soundEnabled = val),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.emailUpdates, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(AppLocalizations.of(context)!.weeklySummaries, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                      value: _emailEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) => setState(() => _emailEnabled = val),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../common/widgets/glass_card.dart';
import '../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final textMuted = textColor?.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.pushNotifications,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.alertsNewPredictions,
                    style: TextStyle(color: textMuted),
                  ),
                  value: _pushEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _pushEnabled = val),
                ),
                Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.soundVibration,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _soundEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _soundEnabled = val),
                ),
                Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.emailUpdates,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.weeklySummaries,
                    style: TextStyle(color: textMuted),
                  ),
                  value: _emailEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _emailEnabled = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'user_home_screen.dart';
import 'reports_history_screen.dart';
import 'upload_report_screen.dart';
import 'patient_dashboard_screen.dart';
import 'doctor_recommendation_screen.dart';

class ClientMainLayout extends StatefulWidget {
  const ClientMainLayout({super.key});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const UserHomeScreen(),
    const ReportsHistoryScreen(),
    const UploadScreen(),
    const PatientDashboardScreen(),
    const DoctorRecommendationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildModernNavigationBar(),
    );
  }

  Widget _buildModernNavigationBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: AppLocalizations.of(context)!.navHome,
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.history_rounded,
              label: AppLocalizations.of(context)!.navReports,
              index: 1,
            ),

            // Instagram style prominent (+) add button
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            _buildNavItem(
              icon: Icons.insert_chart_rounded,
              label: AppLocalizations.of(context)!.navDashboard,
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.medical_information_rounded,
              label: AppLocalizations.of(context)!.navDrRec,
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../features/common/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'user_home_screen.dart';
import 'reports_history_screen.dart';
import 'upload_report_screen.dart';
import 'patient_dashboard_screen.dart';

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
    const DoctorRecsPlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for glassmorphism nav bar to float over background
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildGlassNavigationBar(),
    );
  }

  Widget _buildGlassNavigationBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: AppLocalizations.of(context)!.navHome, index: 0),
              _buildNavItem(icon: Icons.history_rounded, label: AppLocalizations.of(context)!.navReports, index: 1),
              
              // Instagram style prominent (+) add button
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.meshGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),

              _buildNavItem(icon: Icons.insert_chart_rounded, label: AppLocalizations.of(context)!.navDashboard, index: 3),
              _buildNavItem(icon: Icons.medical_information_rounded, label: AppLocalizations.of(context)!.navDrRec, index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppColors.accent : Colors.white54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}

// Simple Placeholder Screen for Doctor Recommendations
class DoctorRecsPlaceholderScreen extends StatelessWidget {
  const DoctorRecsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.meshGradient),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 60, color: Colors.white70),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.doctorRecommendations,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.comingSoon,
                        style: const TextStyle(color: AppColors.accent, fontSize: 16),
                      ),
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

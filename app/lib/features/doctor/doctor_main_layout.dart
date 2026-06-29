import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_home_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_reviews_tab.dart';
import 'doctor_patients_tab.dart';

class DoctorMainLayout extends StatefulWidget {
  const DoctorMainLayout({super.key});

  @override
  State<DoctorMainLayout> createState() => _DoctorMainLayoutState();
}

class _DoctorMainLayoutState extends State<DoctorMainLayout> {
  int _currentIndex = 0;
  String _reviewsInitialTab = 'pending';

  // Navigate to reviews tab and set the toggle state
  void _goToReviewsTab(String status) {
    setState(() {
      _currentIndex = 1;
      _reviewsInitialTab = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // The tabs
    final List<Widget> pages = [
      DoctorHomeScreen(onNavigateToReviews: _goToReviewsTab),
      DoctorReviewsTab(initialStatus: _reviewsInitialTab),
      const DoctorPatientsTab(),
      const DoctorProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildModernNavigationBar(user?.uid ?? ''),
    );
  }

  Widget _buildModernNavigationBar(String doctorId) {
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
              icon: Icons.dashboard_rounded,
              label: "Home",
              index: 0,
            ),
            _buildReviewsNavItem(
              doctorId: doctorId,
              icon: Icons.assignment_rounded,
              label: "Reviews",
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.people_rounded,
              label: "Patients",
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: "Profile",
              index: 3,
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
        width: 70,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsNavItem({
    required String doctorId,
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
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: color),

                // Red Notification Badge for Pending Reviews
                if (doctorId.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collectionGroup('reports')
                          .where('assignedDoctorId', isEqualTo: doctorId)
                          .where('doctorReviewStatus', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

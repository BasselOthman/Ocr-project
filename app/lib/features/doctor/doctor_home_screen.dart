import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/widgets/animated_scale_button.dart';
import '../common/widgets/glass_card.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Function(String) onNavigateToReviews;

  const DoctorHomeScreen({super.key, required this.onNavigateToReviews});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _doctorName = "Doctor";
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  void _fetchDoctorName() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _doctorName = doc.data()!['name'] ?? "Doctor";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(color: hintColor, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Dr. $_doctorName",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ).animate().fade().slideX(begin: -0.2),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedScaleButton(
                          onTap: () => widget.onNavigateToReviews('pending'),
                          child: _buildStatCard(
                            "Pending",
                            Icons.pending_actions,
                            Colors.orangeAccent,
                            'pending',
                            theme,
                            textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedScaleButton(
                          onTap: () => widget.onNavigateToReviews('completed'),
                          child: _buildStatCard(
                            "Completed",
                            Icons.check_circle_outline,
                            Colors.green,
                            'completed',
                            theme,
                            textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2),

                const SizedBox(height: 32),

                // Information or greeting area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Your Dashboard",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tap on Pending or Completed to manage your patient reports.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: hintColor, fontSize: 16),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    IconData icon,
    Color color,
    String status,
    ThemeData theme,
    Color textColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              if (_user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('reports')
                      .where('assignedDoctorId', isEqualTo: _user.uid)
                      .where(
                        'doctorReviewStatus',
                        isEqualTo: status == 'completed' ? 'reviewed' : status,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data!.docs.length}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

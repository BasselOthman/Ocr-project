import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/common/app_colors.dart';
import '../../routes/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/glass_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Fallback if displayName is missing
    if (user != null && user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'Patient';
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    
    // Get formatted date
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateString = '${now.day} ${months[now.month - 1]}, ${now.year}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'DIAGKNOWSYS', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 20)
        ),
        leading: IconButton(
          icon: const Icon(Icons.person_rounded, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.clientProfile),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.clientNotifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Header Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.meshGradient,
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // padding for the bottom nav bar
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Greeting Header
                    Text(
                      AppLocalizations.of(context)!.hello,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
                    
                    Text(
                      userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ).animate().fade(duration: 500.ms).slideY(begin: -0.2),

                    const SizedBox(height: 40),

                    // Simple clean date card
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.today,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateString,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ).animate().fade(duration: 600.ms).slideX(begin: 0.1),

                    const SizedBox(height: 40),

                    // Clean prompt
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 60, color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.readyToCheckHealth,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.tapPlusToScan,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 700.ms).scale(),

                  ],
                ),
              ),
            ),
          ),
        ]
      )
    );
  }
}

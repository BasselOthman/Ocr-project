import 'package:flutter/material.dart';

// ================= AUTH =================
import 'package:gp_app/features/auth/auth_screen.dart';
import 'package:gp_app/features/auth/doctor_register_screen.dart';

// ================= CLIENT =================
import 'package:gp_app/features/user/user_profile_screen.dart';
import 'package:gp_app/features/user/upload_report_screen.dart';
import 'package:gp_app/features/user/report_analysis_screen.dart';
import 'package:gp_app/features/user/reports_history_screen.dart';
import 'package:gp_app/features/user/notification_settings_screen.dart';
import 'package:gp_app/features/user/account_settings_screen.dart';
import 'package:gp_app/features/user/client_main_layout.dart';
import 'package:gp_app/features/user/security_settings_screen.dart';

import '../../features/doctor/doctor_main_layout.dart';
import '../../features/doctor/doctor_profile_screen.dart';
import '../../features/doctor/doctor_ratings_screen.dart';
import '../../features/doctor/doctor_contact_screen.dart';
import '../../features/doctor/patient_review_screen.dart';

class DoctorContactScreen extends StatefulWidget {
  const DoctorContactScreen({super.key});

  @override
  State<DoctorContactScreen> createState() => _DoctorContactScreenState();
}

class _DoctorContactScreenState extends State<DoctorContactScreen> {
  final phoneController = TextEditingController(text: '+20 100 123 4567');
  final clinicController = TextEditingController(text: 'Nasr City Clinic');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Information')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clinicController,
              decoration: const InputDecoration(labelText: 'Clinic Address'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact info updated')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRoutes {
  // ========== AUTH ==========
  static const String auth = '/';
  static const String doctorRegister = '/auth/doctor_register';

  // ========== CLIENT ==========
  static const String clientHome = '/client/home';
  static const String clientProfile = '/client/profile';
  static const String uploadReport = '/client/upload';
  static const String reportAnalysis = '/client/analysis';

  static const String clientHistory = '/client/history';
  static const String clientNotifications = '/client/notifications';
  static const String clientAccount = '/client/account';
  static const String clientSecurity = '/client/security';

  // ========== DOCTOR ==========
  static const String doctorHome = '/doctor/home';
  static const String doctorProfile = '/doctor/profile';
  static const String doctorRatings = '/doctor/ratings';
  static const String doctorContact = '/doctor/contact';
  static const String patientReview = '/doctor/patient_review';

  // ================= ROUTES MAP =================
  static Map<String, WidgetBuilder> routes() {
    return {
      // ---------- AUTH ----------
      auth: (context) => const AuthScreen(),
      doctorRegister: (context) => const DoctorRegisterScreen(),

      // ---------- CLIENT ----------
      // Standardizing names based on your imports
      clientHome: (context) => const ClientMainLayout(),
      clientProfile: (context) => const ProfileScreen(),
      uploadReport: (context) => const UploadScreen(),
      reportAnalysis: (context) => const ReportAnalysis(),
      clientHistory: (context) => const ReportsHistoryScreen(),
      clientNotifications: (context) => const NotificationSettingsScreen(),
      clientAccount: (context) => const AccountSettingsScreen(),
      clientSecurity: (context) => const SecuritySettingsScreen(),

      // ---------- DOCTOR ----------
      doctorHome: (context) => const DoctorMainLayout(),
      doctorProfile: (context) => const DoctorProfileScreen(),
      doctorRatings: (context) => const DoctorRatingsScreen(),
      doctorContact: (context) => const DoctorContact(),
      patientReview: (context) => const PatientReviewScreen(),
    };
  }
}

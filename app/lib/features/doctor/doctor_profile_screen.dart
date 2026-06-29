import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../../routes/app_routes.dart';
import '../../core/locale_provider.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),
                  _buildSettingsList(context, user),
                  const SizedBox(height: 100), // bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = user.displayName ?? "Doctor";
        String email = user.email ?? "";
        String specialty = "Specialty not set";
        String license = "License not set";

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          specialty = data['specialty'] ?? specialty;
          license = data['licenseId'] ?? license;
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.5),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Dr. $name",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Text(
                    "Specialty: $specialty",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "License: $license",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsList(BuildContext context, User? user) {
    return Column(
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.person_outline,
          title: "Account Settings",
          subtitle: "Update personal & professional details",
          onTap: () => Navigator.pushNamed(context, AppRoutes.clientAccount),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.calendar_today,
          title: "Manage Availability",
          subtitle: "Block or unblock booking timeslots",
          onTap: () {
            _showManageAvailabilityDialog(context, user?.uid ?? '');
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.notifications_none,
          title: "Notifications",
          subtitle: "Manage alert preferences",
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.clientNotifications),
        ),
        Consumer<LocaleProvider>(
          builder: (context, provider, child) {
            final isArabic = provider.locale?.languageCode == 'ar';
            return _buildSettingsTile(
              context,
              icon: Icons.language,
              title: "Language",
              subtitle: isArabic ? "Arabic" : "English",
              onTap: () {
                provider.setLocale(Locale(isArabic ? 'en' : 'ar'));
              },
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: "Log Out",
          subtitle: "Sign out of your account",
          isDestructive: true,
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
        ),
      ],
    );
  }

  void _showManageAvailabilityDialog(BuildContext context, String doctorId) {
    if (doctorId.isEmpty) return;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    List<String> disabledSlots = [];
    bool isLoading = false;
    bool hasFetched = false;

    final List<String> allTimeSlots = [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final dateKey =
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

            Future<void> fetchSlots() async {
              setState(() => isLoading = true);
              try {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doctorId)
                    .get();
                if (doc.exists && doc.data() != null) {
                  final data = doc.data()!;
                  final map = data['disabledSlots'] as Map<String, dynamic>?;
                  if (map != null && map.containsKey(dateKey)) {
                    final list = map[dateKey] as List<dynamic>?;
                    if (list != null) {
                      disabledSlots = list.map((e) => e.toString()).toList();
                    } else {
                      disabledSlots = [];
                    }
                  } else {
                    disabledSlots = [];
                  }
                }
              } catch (_) {}
              setState(() {
                isLoading = false;
                hasFetched = true;
              });
            }

            if (!hasFetched && !isLoading) {
              Future.microtask(() => fetchSlots());
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Manage Availability",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            hasFetched = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Click timeslots to disable/remove them from patient booking:",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allTimeSlots.map((slot) {
                              final isDisabled = disabledSlots.contains(slot);
                              return FilterChip(
                                label: Text(slot),
                                selected: !isDisabled,
                                selectedColor: AppColors.accent.withValues(
                                  alpha: 0.2,
                                ),
                                checkmarkColor: AppColors.accent,
                                labelStyle: TextStyle(
                                  color: isDisabled
                                      ? Colors.redAccent
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Colors.redAccent.withValues(
                                  alpha: 0.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDisabled
                                        ? Colors.redAccent
                                        : AppColors.accent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      disabledSlots.remove(slot);
                                    } else {
                                      disabledSlots.add(slot);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doctorId)
                                .set({
                                  'disabledSlots': {dateKey: disabledSlots},
                                }, SetOptions(merge: true));
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Availability updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

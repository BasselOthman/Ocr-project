import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';

class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$displayHour:$minute $amPm";
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final String name = patient['name'];
    final String email = patient['email'];
    final int age = patient['age'];
    final DateTime? apptDate = patient['appointmentDate'];
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    List<String> metaItems = [];
    if (age > 0) metaItems.add("Age: $age");
    if (email.isNotEmpty) metaItems.add(email);
    final String subtitleText = metaItems.isNotEmpty
        ? metaItems.join(" • ")
        : "No profile email/age";
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.5),
              radius: 26,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (apptDate != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: apptDate.isAfter(DateTime.now())
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  )
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: apptDate.isAfter(DateTime.now())
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    )
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            "${apptDate.day}/${apptDate.month} @ ${_formatTime(apptDate)}",
                            style: TextStyle(
                              color: apptDate.isAfter(DateTime.now())
                                  ? theme.colorScheme.primary
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not authenticated"));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Current Patients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Modern Preply-style Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search patients by name or email...",
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                ),

                // StreamBuilder for patients list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('reports')
                        .where('assignedDoctorId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final Set<String> patientIds = {};
                      final Map<String, DateTime?> patientAppts = {};
                      for (var doc in docs) {
                        final patientId = doc.reference.parent.parent?.id;
                        if (patientId != null) {
                          patientIds.add(patientId);
                          final data = doc.data() as Map<String, dynamic>;
                          final apptTimestamp =
                              data['appointmentDate'] as Timestamp?;
                          if (apptTimestamp != null) {
                            final apptDate = apptTimestamp.toDate();
                            final existing = patientAppts[patientId];
                            if (existing == null) {
                              patientAppts[patientId] = apptDate;
                            } else {
                              final now = DateTime.now();
                              // Prioritize the earliest future appointment. If none, latest past.
                              if (apptDate.isAfter(now)) {
                                if (existing.isBefore(now) ||
                                    apptDate.isBefore(existing)) {
                                  patientAppts[patientId] = apptDate;
                                }
                              } else {
                                if (existing.isBefore(now) &&
                                    apptDate.isAfter(existing)) {
                                  patientAppts[patientId] = apptDate;
                                }
                              }
                            }
                          }
                        }
                      }

                      if (patientIds.isEmpty) {
                        return Center(
                          child: Text(
                            'No patients yet.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final patientList = patientIds.toList();

                      // Resolve patient profiles (users or patients collections) in parallel
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: Future.wait(
                          patientList.map((patientId) async {
                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .get();
                              if (doc.exists && doc.data() != null) {
                                final data = doc.data()!;
                                return {
                                  'id': patientId,
                                  'name': data['name'] ?? 'Unknown',
                                  'email': data['email'] ?? '',
                                  'age': data['age'] ?? 0,
                                  'appointmentDate': patientAppts[patientId],
                                };
                              }
                            } catch (_) {}

                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('patients')
                                  .doc(patientId)
                                  .get();
                              if (doc.exists && doc.data() != null) {
                                final data = doc.data()!;
                                return {
                                  'id': patientId,
                                  'name': data['name'] ?? 'Unknown',
                                  'email': '',
                                  'age': 0,
                                  'appointmentDate': patientAppts[patientId],
                                };
                              }
                            } catch (_) {}

                            return {
                              'id': patientId,
                              'name': 'Unknown',
                              'email': '',
                              'age': 0,
                              'appointmentDate': patientAppts[patientId],
                            };
                          }),
                        ),
                        builder: (context, patientsSnap) {
                          if (patientsSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            );
                          }
                          if (patientsSnap.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${patientsSnap.error}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          final patients = patientsSnap.data ?? [];
                          final filteredPatients = patients.where((p) {
                            final name = p['name'].toString().toLowerCase();
                            final email = p['email'].toString().toLowerCase();
                            final query = _searchQuery.toLowerCase();
                            return name.contains(query) ||
                                email.contains(query);
                          }).toList();

                          if (filteredPatients.isEmpty) {
                            return Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No patients yet.'
                                    : 'No patients found matching "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          // Sort patients by priority: upcoming appointments first, sorted ascending by date (who comes first)
                          filteredPatients.sort((a, b) {
                            final DateTime? dateA = a['appointmentDate'];
                            final DateTime? dateB = b['appointmentDate'];
                            final now = DateTime.now();
                            if (dateA == null && dateB == null) return 0;
                            if (dateA == null) return 1;
                            if (dateB == null) return -1;

                            final isAUpcoming = dateA.isAfter(now);
                            final isBUpcoming = dateB.isAfter(now);
                            if (isAUpcoming && !isBUpcoming) return -1;
                            if (!isAUpcoming && isBUpcoming) return 1;

                            if (isAUpcoming) {
                              return dateA.compareTo(dateB);
                            } else {
                              return dateB.compareTo(dateA);
                            }
                          });

                          // Find the next upcoming appointment among all resolved patients for banner
                          Map<String, dynamic>? nextApptPatient;
                          final now = DateTime.now();
                          for (var p in patients) {
                            final date = p['appointmentDate'] as DateTime?;
                            if (date != null && date.isAfter(now)) {
                              if (nextApptPatient == null ||
                                  date.isBefore(
                                    nextApptPatient['appointmentDate'],
                                  )) {
                                nextApptPatient = p;
                              }
                            }
                          }

                          final theme = Theme.of(context);

                          return Column(
                            children: [
                              if (nextApptPatient != null) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.05,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active,
                                          color: theme.colorScheme.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Next Upcoming Appointment",
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${nextApptPatient['name']} is scheduled for review",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${nextApptPatient['appointmentDate'].day}/${nextApptPatient['appointmentDate'].month}/${nextApptPatient['appointmentDate'].year} at ${_formatTime(nextApptPatient['appointmentDate'])}",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.6),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    100,
                                  ),
                                  itemCount: filteredPatients.length,
                                  itemBuilder: (context, index) {
                                    final patient = filteredPatients[index];
                                    return _buildPatientCard(patient);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

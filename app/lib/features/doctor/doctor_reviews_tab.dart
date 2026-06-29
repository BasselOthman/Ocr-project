import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../common/widgets/glass_card.dart';

class DoctorReviewsTab extends StatefulWidget {
  final String initialStatus;

  const DoctorReviewsTab({super.key, this.initialStatus = 'pending'});

  @override
  State<DoctorReviewsTab> createState() => _DoctorReviewsTabState();
}

class _DoctorReviewsTabState extends State<DoctorReviewsTab> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(DoctorReviewsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _selectedStatus = widget.initialStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);

    if (user == null) {
      return Center(
        child: Text("Not authenticated", style: TextStyle(color: textColor)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reviews',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                _buildToggle(theme, textColor, hintColor),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('reports')
                        .where('assignedDoctorId', isEqualTo: user.uid)
                        .where(
                          'doctorReviewStatus',
                          isEqualTo: _selectedStatus == 'completed'
                              ? 'reviewed'
                              : _selectedStatus,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            _selectedStatus == 'pending'
                                ? 'No pending reviews.'
                                : 'No completed reviews.',
                            style: TextStyle(color: hintColor, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var report =
                              docs[index].data() as Map<String, dynamic>;
                          String patientId =
                              docs[index].reference.parent.parent?.id ?? '';
                          String reportId = docs[index].id;
                          return _buildReportItem(
                            report,
                            patientId,
                            reportId,
                            user,
                            theme,
                            textColor,
                            hintColor,
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

  Widget _buildToggle(ThemeData theme, Color textColor, Color hintColor) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                'Pending',
                'pending',
                theme,
                textColor,
                hintColor,
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                'Completed',
                'completed',
                theme,
                textColor,
                hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    String status,
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    bool isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : hintColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(
    Map<String, dynamic> report,
    String patientId,
    String reportId,
    User? user,
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final status = report['doctorReviewStatus'] ?? 'pending';
    final createdAt = report['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy - HH:mm').format(createdAt.toDate())
        : 'Unknown Date';

    return FutureBuilder<DocumentSnapshot>(
      future: () async {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();
          if (userDoc.exists) return userDoc;
        } catch (_) {}
        return FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get();
      }(),
      builder: (context, userSnap) {
        String patientName = report['patientName'] ?? 'Unknown';
        if (userSnap.hasData && userSnap.data!.exists) {
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('name')) {
            patientName = userData['name'];
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/doctor/patient_review',
                arguments: {
                  'reportRef': FirebaseFirestore.instance
                      .collection('patients')
                      .doc(patientId)
                      .collection('reports')
                      .doc(reportId),
                  'patientName': patientName,
                  'reportData': report,
                  'doctorName': user?.displayName ?? 'Doctor',
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'pending'
                          ? Colors.orangeAccent.withValues(alpha: 0.2)
                          : Colors.greenAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      status == 'pending'
                          ? Icons.pending_actions
                          : Icons.check_circle_outline,
                      color: status == 'pending'
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Patient: $patientName",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(color: hintColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: hintColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

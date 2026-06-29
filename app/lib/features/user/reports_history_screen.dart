import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';
import '../../routes/app_routes.dart';
import '../../l10n/app_localizations.dart';

class ReportsHistoryScreen extends StatefulWidget {
  const ReportsHistoryScreen({super.key});

  @override
  State<ReportsHistoryScreen> createState() => _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState extends State<ReportsHistoryScreen> {
  Future<void> _deleteReport(String documentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteReport,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteReport,
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: textColor.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .collection('reports')
            .doc(documentId)
            .delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.reportDeletedSuccess,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.failedToDelete} $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.labResults,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: user == null
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.pleaseLogIn,
                      style: TextStyle(color: textColor),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('patients')
                        .doc(user.uid)
                        .collection('reports')
                        .orderBy('createdAt', descending: true)
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
                            AppLocalizations.of(context)!.errorFetchingHistory,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 80,
                                color: hintColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noLabResultsFound,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final docData = doc.data() as Map<String, dynamic>;
                          final createdAt = docData['createdAt'] != null
                              ? (docData['createdAt'] as Timestamp).toDate()
                              : DateTime.now();

                          String formattedDate =
                              "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
                          String formattedTime =
                              "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

                          final Map<String, dynamic>? rawPredictions =
                              docData['predictions'];
                          bool hasWarnings = false;
                          if (rawPredictions != null) {
                            rawPredictions.forEach((key, value) {
                              if (value['is_positive'] == true) {
                                hasWarnings = true;
                              }
                            });
                          }

                          List<Map<String, dynamic>> reconstructedResultsList =
                              [];
                          final Map<String, dynamic>? rawResultsMap =
                              docData['results'];
                          if (rawResultsMap != null) {
                            rawResultsMap.forEach((key, value) {
                              reconstructedResultsList.add({
                                'Test_Name_OCR': key,
                                'Value': value['value'],
                                'Unit': value['unit'],
                                'Reliability_Level': value['reliability'],
                                'Reference_Range': value['ref_range'],
                                'Flag': value['flag'],
                                'LOINC_Code': value['loinc_code'],
                                'Crop_Path': value['crop_path'],
                              });
                            });
                          }

                          // Displaying Date as Title, Time as Subtitle per user request
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedScaleButton(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.reportAnalysis,
                                  arguments: {
                                    'results': reconstructedResultsList,
                                    'predictions': rawPredictions ?? {},
                                    'explanation': docData['explanation'] ?? '',
                                    'explanation_en':
                                        docData['explanation_en'] ?? '',
                                    'explanation_ar':
                                        docData['explanation_ar'] ?? '',
                                    'doctorReviewStatus':
                                        docData['doctorReviewStatus'],
                                    'doctorReviewDecision':
                                        docData['doctorReviewDecision'],
                                    'doctorReviewNotes':
                                        docData['doctorReviewNotes'],
                                    'doctorReviewName':
                                        docData['doctorReviewName'],
                                    'doctorReviewModifiedDisease':
                                        docData['doctorReviewModifiedDisease'],
                                    'assignedDoctorId':
                                        docData['assignedDoctorId'],
                                  },
                                );
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 16,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_month,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "${AppLocalizations.of(context)!.timeLabel} $formattedTime",
                                            style: TextStyle(
                                              color: hintColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Icons
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                    if (hasWarnings) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.warning_rounded,
                                        size: 20,
                                        color: Colors.orangeAccent,
                                      ),
                                    ],

                                    const SizedBox(width: 8),

                                    // Delete Button
                                    IconButton(
                                      onPressed: () => _deleteReport(doc.id),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 22,
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      splashRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

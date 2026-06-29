import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/widgets/glass_card.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/biomarker_dictionary.dart';
import 'historical_trends_tab.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  List<String> _extractRecommendations(String explanation) {
    if (explanation.isEmpty) return [];

    // Attempt to specifically grab the recommendations section if it exists
    String rawText = explanation;
    if (explanation.toLowerCase().contains('recommendation')) {
      final splitParts = explanation.split(RegExp(r'(?i)recommendation[s]?'));
      if (splitParts.length > 1) {
        rawText = splitParts.last;
      }
    }

    List<String> guidelines = [];
    final lines = rawText.split('\n');
    for (var line in lines) {
      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        String cleaned = line.trim().substring(2).replaceAll('**', '').trim();

        // Filter out short/irrelevant lines like "Probability: 80%" or just numbers
        bool isIrrelevant =
            cleaned.length < 25 ||
            cleaned.toLowerCase().startsWith('probability') ||
            cleaned.toLowerCase().startsWith('score');

        if (!isIrrelevant) {
          guidelines.add(cleaned);
        }
      }
    }

    if (guidelines.isEmpty) {
      final sentences = rawText.split(RegExp(r'(?<=[.!?])\s+'));
      for (var s in sentences) {
        String cleaned = s.replaceAll('**', '').trim();
        bool isIrrelevant =
            cleaned.length < 25 ||
            cleaned.toLowerCase().startsWith('probability');
        if (!isIrrelevant && cleaned.length < 200) {
          guidelines.add(cleaned);
        }
      }
    }

    return guidelines.take(4).toList();
  }

  String _getTimeAgo(DateTime date, BuildContext context) {
    final difference = DateTime.now().difference(date);
    final l10n = AppLocalizations.of(context)!;
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${l10n.yearsAgo}';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${l10n.monthsAgo}';
    }
    if (difference.inDays > 1) return '${difference.inDays} ${l10n.daysAgo}';
    if (difference.inDays == 1) return l10n.oneDayAgo;
    if (difference.inHours > 0) return '${difference.inHours} ${l10n.hoursAgo}';
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${l10n.minutesAgo}';
    }
    return l10n.justNow;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$displayHour:$minute $amPm";
  }

  Future<String> _getDoctorName(String doctorId) async {
    if (doctorId.isEmpty) return 'Doctor';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'Doctor';
      }
    } catch (_) {}
    return 'Doctor';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.analyticsDashboard,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                          child: CircularProgressIndicator(color: primaryColor),
                        );
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.noDataScanFirst,
                            style: TextStyle(color: hintColor),
                          ),
                        );
                      }

                      final allDocs = snapshot.data!.docs;
                      final docData =
                          allDocs.first.data() as Map<String, dynamic>;

                      final createdAt = docData['createdAt'] != null
                          ? (docData['createdAt'] as Timestamp).toDate()
                          : DateTime.now();

                      final timeAgo = _getTimeAgo(createdAt, context);

                      // Find the next upcoming appointment date
                      DateTime? nextApptDate;
                      String? nextApptDocId;
                      final now = DateTime.now();
                      for (var doc in allDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final apptTimestamp =
                            data['appointmentDate'] as Timestamp?;
                        if (apptTimestamp != null) {
                          final date = apptTimestamp.toDate();
                          if (date.isAfter(now)) {
                            if (nextApptDate == null ||
                                date.isBefore(nextApptDate)) {
                              nextApptDate = date;
                              nextApptDocId = data['assignedDoctorId'];
                            }
                          }
                        }
                      }

                      // Process recommendations
                      final String legacyExplanation =
                          docData['explanation'] ?? '';
                      final String explanationEn =
                          docData['explanation_en'] ?? '';
                      final String explanationAr =
                          docData['explanation_ar'] ?? '';

                      String currentLang = Localizations.localeOf(
                        context,
                      ).languageCode;
                      String explanation = currentLang == 'ar'
                          ? explanationAr
                          : explanationEn;
                      if (explanation.isEmpty) explanation = legacyExplanation;

                      final recommendations = _extractRecommendations(
                        explanation,
                      );

                      // Process abnormal markers
                      List<String> abnormalMarkers = [];
                      final Map<String, dynamic>? rawResultsMap =
                          docData['results'];
                      if (rawResultsMap != null) {
                        rawResultsMap.forEach((key, value) {
                          final String flag =
                              value['flag']?.toString() ?? 'Unknown';
                          if (flag != 'Normal' &&
                              flag != 'Unknown' &&
                              flag.isNotEmpty &&
                              flag != '-') {
                            abnormalMarkers.add(key);
                          }
                        });
                      }

                      // Calculate simple progress gauge (score out of 100)
                      int totalTests = rawResultsMap?.length ?? 1;
                      if (totalTests == 0) totalTests = 1;
                      int healthyTests = totalTests - abnormalMarkers.length;
                      double healthScore = (healthyTests / totalTests) * 100;

                      final List<dynamic> topConcerns =
                          docData['top_concerns'] ?? [];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Data Last Synced
                            Center(
                              child: Text(
                                '${AppLocalizations.of(context)!.lastScan} $timeAgo',
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().fade().slideY(),

                            const SizedBox(height: 24),

                            // Next Upcoming Appointment Card "In Front"
                            if (nextApptDate != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: FutureBuilder<String>(
                                  future: _getDoctorName(nextApptDocId ?? ''),
                                  builder: (context, docNameSnap) {
                                    final docName =
                                        docNameSnap.data ?? 'Doctor';
                                    return GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.event_available_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "NEXT UPCOMING VISIT",
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "Review with Dr. $docName",
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${nextApptDate!.day}/${nextApptDate.month}/${nextApptDate.year} at ${_formatTime(nextApptDate)}",
                                                  style: TextStyle(
                                                    color: hintColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 2. Recommendations Bubbles
                            if (recommendations.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.aiRecommendations,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: recommendations.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                          width: 200,
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: theme
                                                      .scaffoldBackgroundColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    side: BorderSide(
                                                      color: theme.dividerColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                    ),
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .lightbulb_outline_rounded,
                                                        color: primaryColor,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.aiInsight,
                                                        style: TextStyle(
                                                          color: textColor,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    recommendations[index],
                                                    style: TextStyle(
                                                      color: hintColor,
                                                      fontSize: 15,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.close,
                                                        style: TextStyle(
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: GlassCard(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .lightbulb_outline_rounded,
                                                    color: primaryColor,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Expanded(
                                                    child: Text(
                                                      recommendations[index],
                                                      style: TextStyle(
                                                        color: textColor,
                                                        fontSize: 13,
                                                        height: 1.4,
                                                      ),
                                                      overflow:
                                                          TextOverflow.fade,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.tapToRead,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fade(delay: (index * 100).ms)
                                        .slideX(begin: 0.2);
                                  },
                                ),
                              ),
                            ] else if (explanation.isNotEmpty) ...[
                              // Fallback if we couldn't parse bullets but there IS an explanation
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.aiSummaryRecorded,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 32),

                            // 3. Progress Core Health
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.biomarkerStability,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: GlassCard(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CircularProgressIndicator(
                                            value: healthScore / 100,
                                            strokeWidth: 8,
                                            backgroundColor: theme.dividerColor
                                                .withValues(alpha: 0.1),
                                            color: healthScore > 80
                                                ? Colors.green
                                                : (healthScore > 50
                                                      ? Colors.orangeAccent
                                                      : Colors.redAccent),
                                          ),
                                          Center(
                                            child: Text(
                                              '${healthScore.toInt()}%',
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            healthScore > 80
                                                ? AppLocalizations.of(
                                                    context,
                                                  )!.excellentStatus
                                                : AppLocalizations.of(
                                                    context,
                                                  )!.needsAttention,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$healthyTests ${AppLocalizations.of(context)!.outOf} $totalTests ${AppLocalizations.of(context)!.trackedMarkersNormal}',
                                            style: TextStyle(
                                              color: hintColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade(duration: 500.ms).slideY(begin: 0.1),

                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoricalTrendsTab(
                                        patientId: user.uid,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.tealAccent,
                                        Colors.blueAccent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.tealAccent.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.show_chart,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "View Full History & Trends",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fade().slideY(),

                            const SizedBox(height: 32),

                            // 4. Top Concerns / Flagged Markers
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                "Top Concerns",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            (topConcerns.isEmpty && abnormalMarkers.isEmpty)
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.allMarkersNormal,
                                              style: TextStyle(
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    itemCount: topConcerns.isNotEmpty
                                        ? topConcerns.length
                                        : abnormalMarkers.length,
                                    itemBuilder: (context, index) {
                                      String testName = "";
                                      String severityLabel = "";
                                      Color severityColor = Colors.orangeAccent;

                                      if (topConcerns.isNotEmpty) {
                                        var concern = topConcerns[index];
                                        testName = concern['test'] ?? "";
                                        String sev =
                                            concern['severity'] ?? "High";
                                        severityLabel = sev;
                                        if (sev == "Critical") {
                                          severityColor = Colors.redAccent;
                                        }
                                        if (sev == "Moderate") {
                                          severityColor = Colors.yellowAccent;
                                        }
                                      } else {
                                        testName = abnormalMarkers[index];
                                      }

                                      return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                String lang =
                                                    Localizations.localeOf(
                                                      context,
                                                    ).languageCode;
                                                String definition =
                                                    BiomarkerDictionary.getDefinition(
                                                      testName,
                                                      lang,
                                                    );
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: theme
                                                        .scaffoldBackgroundColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: BorderSide(
                                                        color: theme
                                                            .dividerColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                      ),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.info_outline,
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          testName,
                                                          style: TextStyle(
                                                            color: textColor,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      definition,
                                                      style: TextStyle(
                                                        color: hintColor,
                                                        fontSize: 15,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx),
                                                        child: Text(
                                                          AppLocalizations.of(
                                                                context,
                                                              )!.close ??
                                                              "Close",
                                                          style: TextStyle(
                                                            color: primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: GlassCard(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: severityColor,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            testName,
                                                            style: TextStyle(
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          if (severityLabel
                                                              .isNotEmpty)
                                                            Text(
                                                              severityLabel,
                                                              style: TextStyle(
                                                                color:
                                                                    severityColor,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.touch_app,
                                                      size: 16,
                                                      color: hintColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                          .animate()
                                          .fade(delay: (index * 100).ms)
                                          .slideX(begin: -0.1);
                                    },
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

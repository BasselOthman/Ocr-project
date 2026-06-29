import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/biomarker_dictionary.dart';
import '../../core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/widgets/biomarker_trend_chart.dart';

class ReportAnalysis extends StatefulWidget {
  const ReportAnalysis({super.key});

  @override
  State<ReportAnalysis> createState() => _ReportAnalysisState();
}

class _ReportAnalysisState extends State<ReportAnalysis> {
  bool _loading = true;
  Map<String, dynamic>? _analysis;

  Color _getVerdictColor(String? decision) {
    if (decision == 'CONFIRM') return Colors.green;
    if (decision == 'REJECT') return Colors.red;
    if (decision == 'MODIFY') return Colors.orange;
    if (decision == 'REQUEST_TESTS') return Colors.deepPurpleAccent;
    return Colors.blue;
  }

  IconData _getVerdictIcon(String? decision) {
    if (decision == 'CONFIRM') return Icons.check_circle;
    if (decision == 'REJECT') return Icons.cancel;
    if (decision == 'MODIFY') return Icons.warning_rounded;
    if (decision == 'REQUEST_TESTS') return Icons.science;
    return Icons.info;
  }

  String _getVerdictTitle(String? decision, String? doctorName) {
    String dr = doctorName ?? "Doctor";
    if (decision == 'CONFIRM') return "$dr confirmed the AI assessment";
    if (decision == 'REJECT') return "$dr dismissed the AI assessment";
    if (decision == 'MODIFY') return "$dr updated the assessment";
    if (decision == 'REQUEST_TESTS') return "$dr requested additional tests";
    return "$dr reviewed the report";
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _fetchAnalysis(args);
    });
  }

  Future<void> _fetchAnalysis(Map<String, dynamic>? args) async {
    setState(() {
      _loading = false;

      if (args != null && args['results'] != null) {
        List<dynamic> results = args['results'];

        List<Map<String, dynamic>> mappedValues = results.map((r) {
          return {
            'test': r['Test_Name_OCR'] ?? r['Test_Code'] ?? 'Unknown',
            'value': r['Value'] ?? '-',
            'unit': r['Unit'] ?? '',
            'status': (r['Flag'] == 'Unknown' || r['Flag'] == 'Normal')
                ? 'normal'
                : 'flagged',
            'ocr_warning': r['Reliability_Level'] != 'HIGH',
            'min': r['Reference_Range'] ?? '-',
            'max': '',
            'loinc_code':
                r['LOINC_Code'] ?? r['loinc_code'] ?? r['LOINC'] ?? r['loinc'],
            'crop_path': r['Crop_Path'] ?? r['crop_path'],
          };
        }).toList();

        Map<String, dynamic> rawPredictions = args['predictions'] ?? {};
        Map<String, dynamic> filteredPredictions = {};

        rawPredictions.forEach((key, value) {
          double prob = (value['probability'] ?? 0.0) * 100;
          if (prob >= 2.0) {
            filteredPredictions[key] = value;
          }
        });

        _analysis = {
          'summary': 'Extracted ${results.length} tests successfully.',
          'values': mappedValues,
          'predictions': filteredPredictions,
          'explanation': args['explanation'] ?? '',
          'explanation_en': args['explanation_en'] ?? '',
          'explanation_ar': args['explanation_ar'] ?? '',
          'doctorReviewStatus': args['doctorReviewStatus'],
          'doctorReviewDecision': args['doctorReviewDecision'],
          'doctorReviewNotes': args['doctorReviewNotes'],
          'doctorReviewPrescription': args['doctorReviewPrescription'],
          'doctorReviewRequestedTests':
              args['doctorReviewRequestedTests'] ?? [],
          'doctorReviewName': args['doctorReviewName'],
          'doctorReviewModifiedDisease': args['doctorReviewModifiedDisease'],
          'assignedDoctorId': args['assignedDoctorId'],
        };

        final docName = _analysis!['doctorReviewName']?.toString();
        final docId = _analysis!['assignedDoctorId']?.toString();
        if (docId != null &&
            docId.isNotEmpty &&
            (docName == null ||
                docName == 'Doctor' ||
                docName == 'Dr. Doctor' ||
                docName.isEmpty)) {
          _fetchDoctorNameForPatient(docId);
        }
      } else {
        _analysis = {
          'summary': AppLocalizations.of(context)!.noResultsReceived,
          'values': [],
        };
      }
    });
  }

  void _fetchDoctorNameForPatient(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _analysis!['doctorReviewName'] = "Dr. ${data['name']}";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor name for patient: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final textMuted = textColor?.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.reportAnalysis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- PENDING / MISSING TESTS WARNING BANNER ---
                    if (_analysis!['doctorReviewDecision'] == 'REQUEST_TESTS' &&
                        (_analysis!['doctorReviewRequestedTests'] as List)
                            .isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "⚠️ ACTION REQUIRED",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Your doctor has requested additional lab tests to complete your clinical assessment. Please submit results for the following:",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...(_analysis!['doctorReviewRequestedTests']
                                    as List)
                                .map(
                                  (test) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_box_outline_blank,
                                          color: textMuted,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            test.toString(),
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.1, end: 0),
                    ],

                    // Doctor Verdict Card or Awaiting Review Warning
                    if (_analysis!['doctorReviewStatus'] == 'reviewed') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: _getVerdictColor(
                                      _analysis!['doctorReviewDecision'],
                                    ).withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                          border: Border.all(
                            color: _getVerdictColor(
                              _analysis!['doctorReviewDecision'],
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getVerdictIcon(
                                    _analysis!['doctorReviewDecision'],
                                  ),
                                  color: _getVerdictColor(
                                    _analysis!['doctorReviewDecision'],
                                  ),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getVerdictTitle(
                                      _analysis!['doctorReviewDecision'],
                                      _analysis!['doctorReviewName'],
                                    ),
                                    style: TextStyle(
                                      color: _getVerdictColor(
                                        _analysis!['doctorReviewDecision'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_analysis!['doctorReviewDecision'] ==
                                'MODIFY') ...[
                              Text(
                                "Updated Assessment: ${_analysis!['doctorReviewModifiedDisease']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_analysis!['doctorReviewNotes'] != null &&
                                _analysis!['doctorReviewNotes']
                                    .toString()
                                    .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _analysis!['doctorReviewNotes'],
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 15,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (_analysis!['doctorReviewPrescription'] !=
                                    null &&
                                _analysis!['doctorReviewPrescription']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.withValues(alpha: 0.1),
                                      Colors.teal.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.teal.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.medication,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Prescribed Medication",
                                          style: TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _analysis!['doctorReviewPrescription'],
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        height: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.1, end: 0),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.awaitingDoctorReview,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.aiAnalysisWarning,
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.1, end: 0),
                    ],

                    // ML Predictions Row (Gauges)
                    if (_analysis!['predictions'] != null &&
                        (_analysis!['predictions'] as Map).isNotEmpty)
                      Builder(
                        builder: (context) {
                          var sortedPredictions =
                              (_analysis!['predictions']
                                      as Map<String, dynamic>)
                                  .entries
                                  .toList()
                                ..sort(
                                  (a, b) => (b.value['probability'] as num)
                                      .compareTo(a.value['probability'] as num),
                                );
                          return SizedBox(
                            height: 240,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: sortedPredictions.length,
                              itemBuilder: (context, index) {
                                var entry = sortedPredictions[index];
                                String key = entry.key;
                                var pred = entry.value;
                                bool isRisk = pred['is_positive'] == true;
                                double prob = (pred['probability'] as num)
                                    .toDouble(); // 0.0 to 1.0

                                Color gaugeColor = isRisk
                                    ? Colors.redAccent
                                    : Colors.green;

                                return GestureDetector(
                                      onTap: () {
                                        final patientId =
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid ??
                                            '';
                                        _showDiseaseDetailsDialog(
                                          context,
                                          key,
                                          pred,
                                          patientId,
                                        );
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          width: 160,
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                            bottom: 20,
                                            top: 10,
                                          ), // Shadow margin
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: theme.dividerColor
                                                  .withValues(alpha: 0.1),
                                            ),
                                            boxShadow: isDark
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      blurRadius: 15,
                                                      offset: const Offset(
                                                        0,
                                                        8,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                key
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: textMuted,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              CircularPercentIndicator(
                                                radius: 40.0,
                                                lineWidth: 8.0,
                                                animation: true,
                                                percent: prob.clamp(0.0, 1.0),
                                                center: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4.0,
                                                        ),
                                                    child: Text(
                                                      "${(prob * 100).toInt()}%",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                circularStrokeCap:
                                                    CircularStrokeCap.round,
                                                progressColor: gaugeColor,
                                                backgroundColor: gaugeColor
                                                    .withValues(alpha: 0.15),
                                              ),
                                              const Spacer(),
                                              Text(
                                                isRisk
                                                    ? AppLocalizations.of(
                                                        context,
                                                      )!.needsReview
                                                    : AppLocalizations.of(
                                                        context,
                                                      )!.highlyAccurate,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isRisk
                                                      ? Colors.redAccent
                                                      : textMuted,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isRisk &&
                                                  pred['drivers'] != null) ...[
                                                const SizedBox(height: 6),
                                                ...((pred['drivers']
                                                        as Map<String, dynamic>)
                                                    .entries
                                                    .take(2)
                                                    .map(
                                                      (e) => Text(
                                                        "${e.key.toUpperCase()} +${(e.value * 100).toStringAsFixed(0)}%",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: textMuted,
                                                        ),
                                                      ),
                                                    )),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fade(
                                      duration: 500.ms,
                                      delay: (100 * index).ms,
                                    )
                                    .slideY(begin: 0.2, end: 0);
                              },
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.detectedValues,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Values List
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: (_analysis!['values'] as List).length,
                      itemBuilder: (context, i) {
                        final v =
                            (_analysis!['values'] as List)[i]
                                as Map<String, dynamic>;

                        String refRangeText = '${v['min']}${v['max']}';
                        Color statusColor = v['status'] == 'normal'
                            ? Colors.green
                            : Colors.redAccent;
                        String statusText = v['status'] == 'normal'
                            ? AppLocalizations.of(context)!.normalStatus
                            : AppLocalizations.of(context)!.flaggedStatus;

                        return GestureDetector(
                              onTap: () => _showLabDetailsDialog(
                                context,
                                v,
                                theme,
                                textColor,
                                textMuted,
                                isDark,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${v['test']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${v['value']} ${v['unit']}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '${AppLocalizations.of(context)!.refRange} $refRangeText',
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if ((v['loinc_code'] ?? v['LOINC_Code']) !=
                                            null &&
                                        (v['loinc_code'] ?? v['LOINC_Code'])
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "LOINC: ${v['loinc_code'] ?? v['LOINC_Code']}",
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fade(duration: 400.ms, delay: (50 * i).ms)
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),
                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
      ),
      floatingActionButton: () {
        if (_analysis == null) return null;
        String currentLang = Localizations.localeOf(context).languageCode;
        String currentExplanation = currentLang == 'ar'
            ? (_analysis!['explanation_ar'] ?? '')
            : (_analysis!['explanation_en'] ?? '');
        if (currentExplanation.isEmpty) {
          currentExplanation = _analysis!['explanation'] ?? '';
        }

        if (currentExplanation.isNotEmpty) {
          return FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.aiClinicalSummary,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Markdown(
                          data: currentExplanation,
                          styleSheet: MarkdownStyleSheet(
                            h1: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            h2: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            h3: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textMuted,
                            ),
                            p: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              height: 1.5,
                            ),
                            listBullet: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            backgroundColor: theme.colorScheme.primary,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              AppLocalizations.of(context)!.readSummary,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        return null;
      }(),
    );
  }

  void _showLabDetailsDialog(
    BuildContext context,
    Map<String, dynamic> v,
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    String lang = Localizations.localeOf(context).languageCode;
    String definition = BiomarkerDictionary.getDefinition(v['test'], lang);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            v['test'],
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          definition,
                          style: TextStyle(color: textColor, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Value: ${v['value']} ${v['unit']}",
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                Text(
                  "Ref: ${v['min'] ?? '-'}",
                  style: TextStyle(color: textMuted),
                ),
                const SizedBox(height: 16),
                if (v['crop_path'] != null &&
                    v['crop_path'].toString().isNotEmpty) ...[
                  Text(
                    "Source Evidence: (Pinch/drag to zoom)",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 120,
                      width: MediaQuery.of(context).size.width,
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          "${ApiService.baseUrl}/${v['crop_path']}",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[200],
                                child: Center(
                                  child: Text(
                                    "Image not available.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: textMuted),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDiseaseDetailsDialog(
    BuildContext context,
    String diseaseName,
    Map<String, dynamic> diseaseData,
    String patientId,
  ) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withOpacity(0.6);
    final isDark = theme.brightness == Brightness.dark;

    final driversMap = diseaseData['drivers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseName.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: hintColor,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: "Trends"),
                    Tab(text: "Current Values"),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: TabBarView(
                children: [
                  // Slide 1: Trends
                  driversMap.isEmpty
                      ? const Center(
                          child: Text(
                            "No biomarker trends available for this disease.",
                          ),
                        )
                      : _buildTrendsSlide(patientId, driversMap, theme),

                  // Slide 2: Normal Extracted Values
                  _buildCurrentValuesSlide(
                    driversMap,
                    _analysis!['values'] as List<dynamic>? ?? [],
                    theme,
                    textColor,
                    hintColor,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Close",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsSlide(
    String patientId,
    Map<String, dynamic> driversMap,
    ThemeData theme,
  ) {
    final driverNames = driversMap.keys.toList();
    return PageView.builder(
      itemCount: driverNames.length,
      itemBuilder: (context, index) {
        final biomarker = driverNames[index].toUpperCase();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "$biomarker Trend (${index + 1}/${driverNames.length})",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: BiomarkerTrendChart(
                patientId: patientId,
                biomarkerName: biomarker,
                lineColor: theme.colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentValuesSlide(
    Map<String, dynamic> driversMap,
    List<dynamic> valuesList,
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final driverNames = driversMap.keys.toList();
    return ListView.builder(
      itemCount: driverNames.length,
      itemBuilder: (context, index) {
        final key = driverNames[index].toUpperCase();
        final valData = valuesList.firstWhere(
          (v) => v['test'].toString().toUpperCase() == key,
          orElse: () => null,
        );

        final valStr = valData != null ? (valData['value'] ?? '-') : '-';
        final unitStr = valData != null ? (valData['unit'] ?? '') : '';
        final statusStr = valData != null
            ? (valData['status'] ?? 'normal')
            : 'normal';
        final isNormal = statusStr == 'normal';
        final flagColor = isNormal ? Colors.green : Colors.redAccent;

        return Card(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Risk Contribution: ${(driversMap[driverNames[index]] * 100).toStringAsFixed(1)}%",
                      style: TextStyle(color: hintColor, fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$valStr $unitStr",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNormal ? "Normal" : "Flagged",
                      style: TextStyle(
                        color: flagColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

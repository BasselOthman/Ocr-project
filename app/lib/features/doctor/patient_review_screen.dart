import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../common/widgets/animated_scale_button.dart';
import '../common/widgets/glass_card.dart';
import 'generate_report_service.dart';
import 'package:printing/printing.dart';
import '../common/widgets/biomarker_trend_chart.dart';
import '../../core/services/api_service.dart';

class PatientReviewScreen extends StatefulWidget {
  const PatientReviewScreen({super.key});

  @override
  State<PatientReviewScreen> createState() => _PatientReviewScreenState();
}

class _PatientReviewScreenState extends State<PatientReviewScreen> {
  late DocumentReference reportRef;
  late String patientName;
  late Map<String, dynamic> reportData;
  late String doctorName;

  String? _selectedDecision;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _modifiedDiseaseController =
      TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  List<String> _selectedTestsToRequest = [];
  bool _isSaving = false;
  Set<String> _historicallyChangedBiomarkers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      reportRef = args['reportRef'];
      patientName = args['patientName'];
      reportData = args['reportData'];
      doctorName = args['doctorName'] ?? 'Doctor';

      // Load existing review if present
      if (reportData['doctorReviewStatus'] == 'reviewed') {
        _selectedDecision = reportData['doctorReviewDecision'];
        _notesController.text = reportData['doctorReviewNotes'] ?? '';
        _modifiedDiseaseController.text =
            reportData['doctorReviewModifiedDisease'] ?? '';
        _prescriptionController.text =
            reportData['doctorReviewPrescription'] ?? '';
        if (reportData['doctorReviewRequestedTests'] != null) {
          _selectedTestsToRequest = List<String>.from(
            reportData['doctorReviewRequestedTests'],
          );
        }
      }

      _fetchDoctorName();
      _fetchHistoricalReports(reportRef.parent.parent!.id);
    }
  }

  void _fetchDoctorName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            if (mounted) {
              setState(() {
                doctorName = data['name'];
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching doctor name: $e");
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _modifiedDiseaseController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  void _saveReview() async {
    if (_selectedDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Confirm, Modify, or Reject.'),
        ),
      );
      return;
    }
    if (_selectedDecision == 'MODIFY' &&
        _modifiedDiseaseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the modified assessment.')),
      );
      return;
    }

    if (_selectedDecision == 'REQUEST_TESTS' &&
        _selectedTestsToRequest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one test to request.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await reportRef.update({
        'doctorReviewStatus': 'reviewed',
        'doctorReviewDecision': _selectedDecision,
        'doctorReviewNotes': _notesController.text.trim(),
        'doctorReviewModifiedDisease': _modifiedDiseaseController.text.trim(),
        'doctorReviewPrescription': _prescriptionController.text.trim(),
        'doctorReviewRequestedTests': _selectedDecision == 'REQUEST_TESTS'
            ? _selectedTestsToRequest
            : [],
        'doctorReviewName': "Dr. $doctorName",
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          "Patient Review",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
            onPressed: () async {
              if (_selectedDecision == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please make a decision first before generating the PDF.',
                    ),
                  ),
                );
                return;
              }
              final pdfBytes = await GenerateReportService.generateAndPrintPdf(
                patientName: patientName,
                doctorName: doctorName,
                reportData: reportData,
                decision: _selectedDecision!,
                modifiedDisease: _modifiedDiseaseController.text,
                notes: _notesController.text,
                requestedTests: _selectedDecision == 'REQUEST_TESTS'
                    ? _selectedTestsToRequest
                    : [],
                prescription: _prescriptionController.text.trim(),
              );

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          'Report Preview',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      body: PdfPreview(
                        build: (format) => pdfBytes,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient Card
              _buildPatientInfoCard(theme, textColor),
              const SizedBox(height: 24),

              // Action Required: AI Assessment Review
              _buildAssessmentReviewCard(theme, textColor, textMuted, isDark),
              const SizedBox(height: 24),

              // Top Concerns Panel
              _buildTopConcernsCard(theme, textColor, textMuted, isDark),

              // AI Clinical Summary
              _buildClinicalSummaryCard(theme, textColor, textMuted, isDark),
              const SizedBox(height: 24),

              Text(
                "Lab Values",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildLabValuesList(theme, textColor, textMuted, isDark),
              const SizedBox(height: 24),

              // Follow-Up Planner
              _buildFollowUpPlanner(theme, textColor, textMuted, isDark),

              const SizedBox(height: 100), // Padding
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveReview,
        backgroundColor: theme.colorScheme.primary,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: const Text(
          "Save Review",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(ThemeData theme, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            patientName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: textColor,
            ),
          ),
        ],
      ),
    ).animate().fade().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAssessmentReviewCard(
    ThemeData theme,
    Color? rawTextColor,
    Color? rawTextMuted,
    bool isDark,
  ) {
    final Color textColor =
        rawTextColor ?? (isDark ? Colors.white : Colors.black);
    final Color textMuted =
        rawTextMuted ?? (isDark ? Colors.white70 : Colors.black54);

    // Safely cast predictions map
    final Map<String, dynamic> predictions = {};
    if (reportData['predictions'] is Map) {
      (reportData['predictions'] as Map).forEach((k, v) {
        if (v is Map) {
          predictions[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
    }

    // Sort and get highest probability
    String primaryDisease = "Unknown";
    String originalDiseaseKey = "";
    double highestProb = 0.0;

    predictions.forEach((key, val) {
      final probVal = val['probability'];
      double prob = 0.0;
      if (probVal is num) {
        prob = probVal.toDouble();
      } else if (probVal is String) {
        prob = double.tryParse(probVal) ?? 0.0;
      }
      if (prob > highestProb) {
        highestProb = prob;
        primaryDisease = key;
        originalDiseaseKey = key;
      }
    });

    primaryDisease = primaryDisease.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "AI Assessment",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (highestProb > 0.05) ...[
            Text(
              "Highest Probability:",
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                final patientId = reportRef.parent.parent!.id;
                _showDiseaseDetailsDialog(
                  context,
                  originalDiseaseKey,
                  predictions[originalDiseaseKey],
                  patientId,
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        primaryDisease,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    Text(
                      "${(highestProb * 100).toInt()}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (originalDiseaseKey.isNotEmpty &&
                predictions[originalDiseaseKey]['drivers'] != null) ...[
              const SizedBox(height: 16),
              Text(
                "Key Risk Drivers:",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...() {
                final driversMap = predictions[originalDiseaseKey]['drivers'];
                if (driversMap is Map) {
                  return driversMap.entries.map((e) {
                    final contribVal = e.value;
                    double contrib = 0.0;
                    if (contribVal is num) {
                      contrib = contribVal.toDouble();
                    } else if (contribVal is String) {
                      contrib = double.tryParse(contribVal) ?? 0.0;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${e.key.toString().toUpperCase()} contribution: ${(contrib * 100).toStringAsFixed(1)}%",
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }
                return <Widget>[];
              }(),
            ],
          ] else ...[
            const Text(
              "AI indicates normal results. No major disease probabilities detected.",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          // Show other disease predictions if they exist
          if (predictions.length > 1) ...[
            const SizedBox(height: 20),
            Text(
              "Other Disease Probabilities:",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: predictions.entries
                  .where((e) => e.key != originalDiseaseKey)
                  .map((e) {
                    final probVal = e.value['probability'];
                    double prob = 0.0;
                    if (probVal is num) {
                      prob = probVal.toDouble();
                    } else if (probVal is String) {
                      prob = double.tryParse(probVal) ?? 0.0;
                    }
                    return GestureDetector(
                      onTap: () {
                        final patientId = reportRef.parent.parent!.id;
                        _showDiseaseDetailsDialog(
                          context,
                          e.key,
                          e.value,
                          patientId,
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${e.key.replaceAll('_', ' ').toUpperCase()}: ${(prob * 100).toInt()}%",
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Your Decision:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Toggle Buttons
          Row(
            children: [
              _buildDecisionButton(
                'CONFIRM',
                'Confirm',
                Icons.check_circle,
                Colors.green,
                theme,
                isDark,
              ),
              const SizedBox(width: 8),
              _buildDecisionButton(
                'MODIFY',
                'Modify',
                Icons.warning_rounded,
                Colors.orange,
                theme,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDecisionButton(
                'REJECT',
                'Reject',
                Icons.cancel,
                Colors.redAccent,
                theme,
                isDark,
              ),
              const SizedBox(width: 8),
              _buildDecisionButton(
                'REQUEST_TESTS',
                'Request Tests',
                Icons.science,
                Colors.deepPurpleAccent,
                theme,
                isDark,
              ),
            ],
          ),

          if (_selectedDecision == 'MODIFY') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _modifiedDiseaseController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Modified Assessment",
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          if (_selectedDecision == 'REQUEST_TESTS') ...[
            const SizedBox(height: 16),
            _buildTestRequestSelector(theme, textColor, textMuted, isDark),
          ],

          const SizedBox(height: 24),
          Text(
            "Medicine Prescription (visible to patient):",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prescriptionController,
            maxLines: 2,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "e.g., Metformin 500mg once daily.",
              hintStyle: TextStyle(color: textMuted),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            "Clinical Notes (visible to patient):",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText:
                  "e.g., Continue current lifestyle changes. Reassess in 3 months.",
              hintStyle: TextStyle(color: textMuted),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildDecisionButton(
    String value,
    String label,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isDark,
  ) {
    bool isSelected = _selectedDecision == value;
    Color defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[100]!;
    Color defaultBorder = isDark
        ? theme.dividerColor.withValues(alpha: 0.1)
        : Colors.grey[300]!;

    return Expanded(
      child: AnimatedScaleButton(
        onTap: () => setState(() => _selectedDecision = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : defaultBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : defaultBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : theme.iconTheme.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : theme.textTheme.bodyLarge?.color?.withValues(
                          alpha: 0.7,
                        ),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestRequestSelector(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    final allAvailableTests = [
      "Hemoglobin (HGB)",
      "Hematocrit (HCT)",
      "Red Blood Cells (RBC)",
      "White Blood Cells (WBC)",
      "Platelets (PLT)",
      "Thyroid Stimulating Hormone (TSH)",
      "Free T4 (FT4)",
      "Random Blood Glucose (GLU)",
      "Fasting Blood Glucose (FBS)",
      "Hemoglobin A1c (HbA1c)",
      "Creatinine",
      "Urea",
      "Uric Acid",
      "ALT (SGPT)",
      "AST (SGOT)",
      "Total Bilirubin",
      "Direct Bilirubin",
      "Indirect Bilirubin",
      "Alkaline Phosphatase (ALP)",
      "GGT",
      "LDL Cholesterol",
      "HDL Cholesterol",
      "Triglycerides",
      "eGFR",
      "HBsAg",
      "HCV Ab",
      "HIV",
    ];

    final doneTests =
        (reportData['results'] as Map<String, dynamic>?)?.keys
            .map((k) => k.toLowerCase())
            .toList() ??
        [];

    final filterableTests = allAvailableTests.where((test) {
      final lowerTest = test.toLowerCase();
      final match = RegExp(r'\((.*?)\)').firstMatch(lowerTest);
      final code = match?.group(1);

      bool isDone = doneTests.any(
        (done) =>
            lowerTest.contains(done) ||
            done.contains(lowerTest) ||
            (code != null && (done.contains(code) || code.contains(done))),
      );
      return !isDone;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.deepPurpleAccent.withValues(alpha: 0.05)
            : Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science,
                color: Colors.deepPurpleAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Select Tests to Request:",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filterableTests.isEmpty)
            Text(
              "All standard tests have already been performed.",
              style: TextStyle(color: textMuted, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filterableTests.map((test) {
                bool isSelected = _selectedTestsToRequest.contains(test);
                return FilterChip(
                  label: Text(
                    test,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.deepPurpleAccent,
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTestsToRequest.add(test);
                      } else {
                        _selectedTestsToRequest.remove(test);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClinicalSummaryCard(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    final String currentLang =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    String summary = currentLang == 'ar'
        ? (reportData['clinical_summary_ar'] ??
              reportData['explanation_ar'] ??
              '')
        : (reportData['clinical_summary_en'] ??
              reportData['explanation_en'] ??
              '');
    if (summary.isEmpty) {
      summary =
          reportData['explanation_en'] ??
          reportData['explanation'] ??
          "No summary generated.";
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "AI Clinical Summary",
              style: TextStyle(color: textColor),
            ),
            backgroundColor: theme.colorScheme.surface,
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: summary,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    h2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    h3: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                    ),
                    p: TextStyle(fontSize: 14, color: textColor, height: 1.5),
                    listBullet: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "AI Clinical Summary",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.open_in_full, size: 16, color: textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              // Clean simple preview striping basic markdown characters for readability
              summary
                  .replaceAll(RegExp(r'[#*`\-_]+'), ' ')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
              style: TextStyle(color: textMuted, height: 1.5, fontSize: 14),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to read full summary",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLabValuesList(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    Map<String, dynamic> resultsMap = reportData['results'] ?? {};
    if (resultsMap.isEmpty) {
      return Text(
        "No lab results available.",
        style: TextStyle(color: textMuted),
      );
    }

    List<Widget> items = [];
    resultsMap.forEach((testName, val) {
      String status = val['flag'] ?? 'Normal';
      bool isNormal =
          status.toLowerCase() == 'normal' || status.toLowerCase() == 'unknown';

      // We will parse reference ranges to find real highs/lows if necessary, but assuming standard flag logic:
      Color statusColor = Colors.green;
      IconData statusIcon = Icons.check_circle;
      if (!isNormal) {
        statusColor = status.toLowerCase().contains('high')
            ? Colors.redAccent
            : Colors.orange;
        statusIcon = status.toLowerCase().contains('high')
            ? Icons.arrow_upward
            : Icons.arrow_downward;
      }

      items.add(
        GestureDetector(
          onTap: () {
            _showLabDetailsDialog(
              context,
              testName,
              val,
              theme,
              textColor,
              textMuted,
              isDark,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNormal
                    ? theme.dividerColor.withValues(alpha: 0.1)
                    : statusColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ref: ${val['ref_range'] ?? '-'}",
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                      if ((val['loinc_code'] ??
                                  val['LOINC_Code'] ??
                                  val['loinc'] ??
                                  val['LOINC']) !=
                              null &&
                          (val['loinc_code'] ??
                                  val['LOINC_Code'] ??
                                  val['loinc'] ??
                                  val['LOINC'])
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "LOINC: ${val['loinc_code'] ?? val['LOINC_Code'] ?? val['loinc'] ?? val['LOINC']}",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${val['value']} ${val['unit']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isNormal ? textColor : statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_historicallyChangedBiomarkers.contains(
                      testName.toUpperCase(),
                    ))
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.scaffoldBackgroundColor,
                              title: Text(
                                "$testName History",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 350,
                                child: BiomarkerTrendChart(
                                  patientId: reportRef.parent.parent!.id,
                                  biomarkerName: testName,
                                  lineColor: statusColor,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    "Close",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_graph,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Trend",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Column(children: items).animate().fade(delay: 300.ms);
  }

  void _showLabDetailsDialog(
    BuildContext context,
    String testName,
    Map<String, dynamic> val,
    ThemeData theme,
    Color? rawTextColor,
    Color? rawTextMuted,
    bool isDark,
  ) {
    final Color textColor =
        rawTextColor ?? (isDark ? Colors.white : Colors.black);
    final Color textMuted =
        rawTextMuted ?? (isDark ? Colors.white70 : Colors.black54);

    // Safely cast predictions map
    final Map<String, dynamic> predictions = {};
    if (reportData['predictions'] is Map) {
      (reportData['predictions'] as Map).forEach((k, v) {
        if (v is Map) {
          predictions[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
    }

    String primaryDisease = "Unknown";
    String originalDiseaseKey = "";
    double highestProb = 0.0;

    predictions.forEach((key, val) {
      final probVal = val['probability'];
      double prob = 0.0;
      if (probVal is num) {
        prob = probVal.toDouble();
      } else if (probVal is String) {
        prob = double.tryParse(probVal) ?? 0.0;
      }
      if (prob > highestProb) {
        highestProb = prob;
        primaryDisease = key;
        originalDiseaseKey = key;
      }
    });
    primaryDisease = primaryDisease.replaceAll('_', ' ').toUpperCase();

    // Determine if this test contributes to the primary disease prediction
    double? contribution;
    if (originalDiseaseKey.isNotEmpty &&
        predictions.containsKey(originalDiseaseKey)) {
      final diseaseData = predictions[originalDiseaseKey];
      if (diseaseData is Map && diseaseData.containsKey('drivers')) {
        final driversMap = diseaseData['drivers'];
        if (driversMap is Map) {
          final drivers = Map<String, dynamic>.from(driversMap);
          String normalizedTestName = testName.toLowerCase();
          drivers.forEach((key, value) {
            String normalizedKey = key.toLowerCase();
            if (normalizedKey.contains(normalizedTestName) ||
                normalizedTestName.contains(normalizedKey)) {
              contribution = double.tryParse(value.toString());
            }
            // specific overrides for common mappings
            if (normalizedTestName == 'glu' && normalizedKey == 'glucose') {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'hgb' && normalizedKey == 'hemoglobin') {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'hba1c' &&
                normalizedKey.contains('hemoglobin a1c')) {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'chol' &&
                normalizedKey.contains('cholesterol, total')) {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'ldl' &&
                normalizedKey.contains('cholesterol, ldl')) {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'hdl' &&
                normalizedKey.contains('cholesterol, hdl')) {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'creat' && normalizedKey == 'creatinine') {
              contribution = double.tryParse(value.toString());
            }
            if (normalizedTestName == 'tp' &&
                normalizedKey.contains('protein, total')) {
              contribution = double.tryParse(value.toString());
            }
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.biotech_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      testName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((val['loinc_code'] ??
                          val['LOINC_Code'] ??
                          val['loinc'] ??
                          val['LOINC']) !=
                      null &&
                  (val['loinc_code'] ??
                          val['LOINC_Code'] ??
                          val['loinc'] ??
                          val['LOINC'])
                      .toString()
                      .isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "LOINC: ${val['loinc_code'] ?? val['LOINC_Code'] ?? val['loinc'] ?? val['LOINC']}",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow(
                "Extracted Value",
                "${val['value']} ${val['unit'] ?? ''}",
                Icons.data_usage_rounded,
                textColor,
                textMuted,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                "Reference Range",
                val['ref_range']?.toString() ?? 'N/A',
                Icons.rule_rounded,
                textColor,
                textMuted,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                "Status",
                val['flag']?.toString() ?? 'Normal',
                Icons.flag_rounded,
                val['flag'] == 'High'
                    ? Colors.redAccent
                    : (val['flag'] == 'Low'
                          ? Colors.orangeAccent
                          : Colors.green),
                textMuted,
              ),

              if (contribution != null && contribution! > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Driver for $primaryDisease",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "This biomarker heavily influenced the AI's classification for $primaryDisease (Impact Score: ${contribution!.toStringAsFixed(4)}).",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if ((val['crop_path'] ?? val['Crop_Path']) != null &&
                  (val['crop_path'] ?? val['Crop_Path'])
                      .toString()
                      .isNotEmpty) ...[
                const SizedBox(height: 24),
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
                        "${ApiService.baseUrl}/${val['crop_path'] ?? val['Crop_Path']}",
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          padding: const EdgeInsets.all(16),
                          color: isDark ? Colors.white12 : Colors.grey[200],
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
              ] else ...[
                Text(
                  "No visual evidence available.",
                  style: TextStyle(
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: textMuted, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: textMuted, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConcernsCard(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    final List<dynamic> topConcerns = reportData['top_concerns'] ?? [];
    if (topConcerns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Critical Concerns",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: topConcerns.map<Widget>((concern) {
              String test = concern['test'] ?? "";
              String severity = concern['severity'] ?? "High";
              String val = concern['value'] ?? "";
              String unit = concern['unit'] ?? "";
              Color sevColor = severity == "Critical"
                  ? Colors.redAccent
                  : (severity == "High" ? Colors.orange : Colors.amber);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: sevColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        test,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$val $unit",
                          style: TextStyle(
                            color: sevColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          severity,
                          style: TextStyle(
                            color: sevColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ).animate().fade().slideX(begin: 0.1),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFollowUpPlanner(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Follow-Up Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showFollowUpDialog(theme, textColor, textMuted, isDark),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Schedule Follow-Up Retest",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Track patient outcome and compliance",
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ).animate().fade().slideY(begin: 0.1),
      ],
    );
  }

  void _showFollowUpDialog(
    ThemeData theme,
    Color? textColor,
    Color? textMuted,
    bool isDark,
  ) {
    List<String> selectedTests = [];
    final List<dynamic> topConcerns = reportData['top_concerns'] ?? [];
    List<String> availableTests = [];

    if (topConcerns.isNotEmpty) {
      for (var c in topConcerns) {
        availableTests.add(c['test']);
        selectedTests.add(c['test']);
      }
    } else {
      // if no top concerns, populate with abnormal markers
      Map<String, dynamic> resultsMap = reportData['results'] ?? {};
      resultsMap.forEach((testName, val) {
        String status = val['flag'] ?? 'Normal';
        if (status.toLowerCase() != 'normal' &&
            status.toLowerCase() != 'unknown') {
          availableTests.add(testName);
          selectedTests.add(testName);
        }
      });
    }

    String timeFrame = "1 month";
    final timeFrames = ["1 week", "2 weeks", "1 month", "3 months", "6 months"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create Follow-Up",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Timeframe",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: timeFrame,
                    dropdownColor: theme.colorScheme.surface,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                    ),
                    items: timeFrames
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, style: TextStyle(color: textColor)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => timeFrame = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Biomarkers to Retest",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  availableTests.isEmpty
                      ? Text(
                          "No abnormal tests found.",
                          style: TextStyle(color: textMuted),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: availableTests.length,
                            itemBuilder: (context, index) {
                              String t = availableTests[index];
                              return CheckboxListTile(
                                title: Text(
                                  t,
                                  style: TextStyle(color: textColor),
                                ),
                                value: selectedTests.contains(t),
                                activeColor: theme.colorScheme.primary,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedTests.add(t);
                                    } else {
                                      selectedTests.remove(t);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedTests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one biomarker.',
                              ),
                            ),
                          );
                          return;
                        }
                        await reportRef.parent.parent!
                            .collection('followups')
                            .add({
                              'createdAt': FieldValue.serverTimestamp(),
                              'doctorId':
                                  FirebaseAuth.instance.currentUser?.uid,
                              'doctorName': doctorName,
                              'timeFrame': timeFrame,
                              'testsToRepeat': selectedTests,
                              'status': 'pending',
                              'originalReportId': reportRef.id,
                            });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Follow-up scheduled.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Save Follow-Up Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _fetchHistoricalReports(String patientId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('reports')
          .orderBy('createdAt', descending: false)
          .get();

      final docs = snap.docs;
      Map<String, List<double>> biomarkerHistory = {};

      for (var doc in docs) {
        final data = doc.data();
        final results = data['results'] as Map<String, dynamic>?;
        if (results != null) {
          results.forEach((key, value) {
            final valStr =
                value['value']?.toString() ?? value['Value']?.toString() ?? '';
            final numVal = _extractNum(valStr);
            if (numVal != null) {
              final normalizedKey = key.toUpperCase();
              biomarkerHistory.putIfAbsent(normalizedKey, () => []).add(numVal);
            }
          });
        }
      }

      final changed = <String>{};
      biomarkerHistory.forEach((biomarker, values) {
        if (values.length >= 2) {
          final first = values.first;
          final allSame = values.every((v) => v == first);
          if (!allSame) {
            changed.add(biomarker);
          }
        }
      });

      if (mounted) {
        setState(() {
          _historicallyChangedBiomarkers = changed;
        });
      }
    } catch (e) {
      debugPrint("Error fetching historical reports: $e");
    }
  }

  double? _extractNum(String s) {
    final m = RegExp(r"[-+]?\d*\.\d+|\d+").firstMatch(s.replaceAll(',', ''));
    return m != null ? double.tryParse(m.group(0)!) : null;
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
                    reportData['results'] as Map<String, dynamic>? ?? {},
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
    Map<String, dynamic> resultsMap,
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final driverNames = driversMap.keys.toList();
    return ListView.builder(
      itemCount: driverNames.length,
      itemBuilder: (context, index) {
        final key = driverNames[index].toUpperCase();
        final valData = resultsMap[key] ?? resultsMap[key.toLowerCase()];

        final valStr = valData != null
            ? (valData['value'] ?? valData['Value'] ?? '-')
            : '-';
        final unitStr = valData != null
            ? (valData['unit'] ?? valData['Unit'] ?? '')
            : '';
        final flagStr = valData != null
            ? (valData['flag'] ?? valData['Flag'] ?? 'Normal')
            : 'Normal';

        final isNormal =
            flagStr == 'Normal' || flagStr == 'Unknown' || flagStr == '-';
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
                      flagStr,
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

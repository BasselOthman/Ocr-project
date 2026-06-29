import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/widgets/biomarker_trend_chart.dart';

class HistoricalTrendsTab extends StatefulWidget {
  final String patientId;

  const HistoricalTrendsTab({super.key, required this.patientId});

  @override
  State<HistoricalTrendsTab> createState() => _HistoricalTrendsTabState();
}

class _HistoricalTrendsTabState extends State<HistoricalTrendsTab> {
  String? selectedBiomarker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Health Trends",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('patients')
              .doc(widget.patientId)
              .collection('reports')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final docs = snapshot.data?.docs ?? [];

            // Map of biomarker key -> list of values
            Map<String, List<double>> biomarkerValues = {};
            // Map of key -> display name
            Map<String, String> displayNames = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final results = data['results'] as Map<String, dynamic>? ?? {};

              results.forEach((key, resValue) {
                if (resValue is Map<String, dynamic>) {
                  final valStr = (resValue['value'] ?? resValue['Value'] ?? '')
                      .toString();
                  double? val = double.tryParse(
                    valStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                  );
                  if (val != null) {
                    // Standardize display name
                    String displayName = key;
                    if (key == key.toUpperCase()) {
                      // e.g. HGB -> HGB, ALT -> ALT
                      displayName = key;
                    } else if (key == key.toLowerCase()) {
                      displayName =
                          key.substring(0, 1).toUpperCase() + key.substring(1);
                    }
                    displayNames[key] = displayName;
                    biomarkerValues.putIfAbsent(key, () => []).add(val);
                  }
                }
              });
            }

            // Filter biomarkers that actually change (>= 2 points, min != max)
            List<String> activeBiomarkers = [];
            biomarkerValues.forEach((key, values) {
              if (values.length >= 2) {
                double minVal = values.reduce((a, b) => a < b ? a : b);
                double maxVal = values.reduce((a, b) => a > b ? a : b);
                if (minVal != maxVal) {
                  activeBiomarkers.add(key);
                }
              }
            });

            // Sort active biomarkers alphabetically by display name
            activeBiomarkers.sort(
              (a, b) => (displayNames[a] ?? a).compareTo(displayNames[b] ?? b),
            );

            if (activeBiomarkers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.show_chart, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "No Changing Health Trends",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Upload at least two lab reports with varying biomarker values (including CBC tests) to start tracking trends.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              );
            }

            // Ensure selectedBiomarker is valid
            if (selectedBiomarker == null ||
                !activeBiomarkers.contains(selectedBiomarker)) {
              selectedBiomarker = activeBiomarkers.first;
            }

            // Find other changing biomarker for the second chart if possible
            String otherBiomarker = activeBiomarkers.firstWhere(
              (b) => b != selectedBiomarker,
              orElse: () => "",
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monitor how your key health markers are trending across all your past reports.",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBiomarker,
                        dropdownColor: theme.scaffoldBackgroundColor,
                        icon: Icon(Icons.arrow_drop_down, color: textColor),
                        isExpanded: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedBiomarker = newValue;
                            });
                          }
                        },
                        items: activeBiomarkers.map<DropdownMenuItem<String>>((
                          String key,
                        ) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(displayNames[key] ?? key),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // The Graph
                  BiomarkerTrendChart(
                    patientId: widget.patientId,
                    biomarkerName: selectedBiomarker!,
                    lineColor: Colors.tealAccent,
                  ),
                  if (otherBiomarker.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      "Other Notable Trends",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BiomarkerTrendChart(
                      patientId: widget.patientId,
                      biomarkerName: otherBiomarker,
                      lineColor: Colors.orangeAccent,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/common/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ReportAnalysis extends StatefulWidget {
  const ReportAnalysis({super.key});

  @override
  State<ReportAnalysis> createState() => _ReportAnalysisState();
}

class _ReportAnalysisState extends State<ReportAnalysis> {
  bool _loading = true;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
             'status': (r['Flag'] == 'Unknown' || r['Flag'] == 'Normal') ? 'normal' : 'flagged',
             'ocr_warning': r['Reliability_Level'] != 'HIGH',
             'min': r['Reference_Range'] ?? '-',
             'max': ''
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
        };
      } else {
        _analysis = {
          'summary': AppLocalizations.of(context)!.noResultsReceived,
          'values': [],
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Top Blue Background
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.deepBlueGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              )
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        AppLocalizations.of(context)!.reportAnalysis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ML Predictions Row (Gauges)
                            if (_analysis!['predictions'] != null && (_analysis!['predictions'] as Map).isNotEmpty)
                              SizedBox(
                                height: 210,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (_analysis!['predictions'] as Map).length,
                                  itemBuilder: (context, index) {
                                    String key = (_analysis!['predictions'] as Map).keys.elementAt(index);
                                    var pred = (_analysis!['predictions'] as Map)[key];
                                    bool isRisk = pred['is_positive'] == true;
                                    double prob = pred['probability']; // 0.0 to 1.0
                                    
                                    Color gaugeColor = isRisk ? AppColors.error : AppColors.success;
                                    
                                    return Container(
                                      width: 160,
                                      margin: const EdgeInsets.only(right: 16, bottom: 20, top: 10), // Shadow margin
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          )
                                        ]
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            key.replaceAll('_', ' ').toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
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
                                            center: Text(
                                              "${(prob * 100).toInt()}%",
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                                            ),
                                            circularStrokeCap: CircularStrokeCap.round,
                                            progressColor: gaugeColor,
                                            backgroundColor: gaugeColor.withValues(alpha: 0.15),
                                          ),
                                          const Spacer(),
                                          Text(
                                            isRisk ? AppLocalizations.of(context)!.needsReview : AppLocalizations.of(context)!.highlyAccurate,
                                            style: TextStyle(fontSize: 11, color: isRisk ? AppColors.error : AppColors.textMuted, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ).animate().fade(duration: 500.ms, delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
                                  },
                                ),
                              ),
                              
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.detectedValues, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                            const SizedBox(height: 12),
                            
                            // Values List
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: (_analysis!['values'] as List).length,
                              itemBuilder: (context, i) {
                                final v = (_analysis!['values'] as List)[i] as Map<String, dynamic>;
                                
                                String refRangeText = '${v['min']}${v['max']}';
                                Color statusColor = v['status'] == 'normal' ? AppColors.success : AppColors.error;
                                String statusText = v['status'] == 'normal' ? AppLocalizations.of(context)!.normalStatus : AppLocalizations.of(context)!.flaggedStatus;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                    ]
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${v['test']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                           Text('${v['value']} ${v['unit']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                           Text('${AppLocalizations.of(context)!.refRange} $refRangeText', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fade(duration: 400.ms, delay: (50 * i).ms).slideX(begin: 0.05, end: 0);
                              },
                            ),
                            const SizedBox(height: 80), // Padding for FAB
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: () {
        if (_analysis == null) return null;
        String currentLang = Localizations.localeOf(context).languageCode;
        String currentExplanation = currentLang == 'ar' ? (_analysis!['explanation_ar'] ?? '') : (_analysis!['explanation_en'] ?? '');
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.aiClinicalSummary,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      Expanded(
                        child: Markdown(
                          data: currentExplanation,
                          styleSheet: MarkdownStyleSheet(
                            h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                            h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            p: const TextStyle(fontSize: 14, color: AppColors.primary, height: 1.5),
                            listBullet: const TextStyle(fontSize: 14, color: AppColors.secondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            backgroundColor: AppColors.secondary,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.readSummary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }
        return null;
      }(),
    );
  }
}

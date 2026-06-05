import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../../l10n/app_localizations.dart';

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
        bool isIrrelevant = cleaned.length < 25 || 
                            cleaned.toLowerCase().startsWith('probability') ||
                            cleaned.toLowerCase().startsWith('score');
        
        if (!isIrrelevant) {
          guidelines.add(cleaned);
        }
      }
    }

    if (guidelines.isEmpty) {
        final sentences = rawText.split(RegExp(r'(?<=[.!?])\s+'));
        for(var s in sentences) {
            String cleaned = s.replaceAll('**', '').trim();
            bool isIrrelevant = cleaned.length < 25 || 
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
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()} ${l10n.yearsAgo}';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()} ${l10n.monthsAgo}';
    if (difference.inDays > 1) return '${difference.inDays} ${l10n.daysAgo}';
    if (difference.inDays == 1) return l10n.oneDayAgo;
    if (difference.inHours > 0) return '${difference.inHours} ${l10n.hoursAgo}';
    if (difference.inMinutes > 0) return '${difference.inMinutes} ${l10n.minutesAgo}';
    return l10n.justNow;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.analyticsDashboard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.meshGradient),
          ),
          
          SafeArea(
            child: user == null
                ? Center(child: Text(AppLocalizations.of(context)!.pleaseLogIn, style: const TextStyle(color: Colors.white)))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('patients')
                        .doc(user.uid)
                        .collection('reports')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(AppLocalizations.of(context)!.noDataScanFirst, style: const TextStyle(color: Colors.white70)),
                        );
                      }

                      final docData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      
                      final createdAt = docData['createdAt'] != null 
                          ? (docData['createdAt'] as Timestamp).toDate() 
                          : DateTime.now();
                          
                      final timeAgo = _getTimeAgo(createdAt, context);
                      
                      // Process recommendations
                      final String legacyExplanation = docData['explanation'] ?? '';
                      final String explanationEn = docData['explanation_en'] ?? '';
                      final String explanationAr = docData['explanation_ar'] ?? '';
                      
                      String currentLang = Localizations.localeOf(context).languageCode;
                      String explanation = currentLang == 'ar' ? explanationAr : explanationEn;
                      if (explanation.isEmpty) explanation = legacyExplanation;
                      
                      final recommendations = _extractRecommendations(explanation);

                      // Process abnormal markers
                      List<String> abnormalMarkers = [];
                      final Map<String, dynamic>? rawResultsMap = docData['results'];
                      if (rawResultsMap != null) {
                          rawResultsMap.forEach((key, value) {
                              final String flag = value['flag']?.toString() ?? 'Unknown';
                              // If it is definitely high or low
                              if (flag != 'Normal' && flag != 'Unknown' && flag.isNotEmpty && flag != '-') {
                                  abnormalMarkers.add(key);
                              }
                          });
                      }

                      // Calculate simple progress gauge (score out of 100)
                      int totalTests = rawResultsMap?.length ?? 1;
                      if (totalTests == 0) totalTests = 1;
                      int healthyTests = totalTests - abnormalMarkers.length;
                      double healthScore = (healthyTests / totalTests) * 100;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Data Last Synced
                            Center(
                              child: Text('${AppLocalizations.of(context)!.lastScan} $timeAgo', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            ).animate().fade().slideY(),
                            
                            const SizedBox(height: 32),

                            // 2. Recommendations Bubbles
                            if (recommendations.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(AppLocalizations.of(context)!.aiRecommendations, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: recommendations.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 200,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: AppColors.background,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                              ),
                                              title: Row(
                                                children: [
                                                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent),
                                                  const SizedBox(width: 8),
                                                  Text(AppLocalizations.of(context)!.aiInsight, style: const TextStyle(color: Colors.white, fontSize: 18)),
                                                ],
                                              ),
                                              content: Text(
                                                recommendations[index],
                                                style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: AppColors.accent)),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                        child: GlassCard(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 24),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: Text(
                                                  recommendations[index],
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                                  overflow: TextOverflow.fade,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: Text(AppLocalizations.of(context)!.tapToRead, style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
                                  },
                                ),
                              ),
                            ] else if (explanation.isNotEmpty) ...[
                              // Fallback if we couldn't parse bullets but there IS an explanation
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(AppLocalizations.of(context)!.aiSummaryRecorded, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 32),

                            // 3. Progress Core Health
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(AppLocalizations.of(context)!.biomarkerStability, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            color: healthScore > 80 ? AppColors.success : (healthScore > 50 ? Colors.orangeAccent : Colors.redAccent),
                                          ),
                                          Center(
                                            child: Text('${healthScore.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            healthScore > 80 ? AppLocalizations.of(context)!.excellentStatus : AppLocalizations.of(context)!.needsAttention,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${healthyTests} ${AppLocalizations.of(context)!.outOf} $totalTests ${AppLocalizations.of(context)!.trackedMarkersNormal}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ).animate().fade(duration: 500.ms).slideY(begin: 0.1),

                            const SizedBox(height: 32),

                            // 4. Abnormal Markers
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(AppLocalizations.of(context)!.flaggedMarkers, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(height: 16),
                            
                            abnormalMarkers.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text(AppLocalizations.of(context)!.allMarkersNormal, style: const TextStyle(color: Colors.white))),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: abnormalMarkers.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: GlassCard(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 24),
                                              const SizedBox(width: 16),
                                              Expanded(child: Text(abnormalMarkers[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                            ],
                                          ),
                                        ),
                                      ).animate().fade(delay: (index * 100).ms).slideX(begin: -0.1);
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

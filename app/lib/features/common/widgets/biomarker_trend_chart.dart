import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

class BiomarkerTrendChart extends StatelessWidget {
  final String patientId;
  final String biomarkerName;
  final Color lineColor;

  const BiomarkerTrendChart({
    super.key,
    required this.patientId,
    required this.biomarkerName,
    this.lineColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: lineColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$biomarkerName History",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('reports')
                  .orderBy('createdAt', descending: false) // Chronological
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading data: ${snapshot.error}"),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Extract points
                List<FlSpot> spots = [];
                List<DateTime> dates = [];
                double minY = double.infinity;
                double maxY = double.negativeInfinity;
                String unit = "";
                double? refMin;
                double? refMax;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final results =
                      data['results'] as Map<String, dynamic>? ?? {};

                  // Find the matching biomarker (case-insensitive, basic match)
                  Map<String, dynamic>? foundRes;
                  for (var key in results.keys) {
                    if (key.toLowerCase() == biomarkerName.toLowerCase() ||
                        key.toLowerCase().contains(
                          biomarkerName.toLowerCase(),
                        )) {
                      foundRes = results[key] as Map<String, dynamic>?;
                      break;
                    }
                  }

                  if (foundRes != null) {
                    final valStr =
                        (foundRes['Value'] ?? foundRes['value'] ?? '')
                            .toString();
                    if (valStr.isEmpty) continue;
                    final timestamp = data['createdAt'] as Timestamp?;

                    if (timestamp != null) {
                      try {
                        double val = double.parse(
                          valStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                        );
                        dates.add(timestamp.toDate());
                        spots.add(
                          FlSpot(
                            timestamp
                                .toDate()
                                .millisecondsSinceEpoch
                                .toDouble(),
                            val,
                          ),
                        );

                        if (val < minY) minY = val;
                        if (val > maxY) maxY = val;
                        if (unit.isEmpty) {
                          unit = (foundRes['Unit'] ?? foundRes['unit'] ?? '')
                              .toString();
                        }

                        // Try to parse ref range just once
                        if (refMin == null &&
                            foundRes['Reference_Range'] != null) {
                          final refStr = foundRes['Reference_Range'].toString();
                          if (refStr.contains('-')) {
                            final parts = refStr.split('-');
                            refMin = double.tryParse(
                              parts[0].replaceAll(RegExp(r'[^0-9.]'), ''),
                            );
                            refMax = double.tryParse(
                              parts[1].replaceAll(RegExp(r'[^0-9.]'), ''),
                            );
                          }
                        }
                      } catch (e) {
                        // skip parse errors
                      }
                    }
                  }
                }

                if (spots.isEmpty) {
                  return const Center(
                    child: Text(
                      "No historical data available.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                if (spots.length == 1) {
                  return Center(
                    child: Text(
                      "Only 1 data point: ${spots[0].y} $unit\nNeed more reports for a trend.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Adjust min/max for graph padding
                double dataRange = maxY - minY;
                if (dataRange == 0) dataRange = maxY > 0 ? maxY * 0.2 : 10;
                double paddingY = dataRange * 0.2;

                double chartMinY = minY - paddingY;
                double chartMaxY = maxY + paddingY;

                // Only expand to include ref range if it's reasonably close (prevents flattening the curve)
                if (refMin != null &&
                    chartMinY > refMin &&
                    (chartMinY - refMin) < dataRange * 3) {
                  chartMinY = refMin - paddingY;
                }
                if (refMax != null &&
                    chartMaxY < refMax &&
                    (refMax - chartMaxY) < dataRange * 3) {
                  chartMaxY = refMax + paddingY;
                }

                // Calculate display interval for dates to prevent overlap
                double xInterval = 1;
                if (dates.length > 1) {
                  double timeRange =
                      dates.last.millisecondsSinceEpoch.toDouble() -
                      dates.first.millisecondsSinceEpoch.toDouble();
                  if (timeRange == 0) timeRange = 86400000; // 1 day

                  if (dates.length > 15) {
                    xInterval = timeRange / 4;
                  } else if (dates.length > 8) {
                    xInterval = timeRange / 3;
                  } else if (dates.length > 4) {
                    xInterval = timeRange / 2;
                  } else {
                    xInterval =
                        timeRange / (dates.length > 1 ? dates.length - 1 : 1);
                  }

                  // Ensure interval is at least 1 day to avoid overlapping titles if points are too close
                  if (xInterval < 86400000) xInterval = 86400000;
                }

                double minX = dates.first.millisecondsSinceEpoch.toDouble();
                double maxX = dates.last.millisecondsSinceEpoch.toDouble();
                if (minX == maxX) {
                  minX -= 43200000; // half day
                  maxX += 43200000;
                } else {
                  double paddingX = (maxX - minX) * 0.05;
                  if (paddingX < 86400000) paddingX = 86400000;
                  minX -= paddingX;
                  maxX += paddingX;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (spots.length >= 2) ...[
                      Builder(
                        builder: (context) {
                          double latestVal = spots.last.y;
                          double prevVal = spots[spots.length - 2].y;
                          if (prevVal != 0) {
                            double pctChange =
                                ((latestVal - prevVal) / prevVal) * 100;
                            bool isIncrease = pctChange > 0;
                            String sign = isIncrease ? "+" : "";
                            Color color = isIncrease
                                ? Colors.redAccent
                                : Colors.green;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isIncrease
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "$sign${pctChange.toStringAsFixed(1)}% ${isIncrease ? 'Increase' : 'Decrease'} since last test",
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: paddingY > 0 ? paddingY : null,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withValues(alpha: 0.15),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: xInterval,
                                getTitlesWidget: (value, meta) {
                                  DateTime date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt(),
                                      );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MMM yy').format(date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: paddingY > 0 ? paddingY : null,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: minX,
                          maxX: maxX,
                          minY: chartMinY,
                          maxY: chartMaxY,
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              if (refMin != null)
                                HorizontalLine(
                                  y: refMin,
                                  color: Colors.green.withValues(alpha: 0.5),
                                  strokeWidth: 1,
                                  dashArray: [8, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.bottomRight,
                                    padding: const EdgeInsets.only(
                                      right: 5,
                                      bottom: 5,
                                    ),
                                    labelResolver: (line) => 'Min Range',
                                  ),
                                ),
                              if (refMax != null)
                                HorizontalLine(
                                  y: refMax,
                                  color: Colors.green.withValues(alpha: 0.5),
                                  strokeWidth: 1,
                                  dashArray: [8, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(
                                      right: 5,
                                      bottom: -20,
                                    ),
                                    labelResolver: (line) => 'Max Range',
                                  ),
                                ),
                            ],
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: lineColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: lineColor,
                                        ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: lineColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((
                                  LineBarSpot touchedSpot,
                                ) {
                                  DateTime date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        touchedSpot.x.toInt(),
                                      );
                                  return LineTooltipItem(
                                    '${touchedSpot.y} $unit\n${DateFormat('dd MMM yyyy').format(date)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/glass_card.dart';

class DoctorRecommendationScreen extends StatefulWidget {
  const DoctorRecommendationScreen({super.key});

  @override
  State<DoctorRecommendationScreen> createState() =>
      _DoctorRecommendationScreenState();
}

class _DoctorRecommendationScreenState extends State<DoctorRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 state
  String? _selectedDoctorId;
  String? _selectedReportId;
  bool _isSubmitting = false;
  DateTime? _apptDate;
  String? _apptTimeSlot;
  Map<String, dynamic>? _selectedReportPredictions;

  String? _getHighestProbDisease() {
    if (_selectedReportPredictions == null ||
        _selectedReportPredictions!.isEmpty) {
      return null;
    }
    String? bestDisease;
    double highestProb = -1.0;

    _selectedReportPredictions!.forEach((key, value) {
      final probVal = value['probability'];
      double prob = 0.0;
      if (probVal is num) {
        prob = probVal.toDouble();
      } else if (probVal is String) {
        prob = double.tryParse(probVal) ?? 0.0;
      }
      if (prob > highestProb) {
        highestProb = prob;
        bestDisease = key;
      }
    });

    return bestDisease;
  }

  bool _isRecommendedDoctor(String? specialty, String? highestDiseaseKey) {
    if (specialty == null || highestDiseaseKey == null) return false;
    final spec = specialty.toLowerCase();
    final dis = highestDiseaseKey.toLowerCase();

    if (dis == 'anemia' && spec.contains('hematology')) return true;
    if (dis == 'diabetes' && spec.contains('endocrinology')) return true;
    if (dis == 'hyperlipidemia' && spec.contains('cardiology')) return true;
    if (dis == 'kidney' && spec.contains('nephrology')) return true;
    if (dis == 'liver' &&
        (spec.contains('hepatology') || spec.contains('gastroenterology'))) {
      return true;
    }
    if (dis == 'thyroid' && spec.contains('endocrinology')) return true;

    return false;
  }

  List<String> _bookedTimeSlots = [];

  String _formatTimeSlot(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "${displayHour.toString().padLeft(2, '0')}:$minute $amPm";
  }

  void _fetchBookedTimeSlots() async {
    if (_selectedDoctorId == null || _apptDate == null) {
      setState(() {
        _bookedTimeSlots = [];
      });
      return;
    }

    setState(() {
      _bookedTimeSlots = [];
    });

    try {
      final startOfDay = DateTime(
        _apptDate!.year,
        _apptDate!.month,
        _apptDate!.day,
        0,
        0,
        0,
      );
      final endOfDay = DateTime(
        _apptDate!.year,
        _apptDate!.month,
        _apptDate!.day,
        23,
        59,
        59,
      );

      final snap = await FirebaseFirestore.instance
          .collectionGroup('reports')
          .where('assignedDoctorId', isEqualTo: _selectedDoctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      List<String> booked = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final apptTimestamp = data['appointmentDate'] as Timestamp?;
        if (apptTimestamp != null) {
          final date = apptTimestamp.toDate();
          final slot = _formatTimeSlot(date);
          booked.add(slot);
        }
      }

      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedDoctorId)
          .get();
      if (doctorDoc.exists && doctorDoc.data() != null) {
        final docData = doctorDoc.data()!;
        final disabledSlotsMap =
            docData['disabledSlots'] as Map<String, dynamic>?;
        if (disabledSlotsMap != null) {
          final dateKey =
              "${_apptDate!.year}-${_apptDate!.month.toString().padLeft(2, '0')}-${_apptDate!.day.toString().padLeft(2, '0')}";
          final disabledList = disabledSlotsMap[dateKey] as List<dynamic>?;
          if (disabledList != null) {
            for (var slot in disabledList) {
              booked.add(slot.toString());
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookedTimeSlots = booked;
          if (_apptTimeSlot != null &&
              _bookedTimeSlots.contains(_apptTimeSlot)) {
            _apptTimeSlot = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching booked time slots: $e");
    }
  }

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
  ];

  Future<void> _pickApptDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _apptDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _apptDate = picked;
        _apptTimeSlot = null;
      });
      _fetchBookedTimeSlots();
    }
  }

  // Tab 2 state
  List<List<dynamic>> _csvData = [];
  bool _isCsvLoading = true;
  String _selectedGov = 'All';
  List<String> _governorates = ['All'];
  String _sortOrder = 'Sort by rating: High to Low'; // Added sort order state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCsvData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCsvData() async {
    try {
      final String csvString = await rootBundle.loadString(
        'assets/data/doctor_recommendation_FINAL.csv',
      );
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvString,
      );
      if (csvTable.isNotEmpty) {
        // Remove header row
        csvTable.removeAt(0);

        Set<String> govs = {'All'};
        for (var row in csvTable) {
          if (row.length > 6) {
            String gov = row[6].toString().trim();
            if (gov.isNotEmpty) govs.add(gov);
          }
        }

        List<String> sortedGovs = govs.where((g) => g != 'All').toList()
          ..sort();
        _governorates = ['All', ...sortedGovs];

        if (mounted) {
          setState(() {
            _csvData = csvTable;
            _isCsvLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCsvLoading = false);
      }
      debugPrint("Error loading CSV: $e");
    }
  }

  void _shareReport() async {
    if (_selectedDoctorId == null ||
        _selectedReportId == null ||
        _apptDate == null ||
        _apptTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor, report, date, and time slot.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Parse time slot, e.g. "09:30 AM" -> hour 9, minute 30
        final timeParts = _apptTimeSlot!.split(' ');
        final hms = timeParts[0].split(':');
        int hour = int.parse(hms[0]);
        final minute = int.parse(hms[1]);
        // Let's safe-check:
        final slotAmPm = timeParts.length > 1 ? timeParts[1] : 'AM';
        if (slotAmPm == 'PM' && hour < 12) hour += 12;
        if (slotAmPm == 'AM' && hour == 12) hour = 0;

        final appointmentDateTime = DateTime(
          _apptDate!.year,
          _apptDate!.month,
          _apptDate!.day,
          hour,
          minute,
        );

        // Update the report to include the assigned doctor and appointment date
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .collection('reports')
            .doc(_selectedReportId)
            .update({
              'assignedDoctorId': _selectedDoctorId,
              'doctorReviewStatus': 'pending', // pending, reviewed
              'appointmentDate': Timestamp.fromDate(appointmentDateTime),
            });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report successfully shared and appointment booked!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedDoctorId = null;
          _selectedReportId = null;
          _apptDate = null;
          _apptTimeSlot = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing report: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.doctorRecommendations ??
              "Doctor Recommendations",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: hintColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: "Share Report"),
            Tab(text: "Doctors Database"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShareReportTab(theme, textColor, hintColor),
          _buildDatabaseTab(theme, textColor, hintColor),
        ],
      ),
    );
  }

  Widget _buildShareReportTab(
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Share your AI-analyzed reports with a specialist for a professional review.",
            style: TextStyle(color: hintColor, fontSize: 16),
          ).animate().fade().slideY(begin: -0.2),
          const SizedBox(height: 32),

          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "1. Select a Report",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (user != null)
                  _buildReportDropdown(user.uid, theme, textColor, hintColor)
                else
                  Text("Please log in", style: TextStyle(color: textColor)),

                const SizedBox(height: 32),

                Text(
                  "2. Select a Doctor",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDoctorDropdown(theme, textColor, hintColor),

                const SizedBox(height: 32),

                Text(
                  "3. Choose Appointment Date & Time",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Date picker button
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickApptDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _apptDate == null
                                      ? "Select Date"
                                      : "${_apptDate!.day}/${_apptDate!.month}/${_apptDate!.year}",
                                  style: TextStyle(
                                    color: _apptDate == null
                                        ? hintColor
                                        : textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time slot dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            dropdownColor: theme.scaffoldBackgroundColor,
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.access_time,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              hintText: "Select Time",
                              hintStyle: TextStyle(color: hintColor),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            style: TextStyle(color: textColor),
                            initialValue: _apptTimeSlot,
                            items: _timeSlots
                                .where(
                                  (slot) => !_bookedTimeSlots.contains(slot),
                                )
                                .map(
                                  (slot) => DropdownMenuItem(
                                    value: slot,
                                    child: Text(slot),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _apptTimeSlot = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _shareReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Share & Book Appointment",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 100.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildDatabaseTab(ThemeData theme, Color textColor, Color hintColor) {
    if (_isCsvLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    // Filter
    List<List<dynamic>> filtered = _csvData;
    if (_selectedGov != 'All') {
      filtered = filtered
          .where(
            (row) => row.length > 6 && row[6].toString().trim() == _selectedGov,
          )
          .toList();
    }

    final highestDiseaseKey = _getHighestProbDisease();

    filtered.sort((a, b) {
      if (highestDiseaseKey != null) {
        String specA = a.length > 1 ? a[1].toString() : '';
        String specB = b.length > 1 ? b[1].toString() : '';
        bool isRecA = _isRecommendedDoctor(specA, highestDiseaseKey);
        bool isRecB = _isRecommendedDoctor(specB, highestDiseaseKey);

        if (isRecA && !isRecB) return -1;
        if (!isRecA && isRecB) return 1;
      }

      if (_sortOrder == 'Sort by Speciality: A to Z') {
        String specA = a.length > 1 ? a[1].toString() : '';
        String specB = b.length > 1 ? b[1].toString() : '';
        return specA.compareTo(specB);
      } else if (_sortOrder == 'Sort by Speciality: Z to A') {
        String specA = a.length > 1 ? a[1].toString() : '';
        String specB = b.length > 1 ? b[1].toString() : '';
        return specB.compareTo(specA);
      }

      double ratingA =
          double.tryParse(a.length > 3 ? a[3].toString() : '0') ?? 0;
      double ratingB =
          double.tryParse(b.length > 3 ? b[3].toString() : '0') ?? 0;
      if (ratingA > 5.0) ratingA = 5.0;
      if (ratingB > 5.0) ratingB = 5.0;
      if (_sortOrder == 'Sort by rating: Low to High') {
        return ratingA.compareTo(ratingB);
      }
      return ratingB.compareTo(ratingA); // Descending
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Governorate: ",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGov,
                          isExpanded: true,
                          dropdownColor: theme.scaffoldBackgroundColor,
                          style: TextStyle(color: textColor),
                          items: _governorates
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGov = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.sort, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Sort By: ",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOrder,
                          isExpanded: true,
                          dropdownColor: theme.scaffoldBackgroundColor,
                          style: TextStyle(color: textColor),
                          items:
                              [
                                    'Sort by rating: High to Low',
                                    'Sort by rating: Low to High',
                                    'Sort by Speciality: A to Z',
                                    'Sort by Speciality: Z to A',
                                  ]
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(o),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortOrder = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final row = filtered[index];
              // Columns:
              // 0: Name, 1: Speciality, 2: Address, 3: Rating, 4: Phone, 5: Profile,
              // 6: Governorate, 7: google maps url, 8: maps rating, 9: source file,
              // 10: maps address, 11: maps phone, 12: Full address, 13: lat, 14: lng,
              // 15: place id, 16: maps url, 17: google maps link

              String name = row.isNotEmpty ? row[0].toString() : 'Unknown';
              String spec = row.length > 1 ? row[1].toString() : '';
              String rating = row.length > 3 ? row[3].toString() : '0';
              String gov = row.length > 6 ? row[6].toString() : '';
              String address = row.length > 12
                  ? row[12].toString()
                  : (row.length > 2 ? row[2].toString() : '');
              String mapUrl = row.length > 17
                  ? row[17].toString()
                  : (row.length > 7 ? row[7].toString() : '');

              double numRating = double.tryParse(rating) ?? 0.0;
              if (numRating > 5.0) numRating = 5.0;

              final isRec = _isRecommendedDoctor(spec, highestDiseaseKey);

              return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Dr. $name",
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (isRec) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: theme.colorScheme.primary,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Recommended",
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      numRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            spec,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: hintColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address.isNotEmpty ? "$address ($gov)" : gov,
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (mapUrl.isNotEmpty &&
                              mapUrl.startsWith('http')) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(mapUrl);
                                  try {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {
                                    debugPrint('Could not launch $uri');
                                  }
                                },
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text("Open in Maps"),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fade(delay: (50 * (index % 10)).ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorDropdown(
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final isLoading = !snapshot.hasData;
        final docsList = isLoading
            ? <QueryDocumentSnapshot>[]
            : snapshot.data!.docs.cast<QueryDocumentSnapshot>().toList();
        final highestDiseaseKey = _getHighestProbDisease();

        if (highestDiseaseKey != null) {
          docsList.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final specA = dataA['specialty'] ?? '';
            final isRecA = _isRecommendedDoctor(specA, highestDiseaseKey);

            final dataB = b.data() as Map<String, dynamic>;
            final specB = dataB['specialty'] ?? '';
            final isRecB = _isRecommendedDoctor(specB, highestDiseaseKey);

            if (isRecA && !isRecB) return -1;
            if (!isRecA && isRecB) return 1;
            return 0;
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: theme.scaffoldBackgroundColor,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hintColor,
                      ),
                    )
                  : Icon(Icons.keyboard_arrow_down, color: textColor),
              value: _selectedDoctorId,
              hint: Text(
                isLoading ? "Loading specialists..." : "Choose a specialist...",
                style: TextStyle(color: hintColor),
              ),
              items: docsList.map<DropdownMenuItem<String>>((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown Doctor';
                final specialty = data['specialty'] ?? 'General';
                final isRec = _isRecommendedDoctor(
                  specialty,
                  highestDiseaseKey,
                );
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    "${isRec ? '⭐ ' : ''}Dr. $name ($specialty)${isRec ? ' (Recommended)' : ''}",
                    style: TextStyle(
                      color: isRec ? theme.colorScheme.primary : textColor,
                      fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (val) {
                      setState(() {
                        _selectedDoctorId = val;
                        _apptTimeSlot = null;
                      });
                      _fetchBookedTimeSlots();
                    },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportDropdown(
    String userId,
    ThemeData theme,
    Color textColor,
    Color hintColor,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(userId)
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final isLoading = !snapshot.hasData;
        final docs = isLoading ? [] : snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: theme.scaffoldBackgroundColor,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hintColor,
                      ),
                    )
                  : Icon(Icons.keyboard_arrow_down, color: textColor),
              value: _selectedReportId,
              hint: Text(
                isLoading ? "Loading reports..." : "Choose a report...",
                style: TextStyle(color: hintColor),
              ),
              items: docs.map<DropdownMenuItem<String>>((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sourceFile = data['sourceFile'] ?? 'Unknown File';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final dateStr = createdAt != null
                    ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                    : "";

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    "$sourceFile - $dateStr",
                    style: TextStyle(color: textColor),
                  ),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (val) {
                      setState(() {
                        _selectedReportId = val;
                        final selectedDoc = docs.firstWhere((d) => d.id == val);
                        final data = selectedDoc.data() as Map<String, dynamic>;

                        final Map<String, dynamic> parsedPredictions = {};
                        if (data['predictions'] is Map) {
                          (data['predictions'] as Map).forEach((k, v) {
                            if (v is Map) {
                              parsedPredictions[k.toString()] =
                                  Map<String, dynamic>.from(v);
                            }
                          });
                        }
                        _selectedReportPredictions = parsedPredictions;
                      });
                    },
            ),
          ),
        );
      },
    );
  }
}

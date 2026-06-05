class LabResult {
  final String id;
  final String testName;
  final double value;
  final String unit;
  final double minRange;
  final double maxRange;
  final DateTime date;

  LabResult({
    required this.id,
    required this.testName,
    required this.value,
    required this.unit,
    required this.minRange,
    required this.maxRange,
    required this.date,
  });

  // For demo sample
  factory LabResult.sample(String id) => LabResult(
    id: id,
    testName: 'Hemoglobin',
    value: 12.5,
    unit: 'g/dL',
    minRange: 12.0,
    maxRange: 16.0,
    date: DateTime.now().subtract(Duration(days: 30)),
  );
}

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class GenerateReportService {
  static Future<Uint8List> generateAndPrintPdf({
    required String patientName,
    required String doctorName,
    required Map<String, dynamic> reportData,
    required String decision,
    required String modifiedDisease,
    required String notes,
    List<String> requestedTests = const [],
    String prescription = '',
  }) async {
    final pdf = pw.Document();

    final date = DateTime.now();
    final dateStr = "${date.day}/${date.month}/${date.year}";

    final results = reportData['results'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'MEDICAL REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.blue900, thickness: 2),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (context) => [
          // Patient & Doctor Info
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Patient Name:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      patientName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Reviewed By:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      doctorName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Doctor's Assessment
          pw.Text(
            'Doctor\'s Assessment',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: decision == 'REJECT' ? PdfColors.red : PdfColors.green,
                width: 2,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  decision == 'CONFIRM'
                      ? 'Assessment Confirmed'
                      : decision == 'MODIFY'
                      ? 'Modified Assessment: $modifiedDisease'
                      : decision == 'REQUEST_TESTS'
                      ? 'Additional Tests Requested'
                      : 'AI Assessment Rejected',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (requestedTests.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Tests to Complete:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: requestedTests
                        .map(
                          (t) => pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '• ',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red900,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  t,
                                  style: const pw.TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (prescription.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Prescribed Medication:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    prescription,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.teal900,
                    ),
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Clinical Notes:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(notes, style: const pw.TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Lab Results
          pw.Text(
            'Laboratory Results',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Test Name', 'Value', 'Unit', 'Reference', 'Status'],
            data: results.entries.map((e) {
              final val = e.value as Map<String, dynamic>;
              return [
                e.key,
                val['value']?.toString() ?? '-',
                val['unit']?.toString() ?? '-',
                val['ref_range']?.toString() ?? '-',
                val['flag']?.toString() ?? 'Normal',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 12),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'This report was automatically generated and verified by a medical professional.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return await pdf.save();
  }
}

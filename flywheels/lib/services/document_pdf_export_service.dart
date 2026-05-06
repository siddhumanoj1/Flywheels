import 'dart:io';

import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DocumentPdfExportResult {
  const DocumentPdfExportResult({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;
}

abstract final class DocumentPdfExportService {
  static Future<DocumentPdfExportResult> exportDocument({
    required ServiceDocument document,
    required CarProfile? car,
    GarageUser? customer,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 56,
                height: 56,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'FA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FLYWHEELS AUTO',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Garage management, live service tracking, and customer care.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                document.type.label,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(height: 2, color: PdfColors.red),
          pw.SizedBox(height: 22),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _detailBlock(
                  title: 'Document',
                  lines: [
                    document.title,
                    'Created: ${_formatPdfDate(document.createdAt)}',
                    'Updated: ${_formatPdfDate(document.updatedAt)}',
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _detailBlock(
                  title: 'Customer / Vehicle',
                  lines: [
                    customer?.name ?? 'Customer',
                    customer?.phone ?? '',
                    car?.carNumber ?? 'Vehicle',
                    car?.model ?? '',
                  ].where((line) => line.trim().isNotEmpty).toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            headers: const ['Item', 'Qty', 'Rate', 'Total'],
            data: document.items
                .map(
                  (item) => [
                    item.description,
                    item.quantity.toString(),
                    formatCurrency(item.unitPrice),
                    formatCurrency(item.total),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    formatCurrency(document.total),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Approval: ${document.approvalState.name}'),
              _pill('Payment: ${document.paymentState.name}'),
              _pill(document.pdfLabel),
            ],
          ),
        ],
      ),
    );

    final baseDirectory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}Flywheels Documents',
    );
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final fileName = '${_safeFileName(document.title)}.pdf';
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return DocumentPdfExportResult(filePath: file.path, fileName: fileName);
  }

  static pw.Widget _detailBlock({
    required String title,
    required List<String> lines,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 6),
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(line),
          ),
        ),
      ],
    );
  }

  static pw.Widget _pill(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static String _formatPdfDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _safeFileName(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty ? 'flywheels-document' : normalized;
  }
}

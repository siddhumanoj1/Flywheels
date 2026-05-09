import 'dart:io';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flutter/services.dart';
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
  }) {
    return _export(
      _DocumentPrintData(
        type: document.type,
        documentNumber: document.title,
        date: document.createdAt,
        customerName: customer?.name ?? 'Customer',
        vehicleNumber: car?.carNumber ?? 'Vehicle',
        carModel: car?.model ?? 'N/A',
        items: document.items,
      ),
    );
  }

  static Future<DocumentPdfExportResult> exportDraft({
    required DocumentDraft draft,
    DateTime? date,
  }) {
    return _export(
      _DocumentPrintData(
        type: draft.type,
        documentNumber: draft.documentNumber,
        date: date ?? DateTime.now(),
        customerName: draft.customerName,
        vehicleNumber: draft.vehicleNumber,
        carModel: draft.carModel,
        items: draft.items,
      ),
    );
  }

  static Future<DocumentPdfExportResult> _export(
    _DocumentPrintData data,
  ) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load(
      'assets/branding/flywheels-logo.png',
    );
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(86, 28, 28, 28),
          buildBackground: (context) => _sideTitle(data),
        ),
        build: (context) => _templateContent(data, logo),
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

    final fileName =
        '${_safeFileName('${data.type.label}-${data.documentNumber}').trim()}.pdf';
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return DocumentPdfExportResult(filePath: file.path, fileName: fileName);
  }

  static List<pw.Widget> _templateContent(
    _DocumentPrintData data,
    pw.ImageProvider logo,
  ) {
    return [
      _header(logo),
      pw.SizedBox(height: 18),
      pw.Container(height: 1.4, color: PdfColors.red),
      pw.SizedBox(height: 18),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _detailValue('Date', formatLongDate(data.date))),
          pw.Expanded(
            child: _detailValue(
              'To',
              formatCustomerNameForDocument(data.customerName),
            ),
          ),
          pw.Expanded(child: _detailValue('Ship To', 'In-Store')),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Container(height: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 16),
      pw.Text(
        'Vehicle Details',
        style: pw.TextStyle(
          color: PdfColors.red,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(data.carModelOrFallback),
      pw.Text(data.vehicleNumberOrFallback),
      pw.SizedBox(height: 18),
      _itemsTable(data.items),
      pw.SizedBox(height: 18),
      pw.Container(height: 2, color: PdfColors.red),
      pw.SizedBox(height: 10),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 250,
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  _totalLabel(data.type),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                formatCurrency(data.total),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 18),
      pw.Center(
        child: pw.Text(
          'Thanks for choosing us to serve your automotive needs!',
          style: pw.TextStyle(
            color: PdfColors.red,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 26),
      _footer(),
    ];
  }

  static pw.Widget _sideTitle(_DocumentPrintData data) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 15,
            top: 52,
            child: pw.Transform.rotateBox(
              angle: 1.5708,
              child: pw.SizedBox(
                width: 350,
                height: 48,
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: pw.TextStyle(
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                    children: [
                      pw.TextSpan(text: '${data.type.label} '),
                      pw.TextSpan(
                        text: '[${data.documentNumberOrDraft}]',
                        style: pw.TextStyle(
                          color: PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _header(pw.ImageProvider logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FLYWHEELS AUTO',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Ayush hospital road, beside Saibaba temple\n'
                'Nagarjuna Nagar, Currency Nagar\n'
                'Vijayawada, Andhra Pradesh -520008',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                  lineSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'GST IN: 37AAJFF3362M1Z1',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Image(logo, width: 132, fit: pw.BoxFit.contain),
      ],
    );
  }

  static pw.Widget _detailValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.red,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value.trim().isEmpty ? 'N/A' : value.trim(),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _itemsTable(List<DocumentLineItem> items) {
    final rows = items.isEmpty
        ? const [
            DocumentLineItem(
              description: 'No line items',
              quantity: 1,
              unitPrice: 0,
              total: 0,
            ),
          ]
        : items;

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.grey300),
        left: pw.BorderSide(color: PdfColors.grey300),
        right: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        verticalInside: pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(48),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
        4: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: PdfColors.red),
          children: [
            _pdfTableCell(
              'Serial No.',
              header: true,
              align: pw.TextAlign.center,
            ),
            _pdfTableCell('Description', header: true),
            _pdfTableCell(
              'Unit Price',
              header: true,
              align: pw.TextAlign.right,
            ),
            _pdfTableCell('Quantity', header: true, align: pw.TextAlign.right),
            _pdfTableCell('Total', header: true, align: pw.TextAlign.right),
          ],
        ),
        ...rows.asMap().entries.map(
          (entry) => pw.TableRow(
            children: [
              _pdfTableCell('${entry.key + 1}', align: pw.TextAlign.center),
              _pdfTableCell(entry.value.description),
              _pdfTableCell(
                entry.value.unitPrice > 0
                    ? formatCurrency(entry.value.unitPrice)
                    : '',
                align: pw.TextAlign.right,
              ),
              _pdfTableCell(
                entry.value.quantity.toString(),
                align: pw.TextAlign.right,
              ),
              _pdfTableCell(
                formatCurrency(entry.value.total),
                align: pw.TextAlign.right,
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfTableCell(
    String value, {
    bool header = false,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          color: header ? PdfColors.white : PdfColors.black,
          fontSize: 9,
          fontWeight: header || bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Container(height: 2, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _footerLine('Tel:', '+ 91-9966783333\n+ 91-9563998998'),
            ),
            pw.Expanded(
              child: pw.Column(
                children: [
                  _footerLine('Email:', 'flywheelsauto.vjy@gmail.com'),
                  pw.SizedBox(height: 6),
                  _footerLine('Web:', 'www.flywheelsauto.in'),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'A 2LYP create',
            style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
          ),
        ),
      ],
    );
  }

  static pw.Widget _footerLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 44,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.red,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8, lineSpacing: 2),
          ),
        ),
      ],
    );
  }

  static String _totalLabel(DocumentType type) {
    switch (type) {
      case DocumentType.quotation:
      case DocumentType.estimation:
        return 'ESTIMATED TOTAL';
      case DocumentType.invoice:
        return 'GRAND TOTAL';
      case DocumentType.jobCard:
        return 'JOB TOTAL';
    }
  }

  static String _safeFileName(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty ? 'flywheels-document' : normalized;
  }
}

class _DocumentPrintData {
  const _DocumentPrintData({
    required this.type,
    required this.documentNumber,
    required this.date,
    required this.customerName,
    required this.vehicleNumber,
    required this.carModel,
    required this.items,
  });

  final DocumentType type;
  final String documentNumber;
  final DateTime date;
  final String customerName;
  final String vehicleNumber;
  final String carModel;
  final List<DocumentLineItem> items;

  double get total => items.fold<double>(0, (sum, item) => sum + item.total);
  String get documentNumberOrDraft =>
      documentNumber.trim().isEmpty ? 'Draft' : documentNumber.trim();
  String get vehicleNumberOrFallback =>
      vehicleNumber.trim().isEmpty ? 'N/A' : vehicleNumber.trim();
  String get carModelOrFallback =>
      carModel.trim().isEmpty ? 'N/A' : carModel.trim();
}

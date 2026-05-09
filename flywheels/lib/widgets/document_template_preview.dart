import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flutter/material.dart';

class DocumentTemplatePreview extends StatelessWidget {
  const DocumentTemplatePreview({
    super.key,
    required this.type,
    required this.documentNumber,
    required this.date,
    required this.customerName,
    required this.vehicleNumber,
    required this.carModel,
    required this.items,
    this.padding = const EdgeInsets.all(28),
  });

  static const _pageWidth = 595.0;
  static const _pageHeight = 842.0;

  final DocumentType type;
  final String documentNumber;
  final DateTime date;
  final String customerName;
  final String vehicleNumber;
  final String carModel;
  final List<DocumentLineItem> items;
  final EdgeInsets padding;

  double get total => items.fold<double>(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _pageWidth,
          height: _pageHeight,
          child: _TemplatePage(
            type: type,
            documentNumber: documentNumber,
            date: date,
            customerName: customerName,
            vehicleNumber: vehicleNumber,
            carModel: carModel,
            items: items,
            total: total,
            padding: padding,
          ),
        ),
      ),
    );
  }
}

class _TemplatePage extends StatelessWidget {
  const _TemplatePage({
    required this.type,
    required this.documentNumber,
    required this.date,
    required this.customerName,
    required this.vehicleNumber,
    required this.carModel,
    required this.items,
    required this.total,
    required this.padding,
  });

  final DocumentType type;
  final String documentNumber;
  final DateTime date;
  final String customerName;
  final String vehicleNumber;
  final String carModel;
  final List<DocumentLineItem> items;
  final double total;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final safeNumber = documentNumber.trim().isEmpty
        ? 'Draft'
        : documentNumber.trim();

    return Container(
      color: AppPalette.white,
      padding: padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -padding.left + 8,
            top: -padding.top + 16,
            width: 56,
            child: RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: 360,
                height: 56,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    maxLines: 1,
                    text: TextSpan(
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.56),
                        letterSpacing: 0,
                      ),
                      children: [
                        TextSpan(text: '${type.label} '),
                        TextSpan(
                          text: '[$safeNumber]',
                          style: const TextStyle(color: AppPalette.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLYWHEELS AUTO',
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppPalette.red,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ayush hospital road, beside Saibaba temple\n'
                            'Nagarjuna Nagar, Currency Nagar\n'
                            'Vijayawada, Andhra Pradesh -520008',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppPalette.muted,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GST IN: 37AAJFF3362M1Z1',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppPalette.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/branding/flywheels-logo.png',
                      width: 132,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1.4, color: AppPalette.red),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TemplateInfoBlock(
                        label: 'Date',
                        value: formatLongDate(date),
                      ),
                    ),
                    Expanded(
                      child: _TemplateInfoBlock(
                        label: 'To',
                        value: formatCustomerNameForDocument(customerName),
                      ),
                    ),
                    const Expanded(
                      child: _TemplateInfoBlock(
                        label: 'Ship To',
                        value: 'In-Store',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppPalette.border),
                const SizedBox(height: 16),
                Text(
                  'Vehicle Details',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  carModel.trim().isEmpty ? 'N/A' : carModel.trim(),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  vehicleNumber.trim().isEmpty ? 'N/A' : vehicleNumber.trim(),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: _TemplateItemsTable(items: items),
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 2, color: AppPalette.red),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _totalLabel(type),
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          formatCurrency(total),
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Thanks for choosing us to serve your automotive needs!',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppPalette.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(height: 2, color: AppPalette.border),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FooterLine(
                        label: 'Tel:',
                        value: '+ 91-9966783333\n+ 91-9563998998',
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          _FooterLine(
                            label: 'Email:',
                            value: 'flywheelsauto.vjy@gmail.com',
                          ),
                          SizedBox(height: 6),
                          _FooterLine(
                            label: 'Web:',
                            value: 'www.flywheelsauto.in',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'A 2LYP create',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.black38,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateInfoBlock extends StatelessWidget {
  const _TemplateInfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppPalette.red,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? 'N/A' : value.trim(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TemplateItemsTable extends StatelessWidget {
  const _TemplateItemsTable({required this.items});

  final List<DocumentLineItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.bodySmall?.copyWith(
      color: AppPalette.white,
      fontWeight: FontWeight.w800,
      fontSize: 10,
    );
    final cellStyle = textTheme.bodySmall?.copyWith(
      color: AppPalette.black,
      fontSize: 10,
    );

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FlexColumnWidth(),
      },
      border: TableBorder(
        horizontalInside: const BorderSide(color: AppPalette.border),
        bottom: const BorderSide(color: AppPalette.border),
        left: const BorderSide(color: AppPalette.border),
        right: const BorderSide(color: AppPalette.border),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppPalette.red),
          children: [
            _tableCell('Serial No.', headerStyle, align: TextAlign.center),
            _tableCell('Description', headerStyle),
            _tableCell('Unit Price', headerStyle, align: TextAlign.right),
            _tableCell('Quantity', headerStyle, align: TextAlign.right),
            _tableCell('Total', headerStyle, align: TextAlign.right),
          ],
        ),
        ...items.asMap().entries.map(
          (entry) => TableRow(
            children: [
              _tableCell(
                '${entry.key + 1}',
                cellStyle,
                align: TextAlign.center,
              ),
              _tableCell(
                entry.value.description,
                cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              _tableCell(
                entry.value.unitPrice > 0
                    ? formatCurrency(entry.value.unitPrice)
                    : '',
                cellStyle,
                align: TextAlign.right,
              ),
              _tableCell(
                entry.value.quantity.toString(),
                cellStyle,
                align: TextAlign.right,
              ),
              _tableCell(
                formatCurrency(entry.value.total),
                cellStyle?.copyWith(fontWeight: FontWeight.w700),
                align: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell(
    String value,
    TextStyle? style, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(value, style: style, textAlign: align),
    );
  }
}

class _FooterLine extends StatelessWidget {
  const _FooterLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppPalette.red,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 9, height: 1.25),
          ),
        ),
      ],
    );
  }
}

String _totalLabel(DocumentType type) {
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

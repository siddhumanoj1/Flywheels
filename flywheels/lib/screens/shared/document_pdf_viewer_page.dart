import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flutter/material.dart';

class DocumentPdfViewerPage extends StatelessWidget {
  const DocumentPdfViewerPage({
    super.key,
    required this.document,
    required this.car,
  });

  final ServiceDocument document;
  final CarProfile car;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${document.title} PDF')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    BrandLogo(size: 54),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FLYWHEELS AUTO'),
                        SizedBox(height: 4),
                        Text('Invoice, quotation, and receipt preview'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 2, color: AppPalette.red),
                const SizedBox(height: 18),
                Text(
                  document.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${document.type.label} | ${formatShortDate(document.updatedAt)}',
                ),
                const SizedBox(height: 16),
                Text('Vehicle: ${car.carNumber}'),
                Text('Model: ${car.model}'),
                const SizedBox(height: 16),
                ...document.items.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 26, child: Text('${entry.key + 1}.')),
                        Expanded(child: Text(entry.value.description)),
                        Text(
                          '${entry.value.quantity} x ${formatCurrency(entry.value.unitPrice)}',
                        ),
                        const SizedBox(width: 12),
                        Text(formatCurrency(entry.value.total)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(document.total),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text('Approval: ${document.approvalState.name}'),
                    ),
                    Chip(label: Text('Payment: ${document.paymentState.name}')),
                    Chip(label: Text(document.pdfLabel)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

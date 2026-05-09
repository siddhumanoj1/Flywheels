import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/document_template_preview.dart';
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
    final customer = FlywheelsScope.of(context).customerForCar(car.id);

    return Scaffold(
      appBar: AppBar(title: Text('${document.type.label} ${document.title}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.414,
            child: DocumentTemplatePreview(
              type: document.type,
              documentNumber: document.title,
              date: document.createdAt,
              customerName: customer?.name ?? 'Customer',
              vehicleNumber: car.carNumber,
              carModel: car.model,
              items: document.items,
            ),
          ),
        ],
      ),
    );
  }
}

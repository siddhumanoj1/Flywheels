import 'package:flywheels/models/app_models.dart';

abstract final class DocumentBuilderService {
  static DocumentDraft buildEmptyDraft({
    required DocumentType type,
    CarProfile? car,
  }) {
    return DocumentDraft(
      documentNumber: createDocumentNumber(type),
      type: type,
      customerName: '',
      customerPhone: '',
      vehicleNumber: car?.carNumber ?? '',
      carModel: car?.model ?? '',
      items: const [],
      selectedCarId: car?.id,
    );
  }

  static DocumentDraft parseOwnerInput(
    String rawText, {
    DocumentType? fallbackType,
    CarProfile? selectedCar,
  }) {
    final lines = rawText
        .replaceAll('\r', '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException(
        'Paste line items or the full document text before parsing.',
      );
    }

    final firstLineIsType = _looksLikeType(lines.first);
    final detectedType = firstLineIsType
        ? _detectType(lines.first, fallbackType)
        : _detectType('', fallbackType);

    late final String vehicleNumber;
    late final String carModel;
    late final String customerName;
    late final List<String> itemLines;

    if (firstLineIsType) {
      if (lines.length < 5) {
        throw const FormatException(
          'Add vehicle number, car model, customer name, and line items after the document type.',
        );
      }
      vehicleNumber = lines[1];
      carModel = lines[2];
      customerName = lines[3];
      itemLines = lines.skip(4).toList();
    } else if (selectedCar != null &&
        lines.length >= 3 &&
        !_looksLikeItem(lines[0]) &&
        !_looksLikeItem(lines[1]) &&
        !_looksLikeItem(lines[2])) {
      vehicleNumber = lines[0];
      carModel = lines[1];
      customerName = lines[2];
      itemLines = lines.skip(3).toList();
    } else if (selectedCar != null) {
      vehicleNumber = selectedCar.carNumber;
      carModel = selectedCar.model;
      if (_looksLikeItem(lines.first)) {
        customerName = '';
        itemLines = lines;
      } else {
        customerName = lines.first;
        itemLines = lines.skip(1).toList();
      }
    } else {
      if (lines.length < 4) {
        throw const FormatException(
          'Select a car or paste vehicle number, car model, customer name, and line items.',
        );
      }
      vehicleNumber = lines[0];
      carModel = lines[1];
      customerName = lines[2];
      itemLines = lines.skip(3).toList();
    }

    if (itemLines.isEmpty) {
      throw const FormatException(
        'Add at least one line item in Description - Price format.',
      );
    }

    return DocumentDraft(
      documentNumber: createDocumentNumber(detectedType),
      type: detectedType,
      customerName: customerName,
      customerPhone: '',
      vehicleNumber: vehicleNumber,
      carModel: carModel,
      items: itemLines.map(_parseLineItem).toList(),
      selectedCarId: selectedCar?.id,
      rawText: rawText,
    );
  }

  static DocumentDraft applyQuickCommand(DocumentDraft draft, String request) {
    final normalized = request.trim().toLowerCase();
    if (normalized.isEmpty) {
      return draft;
    }

    if (normalized.startsWith('remove ')) {
      final needle = normalized.replaceFirst(RegExp(r'^remove\s+'), '');
      final items = draft.items
          .where((item) => !item.description.toLowerCase().contains(needle))
          .toList();
      return draft.copyWith(items: items);
    }

    final addMatch = RegExp(
      r'^add\s+(.+?)\s+for\s+(\d+(?:\.\d+)?)\s*(each)?$',
      caseSensitive: false,
    ).firstMatch(request);
    if (addMatch != null) {
      final description = addMatch.group(1)!.trim();
      final price = double.parse(addMatch.group(2)!);
      final quantityMatch = RegExp(r'^(\d+)\s+(.+)$').firstMatch(description);
      final quantity = quantityMatch == null
          ? 1
          : int.parse(quantityMatch.group(1)!);
      final normalizedDescription = quantityMatch == null
          ? description
          : quantityMatch.group(2)!;
      return draft.copyWith(
        items: [
          ...draft.items,
          DocumentLineItem(
            description: normalizedDescription,
            quantity: quantity,
            unitPrice: price,
            total: price * quantity,
          ),
        ],
      );
    }

    final updateMatch = RegExp(
      r'^update\s+(.+?)\s+to\s+(\d+(?:\.\d+)?)$',
      caseSensitive: false,
    ).firstMatch(request);
    if (updateMatch != null) {
      final needle = updateMatch.group(1)!.trim().toLowerCase();
      final nextPrice = double.parse(updateMatch.group(2)!);
      var found = false;
      final items = draft.items.map((item) {
        if (!item.description.toLowerCase().contains(needle)) {
          return item;
        }
        found = true;
        return item.copyWith(
          unitPrice: nextPrice,
          total: nextPrice * item.quantity,
        );
      }).toList();

      if (!found) {
        throw const FormatException(
          'No line item matched that update request.',
        );
      }
      return draft.copyWith(items: items);
    }

    throw const FormatException('Use add, remove, or update commands.');
  }

  static String createDocumentNumber(
    DocumentType type, {
    Iterable<ServiceDocument> existingDocuments = const [],
  }) {
    final highestNumber = existingDocuments
        .map((document) => int.tryParse(document.title.trim()))
        .whereType<int>()
        .fold<int>(1999, (highest, value) => value > highest ? value : highest);
    return (highestNumber + 1).toString();
  }

  static DocumentType _detectType(
    String firstLine,
    DocumentType? fallbackType,
  ) {
    final normalized = firstLine.trim().toLowerCase();
    if (normalized == 'invoice') return DocumentType.invoice;
    if (normalized == 'quotation' || normalized == 'quote') {
      return DocumentType.quotation;
    }
    if (normalized == 'estimation' || normalized == 'estimate') {
      return DocumentType.estimation;
    }
    if (normalized == 'job card' || normalized == 'jobcard') {
      return DocumentType.jobCard;
    }
    if (fallbackType != null) return fallbackType;
    throw const FormatException(
      'Start the text with Invoice, Quotation, Estimation, or Job Card.',
    );
  }

  static bool _looksLikeType(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'invoice' ||
        normalized == 'quotation' ||
        normalized == 'quote' ||
        normalized == 'estimation' ||
        normalized == 'estimate' ||
        normalized == 'job card' ||
        normalized == 'jobcard';
  }

  static bool _looksLikeItem(String value) {
    return value.contains(' - ') ||
        RegExp(r'\d').hasMatch(value) && value.contains('*');
  }

  static DocumentLineItem _parseLineItem(String line) {
    final segments = line
        .split(RegExp(r'\s+-\s+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.length < 2) {
      throw FormatException(
        'Unable to parse "$line". Use Description - 100 style entries.',
      );
    }

    final description = segments[0];
    final firstMoney = _parseMoneySegment(segments[1]);
    final explicitTotal = segments.length > 2
        ? double.tryParse(segments[2].replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;

    return DocumentLineItem(
      description: description,
      quantity: firstMoney.quantity,
      unitPrice: firstMoney.unitPrice,
      total: explicitTotal ?? firstMoney.total,
    );
  }

  static _MoneyBreakdown _parseMoneySegment(String segment) {
    final cleaned = segment.replaceAll(RegExp(r'[^0-9.*]'), '').trim();
    if (cleaned.isEmpty) {
      return const _MoneyBreakdown(quantity: 1, unitPrice: 0, total: 0);
    }

    if (cleaned.contains('*')) {
      final parts = cleaned.split('*');
      final unitPrice = double.tryParse(parts.first) ?? 0;
      final quantity = int.tryParse(parts.last) ?? 1;
      return _MoneyBreakdown(
        quantity: quantity,
        unitPrice: unitPrice,
        total: unitPrice * quantity,
      );
    }

    final value = double.tryParse(cleaned) ?? 0;
    return _MoneyBreakdown(quantity: 1, unitPrice: value, total: value);
  }
}

class _MoneyBreakdown {
  const _MoneyBreakdown({
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final int quantity;
  final double unitPrice;
  final double total;
}

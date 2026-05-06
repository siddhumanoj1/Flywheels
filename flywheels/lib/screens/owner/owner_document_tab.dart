import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/document_builder_service.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/services/whatsapp_share_service.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flutter/material.dart';

class OwnerDocumentTab extends StatefulWidget {
  const OwnerDocumentTab({super.key, this.preferredCarId});

  final String? preferredCarId;

  @override
  State<OwnerDocumentTab> createState() => _OwnerDocumentTabState();
}

class _OwnerDocumentTabState extends State<OwnerDocumentTab> {
  final _rawTextController = TextEditingController();
  final _quickEditController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _carModelController = TextEditingController();
  final _fuelTypeController = TextEditingController(text: 'Petrol');
  final _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );

  DocumentType _selectedType = DocumentType.invoice;
  bool _useExistingCustomer = true;
  bool _showLibrary = false;
  bool _libraryNewestFirst = true;
  String? _selectedCustomerId;
  String? _selectedCarId;
  String _libraryQuery = '';
  DocumentType? _libraryTypeFilter;
  List<DocumentLineItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.preferredCarId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_documentNumberController.text.isEmpty) {
      _seedDraft();
    }
  }

  @override
  void didUpdateWidget(covariant OwnerDocumentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preferredCarId != null &&
        widget.preferredCarId != oldWidget.preferredCarId) {
      setState(() {
        _selectedCarId = widget.preferredCarId;
      });
      _hydrateFromSelectedCar();
    }
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _quickEditController.dispose();
    _documentNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _vehicleNumberController.dispose();
    _carModelController.dispose();
    _fuelTypeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _seedDraft() {
    final controller = FlywheelsScope.of(context);
    final selectedCar = controller.cars
        .where((car) => car.id == _selectedCarId)
        .firstOrNull;
    final draft = DocumentBuilderService.buildEmptyDraft(
      type: _selectedType,
      car: selectedCar,
    );
    _applyDraft(draft);
    _hydrateFromSelectedCar();
  }

  void _applyDraft(DocumentDraft draft) {
    setState(() {
      _selectedType = draft.type;
      _selectedCarId = draft.selectedCarId ?? _selectedCarId;
      _documentNumberController.text = draft.documentNumber;
      _customerNameController.text = draft.customerName;
      _customerPhoneController.text = draft.customerPhone;
      _vehicleNumberController.text = draft.vehicleNumber;
      _carModelController.text = draft.carModel;
      if (draft.rawText.isNotEmpty) {
        _rawTextController.text = draft.rawText;
      }
      _items = List<DocumentLineItem>.from(draft.items);
    });
  }

  void _hydrateFromSelectedCar() {
    final controller = FlywheelsScope.of(context);
    final selectedCar = controller.cars
        .where((car) => car.id == _selectedCarId)
        .firstOrNull;
    if (selectedCar == null) return;
    final customer = controller.customerForCar(selectedCar.id);
    setState(() {
      _vehicleNumberController.text = selectedCar.carNumber;
      _carModelController.text = selectedCar.model;
      _fuelTypeController.text = selectedCar.fuelType;
      _yearController.text = selectedCar.year.toString();
      _customerNameController.text =
          customer?.name ?? _customerNameController.text.trim();
      _customerPhoneController.text =
          customer?.phone ?? _customerPhoneController.text.trim();
      _selectedCustomerId = customer?.id ?? _selectedCustomerId;
    });
    _seedRawTemplate();
  }

  void _seedRawTemplate({bool force = false}) {
    final customerName = _customerNameController.text.trim();
    if (customerName.isEmpty) return;
    if (force || _rawTextController.text.trim().isEmpty) {
      _rawTextController.text = '$customerName\n\n';
    }
  }

  DocumentDraft _currentDraft() {
    return DocumentDraft(
      documentNumber: _documentNumberController.text.trim(),
      type: _selectedType,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim(),
      carModel: _carModelController.text.trim(),
      items: _items,
      selectedCarId: _selectedCarId,
      rawText: _rawTextController.text,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildModeSwitch() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: false,
          icon: Icon(Icons.edit_document),
          label: Text('Document Studio'),
        ),
        ButtonSegment<bool>(
          value: true,
          icon: Icon(Icons.library_books_outlined),
          label: Text('Document Library'),
        ),
      ],
      selected: {_showLibrary},
      onSelectionChanged: (selection) =>
          setState(() => _showLibrary = selection.first),
    );
  }

  void _parseDocument() {
    try {
      final controller = FlywheelsScope.of(context);
      final selectedCar = controller.cars
          .where((car) => car.id == _selectedCarId)
          .firstOrNull;
      final draft = DocumentBuilderService.parseOwnerInput(
        _rawTextController.text,
        fallbackType: _selectedType,
        selectedCar: selectedCar,
      );
      _applyDraft(
        draft.copyWith(
          customerName: draft.customerName.isEmpty
              ? _customerNameController.text.trim()
              : draft.customerName,
          vehicleNumber: draft.vehicleNumber.isEmpty
              ? _vehicleNumberController.text.trim()
              : draft.vehicleNumber,
          carModel: draft.carModel.isEmpty
              ? _carModelController.text.trim()
              : draft.carModel,
        ),
      );
      _showMessage('${draft.type.label} parsed successfully.');
    } on FormatException catch (error) {
      _showMessage(error.message);
    }
  }

  void _applyQuickEdit() {
    try {
      final draft = DocumentBuilderService.applyQuickCommand(
        _currentDraft(),
        _quickEditController.text,
      );
      _applyDraft(draft);
      _quickEditController.clear();
      _showMessage('Document updated.');
    } on FormatException catch (error) {
      _showMessage(error.message);
    }
  }

  void _addBlankItem() {
    setState(() {
      _items = [
        ..._items,
        const DocumentLineItem(
          description: '',
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
      ];
    });
  }

  void _updateItem(int index, DocumentLineItem item) {
    final items = List<DocumentLineItem>.from(_items);
    final shouldCalculate = item.quantity > 0 && item.unitPrice > 0;
    items[index] = item.copyWith(
      total: shouldCalculate ? item.quantity * item.unitPrice : item.total,
    );
    setState(() {
      _items = items;
    });
  }

  void _removeItem(int index) {
    final items = List<DocumentLineItem>.from(_items)..removeAt(index);
    setState(() {
      _items = items;
    });
  }

  Future<ServiceDocument?> _sendDocument({bool sendToChat = false}) async {
    if (_useExistingCustomer && _selectedCarId == null) {
      _showMessage('Select a car before sending a document.');
      return null;
    }
    if (!_useExistingCustomer &&
        (_customerNameController.text.trim().isEmpty ||
            _customerPhoneController.text.trim().isEmpty ||
            _vehicleNumberController.text.trim().isEmpty ||
            _carModelController.text.trim().isEmpty)) {
      _showMessage(
        'Complete customer, phone, vehicle, and model for new customer documents.',
      );
      return null;
    }
    if (_items.isEmpty) {
      _showMessage('Add at least one line item before sending.');
      return null;
    }

    final controller = FlywheelsScope.of(context);
    final document = controller.sendDocument(
      _currentDraft(),
      customerUserId: _useExistingCustomer ? _selectedCustomerId : null,
      fuelType: _fuelTypeController.text.trim(),
      year: int.tryParse(_yearController.text.trim()),
    );
    if (sendToChat && document != null) {
      final car = controller.cars
          .where((item) => item.id == document.carId)
          .firstOrNull;
      final customer = car == null ? null : controller.customerForCar(car.id);
      try {
        final export = await DocumentPdfExportService.exportDocument(
          document: document,
          car: car,
          customer: customer,
        );
        controller.sendDocumentInChat(
          document,
          attachmentPath: export.filePath,
        );
      } catch (_) {
        controller.sendDocumentInChat(document);
      }
    }
    _documentNumberController.text =
        DocumentBuilderService.createDocumentNumber(_selectedType);
    _showMessage(
      sendToChat
          ? '${_selectedType.label} sent and attached to chat.'
          : '${_selectedType.label} sent to the selected car.',
    );
    return document;
  }

  Future<void> _confirmSendDocument({bool sendToChat = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send ${_selectedType.label}?'),
        content: Text(
          sendToChat
              ? 'This saves the document and sends it in the customer chat.'
              : 'This saves the document to the customer Document Library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _sendDocument(sendToChat: sendToChat);
    }
  }

  Future<void> _showDraftPreviewDialog() async {
    final selectedCar = FlywheelsScope.of(
      context,
    ).cars.where((car) => car.id == _selectedCarId).firstOrNull;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selectedType.label} preview'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: _DraftPreviewContent(
              documentNumber: _documentNumberController.text,
              type: _selectedType,
              vehicleNumber:
                  selectedCar?.carNumber ?? _vehicleNumberController.text,
              carModel: _carModelController.text,
              customerName: _customerNameController.text,
              items: _items,
              total: _items.fold<double>(0, (sum, item) => sum + item.total),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmSendDocument();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareDraftOnWhatsapp() async {
    final phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Add a customer phone number first.');
      return;
    }
    final message =
        'FLYWHEELS AUTO\n'
        '${_selectedType.label}: ${_documentNumberController.text.trim()}\n'
        'Vehicle: ${_vehicleNumberController.text.trim()}\n'
        'Model: ${_carModelController.text.trim()}\n'
        'Customer: ${_customerNameController.text.trim()}\n'
        'Total: ${formatCurrency(_items.fold<double>(0, (sum, item) => sum + item.total))}';
    final sent = await WhatsappShareService.share(
      phone: phone,
      message: message,
    );
    if (!mounted) return;
    _showMessage(
      sent
          ? '${_selectedType.label} shared on WhatsApp.'
          : 'WhatsApp could not be opened.',
    );
  }

  Future<void> _shareDocumentOnWhatsapp(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    if (customer == null || customer.phone.trim().isEmpty) {
      _showMessage('No customer phone is available for this document.');
      return;
    }
    final export = await DocumentPdfExportService.exportDocument(
      document: document,
      car: car,
      customer: customer,
    );
    final sent = await WhatsappShareService.sharePdf(
      filePath: export.filePath,
      fileName: export.fileName,
      message: controller.buildDocumentWhatsappMessage(document),
    );
    if (!mounted) return;
    _showMessage(
      sent
          ? 'PDF ready for WhatsApp sharing.'
          : 'PDF saved. WhatsApp share sheet could not be opened.',
    );
  }

  Future<void> _downloadDocumentPdf(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    final export = await DocumentPdfExportService.exportDocument(
      document: document,
      car: car,
      customer: customer,
    );
    if (!mounted) return;
    _showMessage('${document.title} PDF saved to ${export.filePath}');
  }

  Future<void> _sharePaymentReminder(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    if (customer == null || customer.phone.trim().isEmpty) {
      _showMessage('No customer phone is available for this reminder.');
      return;
    }
    final sent = await WhatsappShareService.share(
      phone: customer.phone,
      message: controller.buildPaymentReminderMessage(document),
    );
    if (!mounted) return;
    _showMessage(
      sent
          ? 'Payment reminder shared on WhatsApp.'
          : 'WhatsApp could not be opened.',
    );
  }

  Future<void> _showDocumentPreviewDialog(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${document.type.label} preview'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: _ServiceDocumentPreviewContent(document: document, car: car),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadDocumentPdf(document);
            },
            child: const Text('Download PDF'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareDocumentOnWhatsapp(document);
            },
            child: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDocumentToChat(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    final export = await DocumentPdfExportService.exportDocument(
      document: document,
      car: car,
      customer: customer,
    );
    controller.sendDocumentInChat(document, attachmentPath: export.filePath);
    if (!mounted) return;
    _showMessage('${document.title} PDF sent in customer chat.');
  }

  Widget _buildDocumentLibrary(
    AppController controller,
    List<ServiceDocument> documents,
  ) {
    final needle = _libraryQuery.trim().toLowerCase();
    final visibleDocuments =
        documents.where((document) {
          final car = controller.cars
              .where((item) => item.id == document.carId)
              .firstOrNull;
          final customer = car == null
              ? null
              : controller.customerForCar(car.id);
          final searchable =
              '${document.title} ${document.type.label} ${document.approvalState.name} ${document.paymentState.name} ${car?.carNumber ?? ''} ${customer?.name ?? ''}';
          final matchesQuery =
              needle.isEmpty || searchable.toLowerCase().contains(needle);
          final matchesFilter =
              _libraryTypeFilter == null || document.type == _libraryTypeFilter;
          return matchesQuery && matchesFilter;
        }).toList()..sort(
          (left, right) => _libraryNewestFirst
              ? right.updatedAt.compareTo(left.updatedAt)
              : left.updatedAt.compareTo(right.updatedAt),
        );

    return ListView(
      key: const PageStorageKey('owner-document-library'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildModeSwitch(),
        const SizedBox(height: 16),
        Text('Document Library', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search documents, customers, cars',
          ),
          onChanged: (value) => setState(() => _libraryQuery = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<DocumentType?>(
                initialValue: _libraryTypeFilter,
                decoration: const InputDecoration(labelText: 'Filter'),
                items: [
                  const DropdownMenuItem<DocumentType?>(
                    value: null,
                    child: Text('All documents'),
                  ),
                  ...DocumentType.values.map(
                    (type) => DropdownMenuItem<DocumentType?>(
                      value: type,
                      child: Text(type.label),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _libraryTypeFilter = value),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: _libraryNewestFirst ? 'Newest first' : 'Oldest first',
              onPressed: () =>
                  setState(() => _libraryNewestFirst = !_libraryNewestFirst),
              icon: Icon(
                _libraryNewestFirst ? Icons.south_rounded : Icons.north_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (visibleDocuments.isEmpty)
          Text(
            'No documents match this view.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ...visibleDocuments.map((document) {
          final car = controller.cars
              .where((item) => item.id == document.carId)
              .firstOrNull;
          final customer = car == null
              ? null
              : controller.customerForCar(car.id);
          return _OwnerDocumentLibraryTile(
            document: document,
            car: car,
            customer: customer,
            onPreview: () => _showDocumentPreviewDialog(document),
            onDownload: () => _downloadDocumentPdf(document),
            onWhatsapp: () => _shareDocumentOnWhatsapp(document),
            onPaymentReminder: () => _sharePaymentReminder(document),
            onSendToChat: () => _sendDocumentToChat(document),
            onMarkPaid: () => controller.markDocumentPaid(document.id),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final selectedCar = controller.cars
        .where((car) => car.id == _selectedCarId)
        .firstOrNull;
    final customerCars = _selectedCustomerId == null
        ? controller.cars
        : controller.carsForCustomer(_selectedCustomerId!);
    final selectedCustomer = selectedCar == null
        ? null
        : controller.customerForCar(selectedCar.id);
    final documents = _selectedCarId == null
        ? controller.documents
        : controller.documentsForCar(_selectedCarId!);
    final noteHint = selectedCar == null
        ? 'Paste the full invoice, quotation, or estimation text. If you select a car first, this note area can stay much shorter.'
        : 'You do not need to paste the document type, vehicle number, or car model here. The selected car and document type will be used automatically.';

    if (_showLibrary) {
      return _buildDocumentLibrary(controller, documents);
    }

    return ListView(
      key: const PageStorageKey('owner-document-tab'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildModeSwitch(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document studio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Built from the invoice, quotation, and estimation maker flow: parse raw notes, edit line items, quick-edit with commands, preview, and send to a customer car.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Existing customer'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('New customer'),
                    ),
                  ],
                  selected: {_useExistingCustomer},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _useExistingCustomer = selection.first;
                      if (!_useExistingCustomer) {
                        _selectedCarId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<DocumentType>(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppPalette.white;
                      }
                      return AppPalette.black;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppPalette.red;
                      }
                      return AppPalette.soft;
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppPalette.border),
                    ),
                  ),
                  segments: DocumentType.values
                      .map(
                        (type) => ButtonSegment<DocumentType>(
                          value: type,
                          label: Text(type.label),
                        ),
                      )
                      .toList(),
                  selected: {_selectedType},
                  onSelectionChanged: (selection) {
                    final nextType = selection.first;
                    setState(() {
                      _selectedType = nextType;
                      _documentNumberController.text =
                          DocumentBuilderService.createDocumentNumber(nextType);
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_useExistingCustomer) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Select customer',
                    ),
                    items: controller.customers
                        .map(
                          (customer) => DropdownMenuItem<String>(
                            value: customer.id,
                            child: Text('${customer.name} - ${customer.phone}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomerId = value;
                        _selectedCarId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCarId,
                    decoration: const InputDecoration(labelText: 'Select car'),
                    items: customerCars
                        .map(
                          (car) => DropdownMenuItem<String>(
                            value: car.id,
                            child: Text('${car.carNumber} - ${car.model}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCarId = value;
                      });
                      _hydrateFromSelectedCar();
                    },
                  ),
                ],
                if (selectedCar != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-filled from selection',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _AutoFillLine(
                          label: 'Document',
                          value: _selectedType.label,
                        ),
                        _AutoFillLine(
                          label: 'Vehicle',
                          value: selectedCar.carNumber,
                        ),
                        _AutoFillLine(label: 'Model', value: selectedCar.model),
                        if (selectedCustomer != null)
                          _AutoFillLine(
                            label: 'Customer',
                            value: selectedCustomer.name,
                          ),
                        if (selectedCustomer != null)
                          _AutoFillLine(
                            label: 'Phone',
                            value: selectedCustomer.phone,
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _seedRawTemplate(force: true)),
                            child: const Text('Load quick template'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste notes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(noteHint, style: Theme.of(context).textTheme.bodySmall),
                if (selectedCar != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.soft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Text(
                      'Selected car mode is active. Paste only the customer name if needed and the line items below. You can skip typing the document type, vehicle number, and model.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _rawTextController,
                  minLines: 8,
                  maxLines: 12,
                  decoration: InputDecoration(
                    hintText: selectedCar == null
                        ? 'Invoice\nTS19F2222\nMG HECTOR 2.0D\nSAI HEMAJA AEROBRICKS PVTLTD\n\nOilfilter - 690\nEngineoil(fullysynth 5w30) - 800*5 - 4000'
                        : 'SAI HEMAJA AEROBRICKS PVTLTD\n\nOilfilter - 690\nAirfilter - 1050\nEngineoil(fullysynth 5w30) - 800*5 - 4000',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _parseDocument,
                  child: Text('Parse ${_selectedType.label}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _documentNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Document number',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        readOnly:
                            _useExistingCustomer && selectedCustomer != null,
                        decoration: InputDecoration(
                          labelText: 'Customer phone',
                          prefixText: '+91 ',
                          helperText:
                              _useExistingCustomer && selectedCustomer != null
                              ? 'Locked to selected customer'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _fuelTypeController,
                        readOnly: _useExistingCustomer && selectedCar != null,
                        decoration: InputDecoration(
                          labelText: 'Fuel type',
                          helperText:
                              _useExistingCustomer && selectedCar != null
                              ? 'Taken from selected car'
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vehicleNumberController,
                        readOnly: selectedCar != null,
                        decoration: InputDecoration(
                          labelText: 'Vehicle number',
                          helperText: selectedCar == null
                              ? null
                              : 'Locked to selected car',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _carModelController,
                        readOnly: selectedCar != null,
                        decoration: InputDecoration(
                          labelText: 'Car model',
                          helperText: selectedCar == null
                              ? null
                              : 'Locked to selected car',
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_useExistingCustomer) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle year',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Line items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _addBlankItem,
                      child: const Text('Add item'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Text(
                    'No items yet. Parse notes or add items manually.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ..._items.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LineItemEditor(
                      key: ValueKey(
                        '${entry.key}-${entry.value.description}-${entry.value.total}',
                      ),
                      index: entry.key,
                      item: entry.value,
                      onChanged: (item) => _updateItem(entry.key, item),
                      onRemove: () => _removeItem(entry.key),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick edit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Examples: add 2 wiper blades for 500 each, remove engine oil, update airfilter to 950',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quickEditController,
                  decoration: const InputDecoration(labelText: 'Command'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _applyQuickEdit,
                  child: const Text('Apply change'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preview opens in a dialog so the studio stays focused on editing.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showDraftPreviewDialog,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _shareDraftOnWhatsapp,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('WhatsApp'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _sendDocument(),
                      icon: const Icon(Icons.library_add_rounded),
                      label: Text('Send ${_selectedType.label}'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _confirmSendDocument(sendToChat: true),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Send to chat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoFillLine extends StatelessWidget {
  const _AutoFillLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppPalette.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LineItemEditor extends StatefulWidget {
  const _LineItemEditor({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DocumentLineItem item;
  final ValueChanged<DocumentLineItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<_LineItemEditor> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice == 0
          ? ''
          : widget.item.unitPrice.toStringAsFixed(0),
    );
    _totalController = TextEditingController(
      text: widget.item.total == 0 ? '' : widget.item.total.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _LineItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _descriptionController.text = widget.item.description;
      _quantityController.text = widget.item.quantity.toString();
      _priceController.text = widget.item.unitPrice == 0
          ? ''
          : widget.item.unitPrice.toStringAsFixed(0);
      _totalController.text = widget.item.total == 0
          ? ''
          : widget.item.total.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _emit() {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final total = double.tryParse(_totalController.text.trim()) ?? 0;
    widget.onChanged(
      DocumentLineItem(
        description: _descriptionController.text.trim(),
        quantity: quantity == 0 ? 1 : quantity,
        unitPrice: unitPrice,
        total: total,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${widget.index + 1}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _totalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Total'),
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftPreviewContent extends StatelessWidget {
  const _DraftPreviewContent({
    required this.documentNumber,
    required this.type,
    required this.vehicleNumber,
    required this.carModel,
    required this.customerName,
    required this.items,
    required this.total,
  });

  final String documentNumber;
  final DocumentType type;
  final String vehicleNumber;
  final String carModel;
  final String customerName;
  final List<DocumentLineItem> items;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            BrandLogo(size: 42),
            SizedBox(width: 12),
            Text('FLYWHEELS AUTO'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          documentNumber.isEmpty ? 'Draft number pending' : documentNumber,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(vehicleNumber, style: Theme.of(context).textTheme.bodyMedium),
        Text(carModel, style: Theme.of(context).textTheme.bodyMedium),
        Text(customerName, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ...items.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('${entry.key + 1}. ${entry.value.description}'),
                ),
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
            Text(type.label, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text(
              formatCurrency(total),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceDocumentPreviewContent extends StatelessWidget {
  const _ServiceDocumentPreviewContent({
    required this.document,
    required this.car,
  });

  final ServiceDocument document;
  final CarProfile? car;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            BrandLogo(size: 42),
            SizedBox(width: 12),
            Text('FLYWHEELS AUTO'),
          ],
        ),
        const SizedBox(height: 16),
        Text(document.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          car?.carNumber ?? 'Vehicle',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          car?.model ?? 'Model',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${document.type.label} | ${formatCurrency(document.total)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Approval: ${document.approvalState.name}')),
            Chip(label: Text('Payment: ${document.paymentState.name}')),
          ],
        ),
      ],
    );
  }
}

class _OwnerDocumentLibraryTile extends StatelessWidget {
  const _OwnerDocumentLibraryTile({
    required this.document,
    required this.car,
    required this.customer,
    required this.onPreview,
    required this.onDownload,
    required this.onWhatsapp,
    required this.onPaymentReminder,
    required this.onSendToChat,
    required this.onMarkPaid,
  });

  final ServiceDocument document;
  final CarProfile? car;
  final GarageUser? customer;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onWhatsapp;
  final VoidCallback onPaymentReminder;
  final VoidCallback onSendToChat;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                formatShortDate(document.updatedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${document.type.label} | ${formatCurrency(document.total)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Approval: ${document.approvalState.name}')),
              Chip(label: Text('Payment: ${document.paymentState.name}')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onPreview,
                child: const Text('Preview'),
              ),
              OutlinedButton(
                onPressed: onDownload,
                child: const Text('Download PDF'),
              ),
              OutlinedButton(
                onPressed: onWhatsapp,
                child: const Text('WhatsApp'),
              ),
              OutlinedButton(
                onPressed: onSendToChat,
                child: const Text('Send to chat'),
              ),
              if (document.type == DocumentType.invoice &&
                  document.paymentState != PaymentState.paid)
                OutlinedButton(
                  onPressed: onPaymentReminder,
                  child: const Text('Payment reminder'),
                ),
            ],
          ),
          if (document.type == DocumentType.invoice &&
              document.paymentState != PaymentState.paid) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onMarkPaid,
              child: const Text('Mark as paid'),
            ),
          ],
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

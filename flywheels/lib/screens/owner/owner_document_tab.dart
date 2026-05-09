import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/document_builder_service.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/services/whatsapp_share_service.dart';
import 'package:flywheels/widgets/document_template_preview.dart';
import 'package:flutter/material.dart';

class OwnerDocumentTab extends StatefulWidget {
  const OwnerDocumentTab({super.key, this.preferredCarId});

  final String? preferredCarId;

  @override
  State<OwnerDocumentTab> createState() => _OwnerDocumentTabState();
}

class _OwnerDocumentTabState extends State<OwnerDocumentTab> {
  final _scrollController = ScrollController();
  final _rawTextController = TextEditingController();
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
    _scrollController.dispose();
    _rawTextController.dispose();
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
    ).copyWith(documentNumber: _nextDocumentNumber(_selectedType));
    _applyDraft(draft);
    _hydrateFromSelectedCar();
  }

  String _nextDocumentNumber(DocumentType type) {
    return DocumentBuilderService.createDocumentNumber(
      type,
      existingDocuments: FlywheelsScope.of(context).documents,
    );
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

  void _hydrateFromSelectedCustomer() {
    final controller = FlywheelsScope.of(context);
    final customer = _selectedCustomerId == null
        ? null
        : controller.userById(_selectedCustomerId!);
    if (customer == null) return;
    setState(() {
      _customerNameController.text = customer.name;
      _customerPhoneController.text = customer.phone;
    });
    _seedRawTemplate();
  }

  GarageUser? _selectedCustomer(AppController controller) {
    final selectedCar = controller.cars
        .where((car) => car.id == _selectedCarId)
        .firstOrNull;
    if (selectedCar != null) {
      return controller.customerForCar(selectedCar.id);
    }
    if (_selectedCustomerId == null) return null;
    return controller.userById(_selectedCustomerId!);
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
          documentNumber: _documentNumberController.text.trim().isEmpty
              ? _nextDocumentNumber(draft.type)
              : _documentNumberController.text.trim(),
          customerName: draft.customerName.isEmpty
              ? _customerNameController.text.trim()
              : draft.customerName,
          customerPhone: draft.customerPhone.isEmpty
              ? _customerPhoneController.text.trim()
              : draft.customerPhone,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  IconData _documentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.quotation:
        return Icons.request_quote_rounded;
      case DocumentType.estimation:
        return Icons.calculate_rounded;
      case DocumentType.invoice:
        return Icons.receipt_long_rounded;
      case DocumentType.jobCard:
        return Icons.assignment_rounded;
    }
  }

  void _updateItem(int index, DocumentLineItem item, {bool rebuild = false}) {
    if (index < 0 || index >= _items.length) {
      return;
    }
    final items = List<DocumentLineItem>.from(_items);
    final shouldCalculate = item.quantity > 0 && item.unitPrice > 0;
    items[index] = item.copyWith(
      total: shouldCalculate ? item.quantity * item.unitPrice : item.total,
    );
    if (rebuild) {
      setState(() {
        _items = items;
      });
    } else {
      _items = items;
    }
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
    setState(() {
      _documentNumberController.text = _nextDocumentNumber(_selectedType);
    });
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

  bool _validateDraftForOutput() {
    if (_documentNumberController.text.trim().isEmpty) {
      _showMessage('Add a document number before creating the document.');
      return false;
    }
    if (_customerNameController.text.trim().isEmpty ||
        _vehicleNumberController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty) {
      _showMessage('Complete customer, vehicle, and model details first.');
      return false;
    }
    if (_items.isEmpty) {
      _showMessage('Add at least one line item before creating a document.');
      return false;
    }
    return true;
  }

  void _createDraftPreview() {
    if (!_validateDraftForOutput()) return;
    _showDraftPreviewDialog();
  }

  Future<void> _downloadDraftPdf() async {
    if (!_validateDraftForOutput()) return;
    _showMessage('Preparing PDF download...');
    try {
      final export = await DocumentPdfExportService.exportDraft(
        draft: _currentDraft(),
      );
      if (!mounted) return;
      _showMessage('${_selectedType.label} PDF saved to ${export.filePath}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF download failed: $error');
    }
  }

  Future<void> _showDraftPreviewDialog() async {
    if (!_validateDraftForOutput()) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final previewHeight = MediaQuery.sizeOf(context).height * 0.68;
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 8, 0),
          title: Row(
            children: [
              Expanded(child: Text('${_selectedType.label} preview')),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            height: previewHeight.clamp(360, 720),
            child: DocumentTemplatePreview(
              type: _selectedType,
              documentNumber: _documentNumberController.text,
              date: DateTime.now(),
              customerName: _customerNameController.text,
              vehicleNumber: _vehicleNumberController.text,
              carModel: _carModelController.text,
              items: _items,
              padding: const EdgeInsets.all(24),
            ),
          ),
          actions: [
            IconButton.outlined(
              tooltip: 'Download PDF',
              onPressed: () {
                Navigator.of(context).pop();
                _downloadDraftPdf();
              },
              icon: const Icon(Icons.download_rounded),
            ),
            IconButton.outlined(
              tooltip: 'WhatsApp',
              onPressed: () {
                Navigator.of(context).pop();
                _shareDraftOnWhatsapp();
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton.outlined(
              tooltip: 'Send to chat',
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSendDocument(sendToChat: true);
              },
              icon: const Icon(Icons.chat_bubble_rounded),
            ),
            IconButton.filled(
              tooltip: 'Save document',
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSendDocument();
              },
              icon: const Icon(Icons.library_add_rounded),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareDraftOnWhatsapp() async {
    final phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Add a customer phone number first.');
      return;
    }
    if (!_validateDraftForOutput()) return;
    _showMessage('Preparing PDF for sharing...');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      final export = await DocumentPdfExportService.exportDraft(
        draft: _currentDraft(),
      );
      final sent = await WhatsappShareService.sharePdf(
        filePath: export.filePath,
        fileName: export.fileName,
        message:
            'FLYWHEELS AUTO\n'
            '${_selectedType.label}: ${_documentNumberController.text.trim()}\n'
            'Vehicle: ${_vehicleNumberController.text.trim()}\n'
            'Total: ${formatCurrency(_items.fold<double>(0, (sum, item) => sum + item.total))}',
      );
      if (!mounted) return;
      _showMessage(
        sent
            ? '${_selectedType.label} PDF ready for sharing.'
            : 'PDF saved. Share sheet could not be opened.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF share failed: $error');
    }
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
    _showMessage('Preparing PDF for sharing...');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
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
            ? 'PDF ready for sharing.'
            : 'PDF saved. Share sheet could not be opened.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF share failed: $error');
    }
  }

  Future<void> _downloadDocumentPdf(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    _showMessage('Preparing PDF download...');
    try {
      final export = await DocumentPdfExportService.exportDocument(
        document: document,
        car: car,
        customer: customer,
      );
      if (!mounted) return;
      _showMessage('${document.title} PDF saved to ${export.filePath}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF download failed: $error');
    }
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
    final customer = car == null ? null : controller.customerForCar(car.id);
    await showDialog<void>(
      context: context,
      builder: (context) {
        final previewHeight = MediaQuery.sizeOf(context).height * 0.68;
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 8, 0),
          title: Row(
            children: [
              Expanded(child: Text('${document.type.label} ${document.title}')),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            height: previewHeight.clamp(360, 720),
            child: DocumentTemplatePreview(
              type: document.type,
              documentNumber: document.title,
              date: document.createdAt,
              customerName: customer?.name ?? 'Customer',
              vehicleNumber: car?.carNumber ?? 'Vehicle',
              carModel: car?.model ?? 'N/A',
              items: document.items,
              padding: const EdgeInsets.all(24),
            ),
          ),
          actions: [
            IconButton.outlined(
              tooltip: 'Download PDF',
              onPressed: () {
                Navigator.of(context).pop();
                _downloadDocumentPdf(document);
              },
              icon: const Icon(Icons.download_rounded),
            ),
            IconButton.outlined(
              tooltip: 'Send to chat',
              onPressed: () {
                Navigator.of(context).pop();
                _sendDocumentToChat(document);
              },
              icon: const Icon(Icons.chat_bubble_rounded),
            ),
            IconButton.filled(
              tooltip: 'WhatsApp',
              onPressed: () {
                Navigator.of(context).pop();
                _shareDocumentOnWhatsapp(document);
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDocumentToChat(ServiceDocument document) async {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    _showMessage('Preparing PDF for chat...');
    try {
      final export = await DocumentPdfExportService.exportDocument(
        document: document,
        car: car,
        customer: customer,
      );
      controller.sendDocumentInChat(document, attachmentPath: export.filePath);
      if (!mounted) return;
      _showMessage('${document.title} PDF sent in customer chat.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF chat send failed: $error');
    }
  }

  Future<void> _confirmDeleteDocument(ServiceDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${document.title}?'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    FlywheelsScope.of(context).deleteDocument(document.id);
    _showMessage('${document.title} deleted.');
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
            onDelete: () => _confirmDeleteDocument(document),
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
    final selectedCustomer = _selectedCustomer(controller);
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
      controller: _scrollController,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StudioChoiceCard(
                        icon: Icons.person_search_rounded,
                        title: 'Existing customer',
                        selected: _useExistingCustomer,
                        onTap: () {
                          setState(() => _useExistingCustomer = true);
                          _hydrateFromSelectedCustomer();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StudioChoiceCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'New customer',
                        selected: !_useExistingCustomer,
                        onTap: () {
                          setState(() {
                            _useExistingCustomer = false;
                            _selectedCustomerId = null;
                            _selectedCarId = null;
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                            _vehicleNumberController.clear();
                            _carModelController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: DocumentType.values.map((type) {
                    return ChoiceChip(
                      avatar: Icon(
                        _documentTypeIcon(type),
                        size: 18,
                        color: _selectedType == type
                            ? AppPalette.white
                            : AppPalette.black,
                      ),
                      label: Text(type.label),
                      selected: _selectedType == type,
                      selectedColor: AppPalette.red,
                      labelStyle: TextStyle(
                        color: _selectedType == type
                            ? AppPalette.white
                            : AppPalette.black,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedType = type;
                          _documentNumberController.text = _nextDocumentNumber(
                            type,
                          );
                        });
                      },
                    );
                  }).toList(),
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
                      _hydrateFromSelectedCustomer();
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
                        keyboardType: TextInputType.number,
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
                      key: ValueKey('line-item-${entry.key}'),
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
                FilledButton.icon(
                  onPressed: _createDraftPreview,
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Create document'),
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

class _StudioChoiceCard extends StatelessWidget {
  const _StudioChoiceCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppPalette.red : AppPalette.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppPalette.red : AppPalette.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppPalette.white : AppPalette.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? AppPalette.white : AppPalette.black,
                ),
              ),
            ),
          ],
        ),
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
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _quantityFocusNode;
  late final FocusNode _priceFocusNode;
  late final FocusNode _totalFocusNode;

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
    _descriptionFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
    _totalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _LineItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item && !_hasFocus) {
      _syncControllers(widget.item);
    }
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _totalFocusNode.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  bool get _hasFocus =>
      _descriptionFocusNode.hasFocus ||
      _quantityFocusNode.hasFocus ||
      _priceFocusNode.hasFocus ||
      _totalFocusNode.hasFocus;

  void _syncControllers(DocumentLineItem item) {
    _descriptionController.text = item.description;
    _quantityController.text = item.quantity.toString();
    _priceController.text = item.unitPrice == 0
        ? ''
        : item.unitPrice.toStringAsFixed(0);
    _totalController.text = item.total == 0
        ? ''
        : item.total.toStringAsFixed(0);
  }

  void _emit({bool refreshCalculatedTotal = false}) {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final calculatedTotal = quantity > 0 && unitPrice > 0
        ? quantity * unitPrice
        : 0.0;
    var total = double.tryParse(_totalController.text.trim()) ?? 0;
    if (refreshCalculatedTotal && calculatedTotal > 0) {
      total = calculatedTotal;
      final nextTotal = total.toStringAsFixed(0);
      if (_totalController.text != nextTotal) {
        _totalController.value = TextEditingValue(
          text: nextTotal,
          selection: TextSelection.collapsed(offset: nextTotal.length),
        );
      }
    }
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
            focusNode: _descriptionFocusNode,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => _emit(),
            onEditingComplete: _emit,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  focusNode: _priceFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  onChanged: (_) => _emit(refreshCalculatedTotal: true),
                  onEditingComplete: () => _emit(refreshCalculatedTotal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  focusNode: _quantityFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (_) => _emit(refreshCalculatedTotal: true),
                  onEditingComplete: () => _emit(refreshCalculatedTotal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _totalController,
                  focusNode: _totalFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Total'),
                  onChanged: (_) => _emit(),
                  onEditingComplete: _emit,
                ),
              ),
            ],
          ),
        ],
      ),
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
    required this.onDelete,
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
  final VoidCallback onDelete;

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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton.outlined(
                tooltip: 'Preview PDF',
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_rounded),
              ),
              IconButton.outlined(
                tooltip: 'Download PDF',
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
              ),
              IconButton.outlined(
                tooltip: 'WhatsApp',
                onPressed: onWhatsapp,
                icon: const Icon(Icons.ios_share_rounded),
              ),
              IconButton.outlined(
                tooltip: 'Send to chat',
                onPressed: onSendToChat,
                icon: const Icon(Icons.chat_bubble_rounded),
              ),
              if (document.type == DocumentType.invoice &&
                  document.paymentState != PaymentState.paid)
                IconButton.outlined(
                  tooltip: 'Payment reminder',
                  onPressed: onPaymentReminder,
                  icon: const Icon(Icons.notifications_active_rounded),
                ),
              IconButton.outlined(
                tooltip: 'Delete document',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (document.type == DocumentType.invoice &&
              document.paymentState != PaymentState.paid) ...[
            const SizedBox(height: 12),
            IconButton.outlined(
              tooltip: 'Mark as paid',
              onPressed: onMarkPaid,
              icon: const Icon(Icons.price_check_rounded),
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

import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/owner/owner_document_tab.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final _picker = ImagePicker();
  final _ownerReplyController = TextEditingController();
  int _currentIndex = 0;
  String? _preferredCarId;
  String? _selectedOwnerChatUserId;
  String? _selectedOwnerChatCarId;
  String _ownerChatSearch = '';
  bool _ownerChatSlideForward = true;
  _OwnerGarageFilter _garageFilter = _OwnerGarageFilter.inGarage;

  @override
  void dispose() {
    _ownerReplyController.dispose();
    super.dispose();
  }

  Future<void> _addGaragePhoto(
    BuildContext context,
    CarProfile car, {
    JobStatus? status,
  }) async {
    final controller = FlywheelsScope.read(context);
    final captionController = TextEditingController();
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Garage photo update',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                status == null
                    ? 'Add a caption for the photo you are about to upload for ${car.carNumber}.'
                    : 'This photo will move ${car.carNumber} to ${status.label}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'What did the garage complete or inspect?',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(captionController.text.trim()),
                  child: const Text('Continue to photo'),
                ),
              ),
            ],
          ),
        );
      },
    );
    captionController.dispose();
    if (!mounted || caption == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;

    controller.addGaragePhoto(
      carId: car.id,
      imagePath: image.path,
      caption: caption,
      status: status,
    );
  }

  void _showPickupAssignmentSheet(BuildContext context, ServiceJob job) {
    final controller = FlywheelsScope.read(context);
    final car = controller.cars
        .where((item) => item.id == job.carId)
        .firstOrNull;
    final nameController = TextEditingController(
      text: job.pickupPersonName ?? '',
    );
    final phoneController = TextEditingController(
      text: job.pickupPersonPhone ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign pickup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${car?.carNumber ?? 'Vehicle'} | ${formatDateTime(job.pickupTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup person name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Pickup person phone',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.assignPickup(
                        job.id,
                        personName: nameController.text,
                        personPhone: phoneController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Assign and notify customer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
    });
  }

  Future<void> _completePickupWithPhoto(
    BuildContext context,
    ServiceJob job,
  ) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!context.mounted) return;
    FlywheelsScope.read(
      context,
    ).completePickup(job.id, proofImagePath: image?.path);
  }

  void _showAddOwnerCarSheet(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final customers = controller.customers;
    if (customers.isEmpty) return;

    final carNumberController = TextEditingController();
    final modelController = TextEditingController();
    final fuelController = TextEditingController(text: 'Petrol');
    final yearController = TextEditingController(
      text: DateTime.now().year.toString(),
    );
    var selectedCustomerId = customers.first.id;
    String? selectedImagePath;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add car manually',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                        ),
                        items: customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(
                                  '${customer.name} - ${customer.phone}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedCustomerId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: carNumberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle number',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model / variant',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fuelController,
                              decoration: const InputDecoration(
                                labelText: 'Fuel type',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setSheetState(() => selectedImagePath = image.path);
                          }
                        },
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(
                          selectedImagePath == null
                              ? 'Add car photo'
                              : 'Change car photo',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.addOwnerCarForCustomer(
                              customerUserId: selectedCustomerId,
                              carNumber: carNumberController.text.trim(),
                              model: modelController.text.trim(),
                              fuelType: fuelController.text.trim(),
                              year:
                                  int.tryParse(yearController.text.trim()) ??
                                  DateTime.now().year,
                              imagePath: selectedImagePath,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Save car'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      carNumberController.dispose();
      modelController.dispose();
      fuelController.dispose();
      yearController.dispose();
    });
  }

  void _sendOwnerReply() {
    final controller = FlywheelsScope.read(context);
    if (_selectedOwnerChatUserId == null ||
        _ownerReplyController.text.trim().isEmpty) {
      return;
    }
    controller.sendOwnerMessage(
      customerUserId: _selectedOwnerChatUserId!,
      topic: 'Garage update',
      message: _ownerReplyController.text.trim(),
      carId: _selectedOwnerChatCarId,
    );
    setState(() => _ownerReplyController.clear());
  }

  Future<void> _sendDocumentToSelectedChat(ServiceDocument document) async {
    final controller = FlywheelsScope.read(context);
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
      controller.sendDocumentInChat(document, attachmentPath: export.filePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${document.title} PDF sent in chat.')),
      );
    } catch (_) {
      controller.sendDocumentInChat(document);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${document.title} sent in chat.')),
      );
    }
  }

  Future<void> _sendOwnerChatPhoto() async {
    final customerUserId = _selectedOwnerChatUserId;
    if (customerUserId == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    FlywheelsScope.read(context).sendOwnerMessage(
      customerUserId: customerUserId,
      topic: 'Photo',
      message: _ownerReplyController.text.trim(),
      carId: _selectedOwnerChatCarId,
      attachmentPath: image.path,
    );
    setState(() => _ownerReplyController.clear());
  }

  void _openChatForCar(CarProfile car) {
    setState(() {
      _selectedOwnerChatUserId = car.userId;
      _selectedOwnerChatCarId = car.id;
      _ownerChatSlideForward = true;
      _currentIndex = 2;
    });
    FlywheelsScope.read(context).markConversationReadByOwner(car.userId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final titles = ['Owner Dashboard', 'Cars', 'Chat', 'Documents'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 33),
            const SizedBox(width: 14),
            Text(titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _OwnerDashboardTab(
            onAssignPickup: (job) => _showPickupAssignmentSheet(context, job),
            onCompletePickup: (job) => _completePickupWithPhoto(context, job),
            onOpenCars: (filter) => setState(() {
              _garageFilter = filter;
              _currentIndex = 1;
            }),
            onOpenDocuments: (carId) => setState(() {
              _preferredCarId = carId.isEmpty ? null : carId;
              _currentIndex = 3;
            }),
            onOpenChat: _openChatForCar,
          ),
          _OwnerOperationsTab(
            filter: _garageFilter,
            onFilterChanged: (value) => setState(() => _garageFilter = value),
            onOpenDocuments: (carId) {
              setState(() {
                _preferredCarId = carId;
                _currentIndex = 3;
              });
            },
            onOpenChat: _openChatForCar,
            onAddPhoto: (car, status) =>
                _addGaragePhoto(context, car, status: status),
            onAssignPickup: (job) => _showPickupAssignmentSheet(context, job),
            onCompletePickup: (job) => _completePickupWithPhoto(context, job),
            onAddCar: () => _showAddOwnerCarSheet(context),
          ),
          _OwnerChatTab(
            selectedUserId: _selectedOwnerChatUserId,
            selectedCarId: _selectedOwnerChatCarId,
            searchQuery: _ownerChatSearch,
            slideForward: _ownerChatSlideForward,
            replyController: _ownerReplyController,
            onUserChanged: (value) => setState(() {
              _selectedOwnerChatUserId = value;
              _selectedOwnerChatCarId = null;
              _ownerChatSlideForward = value != null;
            }),
            onBack: () => setState(() {
              _selectedOwnerChatUserId = null;
              _selectedOwnerChatCarId = null;
              _ownerChatSlideForward = false;
            }),
            onCarChanged: (value) =>
                setState(() => _selectedOwnerChatCarId = value),
            onSearchChanged: (value) =>
                setState(() => _ownerChatSearch = value),
            onSendDocument: _sendDocumentToSelectedChat,
            onSendPhoto: _sendOwnerChatPhoto,
            onSend: _sendOwnerReply,
          ),
          OwnerDocumentTab(preferredCarId: _preferredCarId),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        badgeCounts: [
          0,
          0,
          controller.unreadMessageCountForCurrentSession(),
          0,
        ],
        items: const [
          AppBottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          AppBottomNavItem(
            icon: Icons.directions_car_outlined,
            activeIcon: Icons.directions_car_rounded,
            label: 'Cars',
          ),
          AppBottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chat',
          ),
          AppBottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Docs',
          ),
        ],
      ),
    );
  }
}

enum _OwnerGarageFilter { inGarage, inTransit, completed, onRoad }

class _OwnerDashboardTab extends StatelessWidget {
  const _OwnerDashboardTab({
    required this.onAssignPickup,
    required this.onCompletePickup,
    required this.onOpenCars,
    required this.onOpenDocuments,
    required this.onOpenChat,
  });

  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final ValueChanged<_OwnerGarageFilter> onOpenCars;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;

  void _openMetricSheet(
    BuildContext context,
    String title,
    List<_DashboardDetailItem> items,
  ) {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = items.where((item) {
              final needle = query.trim().toLowerCase();
              if (needle.isEmpty) return true;
              return item.searchText.toLowerCase().contains(needle);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search customer name or phone',
                        ),
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matches',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(item.icon),
                                    title: Text(item.title),
                                    subtitle: Text(item.subtitle),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final cars = controller.cars;
    final documents = controller.documents;
    final pending = documents
        .where((document) => document.approvalState == ApprovalState.pending)
        .toList();
    final revenue = documents
        .where((document) => document.type == DocumentType.invoice)
        .fold<double>(0, (sum, doc) => sum + doc.total);
    final inGarage = cars
        .where((car) => controller.workflowStateForCar(car.id).isInGarage)
        .toList();
    final transitQueue = cars
        .where((car) => controller.workflowStateForCar(car.id).isTransit)
        .toList();
    final completed = cars
        .where(
          (car) =>
              controller.workflowStateForCar(car.id) ==
              CarWorkflowState.readyForDelivery,
        )
        .toList();
    final inspection = cars
        .where(
          (car) =>
              controller.workflowStateForCar(car.id) ==
              CarWorkflowState.underInspection,
        )
        .toList();
    final workInProgress = cars
        .where(
          (car) =>
              controller.workflowStateForCar(car.id) ==
              CarWorkflowState.workInProgress,
        )
        .toList();
    final invoicesDue = documents
        .where(
          (document) =>
              document.type == DocumentType.invoice &&
              document.paymentState != PaymentState.paid,
        )
        .toList();
    final urgentDocuments = pending.take(3).toList();
    final actionJobs = cars
        .where((car) => controller.workflowStateForCar(car.id).needsOwnerAction)
        .map((car) => controller.latestJobForCar(car.id))
        .whereType<ServiceJob>()
        .take(5)
        .toList();

    _DashboardDetailItem carItem(CarProfile car) {
      final customer = controller.customerForCar(car.id);
      final state = controller.workflowStateForCar(car.id);
      return _DashboardDetailItem(
        icon: Icons.directions_car_rounded,
        title: '${car.carNumber} - ${car.model}',
        subtitle:
            '${customer?.name ?? 'Customer'} | ${customer?.phone ?? '-'} | ${state.label}',
        searchText:
            '${customer?.name ?? ''} ${customer?.phone ?? ''} ${car.carNumber}',
      );
    }

    final pendingItems = pending.map((document) {
      final car = controller.cars
          .where((item) => item.id == document.carId)
          .firstOrNull;
      final customer = car == null ? null : controller.customerForCar(car.id);
      return _DashboardDetailItem(
        icon: Icons.pending_actions_rounded,
        title: '${document.title} - ${formatCurrency(document.total)}',
        subtitle:
            '${customer?.name ?? 'Customer'} | ${customer?.phone ?? '-'} | ${car?.carNumber ?? '-'}',
        searchText:
            '${customer?.name ?? ''} ${customer?.phone ?? ''} ${car?.carNumber ?? ''}',
      );
    }).toList();
    final revenueItems = documents
        .where((document) => document.type == DocumentType.invoice)
        .map((document) {
          final car = controller.cars
              .where((item) => item.id == document.carId)
              .firstOrNull;
          final customer = car == null
              ? null
              : controller.customerForCar(car.id);
          return _DashboardDetailItem(
            icon: Icons.payments_rounded,
            title: '${document.title} - ${formatCurrency(document.total)}',
            subtitle:
                '${customer?.name ?? 'Customer'} | ${customer?.phone ?? '-'} | ${document.paymentState.name}',
            searchText:
                '${customer?.name ?? ''} ${customer?.phone ?? ''} ${car?.carNumber ?? ''}',
          );
        })
        .toList();

    return ListView(
      key: const PageStorageKey('owner-dashboard'),
      padding: const EdgeInsets.all(16),
      children: [
        _OwnerTodayHeader(
          pickupCount: transitQueue.length,
          inspectionCount: inspection.length,
          workCount: workInProgress.length,
          documentCount: pending.length,
        ),
        const SizedBox(height: 14),
        _OwnerWorkflowStrip(
          pickupCount: transitQueue.length,
          garageCount: inGarage.length,
          inspectionCount: inspection.length,
          workCount: workInProgress.length,
          completedCount: completed.length,
          onOpenCars: onOpenCars,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _MetricCard(
              icon: Icons.directions_car_rounded,
              label: 'Cars in garage',
              value: inGarage.length.toString(),
              onTap: () => _openMetricSheet(
                context,
                'Cars in garage',
                inGarage.map(carItem).toList(),
              ),
            ),
            _MetricCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pending approvals',
              value: pending.length.toString(),
              onTap: () =>
                  _openMetricSheet(context, 'Pending approvals', pendingItems),
            ),
            _MetricCard(
              icon: Icons.task_alt_rounded,
              label: 'Completed jobs',
              value: completed.length.toString(),
              onTap: () => _openMetricSheet(
                context,
                'Completed jobs',
                completed.map(carItem).toList(),
              ),
            ),
            _MetricCard(
              icon: Icons.payments_rounded,
              label: 'Revenue',
              value: formatCurrency(revenue),
              onTap: () => _openMetricSheet(context, 'Revenue', revenueItems),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _OwnerPriorityQueue(
          jobs: actionJobs,
          controller: controller,
          onAssignPickup: onAssignPickup,
          onCompletePickup: onCompletePickup,
          onOpenDocuments: onOpenDocuments,
          onOpenChat: onOpenChat,
        ),
        const SizedBox(height: 16),
        _OwnerDocumentActions(
          pending: urgentDocuments,
          invoicesDue: invoicesDue,
          onOpenDocuments: onOpenDocuments,
        ),
        const SizedBox(height: 16),
        _OwnerRecentUpdates(
          notifications: controller.notifications.take(5).toList(),
        ),
        const SizedBox(height: 16),
        _OwnerQuickLaunchRow(
          onOpenGarage: () => onOpenCars(_OwnerGarageFilter.inGarage),
          onOpenTransit: () => onOpenCars(_OwnerGarageFilter.inTransit),
          onOpenDocuments: () => onOpenDocuments(''),
        ),
        const SizedBox(height: 12),
        if (revenueItems.isEmpty && pendingItems.isEmpty)
          const _EmptyOwnerList(message: 'No document activity yet.'),
        if (pendingItems.isNotEmpty || revenueItems.isNotEmpty)
          _OwnerSmallSummary(
            pendingItems: pendingItems.length,
            invoiceItems: revenueItems.length,
            revenue: revenue,
          ),
      ],
    );
  }
}

class _OwnerTodayHeader extends StatelessWidget {
  const _OwnerTodayHeader({
    required this.pickupCount,
    required this.inspectionCount,
    required this.workCount,
    required this.documentCount,
  });

  final int pickupCount;
  final int inspectionCount;
  final int workCount;
  final int documentCount;

  @override
  Widget build(BuildContext context) {
    final focusCount =
        pickupCount + inspectionCount + workCount + documentCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.speed_rounded, color: AppPalette.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today needs $focusCount actions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppPalette.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pickupCount pickup, $inspectionCount inspection, $workCount work, $documentCount approval',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.white.withValues(alpha: 0.72),
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

class _OwnerWorkflowStrip extends StatelessWidget {
  const _OwnerWorkflowStrip({
    required this.pickupCount,
    required this.garageCount,
    required this.inspectionCount,
    required this.workCount,
    required this.completedCount,
    required this.onOpenCars,
  });

  final int pickupCount;
  final int garageCount;
  final int inspectionCount;
  final int workCount;
  final int completedCount;
  final ValueChanged<_OwnerGarageFilter> onOpenCars;

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        icon: Icons.local_shipping_outlined,
        label: 'Transit',
        count: pickupCount,
        filter: _OwnerGarageFilter.inTransit,
      ),
      (
        icon: Icons.home_repair_service_outlined,
        label: 'Garage',
        count: garageCount,
        filter: _OwnerGarageFilter.inGarage,
      ),
      (
        icon: Icons.search_rounded,
        label: 'Inspect',
        count: inspectionCount,
        filter: _OwnerGarageFilter.inGarage,
      ),
      (
        icon: Icons.handyman_outlined,
        label: 'Work',
        count: workCount,
        filter: _OwnerGarageFilter.inGarage,
      ),
      (
        icon: Icons.task_alt_rounded,
        label: 'Done',
        count: completedCount,
        filter: _OwnerGarageFilter.completed,
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final stage = stages[index];
          return _OwnerStageTile(
            icon: stage.icon,
            label: stage.label,
            count: stage.count,
            onTap: () => onOpenCars(stage.filter),
          );
        },
      ),
    );
  }
}

class _OwnerStageTile extends StatelessWidget {
  const _OwnerStageTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const Spacer(),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPriorityQueue extends StatelessWidget {
  const _OwnerPriorityQueue({
    required this.jobs,
    required this.controller,
    required this.onAssignPickup,
    required this.onCompletePickup,
    required this.onOpenDocuments,
    required this.onOpenChat,
  });

  final List<ServiceJob> jobs;
  final AppController controller;
  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (jobs.isEmpty)
              Text(
                'No active workflow items need attention.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...jobs.map((job) {
              final car = controller.cars
                  .where((item) => item.id == job.carId)
                  .firstOrNull;
              if (car == null) return const SizedBox.shrink();
              final customer = controller.customerForCar(car.id);
              return _OwnerActionTile(
                icon: _actionIcon(job),
                title: car.carNumber,
                subtitle:
                    '${customer?.name ?? 'Customer'} | ${_actionLabel(job)}',
                primaryIcon: _primaryIcon(job),
                onPrimary: () => _runPrimary(job, car),
                onChat: () => onOpenChat(car),
                onDocs: () => onOpenDocuments(car.id),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _actionIcon(ServiceJob job) {
    if (job.workflowState.isTransit) {
      return Icons.local_shipping_outlined;
    }
    switch (job.status) {
      case JobStatus.received:
        return Icons.inventory_2_outlined;
      case JobStatus.underInspection:
        return Icons.search_rounded;
      case JobStatus.workInProgress:
        return Icons.handyman_outlined;
      case JobStatus.completed:
        return Icons.receipt_long_outlined;
      case JobStatus.onRoad:
        return Icons.route_rounded;
    }
  }

  IconData _primaryIcon(ServiceJob job) {
    if (job.workflowState.isTransit &&
        job.pickupState == PickupState.requested) {
      return Icons.person_add_alt_1_rounded;
    }
    if (job.workflowState.isTransit &&
        job.pickupState == PickupState.assigned) {
      return Icons.task_alt_rounded;
    }
    if (job.status == JobStatus.completed) return Icons.receipt_long_rounded;
    return Icons.chat_bubble_outline_rounded;
  }

  String _actionLabel(ServiceJob job) {
    final state = job.workflowState;
    if (state.isTransit) {
      final isDelivery =
          state == CarWorkflowState.deliveryRequested ||
          state == CarWorkflowState.deliveryAssigned;
      if (job.pickupState == PickupState.requested) {
        return isDelivery ? 'Assign delivery person' : 'Assign pickup person';
      }
      return isDelivery ? 'Mark delivered' : 'Mark pickup done';
    }
    switch (job.status) {
      case JobStatus.received:
        return 'Move into inspection';
      case JobStatus.underInspection:
        return 'Prepare job card or quotation';
      case JobStatus.workInProgress:
        return 'Share progress photo';
      case JobStatus.completed:
        return 'Send invoice';
      case JobStatus.onRoad:
        return 'Available for new quote';
    }
  }

  void _runPrimary(ServiceJob job, CarProfile car) {
    if (job.workflowState.isTransit &&
        job.pickupState == PickupState.requested) {
      onAssignPickup(job);
      return;
    }
    if (job.workflowState.isTransit &&
        job.pickupState == PickupState.assigned) {
      onCompletePickup(job);
      return;
    }
    if (job.status == JobStatus.completed) {
      onOpenDocuments(car.id);
      return;
    }
    onOpenChat(car);
  }
}

class _OwnerActionTile extends StatelessWidget {
  const _OwnerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onChat,
    required this.onDocs,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback onChat;
  final VoidCallback onDocs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Primary action',
            onPressed: onPrimary,
            icon: Icon(primaryIcon),
          ),
          IconButton.outlined(
            tooltip: 'Chat',
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton.outlined(
            tooltip: 'Documents',
            onPressed: onDocs,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
    );
  }
}

class _OwnerDocumentActions extends StatelessWidget {
  const _OwnerDocumentActions({
    required this.pending,
    required this.invoicesDue,
    required this.onOpenDocuments,
  });

  final List<ServiceDocument> pending;
  final List<ServiceDocument> invoicesDue;
  final ValueChanged<String> onOpenDocuments;

  @override
  Widget build(BuildContext context) {
    final items = [...pending, ...invoicesDue].take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Documents to send or collect',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'No document actions pending.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...items.map((document) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  document.type == DocumentType.invoice
                      ? Icons.receipt_long_rounded
                      : Icons.request_quote_rounded,
                ),
                title: Text(document.title),
                subtitle: Text(
                  '${document.type.label} | ${formatCurrency(document.total)} | ${document.approvalState.name}',
                ),
                trailing: IconButton.outlined(
                  tooltip: 'Open document studio',
                  onPressed: () => onOpenDocuments(document.carId),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OwnerRecentUpdates extends StatelessWidget {
  const _OwnerRecentUpdates({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent updates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              Text(
                'No recent notifications.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...notifications.map(
              (notification) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(notification.title),
                subtitle: Text(notification.message),
                trailing: Text(formatShortDate(notification.createdAt)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerQuickLaunchRow extends StatelessWidget {
  const _OwnerQuickLaunchRow({
    required this.onOpenGarage,
    required this.onOpenTransit,
    required this.onOpenDocuments,
  });

  final VoidCallback onOpenGarage;
  final VoidCallback onOpenTransit;
  final VoidCallback onOpenDocuments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onOpenGarage,
            icon: const Icon(Icons.home_repair_service_outlined),
            label: const Text('Garage'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenTransit,
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Transit'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenDocuments,
            icon: const Icon(Icons.edit_document),
            label: const Text('Docs'),
          ),
        ),
      ],
    );
  }
}

class _OwnerSmallSummary extends StatelessWidget {
  const _OwnerSmallSummary({
    required this.pendingItems,
    required this.invoiceItems,
    required this.revenue,
  });

  final int pendingItems;
  final int invoiceItems;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$pendingItems approvals, $invoiceItems invoices, ${formatCurrency(revenue)} recorded',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

class _DashboardDetailItem {
  const _DashboardDetailItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.searchText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String searchText;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned(right: 0, top: 0, child: LedIndicator(active: true)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppPalette.black),
                  const Spacer(),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerOperationsTab extends StatelessWidget {
  const _OwnerOperationsTab({
    required this.filter,
    required this.onFilterChanged,
    required this.onOpenDocuments,
    required this.onOpenChat,
    required this.onAddPhoto,
    required this.onAssignPickup,
    required this.onCompletePickup,
    required this.onAddCar,
  });

  final _OwnerGarageFilter filter;
  final ValueChanged<_OwnerGarageFilter> onFilterChanged;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;
  final void Function(CarProfile car, JobStatus? status) onAddPhoto;
  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final VoidCallback onAddCar;

  List<CarProfile> _visibleCars(AppController controller) {
    return controller.cars.where((car) {
      final state = controller.workflowStateForCar(car.id);
      switch (filter) {
        case _OwnerGarageFilter.inGarage:
          return state.isInGarage;
        case _OwnerGarageFilter.inTransit:
          return state.isTransit;
        case _OwnerGarageFilter.completed:
          return state == CarWorkflowState.readyForDelivery;
        case _OwnerGarageFilter.onRoad:
          return state.isAvailable;
      }
    }).toList();
  }

  void _showCarDetail(
    BuildContext context,
    AppController controller,
    CarProfile car,
    ServiceJob? job,
  ) {
    final customer = controller.customerForCar(car.id);
    final documents = controller.documentsForCar(car.id);
    final history = controller.jobsForCar(car.id);
    final photos = controller.photoUpdatesForCar(car.id);
    final state = controller.workflowStateForCar(car.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: ListView(
                children: [
                  Row(
                    children: [
                      AppImage(
                        path: car.imageUrl,
                        width: 84,
                        height: 64,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.carNumber,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('${customer?.name ?? '-'} | ${car.model}'),
                            Text(
                              customer?.phone ?? '-',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (job == null || state.isAvailable)
                    _OwnerCarStateCard(state: state)
                  else
                    HorizontalServiceTimeline(status: job.status),
                  const SizedBox(height: 12),
                  if (job != null) _OwnerPickupWorkflowCard(job: job),
                  if (job != null) const SizedBox(height: 10),
                  if (job != null)
                    DropdownButtonFormField<JobStatus>(
                      initialValue: job.status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: JobStatus.values
                          .map(
                            (status) => DropdownMenuItem<JobStatus>(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        controller.setJobStatus(job.id, value);
                        controller.sendStatusUpdate(
                          job.id,
                          '${car.carNumber} moved to ${value.label.toLowerCase()}.',
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  const SizedBox(height: 14),
                  GearboxActionGrid(
                    children: [
                      if (job != null) ...[
                        AutomotiveControlButton(
                          icon: Icons.local_shipping_outlined,
                          label: state == CarWorkflowState.readyForDelivery
                              ? 'Deliver'
                              : 'Assign',
                          active:
                              job.pickupState == PickupState.assigned &&
                              state.isTransit,
                          onPressed: () => onAssignPickup(job),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.task_alt_rounded,
                          label: state == CarWorkflowState.readyForDelivery
                              ? 'Delivered'
                              : 'Transit done',
                          active: job.pickupState == PickupState.completed,
                          onPressed: () => onCompletePickup(job),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.search_rounded,
                          label: 'Inspect',
                          active: job.status == JobStatus.underInspection,
                          onPressed: () =>
                              onAddPhoto(car, JobStatus.underInspection),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.handyman_outlined,
                          label: 'Work photo',
                          active: job.status == JobStatus.workInProgress,
                          onPressed: () =>
                              onAddPhoto(car, JobStatus.workInProgress),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.verified_outlined,
                          label: 'Complete',
                          active: job.status == JobStatus.completed,
                          onPressed: () => onAddPhoto(car, JobStatus.completed),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.route_rounded,
                          label: 'On-Road',
                          active: job.status == JobStatus.onRoad,
                          onPressed: () {
                            controller.setJobStatus(job.id, JobStatus.onRoad);
                            controller.sendStatusUpdate(
                              job.id,
                              '${car.carNumber} is back on road.',
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                      AutomotiveControlButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Photo',
                        onPressed: () => onAddPhoto(car, null),
                      ),
                      AutomotiveControlButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenChat(car);
                        },
                      ),
                      AutomotiveControlButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Bills',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenDocuments(car.id);
                        },
                      ),
                      AutomotiveControlButton(
                        icon: Icons.notifications_active_outlined,
                        label: 'Update',
                        onPressed: job == null
                            ? null
                            : () => controller.sendStatusUpdate(
                                job.id,
                                '${car.carNumber} update shared from the garage desk.',
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...history.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.timeline_rounded),
                      title: Text(item.status.label),
                      subtitle: Text(
                        'ETA ${formatDateTime(item.expectedCompletion)} | Pickup ${item.pickupState.label}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Bills', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (documents.isEmpty)
                    Text(
                      'No bills or estimates yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ...documents.map(
                    (document) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(document.title),
                      subtitle: Text(
                        '${document.type.label} | ${formatCurrency(document.total)} | ${document.approvalState.name}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...photos
                      .take(3)
                      .map(
                        (photo) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: AppImage(
                            path: photo.imagePath,
                            width: 48,
                            height: 38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(photo.caption),
                          subtitle: Text(formatDateTime(photo.createdAt)),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final visibleCars = _visibleCars(controller);

    return ListView(
      key: const PageStorageKey('owner-operations'),
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onAddCar,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add car'),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<_OwnerGarageFilter>(
          segments: const [
            ButtonSegment(
              value: _OwnerGarageFilter.inGarage,
              icon: Icon(Icons.build_circle_outlined),
              label: Text('Garage'),
            ),
            ButtonSegment(
              value: _OwnerGarageFilter.inTransit,
              icon: Icon(Icons.local_shipping_outlined),
              label: Text('Transit'),
            ),
            ButtonSegment(
              value: _OwnerGarageFilter.completed,
              icon: Icon(Icons.task_alt_rounded),
              label: Text('Done'),
            ),
            ButtonSegment(
              value: _OwnerGarageFilter.onRoad,
              icon: Icon(Icons.route_rounded),
              label: Text('On-Road'),
            ),
          ],
          selected: {filter},
          onSelectionChanged: (selection) => onFilterChanged(selection.first),
        ),
        const SizedBox(height: 12),
        if (visibleCars.isEmpty)
          const _EmptyOwnerList(message: 'No cars match this view right now.'),
        ...visibleCars.map((car) {
          final job = controller.latestJobForCar(car.id);
          final state = controller.workflowStateForCar(car.id);
          final customer = controller.customerForCar(car.id);
          final documents = controller.documentsForCar(car.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCarDetail(context, controller, car, job),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      AppImage(
                        path: car.imageUrl,
                        width: 76,
                        height: 58,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    car.carNumber,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                LedIndicator(active: true),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${customer?.name ?? '-'} | ${car.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (state.isAvailable)
                              Text(
                                state == CarWorkflowState.registered
                                    ? 'Registered customer vehicle'
                                    : 'Available for quote or pickup',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              )
                            else
                              HorizontalServiceTimeline(
                                status: job!.status,
                                compact: true,
                              ),
                            Text(
                              '${documents.length} docs | ${state.label}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OwnerPickupWorkflowCard extends StatelessWidget {
  const _OwnerPickupWorkflowCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    final state = job.workflowState;
    final isDelivery =
        state == CarWorkflowState.deliveryRequested ||
        state == CarWorkflowState.deliveryAssigned ||
        state == CarWorkflowState.readyForDelivery;
    final assignee = job.pickupPersonName == null
        ? 'Not assigned'
        : '${job.pickupPersonName}'
              '${job.pickupPersonPhone == null || job.pickupPersonPhone!.isEmpty ? '' : ' | ${job.pickupPersonPhone}'}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDelivery
                      ? 'Delivery ${job.pickupState.label}'
                      : 'Pickup ${job.pickupState.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Time ${formatDateTime(job.pickupTime)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Person $assignee',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (job.pickupAddress != null && job.pickupAddress!.isNotEmpty)
            Text(
              'Address ${job.pickupAddress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _OwnerCarStateCard extends StatelessWidget {
  const _OwnerCarStateCard({required this.state});

  final CarWorkflowState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state == CarWorkflowState.registered
                  ? 'Registered: no active service job yet'
                  : '${state.label}: available for quote or pickup',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOwnerList extends StatelessWidget {
  const _EmptyOwnerList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _OwnerChatTab extends StatelessWidget {
  const _OwnerChatTab({
    required this.selectedUserId,
    required this.selectedCarId,
    required this.searchQuery,
    required this.slideForward,
    required this.replyController,
    required this.onUserChanged,
    required this.onBack,
    required this.onCarChanged,
    required this.onSearchChanged,
    required this.onSendDocument,
    required this.onSendPhoto,
    required this.onSend,
  });

  final String? selectedUserId;
  final String? selectedCarId;
  final String searchQuery;
  final bool slideForward;
  final TextEditingController replyController;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onBack;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ServiceDocument> onSendDocument;
  final VoidCallback onSendPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final selectedCustomer = selectedUserId == null
        ? null
        : controller.userById(selectedUserId!);

    if (selectedUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.markConversationReadByOwner(selectedUserId!);
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) {
        final tween = Tween<Offset>(
          begin: slideForward ? const Offset(1, 0) : const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      child: selectedCustomer == null
          ? _OwnerInboxView(
              key: const ValueKey('owner-inbox'),
              searchQuery: searchQuery,
              onSearchChanged: onSearchChanged,
              onOpenCustomer: (customer) {
                controller.markConversationReadByOwner(customer.id);
                onUserChanged(customer.id);
              },
            )
          : _OwnerChatWindow(
              key: ValueKey('owner-chat-${selectedCustomer.id}'),
              customer: selectedCustomer,
              selectedCarId: selectedCarId,
              replyController: replyController,
              onBack: onBack,
              onCarChanged: onCarChanged,
              onSendDocument: onSendDocument,
              onSendPhoto: onSendPhoto,
              onSend: onSend,
            ),
    );
  }
}

class _OwnerInboxView extends StatelessWidget {
  const _OwnerInboxView({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onOpenCustomer,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<GarageUser> onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final needle = searchQuery.trim().toLowerCase();
    final customers =
        controller.customers.where((customer) {
          final messages = controller.conversationForUser(customer.id);
          final last = messages.isEmpty ? '' : messages.last.message;
          final haystack = '${customer.name} ${customer.phone} $last'
              .toLowerCase();
          return needle.isEmpty || haystack.contains(needle);
        }).toList()..sort((left, right) {
          final leftMessages = controller.conversationForUser(left.id);
          final rightMessages = controller.conversationForUser(right.id);
          final leftDate = leftMessages.isEmpty
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : leftMessages.last.createdAt;
          final rightDate = rightMessages.isEmpty
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : rightMessages.last.createdAt;
          return rightDate.compareTo(leftDate);
        });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search customers or messages',
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            itemCount: customers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final customer = customers[index];
              final messages = controller.conversationForUser(customer.id);
              final last = messages.isEmpty ? null : messages.last;
              final unread = controller.unreadIncomingCountForCustomer(
                customer.id,
              );
              return _OwnerInboxTile(
                customer: customer,
                lastMessage: last,
                unreadCount: unread,
                onTap: () => onOpenCustomer(customer),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OwnerInboxTile extends StatelessWidget {
  const _OwnerInboxTile({
    required this.customer,
    required this.lastMessage,
    required this.unreadCount,
    required this.onTap,
  });

  final GarageUser customer;
  final SupportMessage? lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  String _snippet(String value) {
    if (value.length <= 30) return value;
    return '${value.substring(0, 30)}...';
  }

  @override
  Widget build(BuildContext context) {
    final unread = unreadCount > 0;
    final snippet = lastMessage == null
        ? 'No messages yet'
        : _snippet(lastMessage!.message);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: unread ? AppPalette.red : AppPalette.border,
          ),
        ),
        child: Row(
          children: [
            MessengerAvatar(
              path: customer.profileImagePath,
              initials: customer.name.substring(0, 1),
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: unread ? AppPalette.black : AppPalette.muted,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMessage == null
                      ? ''
                      : formatShortDate(lastMessage!.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                if (unread)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppPalette.red,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPalette.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerChatWindow extends StatelessWidget {
  const _OwnerChatWindow({
    super.key,
    required this.customer,
    required this.selectedCarId,
    required this.replyController,
    required this.onBack,
    required this.onCarChanged,
    required this.onSendDocument,
    required this.onSendPhoto,
    required this.onSend,
  });

  final GarageUser customer;
  final String? selectedCarId;
  final TextEditingController replyController;
  final VoidCallback onBack;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<ServiceDocument> onSendDocument;
  final VoidCallback onSendPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final owner = controller.session!.user;
    final customerCars = controller.carsForCustomer(customer.id);
    final messages = controller.conversationForUser(
      customer.id,
      carId: selectedCarId,
    );
    final documentCars = selectedCarId == null
        ? customerCars
        : customerCars.where((car) => car.id == selectedCarId).toList();
    final documents = documentCars
        .expand((car) => controller.documentsForCar(car.id))
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
          decoration: const BoxDecoration(
            color: AppPalette.white,
            border: Border(bottom: BorderSide(color: AppPalette.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                MessengerAvatar(
                  path: customer.profileImagePath,
                  initials: customer.name.substring(0, 1),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        customer.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final carLabel = controller.cars
                  .where((car) => car.id == message.carId)
                  .firstOrNull
                  ?.carNumber;
              return MessengerBubble(
                message: message,
                fromCurrentUser: message.sentByOwner,
                avatarPath: message.sentByOwner
                    ? owner.profileImagePath
                    : customer.profileImagePath,
                avatarInitials: message.sentByOwner
                    ? owner.name.substring(0, 1)
                    : customer.name.substring(0, 1),
                carLabel: carLabel,
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: AppPalette.white,
              border: Border(top: BorderSide(color: AppPalette.border)),
            ),
            child: Row(
              children: [
                PopupMenuButton<Object>(
                  tooltip: 'Attach',
                  onSelected: (value) {
                    if (value is ServiceDocument) {
                      onSendDocument(value);
                    } else if (value == 'photo') {
                      onSendPhoto();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'photo',
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.photo_library_outlined),
                        title: Text('Gallery Photo'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (documents.isEmpty)
                      const PopupMenuItem<Object>(
                        enabled: false,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.receipt_long_outlined),
                          title: Text('No Document Library files'),
                        ),
                      )
                    else
                      ...documents.map(
                        (document) => PopupMenuItem<ServiceDocument>(
                          value: document,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(document.title),
                            subtitle: Text(document.type.label),
                          ),
                        ),
                      ),
                  ],
                  icon: const Icon(Icons.attach_file_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: replyController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Reply to customer...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

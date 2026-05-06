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
  String _ownerChatTopic = 'Garage update';
  String _ownerChatSearch = '';
  bool _ownerChatSlideForward = true;
  _OwnerGarageFilter _garageFilter = _OwnerGarageFilter.inGarage;

  @override
  void dispose() {
    _ownerReplyController.dispose();
    super.dispose();
  }

  Future<void> _addGaragePhoto(BuildContext context, CarProfile car) async {
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
                'Add a caption for the photo you are about to upload for ${car.carNumber}.',
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
    );
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
      topic: _ownerChatTopic,
      message: _ownerReplyController.text.trim(),
      carId: _selectedOwnerChatCarId,
    );
    setState(() => _ownerReplyController.clear());
  }

  void _insertOwnerQuickMessage(String message) {
    setState(() {
      _ownerReplyController.text = message;
      _ownerReplyController.selection = TextSelection.collapsed(
        offset: _ownerReplyController.text.length,
      );
    });
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

  void _openChatForCar(CarProfile car) {
    setState(() {
      _selectedOwnerChatUserId = car.userId;
      _selectedOwnerChatCarId = car.id;
      _ownerChatTopic = 'Garage update';
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
            const BrandLogo(size: 30),
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
          const _OwnerDashboardTab(),
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
            onAddPhoto: (car) => _addGaragePhoto(context, car),
            onAddCar: () => _showAddOwnerCarSheet(context),
          ),
          _OwnerChatTab(
            selectedUserId: _selectedOwnerChatUserId,
            selectedCarId: _selectedOwnerChatCarId,
            selectedTopic: _ownerChatTopic,
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
            onTopicChanged: (value) => setState(() => _ownerChatTopic = value),
            onSearchChanged: (value) =>
                setState(() => _ownerChatSearch = value),
            onQuickMessage: _insertOwnerQuickMessage,
            onSendDocument: _sendDocumentToSelectedChat,
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

enum _OwnerGarageFilter { inGarage, inTransit, completed }

class _OwnerDashboardTab extends StatelessWidget {
  const _OwnerDashboardTab();

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
    final jobs = controller.jobs;
    final documents = controller.documents;
    final pending = documents
        .where((document) => document.approvalState == ApprovalState.pending)
        .toList();
    final revenue = documents
        .where((document) => document.type == DocumentType.invoice)
        .fold<double>(0, (sum, doc) => sum + doc.total);
    final completed = jobs
        .where(
          (job) =>
              job.status == JobStatus.completed ||
              job.status == JobStatus.readyForDelivery,
        )
        .toList();

    _DashboardDetailItem carJobItem(ServiceJob job) {
      final car = controller.cars.firstWhere((item) => item.id == job.carId);
      final customer = controller.customerForCar(car.id);
      return _DashboardDetailItem(
        icon: Icons.directions_car_rounded,
        title: '${car.carNumber} - ${car.model}',
        subtitle:
            '${customer?.name ?? 'Customer'} | ${customer?.phone ?? '-'} | ${job.status.label}',
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
              value: jobs.length.toString(),
              onTap: () => _openMetricSheet(
                context,
                'Cars in garage',
                jobs.map(carJobItem).toList(),
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
                completed.map(carJobItem).toList(),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requests that need action',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...pending.map(
                  (document) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(document.title),
                    subtitle: Text(
                      '${document.type.label} | ${formatCurrency(document.total)} | ${document.approvalState.name}',
                    ),
                    trailing: Text(formatShortDate(document.updatedAt)),
                  ),
                ),
                ...controller.notifications
                    .take(4)
                    .map(
                      (notification) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(notification.title),
                        subtitle: Text(notification.message),
                        trailing: Text(formatShortDate(notification.createdAt)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
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
    required this.onAddCar,
  });

  final _OwnerGarageFilter filter;
  final ValueChanged<_OwnerGarageFilter> onFilterChanged;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;
  final ValueChanged<CarProfile> onAddPhoto;
  final VoidCallback onAddCar;

  List<ServiceJob> _visibleJobs(List<ServiceJob> jobs) {
    return jobs.where((job) {
      switch (filter) {
        case _OwnerGarageFilter.inGarage:
          return job.status == JobStatus.received ||
              job.status == JobStatus.underInspection ||
              job.status == JobStatus.workInProgress;
        case _OwnerGarageFilter.inTransit:
          return job.pickupRequired &&
              (job.pickupState == PickupState.requested ||
                  job.pickupState == PickupState.assigned);
        case _OwnerGarageFilter.completed:
          return job.status == JobStatus.completed ||
              job.status == JobStatus.readyForDelivery;
      }
    }).toList();
  }

  void _showCarDetail(
    BuildContext context,
    AppController controller,
    CarProfile car,
    ServiceJob job,
  ) {
    final customer = controller.customerForCar(car.id);
    final documents = controller.documentsForCar(car.id);
    final history = controller.jobsForCar(car.id);
    final photos = controller.photoUpdatesForCar(car.id);

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
                  HorizontalServiceTimeline(status: job.status),
                  const SizedBox(height: 10),
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
                      AutomotiveControlButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Assign',
                        active: job.pickupState == PickupState.assigned,
                        onPressed: () => controller.assignPickup(job.id),
                      ),
                      AutomotiveControlButton(
                        icon: Icons.task_alt_rounded,
                        label: 'Pickup done',
                        active: job.pickupState == PickupState.completed,
                        onPressed: () => controller.completePickup(job.id),
                      ),
                      AutomotiveControlButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Photo',
                        onPressed: () => onAddPhoto(car),
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
                        onPressed: () => controller.sendStatusUpdate(
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
    final visibleJobs = _visibleJobs(controller.jobs);

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
          ],
          selected: {filter},
          onSelectionChanged: (selection) => onFilterChanged(selection.first),
        ),
        const SizedBox(height: 12),
        if (visibleJobs.isEmpty)
          const _EmptyOwnerList(message: 'No cars match this view right now.'),
        ...visibleJobs.map((job) {
          final car = controller.cars.firstWhere(
            (item) => item.id == job.carId,
          );
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
                            HorizontalServiceTimeline(
                              status: job.status,
                              compact: true,
                            ),
                            Text(
                              '${documents.length} docs | ${job.status.label}',
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
    required this.selectedTopic,
    required this.searchQuery,
    required this.slideForward,
    required this.replyController,
    required this.onUserChanged,
    required this.onBack,
    required this.onCarChanged,
    required this.onTopicChanged,
    required this.onSearchChanged,
    required this.onQuickMessage,
    required this.onSendDocument,
    required this.onSend,
  });

  final String? selectedUserId;
  final String? selectedCarId;
  final String selectedTopic;
  final String searchQuery;
  final bool slideForward;
  final TextEditingController replyController;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onBack;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onQuickMessage;
  final ValueChanged<ServiceDocument> onSendDocument;
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
              selectedTopic: selectedTopic,
              replyController: replyController,
              onBack: onBack,
              onCarChanged: onCarChanged,
              onTopicChanged: onTopicChanged,
              onQuickMessage: onQuickMessage,
              onSendDocument: onSendDocument,
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
    required this.selectedTopic,
    required this.replyController,
    required this.onBack,
    required this.onCarChanged,
    required this.onTopicChanged,
    required this.onQuickMessage,
    required this.onSendDocument,
    required this.onSend,
  });

  final GarageUser customer;
  final String? selectedCarId;
  final String selectedTopic;
  final TextEditingController replyController;
  final VoidCallback onBack;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String> onQuickMessage;
  final ValueChanged<ServiceDocument> onSendDocument;
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
    const topics = [
      'Garage update',
      'Quotation',
      'Estimation',
      'Bills',
      'Pickup',
      'Payments',
    ];
    const quickTemplates = [
      (
        label: 'Payment reminder',
        message:
            'Payment reminder: your service bill is pending. Please complete the payment so we can close the job.',
      ),
      (
        label: 'Service complete',
        message:
            'Service completion update: your car service is complete and the final quality check is done.',
      ),
      (
        label: 'Pickup reminder',
        message:
            'Pickup reminder: please confirm the pickup address and preferred time for your vehicle handover.',
      ),
      (
        label: 'Quote approval',
        message:
            'Quote approval needed: please review the shared quotation and approve it to begin the next service step.',
      ),
      (
        label: 'Bill shared',
        message:
            'Bill shared: the invoice PDF is attached here for your records and WhatsApp sharing.',
      ),
    ];

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
                PopupMenuButton<String?>(
                  initialValue: selectedCarId,
                  tooltip: 'Filter car',
                  onSelected: onCarChanged,
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All cars'),
                    ),
                    ...customerCars.map(
                      (car) => PopupMenuItem<String?>(
                        value: car.id,
                        child: Text('${car.carNumber} - ${car.model}'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.directions_car_rounded),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics
                .map(
                  (topic) => ChoiceChip(
                    label: Text(topic),
                    selected: selectedTopic == topic,
                    onSelected: (_) => onTopicChanged(topic),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: quickTemplates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = quickTemplates[index];
              return ActionChip(
                avatar: const Icon(Icons.bolt_rounded, size: 16),
                label: Text(template.label),
                onPressed: () => onQuickMessage(template.message),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                PopupMenuButton<ServiceDocument>(
                  tooltip: 'Send document',
                  enabled: documents.isNotEmpty,
                  onSelected: onSendDocument,
                  itemBuilder: (context) => documents
                      .map(
                        (document) => PopupMenuItem<ServiceDocument>(
                          value: document,
                          child: Text(
                            '${document.type.label} ${document.title}',
                          ),
                        ),
                      )
                      .toList(),
                  icon: const Icon(Icons.receipt_long_outlined),
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

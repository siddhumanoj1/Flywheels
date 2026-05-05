import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/owner/owner_document_tab.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
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
  _OwnerGarageFilter _garageFilter = _OwnerGarageFilter.inGarage;

  @override
  void dispose() {
    _ownerReplyController.dispose();
    super.dispose();
  }

  Future<void> _addGaragePhoto(BuildContext context, CarProfile car) async {
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

    FlywheelsScope.of(
      context,
    ).addGaragePhoto(carId: car.id, imagePath: image.path, caption: caption);
  }

  void _sendOwnerReply() {
    final controller = FlywheelsScope.of(context);
    if (_selectedOwnerChatUserId == null ||
        _ownerReplyController.text.trim().isEmpty)
      return;
    controller.sendOwnerMessage(
      customerUserId: _selectedOwnerChatUserId!,
      topic: _ownerChatTopic,
      message: _ownerReplyController.text.trim(),
      carId: _selectedOwnerChatCarId,
    );
    setState(() => _ownerReplyController.clear());
  }

  void _openChatForCar(CarProfile car) {
    setState(() {
      _selectedOwnerChatUserId = car.userId;
      _selectedOwnerChatCarId = car.id;
      _ownerChatTopic = 'Garage update';
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final customers = controller.customersWithConversations;
    _selectedOwnerChatUserId ??= customers.firstOrNull?.id;
    final titles = ['Owner Dashboard', 'Cars', 'Chat', 'Documents'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 28),
            const SizedBox(width: 10),
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
          ),
          _OwnerChatTab(
            selectedUserId: _selectedOwnerChatUserId,
            selectedCarId: _selectedOwnerChatCarId,
            selectedTopic: _ownerChatTopic,
            replyController: _ownerReplyController,
            onUserChanged: (value) => setState(() {
              _selectedOwnerChatUserId = value;
              _selectedOwnerChatCarId = null;
            }),
            onCarChanged: (value) =>
                setState(() => _selectedOwnerChatCarId = value),
            onTopicChanged: (value) => setState(() => _ownerChatTopic = value),
            onSend: _sendOwnerReply,
          ),
          OwnerDocumentTab(preferredCarId: _preferredCarId),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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

    return ListView(
      key: const PageStorageKey('owner-dashboard'),
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(label: 'Cars in garage', value: jobs.length.toString()),
            _StatCard(
              label: 'Pending approvals',
              value: pending.length.toString(),
            ),
            _StatCard(
              label: 'Completed jobs',
              value: jobs
                  .where(
                    (job) =>
                        job.status == JobStatus.completed ||
                        job.status == JobStatus.readyForDelivery,
                  )
                  .length
                  .toString(),
            ),
            _StatCard(label: 'Revenue today', value: formatCurrency(revenue)),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requests that need action',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
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
  });

  final _OwnerGarageFilter filter;
  final ValueChanged<_OwnerGarageFilter> onFilterChanged;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;
  final ValueChanged<CarProfile> onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final pendingApprovals = controller.documents
        .where((document) => document.approvalState == ApprovalState.pending)
        .length;
    final photoRequests = controller.notifications
        .where((notification) => notification.title.contains('photos'))
        .length;
    final visibleJobs = controller.jobs.where((job) {
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

    return ListView(
      key: const PageStorageKey('owner-operations'),
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garage board',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Filter cars by stage, update jobs, upload garage photos, and jump into documents without the clutter.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      label: Text('${visibleJobs.length} cars in this view'),
                    ),
                    Chip(label: Text('$pendingApprovals approvals pending')),
                    Chip(label: Text('$photoRequests photo-related alerts')),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<_OwnerGarageFilter>(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppPalette.white;
                      }
                      return AppPalette.black;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppPalette.black;
                      }
                      return AppPalette.soft;
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppPalette.border),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: _OwnerGarageFilter.inGarage,
                      label: Text('In garage'),
                    ),
                    ButtonSegment(
                      value: _OwnerGarageFilter.inTransit,
                      label: Text('In transit'),
                    ),
                    ButtonSegment(
                      value: _OwnerGarageFilter.completed,
                      label: Text('Completed'),
                    ),
                  ],
                  selected: {filter},
                  onSelectionChanged: (selection) =>
                      onFilterChanged(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (visibleJobs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No cars match this filter right now.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ...visibleJobs.map((job) {
          final car = controller.cars.firstWhere(
            (item) => item.id == job.carId,
          );
          final customer = controller.customerForCar(car.id);
          final carDocuments = controller.documentsForCar(car.id);
          final pendingDocuments = carDocuments
              .where(
                (document) => document.approvalState == ApprovalState.pending,
              )
              .length;
          final latestPhoto = controller.latestPhotoForCar(car.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppImage(
                          path: car.imageUrl,
                          width: 110,
                          height: 84,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${car.carNumber} - ${car.model}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text('${car.fuelType} | ${car.year}'),
                              if (customer != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  customer.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text('Stage: ${job.status.label}'),
                                  ),
                                  Chip(
                                    label: Text(
                                      'Pickup: ${job.pickupState.label}',
                                    ),
                                  ),
                                  Chip(
                                    label: Text('Docs: ${carDocuments.length}'),
                                  ),
                                  Chip(
                                    label: Text(
                                      'Photos: ${controller.photoUpdatesForCar(car.id).length}',
                                    ),
                                  ),
                                  if (pendingDocuments > 0)
                                    Chip(
                                      label: Text(
                                        'Pending approval: $pendingDocuments',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.soft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job schedule',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Text(
                                'Expected completion: ${formatDateTime(job.expectedCompletion)}',
                              ),
                              Text(
                                'Pickup time: ${formatDateTime(job.pickupTime)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<JobStatus>(
                      value: job.status,
                      decoration: const InputDecoration(
                        labelText: 'Update job stage',
                      ),
                      items: JobStatus.values
                          .map(
                            (status) => DropdownMenuItem<JobStatus>(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setJobStatus(job.id, value);
                          controller.sendStatusUpdate(
                            job.id,
                            '${car.carNumber} moved to ${value.label.toLowerCase()}.',
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quick stage actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: JobStatus.values.map((status) {
                        return ActionChip(
                          label: Text(status.label),
                          backgroundColor: status == job.status
                              ? AppPalette.red
                              : AppPalette.soft,
                          labelStyle: TextStyle(
                            color: status == job.status
                                ? AppPalette.white
                                : AppPalette.black,
                            fontWeight: FontWeight.w700,
                          ),
                          onPressed: () {
                            controller.setJobStatus(job.id, status);
                            controller.sendStatusUpdate(
                              job.id,
                              '${car.carNumber} is now ${status.label.toLowerCase()}.',
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Operations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed: () => controller.assignPickup(job.id),
                          child: const Text('Assign pickup'),
                        ),
                        OutlinedButton(
                          onPressed: () => controller.completePickup(job.id),
                          child: const Text('Complete pickup'),
                        ),
                        OutlinedButton(
                          onPressed: () => controller.sendStatusUpdate(
                            job.id,
                            '${car.carNumber} update shared from the garage desk.',
                          ),
                          child: const Text('Send update'),
                        ),
                        OutlinedButton(
                          onPressed: () => onAddPhoto(car),
                          child: const Text('Add photo'),
                        ),
                        OutlinedButton(
                          onPressed: () => onOpenChat(car),
                          child: const Text('Chat customer'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => onOpenDocuments(car.id),
                          child: const Text('Open docs'),
                        ),
                      ],
                    ),
                    if (latestPhoto != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.soft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            AppImage(
                              path: latestPhoto.imagePath,
                              width: 88,
                              height: 68,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Latest garage image',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(latestPhoto.caption),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatDateTime(latestPhoto.createdAt),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
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
          );
        }),
      ],
    );
  }
}

class _OwnerChatTab extends StatelessWidget {
  const _OwnerChatTab({
    required this.selectedUserId,
    required this.selectedCarId,
    required this.selectedTopic,
    required this.replyController,
    required this.onUserChanged,
    required this.onCarChanged,
    required this.onTopicChanged,
    required this.onSend,
  });

  final String? selectedUserId;
  final String? selectedCarId;
  final String selectedTopic;
  final TextEditingController replyController;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<String> onTopicChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final customers = controller.customersWithConversations;
    final selectedCustomer = customers
        .where((user) => user.id == selectedUserId)
        .firstOrNull;
    final customerCars = controller.cars
        .where((car) => car.userId == selectedUserId)
        .toList();
    final messages = selectedUserId == null
        ? const <SupportMessage>[]
        : controller.conversationForUser(selectedUserId!, carId: selectedCarId);

    const topics = [
      'Garage update',
      'Quotation',
      'Pickup and drop',
      'Photo update',
      'Payments',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  DropdownButtonFormField<String?>(
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: customers
                        .map(
                          (user) => DropdownMenuItem<String?>(
                            value: user.id,
                            child: Text(user.name),
                          ),
                        )
                        .toList(),
                    onChanged: onUserChanged,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: selectedCarId,
                    decoration: const InputDecoration(labelText: 'Car'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All cars'),
                      ),
                      ...customerCars.map(
                        (car) => DropdownMenuItem<String?>(
                          value: car.id,
                          child: Text('${car.carNumber} - ${car.model}'),
                        ),
                      ),
                    ],
                    onChanged: onCarChanged,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedTopic,
                    decoration: const InputDecoration(labelText: 'Reply topic'),
                    items: topics
                        .map(
                          (topic) => DropdownMenuItem<String>(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onTopicChanged(value);
                    },
                  ),
                  if (selectedCustomer != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppPalette.soft,
                          child: Text(selectedCustomer.name.substring(0, 1)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${selectedCustomer.name} | ${selectedCustomer.phone}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final carLabel = controller.cars
                            .where((car) => car.id == message.carId)
                            .firstOrNull
                            ?.carNumber;
                        return _OwnerMessageBubble(
                          message: message,
                          carLabel: carLabel,
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
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
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: onSend,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerMessageBubble extends StatelessWidget {
  const _OwnerMessageBubble({required this.message, required this.carLabel});

  final SupportMessage message;
  final String? carLabel;

  @override
  Widget build(BuildContext context) {
    final isOwner = message.sentByOwner;
    return Align(
      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 330),
        decoration: BoxDecoration(
          color: isOwner ? AppPalette.red : AppPalette.soft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carLabel == null ? message.topic : '${message.topic} | $carLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOwner ? AppPalette.white : AppPalette.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isOwner ? AppPalette.white : AppPalette.black,
              ),
            ),
            if (message.attachmentPath != null) ...[
              const SizedBox(height: 8),
              AppImage(
                path: message.attachmentPath!,
                width: 270,
                height: 150,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              formatDateTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOwner
                    ? AppPalette.white.withValues(alpha: 0.72)
                    : AppPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

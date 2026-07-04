import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/owner/owner_document_tab.dart';
import 'package:flywheels/screens/shared/wheels_marketplace_tab.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/services/google_maps_link_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/app_inner_tabs.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/car_status_tracker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final _picker = ImagePicker();
  final _ownerReplyController = TextEditingController();
  late final PageController _pageController;
  int _currentIndex = 0;
  int _carsTrackerReplayToken = 0;
  String? _preferredCarId;
  DocumentType? _preferredDocumentType;
  String? _selectedOwnerChatUserId;
  String? _selectedOwnerChatCarId;
  String _ownerChatSearch = '';
  bool _ownerChatSlideForward = true;
  ChatChannel _ownerChatChannel = ChatChannel.general;
  _OwnerCarProfileFilter _carProfileFilter = _OwnerCarProfileFilter.all;
  String _carProfileSearch = '';
  _OwnerCarProfileSort _carProfileSort = _OwnerCarProfileSort.approvalsFirst;
  bool _pickingProfilePhoto = false;

  static const _wheelsTabIndex = 3;
  static const _chatTabIndex = 4;
  static const _documentsTabIndex = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ownerReplyController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    setState(() => _pickingProfilePhoto = true);
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    setState(() => _pickingProfilePhoto = false);
    if (image == null) return;
    FlywheelsScope.read(context).updateProfilePhoto(image.path);
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
    String? selectedMechanicId;

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
                    DropdownButtonFormField<String>(
                      initialValue: selectedMechanicId,
                      decoration: const InputDecoration(labelText: 'Mechanic'),
                      items: controller.mechanics
                          .map(
                            (mechanic) => DropdownMenuItem(
                              value: mechanic.id,
                              child: Text(
                                '${mechanic.name} - ${mechanic.primarySkill}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final staff = value == null
                            ? null
                            : controller.staffById(value);
                        setSheetState(() {
                          selectedMechanicId = value;
                          if (staff != null) {
                            nameController.text = staff.name;
                            phoneController.text = staff.phone;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
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
      channel: _ownerChatChannel,
      carId: _selectedOwnerChatCarId,
    );
    setState(() => _ownerReplyController.clear());
  }

  void _showStaffProfileSheet(BuildContext context, {StaffProfile? staff}) {
    final controller = FlywheelsScope.read(context);
    final nameController = TextEditingController(text: staff?.name ?? '');
    final phoneController = TextEditingController(text: staff?.phone ?? '');
    final skillController = TextEditingController(
      text: staff?.primarySkill ?? '',
    );
    final salaryController = TextEditingController(
      text: staff == null ? '' : staff.monthlySalary.toStringAsFixed(0),
    );
    var role = staff?.role ?? StaffRole.mechanic;
    var active = staff?.isActive ?? true;

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
                        staff == null ? 'Create staff profile' : 'Edit staff',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<StaffRole>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: StaffRole.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setSheetState(() => role = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: skillController,
                        decoration: const InputDecoration(
                          labelText: 'Primary skill',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly salary',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        title: const Text('Active profile'),
                        onChanged: (value) =>
                            setSheetState(() => active = value),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.upsertStaffProfile(
                              staffId: staff?.id,
                              name: nameController.text,
                              phone: phoneController.text,
                              role: role,
                              primarySkill: skillController.text,
                              monthlySalary:
                                  double.tryParse(
                                    salaryController.text.replaceAll(
                                      RegExp(r'[^0-9.]'),
                                      '',
                                    ),
                                  ) ??
                                  0,
                              isActive: active,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save profile'),
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
      nameController.dispose();
      phoneController.dispose();
      skillController.dispose();
      salaryController.dispose();
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
      controller.sendDocumentInChat(
        document,
        attachmentPath: export.filePath,
        channel: _ownerChatChannel,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${document.title} PDF sent in chat.')),
      );
    } catch (_) {
      controller.sendDocumentInChat(document, channel: _ownerChatChannel);
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
      channel: _ownerChatChannel,
      carId: _selectedOwnerChatCarId,
      attachmentPath: image.path,
    );
    setState(() => _ownerReplyController.clear());
  }

  Future<void> _postCarForSale(CarProfile car) async {
    await showWheelsListingSheet(context, picker: _picker, sourceCar: car);
  }

  void _selectTab(int index) {
    if (index < 0 || index > 6) return;
    setState(() {
      _currentIndex = index;
      if (index == 1) _carsTrackerReplayToken += 1;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleParentPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) _carsTrackerReplayToken += 1;
    });
  }

  void _openChatForCar(CarProfile car) {
    setState(() {
      _selectedOwnerChatUserId = car.userId;
      _selectedOwnerChatCarId = car.id;
      _ownerChatSlideForward = true;
    });
    _selectTab(_chatTabIndex);
    FlywheelsScope.read(context).markConversationReadByOwner(car.userId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final titles = [
      'Owner Dashboard',
      'Cars',
      'Team',
      'Wheels',
      'Chat',
      'Documents',
      'Profile',
    ];

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
      body: PageView(
        controller: _pageController,
        onPageChanged: _handleParentPageChanged,
        children: [
          _OwnerDashboardTab(
            onAssignPickup: (job) => _showPickupAssignmentSheet(context, job),
            onCompletePickup: (job) => _completePickupWithPhoto(context, job),
            onOpenCars: (filter) {
              setState(() => _carProfileFilter = filter);
              _selectTab(1);
            },
            onOpenWheels: () => _selectTab(_wheelsTabIndex),
            onOpenDocuments: (carId) {
              setState(() {
                _preferredCarId = carId.isEmpty ? null : carId;
                _preferredDocumentType = null;
              });
              _selectTab(_documentsTabIndex);
            },
            onCreateJobCard: (carId) {
              setState(() {
                _preferredCarId = carId;
                _preferredDocumentType = DocumentType.jobCard;
              });
              _selectTab(_documentsTabIndex);
            },
            onOpenChat: _openChatForCar,
          ),
          _OwnerOperationsTab(
            filter: _carProfileFilter,
            searchQuery: _carProfileSearch,
            sort: _carProfileSort,
            trackerReplayToken: _carsTrackerReplayToken,
            onFilterChanged: (value) =>
                setState(() => _carProfileFilter = value),
            onSearchChanged: (value) =>
                setState(() => _carProfileSearch = value),
            onSortChanged: (value) => setState(() => _carProfileSort = value),
            onOpenDocuments: (carId) {
              setState(() {
                _preferredCarId = carId;
                _preferredDocumentType = null;
              });
              _selectTab(_documentsTabIndex);
            },
            onCreateJobCard: (carId) {
              setState(() {
                _preferredCarId = carId;
                _preferredDocumentType = DocumentType.jobCard;
              });
              _selectTab(_documentsTabIndex);
            },
            onOpenChat: _openChatForCar,
            onAddPhoto: (car, status) =>
                _addGaragePhoto(context, car, status: status),
            onAssignPickup: (job) => _showPickupAssignmentSheet(context, job),
            onCompletePickup: (job) => _completePickupWithPhoto(context, job),
            onSellCar: _postCarForSale,
            onAddCar: () => _showAddOwnerCarSheet(context),
          ),
          _OwnerTeamTab(
            onAddStaff: () => _showStaffProfileSheet(context),
            onEditStaff: (staff) =>
                _showStaffProfileSheet(context, staff: staff),
          ),
          OwnerWheelsMarketplaceTab(picker: _picker),
          _OwnerChatTab(
            selectedUserId: _selectedOwnerChatUserId,
            selectedCarId: _selectedOwnerChatCarId,
            channel: _ownerChatChannel,
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
            onChannelChanged: (value) =>
                setState(() => _ownerChatChannel = value),
            onSearchChanged: (value) =>
                setState(() => _ownerChatSearch = value),
            onSendDocument: _sendDocumentToSelectedChat,
            onSendPhoto: _sendOwnerChatPhoto,
            onSend: _sendOwnerReply,
          ),
          OwnerDocumentTab(
            preferredCarId: _preferredCarId,
            preferredType: _preferredDocumentType,
          ),
          _OwnerProfileTab(
            onPickProfilePhoto: _pickProfilePhoto,
            isPickingProfilePhoto: _pickingProfilePhoto,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        badgeCounts: [
          0,
          0,
          0,
          0,
          controller.unreadMessageCountForCurrentSession(),
          0,
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
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
            label: 'Team',
          ),
          AppBottomNavItem(
            icon: Icons.motion_photos_auto_outlined,
            activeIcon: Icons.motion_photos_auto_rounded,
            label: 'Wheels',
            color: AppPalette.red,
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
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _OwnerProfileTab extends StatelessWidget {
  const _OwnerProfileTab({
    required this.onPickProfilePhoto,
    required this.isPickingProfilePhoto,
  });

  final VoidCallback onPickProfilePhoto;
  final bool isPickingProfilePhoto;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final user = controller.session!.user;
    final activeJobs = controller.jobs
        .where((job) => job.status != JobStatus.onRoad)
        .length;
    final pendingApprovals =
        controller.pendingSaleListings.length +
        controller.workApprovalRequests
            .where((request) => request.status == RequestStatus.pending)
            .length +
        controller.staffAssignmentProposals
            .where((proposal) => proposal.status == RequestStatus.pending)
            .length;

    return ListView(
      key: const PageStorageKey('owner-profile'),
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                MessengerAvatar(
                  path: user.profileImagePath,
                  initials: user.name.isNotEmpty
                      ? user.name.substring(0, 1)
                      : 'F',
                  radius: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(user.phone),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: isPickingProfilePhoto ? null : onPickProfilePhoto,
                  icon: Icon(
                    isPickingProfilePhoto
                        ? Icons.hourglass_top_rounded
                        : Icons.photo_camera_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            _OwnerProfileMetric(
              label: 'Customers',
              value: controller.customers.length.toString(),
              icon: Icons.people_outline_rounded,
            ),
            _OwnerProfileMetric(
              label: 'Cars',
              value: controller.cars.length.toString(),
              icon: Icons.directions_car_outlined,
            ),
            _OwnerProfileMetric(
              label: 'Active jobs',
              value: activeJobs.toString(),
              icon: Icons.build_circle_outlined,
            ),
            _OwnerProfileMetric(
              label: 'Approvals',
              value: pendingApprovals.toString(),
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Text(
                'Garage overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Team members'),
                  trailing: Text(controller.staffProfiles.length.toString()),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Documents'),
                  trailing: Text(controller.documents.length.toString()),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Alerts'),
                  trailing: Text(controller.notifications.length.toString()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ),
      ],
    );
  }
}

class _OwnerProfileMetric extends StatelessWidget {
  const _OwnerProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppPalette.red),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum _OwnerCarProfileFilter {
  all,
  approvals,
  registered,
  pickupScheduled,
  pickupDone,
  received,
  underInspection,
  workInProgress,
  completed,
  deliveryScheduled,
  onRoad,
}

extension _OwnerCarProfileFilterX on _OwnerCarProfileFilter {
  String get label {
    switch (this) {
      case _OwnerCarProfileFilter.all:
        return 'All';
      case _OwnerCarProfileFilter.approvals:
        return 'Approvals';
      case _OwnerCarProfileFilter.registered:
        return 'Registered';
      case _OwnerCarProfileFilter.pickupScheduled:
        return JobStatus.pickupScheduled.label;
      case _OwnerCarProfileFilter.pickupDone:
        return JobStatus.pickupDone.label;
      case _OwnerCarProfileFilter.received:
        return JobStatus.received.label;
      case _OwnerCarProfileFilter.underInspection:
        return JobStatus.underInspection.label;
      case _OwnerCarProfileFilter.workInProgress:
        return JobStatus.workInProgress.label;
      case _OwnerCarProfileFilter.completed:
        return JobStatus.completed.label;
      case _OwnerCarProfileFilter.deliveryScheduled:
        return JobStatus.deliveryScheduled.label;
      case _OwnerCarProfileFilter.onRoad:
        return JobStatus.onRoad.label;
    }
  }

  IconData get icon {
    switch (this) {
      case _OwnerCarProfileFilter.all:
        return Icons.directions_car_outlined;
      case _OwnerCarProfileFilter.approvals:
        return Icons.mark_chat_unread_outlined;
      case _OwnerCarProfileFilter.registered:
        return Icons.fact_check_outlined;
      case _OwnerCarProfileFilter.pickupScheduled:
        return Icons.local_shipping_outlined;
      case _OwnerCarProfileFilter.pickupDone:
        return Icons.inventory_2_outlined;
      case _OwnerCarProfileFilter.received:
        return Icons.home_repair_service_outlined;
      case _OwnerCarProfileFilter.underInspection:
        return Icons.search_rounded;
      case _OwnerCarProfileFilter.workInProgress:
        return Icons.handyman_outlined;
      case _OwnerCarProfileFilter.completed:
        return Icons.task_alt_rounded;
      case _OwnerCarProfileFilter.deliveryScheduled:
        return Icons.local_shipping_outlined;
      case _OwnerCarProfileFilter.onRoad:
        return Icons.route_rounded;
    }
  }
}

enum _OwnerCarProfileSort { approvalsFirst, status, carNumber, customer }

extension _OwnerCarProfileSortX on _OwnerCarProfileSort {
  String get label {
    switch (this) {
      case _OwnerCarProfileSort.approvalsFirst:
        return 'Approvals first';
      case _OwnerCarProfileSort.status:
        return 'Status';
      case _OwnerCarProfileSort.carNumber:
        return 'Car number';
      case _OwnerCarProfileSort.customer:
        return 'Customer';
    }
  }
}

class _OwnerDashboardTab extends StatelessWidget {
  const _OwnerDashboardTab({
    required this.onAssignPickup,
    required this.onCompletePickup,
    required this.onOpenCars,
    required this.onOpenWheels,
    required this.onOpenDocuments,
    required this.onCreateJobCard,
    required this.onOpenChat,
  });

  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final ValueChanged<_OwnerCarProfileFilter> onOpenCars;
  final VoidCallback onOpenWheels;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<String> onCreateJobCard;
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
    final pendingSales = controller.pendingSaleListings;
    final liveSales = controller.activeSaleListings;
    final soldSales = controller.soldSaleListings;

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
        _OwnerWheelsSummaryCard(
          pending: pendingSales.length,
          live: liveSales.length,
          sold: soldSales.length,
          onOpen: onOpenWheels,
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
          onCreateJobCard: onCreateJobCard,
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
          onOpenGarage: () => onOpenCars(_OwnerCarProfileFilter.received),
          onOpenTransit: () =>
              onOpenCars(_OwnerCarProfileFilter.pickupScheduled),
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
  final ValueChanged<_OwnerCarProfileFilter> onOpenCars;

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        icon: Icons.local_shipping_outlined,
        label: 'Transit',
        count: pickupCount,
        filter: _OwnerCarProfileFilter.pickupScheduled,
      ),
      (
        icon: Icons.home_repair_service_outlined,
        label: 'Garage',
        count: garageCount,
        filter: _OwnerCarProfileFilter.received,
      ),
      (
        icon: Icons.search_rounded,
        label: 'Inspect',
        count: inspectionCount,
        filter: _OwnerCarProfileFilter.underInspection,
      ),
      (
        icon: Icons.handyman_outlined,
        label: 'Work',
        count: workCount,
        filter: _OwnerCarProfileFilter.workInProgress,
      ),
      (
        icon: Icons.task_alt_rounded,
        label: 'Done',
        count: completedCount,
        filter: _OwnerCarProfileFilter.completed,
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

class _OwnerWheelsSummaryCard extends StatelessWidget {
  const _OwnerWheelsSummaryCard({
    required this.pending,
    required this.live,
    required this.sold,
    required this.onOpen,
  });

  final int pending;
  final int live;
  final int sold;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppPalette.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.motion_photos_auto_rounded,
                color: AppPalette.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wheels sales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pending approvals | $live live | $sold sold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open'),
            ),
          ],
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
    required this.onCreateJobCard,
    required this.onOpenChat,
  });

  final List<ServiceJob> jobs;
  final AppController controller;
  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<String> onCreateJobCard;
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
      case JobStatus.pickupScheduled:
        return Icons.local_shipping_outlined;
      case JobStatus.pickupDone:
        return Icons.inventory_2_outlined;
      case JobStatus.received:
        return Icons.inventory_2_outlined;
      case JobStatus.underInspection:
        return Icons.search_rounded;
      case JobStatus.workInProgress:
        return Icons.handyman_outlined;
      case JobStatus.completed:
        return Icons.receipt_long_outlined;
      case JobStatus.deliveryScheduled:
        return Icons.local_shipping_outlined;
      case JobStatus.onRoad:
        return Icons.route_rounded;
    }
  }

  IconData _primaryIcon(ServiceJob job) {
    if (job.status == JobStatus.pickupDone) {
      return Icons.assignment_rounded;
    }
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
      case JobStatus.pickupScheduled:
        return 'Assign pickup person';
      case JobStatus.pickupDone:
        return 'Create job card';
      case JobStatus.received:
        return 'Assign master mechanic';
      case JobStatus.underInspection:
        return 'Prepare job card or quotation';
      case JobStatus.workInProgress:
        return 'Share progress photo';
      case JobStatus.completed:
        return 'Send invoice';
      case JobStatus.deliveryScheduled:
        return 'Assign delivery person';
      case JobStatus.onRoad:
        return 'Available for new quote';
    }
  }

  void _runPrimary(ServiceJob job, CarProfile car) {
    if (job.status == JobStatus.pickupDone) {
      onCreateJobCard(car.id);
      return;
    }
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
    required this.searchQuery,
    required this.sort,
    required this.trackerReplayToken,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onOpenDocuments,
    required this.onCreateJobCard,
    required this.onOpenChat,
    required this.onAddPhoto,
    required this.onAssignPickup,
    required this.onCompletePickup,
    required this.onSellCar,
    required this.onAddCar,
  });

  final _OwnerCarProfileFilter filter;
  final String searchQuery;
  final _OwnerCarProfileSort sort;
  final int trackerReplayToken;
  final ValueChanged<_OwnerCarProfileFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_OwnerCarProfileSort> onSortChanged;
  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<String> onCreateJobCard;
  final ValueChanged<CarProfile> onOpenChat;
  final void Function(CarProfile car, JobStatus? status) onAddPhoto;
  final ValueChanged<ServiceJob> onAssignPickup;
  final ValueChanged<ServiceJob> onCompletePickup;
  final ValueChanged<CarProfile> onSellCar;
  final VoidCallback onAddCar;

  List<WorkApprovalRequest> _approvalRequestsForCar(
    AppController controller,
    CarProfile car,
  ) {
    final jobIds = controller.jobsForCar(car.id).map((job) => job.id).toSet();
    return controller.workApprovalRequests
        .where((request) => jobIds.contains(request.jobId))
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<WorkApprovalRequest> _pendingApprovalRequestsForCar(
    AppController controller,
    CarProfile car,
  ) {
    return _approvalRequestsForCar(
      controller,
      car,
    ).where((request) => request.status == RequestStatus.pending).toList();
  }

  String _statusLabel(ServiceJob? job) {
    return job == null
        ? _OwnerCarProfileFilter.registered.label
        : job.status.label;
  }

  int _statusRank(ServiceJob? job) {
    return job == null ? -1 : job.status.index;
  }

  IconData _statusIcon(ServiceJob? job) {
    if (job == null) return _OwnerCarProfileFilter.registered.icon;
    switch (job.status) {
      case JobStatus.pickupScheduled:
        return _OwnerCarProfileFilter.pickupScheduled.icon;
      case JobStatus.pickupDone:
        return _OwnerCarProfileFilter.pickupDone.icon;
      case JobStatus.received:
        return _OwnerCarProfileFilter.received.icon;
      case JobStatus.underInspection:
        return _OwnerCarProfileFilter.underInspection.icon;
      case JobStatus.workInProgress:
        return _OwnerCarProfileFilter.workInProgress.icon;
      case JobStatus.completed:
        return _OwnerCarProfileFilter.completed.icon;
      case JobStatus.deliveryScheduled:
        return _OwnerCarProfileFilter.deliveryScheduled.icon;
      case JobStatus.onRoad:
        return _OwnerCarProfileFilter.onRoad.icon;
    }
  }

  void _changeJobStatus(
    AppController controller,
    CarProfile car,
    ServiceJob job,
    JobStatus status,
  ) {
    if (job.status == status) return;
    if (job.status == JobStatus.pickupDone) {
      onCreateJobCard(car.id);
      return;
    }
    controller.setJobStatus(job.id, status);
    controller.sendStatusUpdate(
      job.id,
      '${car.carNumber} moved to ${status.label.toLowerCase()}.',
    );
  }

  bool _matchesFilter(
    ServiceJob? job,
    List<WorkApprovalRequest> pendingApprovals,
  ) {
    switch (filter) {
      case _OwnerCarProfileFilter.all:
        return true;
      case _OwnerCarProfileFilter.approvals:
        return pendingApprovals.isNotEmpty;
      case _OwnerCarProfileFilter.registered:
        return job == null;
      case _OwnerCarProfileFilter.pickupScheduled:
        return job?.status == JobStatus.pickupScheduled;
      case _OwnerCarProfileFilter.pickupDone:
        return job?.status == JobStatus.pickupDone;
      case _OwnerCarProfileFilter.received:
        return job?.status == JobStatus.received;
      case _OwnerCarProfileFilter.underInspection:
        return job?.status == JobStatus.underInspection;
      case _OwnerCarProfileFilter.workInProgress:
        return job?.status == JobStatus.workInProgress;
      case _OwnerCarProfileFilter.completed:
        return job?.status == JobStatus.completed;
      case _OwnerCarProfileFilter.deliveryScheduled:
        return job?.status == JobStatus.deliveryScheduled;
      case _OwnerCarProfileFilter.onRoad:
        return job?.status == JobStatus.onRoad;
    }
  }

  bool _matchesSearch(
    AppController controller,
    CarProfile car,
    ServiceJob? job,
    List<WorkApprovalRequest> approvals,
  ) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final customer = controller.customerForCar(car.id);
    final approvalText = approvals
        .map((request) => '${request.title} ${request.message}')
        .join(' ');
    final text = [
      car.carNumber,
      car.model,
      car.fuelType,
      car.year.toString(),
      customer?.name ?? '',
      customer?.phone ?? '',
      _statusLabel(job),
      approvalText,
    ].join(' ').toLowerCase();
    return text.contains(query);
  }

  List<CarProfile> _visibleCars(AppController controller) {
    final cars = controller.cars.where((car) {
      final job = controller.latestJobForCar(car.id);
      final pendingApprovals = _pendingApprovalRequestsForCar(controller, car);
      final approvals = _approvalRequestsForCar(controller, car);
      return _matchesFilter(job, pendingApprovals) &&
          _matchesSearch(controller, car, job, approvals);
    }).toList();
    cars.sort((left, right) => _compareCars(controller, left, right));
    return cars;
  }

  String _mechanicHistoryText(AppController controller, ServiceJob job) {
    final people = <String>[];
    if (job.masterMechanicId != null && job.masterMechanicId!.isNotEmpty) {
      final master = controller.staffById(job.masterMechanicId!);
      people.add('Master: ${master?.name ?? 'Assigned'}');
    }
    final mechanics = job.mechanicIds
        .map((id) => controller.staffById(id)?.name)
        .whereType<String>()
        .toList();
    if (mechanics.isNotEmpty) {
      people.add('Mechanics: ${mechanics.join(', ')}');
    }
    if (job.pickupPersonName != null && job.pickupPersonName!.isNotEmpty) {
      people.add('Pickup: ${job.pickupPersonName}');
    }
    return people.isEmpty ? 'No mechanic assigned yet' : people.join(' | ');
  }

  int _compareCars(
    AppController controller,
    CarProfile left,
    CarProfile right,
  ) {
    final leftJob = controller.latestJobForCar(left.id);
    final rightJob = controller.latestJobForCar(right.id);
    final leftApprovals = _pendingApprovalRequestsForCar(controller, left);
    final rightApprovals = _pendingApprovalRequestsForCar(controller, right);

    int compareApprovalsFirst() {
      final approvalCompare = rightApprovals.length.compareTo(
        leftApprovals.length,
      );
      if (approvalCompare != 0) return approvalCompare;
      final leftLatest = leftApprovals.firstOrNull?.createdAt;
      final rightLatest = rightApprovals.firstOrNull?.createdAt;
      if (leftLatest != null && rightLatest != null) {
        final dateCompare = rightLatest.compareTo(leftLatest);
        if (dateCompare != 0) return dateCompare;
      }
      return left.carNumber.compareTo(right.carNumber);
    }

    switch (sort) {
      case _OwnerCarProfileSort.approvalsFirst:
        return compareApprovalsFirst();
      case _OwnerCarProfileSort.status:
        final statusCompare = _statusRank(
          leftJob,
        ).compareTo(_statusRank(rightJob));
        if (statusCompare != 0) return statusCompare;
        return compareApprovalsFirst();
      case _OwnerCarProfileSort.carNumber:
        return left.carNumber.compareTo(right.carNumber);
      case _OwnerCarProfileSort.customer:
        final leftCustomer = controller.customerForCar(left.id)?.name ?? '';
        final rightCustomer = controller.customerForCar(right.id)?.name ?? '';
        final customerCompare = leftCustomer.compareTo(rightCustomer);
        if (customerCompare != 0) return customerCompare;
        return left.carNumber.compareTo(right.carNumber);
    }
  }

  void _showCarDetail(
    BuildContext context,
    AppController controller,
    CarProfile car,
  ) {
    final customer = controller.customerForCar(car.id);
    final documents = controller.documentsForCar(car.id);
    final history = controller.jobsForCar(car.id);
    final photos = controller.photoUpdatesForCar(car.id);
    final pendingApprovals = _pendingApprovalRequestsForCar(controller, car);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentJob = controller.latestJobForCar(car.id);
            final currentState = controller.workflowStateForCar(car.id);

            void handleTrackerStatus(JobStatus status) {
              final latestJob = controller.latestJobForCar(car.id);
              if (latestJob == null) return;
              if (latestJob.status == JobStatus.pickupDone &&
                  status != JobStatus.pickupDone) {
                Navigator.of(context).pop();
                onCreateJobCard(car.id);
                return;
              }
              _changeJobStatus(controller, car, latestJob, status);
              setModalState(() {});
            }

            void handleStatusPhoto(JobStatus status) {
              final latestJob = controller.latestJobForCar(car.id);
              if (latestJob?.status == JobStatus.pickupDone) {
                Navigator.of(context).pop();
                onCreateJobCard(car.id);
                return;
              }
              onAddPhoto(car, status);
            }

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
                      GarageServiceTracker(
                        status: currentJob?.status ?? JobStatus.onRoad,
                        replayToken: 'owner-detail:${car.id}',
                        onStatusChanged: currentJob == null
                            ? null
                            : handleTrackerStatus,
                      ),
                      const SizedBox(height: 12),
                      if (currentJob != null)
                        _OwnerPickupWorkflowCard(job: currentJob),
                      if (currentJob != null) const SizedBox(height: 10),
                      if (pendingApprovals.isNotEmpty) ...[
                        _OwnerTeamSection(
                          title: 'Approval messages',
                          emptyText: 'No approval messages for this car.',
                          children: pendingApprovals
                              .map(
                                (request) =>
                                    _WorkApprovalCard(request: request),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      GearboxActionGrid(
                        children: [
                          if (currentJob != null) ...[
                            AutomotiveControlButton(
                              icon: Icons.local_shipping_outlined,
                              label:
                                  currentState ==
                                      CarWorkflowState.readyForDelivery
                                  ? 'Deliver'
                                  : 'Assign',
                              active:
                                  currentJob.pickupState ==
                                      PickupState.assigned &&
                                  currentState.isTransit,
                              onPressed: () => onAssignPickup(currentJob),
                            ),
                            AutomotiveControlButton(
                              icon: Icons.task_alt_rounded,
                              label:
                                  currentState ==
                                      CarWorkflowState.readyForDelivery
                                  ? 'Delivered'
                                  : 'Transit done',
                              active:
                                  currentJob.pickupState ==
                                  PickupState.completed,
                              onPressed: () => onCompletePickup(currentJob),
                            ),
                            AutomotiveControlButton(
                              icon: Icons.search_rounded,
                              label: 'Inspect',
                              active:
                                  currentJob.status ==
                                  JobStatus.underInspection,
                              onPressed: () =>
                                  handleStatusPhoto(JobStatus.underInspection),
                            ),
                            AutomotiveControlButton(
                              icon: Icons.assignment_rounded,
                              label: 'Job card',
                              active:
                                  currentJob.status == JobStatus.pickupDone ||
                                  currentJob.status ==
                                      JobStatus.underInspection,
                              onPressed:
                                  currentJob.status == JobStatus.pickupDone ||
                                      currentJob.status == JobStatus.received ||
                                      currentJob.status ==
                                          JobStatus.underInspection
                                  ? () {
                                      Navigator.of(context).pop();
                                      onCreateJobCard(car.id);
                                    }
                                  : null,
                            ),
                            AutomotiveControlButton(
                              icon: Icons.handyman_outlined,
                              label: 'Work photo',
                              active:
                                  currentJob.status == JobStatus.workInProgress,
                              onPressed: () =>
                                  handleStatusPhoto(JobStatus.workInProgress),
                            ),
                            AutomotiveControlButton(
                              icon: Icons.verified_outlined,
                              label: 'Complete',
                              active: currentJob.status == JobStatus.completed,
                              onPressed: () =>
                                  handleStatusPhoto(JobStatus.completed),
                            ),
                            AutomotiveControlButton(
                              icon: Icons.route_rounded,
                              label: 'On-Road',
                              active: currentJob.status == JobStatus.onRoad,
                              onPressed: () {
                                if (currentJob.status == JobStatus.pickupDone) {
                                  Navigator.of(context).pop();
                                  onCreateJobCard(car.id);
                                  return;
                                }
                                controller.setJobStatus(
                                  currentJob.id,
                                  JobStatus.onRoad,
                                );
                                controller.sendStatusUpdate(
                                  currentJob.id,
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
                            icon: Icons.sell_outlined,
                            label: 'Sell',
                            active:
                                currentState.isAvailable ||
                                currentState.isInGarage,
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSellCar(car);
                            },
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
                            onPressed: currentJob == null
                                ? null
                                : () => controller.sendStatusUpdate(
                                    currentJob.id,
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
                            'ETA ${formatDateTime(item.expectedCompletion)} | ${_mechanicHistoryText(controller, item)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bills',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Car profiles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: onAddCar,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add car'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Search cars, customers, approvals',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<_OwnerCarProfileFilter>(
                initialValue: filter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _OwnerCarProfileFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Icon(value.icon, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                value.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onFilterChanged(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<_OwnerCarProfileSort>(
                initialValue: sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: _OwnerCarProfileSort.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleCars.isEmpty)
          const _EmptyOwnerList(message: 'No car profiles match this view.'),
        ...visibleCars.map((car) {
          final job = controller.latestJobForCar(car.id);
          final customer = controller.customerForCar(car.id);
          final documents = controller.documentsForCar(car.id);
          final pendingApprovals = _pendingApprovalRequestsForCar(
            controller,
            car,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCarDetail(context, controller, car),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    if (pendingApprovals.isEmpty)
                                      LedIndicator(active: car.isActive)
                                    else
                                      _OwnerApprovalBadge(
                                        count: pendingApprovals.length,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${customer?.name ?? '-'} | ${car.model}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _OwnerCarMetaChip(
                                      icon: _statusIcon(job),
                                      label: _statusLabel(job),
                                    ),
                                    _OwnerCarMetaChip(
                                      icon: Icons.description_outlined,
                                      label: '${documents.length} docs',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GarageServiceTracker(
                        status: job?.status ?? JobStatus.onRoad,
                        replayToken: 'owner-cars:$trackerReplayToken:${car.id}',
                        onStatusChanged: job == null
                            ? null
                            : (status) => _changeJobStatus(
                                controller,
                                car,
                                job,
                                status,
                              ),
                      ),
                      if (pendingApprovals.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _OwnerApprovalPreview(requests: pendingApprovals),
                      ],
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

class _OwnerCarMetaChip extends StatelessWidget {
  const _OwnerCarMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _OwnerApprovalBadge extends StatelessWidget {
  const _OwnerApprovalBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_chat_unread_outlined,
            color: AppPalette.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerApprovalPreview extends StatelessWidget {
  const _OwnerApprovalPreview({required this.requests});

  final List<WorkApprovalRequest> requests;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final latest = requests.first;
    final staff = controller.staffById(latest.staffId);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_chat_unread_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${requests.length} approval message${requests.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${latest.title} | ${staff?.name ?? 'Staff'} | ${formatShortDate(latest.createdAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
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
    final mapUri = _pickupMapUriForJob(job);

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
          if (job.pickupPhotoPath != null &&
              job.pickupPhotoPath!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            AppImage(
              path: job.pickupPhotoPath!,
              width: double.infinity,
              height: 128,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          if (mapUri != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(mapUri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open map'),
            ),
          ],
        ],
      ),
    );
  }
}

Uri? _pickupMapUriForJob(ServiceJob job) {
  if (job.pickupMapUrl?.trim().isNotEmpty == true) {
    return Uri.tryParse(job.pickupMapUrl!.trim());
  }
  if (job.hasPickupCoordinates) {
    return GoogleMapsLinkService.mapUriForCoordinates(
      latitude: job.pickupLatitude!,
      longitude: job.pickupLongitude!,
    );
  }
  if (job.pickupAddress?.trim().isNotEmpty == true) {
    return GoogleMapsLinkService.mapUriForAddress(job.pickupAddress!.trim());
  }
  return null;
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

class _OwnerTeamTab extends StatelessWidget {
  const _OwnerTeamTab({required this.onAddStaff, required this.onEditStaff});

  final VoidCallback onAddStaff;
  final ValueChanged<StaffProfile> onEditStaff;

  @override
  Widget build(BuildContext context) {
    return AppInnerTabs(
      tabs: [
        AppInnerTab(
          label: 'Home',
          child: ListView(
            key: const PageStorageKey('owner-team-home'),
            padding: const EdgeInsets.all(16),
            children: [
              _OwnerTeamHomeSection(
                onAddStaff: onAddStaff,
                onEditStaff: onEditStaff,
              ),
            ],
          ),
        ),
        AppInnerTab(
          label: 'Attendance',
          child: ListView(
            key: const PageStorageKey('owner-team-attendance'),
            padding: const EdgeInsets.all(16),
            children: const [_OwnerAttendanceSection()],
          ),
        ),
        AppInnerTab(
          label: 'Payroll',
          child: ListView(
            key: const PageStorageKey('owner-team-payroll'),
            padding: const EdgeInsets.all(16),
            children: const [_OwnerPayrollSection()],
          ),
        ),
      ],
    );
  }
}

class _OwnerTeamHomeSection extends StatelessWidget {
  const _OwnerTeamHomeSection({
    required this.onAddStaff,
    required this.onEditStaff,
  });

  final VoidCallback onAddStaff;
  final ValueChanged<StaffProfile> onEditStaff;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final waitingForMaster = controller.jobs
        .where(
          (job) =>
              (job.status == JobStatus.received ||
                  job.status == JobStatus.pickupDone) &&
              (job.masterMechanicId == null || job.masterMechanicId!.isEmpty),
        )
        .toList();
    final pendingProposals = controller.staffAssignmentProposals
        .where((proposal) => proposal.status == RequestStatus.pending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mechanic CRM',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: onAddStaff,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Staff'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _OwnerTeamSummary(
          masters: controller.masterMechanics.length,
          mechanics: controller.mechanics.length,
          pendingTeams: pendingProposals.length,
          pendingWork: waitingForMaster.length,
          labels: const [
            'Masters',
            'Mechanics',
            'Team approvals',
            'Master assign',
          ],
        ),
        const SizedBox(height: 14),
        _OwnerTeamSection(
          title: 'Assign master mechanic',
          emptyText: 'No received cars are waiting for a master mechanic.',
          children: waitingForMaster.map((job) {
            final car = controller.carForJob(job);
            return _MasterAssignmentCard(job: job, car: car);
          }).toList(),
        ),
        const SizedBox(height: 14),
        _OwnerTeamSection(
          title: 'Mechanic team approvals',
          emptyText: 'No mechanic team requests pending.',
          children: pendingProposals
              .map((proposal) => _TeamProposalCard(proposal: proposal))
              .toList(),
        ),
        const SizedBox(height: 14),
        _OwnerStaffProfilesPanel(onEditStaff: onEditStaff),
      ],
    );
  }
}

enum _OwnerStaffProfileFilter {
  all,
  masterMechanics,
  mechanics,
  active,
  inactive,
  requests,
}

extension _OwnerStaffProfileFilterX on _OwnerStaffProfileFilter {
  String get label {
    switch (this) {
      case _OwnerStaffProfileFilter.all:
        return 'All staff';
      case _OwnerStaffProfileFilter.masterMechanics:
        return 'Master Mechanics';
      case _OwnerStaffProfileFilter.mechanics:
        return 'Mechanics';
      case _OwnerStaffProfileFilter.active:
        return 'Active';
      case _OwnerStaffProfileFilter.inactive:
        return 'Inactive';
      case _OwnerStaffProfileFilter.requests:
        return 'Requests';
    }
  }

  IconData get icon {
    switch (this) {
      case _OwnerStaffProfileFilter.all:
        return Icons.groups_outlined;
      case _OwnerStaffProfileFilter.masterMechanics:
        return Icons.engineering_outlined;
      case _OwnerStaffProfileFilter.mechanics:
        return Icons.build_outlined;
      case _OwnerStaffProfileFilter.active:
        return Icons.verified_user_outlined;
      case _OwnerStaffProfileFilter.inactive:
        return Icons.person_off_outlined;
      case _OwnerStaffProfileFilter.requests:
        return Icons.mark_chat_unread_outlined;
    }
  }
}

enum _OwnerStaffProfileSort {
  requestsFirst,
  name,
  role,
  carsHandled,
  attendance,
  salary,
}

extension _OwnerStaffProfileSortX on _OwnerStaffProfileSort {
  String get label {
    switch (this) {
      case _OwnerStaffProfileSort.requestsFirst:
        return 'Requests first';
      case _OwnerStaffProfileSort.name:
        return 'Name';
      case _OwnerStaffProfileSort.role:
        return 'Role';
      case _OwnerStaffProfileSort.carsHandled:
        return 'Cars handled';
      case _OwnerStaffProfileSort.attendance:
        return 'Attendance';
      case _OwnerStaffProfileSort.salary:
        return 'Salary';
    }
  }
}

class _OwnerStaffProfilesPanel extends StatefulWidget {
  const _OwnerStaffProfilesPanel({required this.onEditStaff});

  final ValueChanged<StaffProfile> onEditStaff;

  @override
  State<_OwnerStaffProfilesPanel> createState() =>
      _OwnerStaffProfilesPanelState();
}

class _OwnerStaffProfilesPanelState extends State<_OwnerStaffProfilesPanel> {
  String _searchQuery = '';
  _OwnerStaffProfileFilter _filter = _OwnerStaffProfileFilter.all;
  _OwnerStaffProfileSort _sort = _OwnerStaffProfileSort.requestsFirst;

  List<WorkApprovalRequest> _workRequestsForStaff(
    AppController controller,
    StaffProfile staff,
  ) {
    return controller.workApprovalRequests
        .where((request) => request.staffId == staff.id)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<StaffAssignmentProposal> _teamRequestsForStaff(
    AppController controller,
    StaffProfile staff,
  ) {
    return controller.staffAssignmentProposals
        .where(
          (proposal) =>
              proposal.masterMechanicId == staff.id ||
              proposal.mechanicIds.contains(staff.id),
        )
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  int _pendingRequestCount(AppController controller, StaffProfile staff) {
    final advances = controller
        .advancesForStaff(staff.id)
        .where((advance) => advance.status == RequestStatus.pending)
        .length;
    final leaves = controller
        .leavesForStaff(staff.id)
        .where((leave) => leave.status == RequestStatus.pending)
        .length;
    final work = _workRequestsForStaff(
      controller,
      staff,
    ).where((request) => request.status == RequestStatus.pending).length;
    final teams = _teamRequestsForStaff(
      controller,
      staff,
    ).where((proposal) => proposal.status == RequestStatus.pending).length;
    return advances + leaves + work + teams;
  }

  List<CarProfile> _handledCars(AppController controller, StaffProfile staff) {
    final seen = <String>{};
    final cars = <CarProfile>[];
    for (final job in controller.jobsForStaff(staff.id)) {
      final car = controller.carForJob(job);
      if (car != null && seen.add(car.id)) {
        cars.add(car);
      }
    }
    return cars;
  }

  bool _matchesFilter(AppController controller, StaffProfile staff) {
    switch (_filter) {
      case _OwnerStaffProfileFilter.all:
        return true;
      case _OwnerStaffProfileFilter.masterMechanics:
        return staff.role == StaffRole.masterMechanic;
      case _OwnerStaffProfileFilter.mechanics:
        return staff.role == StaffRole.mechanic;
      case _OwnerStaffProfileFilter.active:
        return staff.isActive;
      case _OwnerStaffProfileFilter.inactive:
        return !staff.isActive;
      case _OwnerStaffProfileFilter.requests:
        return _pendingRequestCount(controller, staff) > 0;
    }
  }

  bool _matchesSearch(AppController controller, StaffProfile staff) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final cars = _handledCars(
      controller,
      staff,
    ).map((car) => '${car.carNumber} ${car.model}').join(' ');
    final advances = controller
        .advancesForStaff(staff.id)
        .map((advance) => advance.reason)
        .join(' ');
    final leaves = controller
        .leavesForStaff(staff.id)
        .map((leave) => leave.reason)
        .join(' ');
    final work = _workRequestsForStaff(
      controller,
      staff,
    ).map((request) => '${request.title} ${request.message}').join(' ');
    final text = [
      staff.name,
      staff.phone,
      staff.role.label,
      staff.primarySkill,
      staff.monthlySalary.toStringAsFixed(0),
      cars,
      advances,
      leaves,
      work,
    ].join(' ').toLowerCase();
    return text.contains(query);
  }

  List<StaffProfile> _visibleStaff(AppController controller) {
    final staff = controller.staffProfiles
        .where(
          (profile) =>
              _matchesFilter(controller, profile) &&
              _matchesSearch(controller, profile),
        )
        .toList();
    staff.sort((left, right) => _compareStaff(controller, left, right));
    return staff;
  }

  int _compareStaff(
    AppController controller,
    StaffProfile left,
    StaffProfile right,
  ) {
    int requestsFirst() {
      final requestCompare = _pendingRequestCount(
        controller,
        right,
      ).compareTo(_pendingRequestCount(controller, left));
      if (requestCompare != 0) return requestCompare;
      return left.name.compareTo(right.name);
    }

    switch (_sort) {
      case _OwnerStaffProfileSort.requestsFirst:
        return requestsFirst();
      case _OwnerStaffProfileSort.name:
        return left.name.compareTo(right.name);
      case _OwnerStaffProfileSort.role:
        final roleCompare = left.role.label.compareTo(right.role.label);
        if (roleCompare != 0) return roleCompare;
        return left.name.compareTo(right.name);
      case _OwnerStaffProfileSort.carsHandled:
        final carCompare = _handledCars(
          controller,
          right,
        ).length.compareTo(_handledCars(controller, left).length);
        if (carCompare != 0) return carCompare;
        return requestsFirst();
      case _OwnerStaffProfileSort.attendance:
        final attendanceCompare = controller
            .attendanceForStaff(right.id)
            .length
            .compareTo(controller.attendanceForStaff(left.id).length);
        if (attendanceCompare != 0) return attendanceCompare;
        return requestsFirst();
      case _OwnerStaffProfileSort.salary:
        final salaryCompare = right.monthlySalary.compareTo(left.monthlySalary);
        if (salaryCompare != 0) return salaryCompare;
        return requestsFirst();
    }
  }

  void _showStaffDetail(
    BuildContext context,
    AppController controller,
    StaffProfile staff,
  ) {
    final jobs = controller.jobsForStaff(staff.id);
    final cars = _handledCars(controller, staff);
    final attendance = controller.attendanceForStaff(staff.id);
    final advances = controller.advancesForStaff(staff.id);
    final leaves = controller.leavesForStaff(staff.id);
    final slips = controller.salarySlipsForStaff(staff.id);
    final workRequests = _workRequestsForStaff(controller, staff);
    final teamRequests = _teamRequestsForStaff(controller, staff);
    final requestTiles = <Widget>[
      ...advances
          .take(4)
          .map(
            (advance) => _OwnerSimpleTile(
              icon: Icons.payments_outlined,
              title:
                  'Advance ${formatCurrency(advance.amount)} | ${advance.status.label}',
              subtitle:
                  '${advance.reason} | ${formatShortDate(advance.requestedAt)}',
            ),
          ),
      ...leaves
          .take(4)
          .map(
            (leave) => _OwnerSimpleTile(
              icon: Icons.event_busy_outlined,
              title:
                  'Leave ${formatShortDate(leave.fromDate)}-${formatShortDate(leave.toDate)} | ${leave.status.label}',
              subtitle: leave.reason,
            ),
          ),
      ...workRequests
          .take(4)
          .map(
            (request) => _OwnerSimpleTile(
              icon: Icons.approval_outlined,
              title: '${request.title} | ${request.status.label}',
              subtitle:
                  '${request.message} | ${formatShortDate(request.createdAt)}',
            ),
          ),
      ...teamRequests.take(4).map((proposal) {
        final job = controller.jobs
            .where((item) => item.id == proposal.jobId)
            .firstOrNull;
        final car = job == null ? null : controller.carForJob(job);
        return _OwnerSimpleTile(
          icon: Icons.groups_outlined,
          title:
              'Team assignment | ${proposal.status.label} | ${car?.carNumber ?? 'Vehicle'}',
          subtitle: formatShortDate(proposal.createdAt),
        );
      }),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.82,
              child: ListView(
                children: [
                  Row(
                    children: [
                      MessengerAvatar(
                        path: staff.profileImagePath,
                        initials: staff.name.substring(0, 1),
                        radius: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${staff.role.label} | ${staff.primarySkill}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${staff.phone} | ${staff.isActive ? 'Active' : 'Inactive'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Edit staff',
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onEditStaff(staff);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OwnerCarMetaChip(
                        icon: Icons.payments_outlined,
                        label: formatCurrency(staff.monthlySalary),
                      ),
                      _OwnerCarMetaChip(
                        icon: Icons.directions_car_outlined,
                        label: '${cars.length} cars handled',
                      ),
                      _OwnerCarMetaChip(
                        icon: Icons.how_to_reg_outlined,
                        label: '${attendance.length} attendance',
                      ),
                      _OwnerCarMetaChip(
                        icon: Icons.receipt_long_outlined,
                        label: '${slips.length} payslips',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _OwnerTeamSection(
                    title: 'Requests',
                    emptyText: 'No requests recorded for this staff profile.',
                    children: requestTiles,
                  ),
                  const SizedBox(height: 14),
                  _OwnerTeamSection(
                    title: 'Generated payslips',
                    emptyText: 'No payslips generated yet.',
                    children: slips
                        .take(6)
                        .map(
                          (slip) => _OwnerSimpleTile(
                            icon: Icons.receipt_long_outlined,
                            title:
                                '${slip.monthLabel} | Net ${formatCurrency(slip.netPay)}',
                            subtitle:
                                'Gross ${formatCurrency(slip.grossPay)} | Advance ${formatCurrency(slip.advanceDeduction)} | Leave ${formatCurrency(slip.leaveDeduction)}',
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _OwnerTeamSection(
                    title: 'Attendance reports',
                    emptyText: 'No attendance records yet.',
                    children: attendance
                        .take(8)
                        .map(
                          (entry) => _OwnerSimpleTile(
                            icon: Icons.how_to_reg_outlined,
                            title:
                                '${formatShortDate(entry.date)} | ${entry.status.label}',
                            subtitle:
                                'Face ${entry.faceVerified ? 'verified' : 'pending'} | Location ${entry.locationVerified ? 'verified' : 'pending'}${entry.note == null ? '' : ' | ${entry.note}'}',
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _OwnerTeamSection(
                    title: 'Cars handled',
                    emptyText: 'No cars handled yet.',
                    children: jobs.take(8).map((job) {
                      final car = controller.carForJob(job);
                      final role = job.masterMechanicId == staff.id
                          ? 'Master'
                          : job.mechanicIds.contains(staff.id)
                          ? 'Mechanic'
                          : 'Pickup';
                      return _OwnerSimpleTile(
                        icon: Icons.directions_car_outlined,
                        title:
                            '${car?.carNumber ?? 'Vehicle'} | ${job.status.label}',
                        subtitle:
                            '$role | ${car?.model ?? '-'} | ETA ${formatDateTime(job.expectedCompletion)}',
                      );
                    }).toList(),
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
    final visibleStaff = _visibleStaff(controller);
    final pendingRequests = controller.staffProfiles.fold<int>(
      0,
      (sum, staff) => sum + _pendingRequestCount(controller, staff),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Staff profiles', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _searchQuery,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Search mechanics, requests, cars',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<_OwnerStaffProfileFilter>(
                initialValue: _filter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Filter'),
                items: _OwnerStaffProfileFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Icon(value.icon, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                value.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _filter = value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<_OwnerStaffProfileSort>(
                initialValue: _sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: _OwnerStaffProfileSort.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OwnerCarMetaChip(
          icon: Icons.mark_chat_unread_outlined,
          label:
              '$pendingRequests request${pendingRequests == 1 ? '' : 's'} pending',
        ),
        const SizedBox(height: 12),
        if (visibleStaff.isEmpty)
          const _EmptyOwnerList(message: 'No staff profiles match this view.'),
        ...visibleStaff.map(
          (staff) => _OwnerStaffProfileCard(
            staff: staff,
            carsHandled: _handledCars(controller, staff).length,
            attendanceCount: controller.attendanceForStaff(staff.id).length,
            payslipCount: controller.salarySlipsForStaff(staff.id).length,
            pendingRequests: _pendingRequestCount(controller, staff),
            onTap: () => _showStaffDetail(context, controller, staff),
            onEdit: () => widget.onEditStaff(staff),
          ),
        ),
      ],
    );
  }
}

class _OwnerAttendanceSection extends StatelessWidget {
  const _OwnerAttendanceSection();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final pendingLeaves = controller.leaveRequests
        .where((leave) => leave.status == RequestStatus.pending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OwnerTeamSummary(
          masters: controller.staffProfiles.length,
          mechanics: controller.attendanceEntries.length,
          pendingTeams: pendingLeaves.length,
          pendingWork: pendingLeaves.length,
          labels: const ['Staff', 'Attendance', 'Leaves', 'Approvals'],
        ),
        const SizedBox(height: 14),
        _OwnerTeamSection(
          title: 'Leave requests',
          emptyText: 'No leave requests pending.',
          children: pendingLeaves
              .map((leave) => _LeaveApprovalCard(leave: leave))
              .toList(),
        ),
        const SizedBox(height: 14),
        Text(
          'Latest attendance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (controller.attendanceEntries.isEmpty)
          const _EmptyOwnerList(message: 'No attendance entries yet.'),
        ...controller.attendanceEntries.take(12).map((entry) {
          final staff = controller.staffById(entry.staffId);
          return _OwnerSimpleTile(
            icon: Icons.how_to_reg_outlined,
            title: '${staff?.name ?? 'Staff'} | ${entry.status.label}',
            subtitle:
                '${formatShortDate(entry.date)} | Face ${entry.faceVerified ? 'verified' : 'pending'} | Location ${entry.locationVerified ? 'verified' : 'pending'}',
          );
        }),
      ],
    );
  }
}

class _OwnerPayrollSection extends StatelessWidget {
  const _OwnerPayrollSection();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final pendingAdvances = controller.salaryAdvances
        .where((advance) => advance.status == RequestStatus.pending)
        .toList();
    final latestSlips = controller.salarySlips.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OwnerTeamSummary(
          masters: controller.staffProfiles.length,
          mechanics: controller.salarySlips.length,
          pendingTeams: pendingAdvances.length,
          pendingWork: controller.salaryAdvances.length,
          labels: const ['Staff', 'Payslips', 'Advance approvals', 'Advances'],
        ),
        const SizedBox(height: 14),
        _OwnerTeamSection(
          title: 'Salary advances',
          emptyText: 'No salary advance requests pending.',
          children: pendingAdvances
              .map((advance) => _AdvanceApprovalCard(advance: advance))
              .toList(),
        ),
        const SizedBox(height: 14),
        Text('Staff salary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...controller.staffProfiles.map(
          (staff) => _PayrollStaffCard(staff: staff),
        ),
        const SizedBox(height: 14),
        Text('Latest payslips', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (latestSlips.isEmpty)
          const _EmptyOwnerList(message: 'No payslips generated yet.'),
        ...latestSlips.map((slip) {
          final staff = controller.staffById(slip.staffId);
          return _OwnerSimpleTile(
            icon: Icons.receipt_long_outlined,
            title: '${staff?.name ?? 'Staff'} | ${slip.monthLabel}',
            subtitle:
                'Net ${formatCurrency(slip.netPay)} | Advance ${formatCurrency(slip.advanceDeduction)}',
          );
        }),
      ],
    );
  }
}

class _OwnerTeamSummary extends StatelessWidget {
  const _OwnerTeamSummary({
    required this.masters,
    required this.mechanics,
    required this.pendingTeams,
    required this.pendingWork,
    this.labels = const ['Masters', 'Mechanics', 'Teams', 'Approvals'],
  });

  final int masters;
  final int mechanics;
  final int pendingTeams;
  final int pendingWork;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final values = [masters, mechanics, pendingTeams, pendingWork];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      childAspectRatio: 0.86,
      children: List.generate(labels.length, (index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  values[index].toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _OwnerTeamSection extends StatelessWidget {
  const _OwnerTeamSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Text(emptyText, style: Theme.of(context).textTheme.bodySmall),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MasterAssignmentCard extends StatelessWidget {
  const _MasterAssignmentCard({required this.job, required this.car});

  final ServiceJob job;
  final CarProfile? car;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_ind_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car?.carNumber ?? 'Vehicle'),
                Text(
                  '${car?.model ?? '-'} | ${job.status.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Assign master mechanic',
            onSelected: (staffId) =>
                controller.assignMasterMechanicToJob(job.id, staffId),
            itemBuilder: (context) => controller.masterMechanics
                .map(
                  (staff) =>
                      PopupMenuItem(value: staff.id, child: Text(staff.name)),
                )
                .toList(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
    );
  }
}

class _TeamProposalCard extends StatelessWidget {
  const _TeamProposalCard({required this.proposal});

  final StaffAssignmentProposal proposal;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final job = controller.jobs
        .where((item) => item.id == proposal.jobId)
        .firstOrNull;
    final car = job == null ? null : controller.carForJob(job);
    final master = controller.staffById(proposal.masterMechanicId);
    final mechanicNames = proposal.mechanicIds
        .map((id) => controller.staffById(id)?.name)
        .whereType<String>()
        .join(', ');
    return _OwnerDecisionCard(
      icon: Icons.groups_outlined,
      title: car?.carNumber ?? 'Mechanic team',
      subtitle:
          '${master?.name ?? 'Master'} requested: ${mechanicNames.isEmpty ? '-' : mechanicNames}',
      onReject: () => controller.decideMechanicTeamProposal(
        proposal.id,
        RequestStatus.rejected,
      ),
      onApprove: () => controller.decideMechanicTeamProposal(
        proposal.id,
        RequestStatus.approved,
      ),
    );
  }
}

class _WorkApprovalCard extends StatelessWidget {
  const _WorkApprovalCard({required this.request});

  final WorkApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final job = controller.jobs
        .where((item) => item.id == request.jobId)
        .firstOrNull;
    final car = job == null ? null : controller.carForJob(job);
    final staff = controller.staffById(request.staffId);
    final isDone =
        request.status != RequestStatus.pending || request.forwardedToCustomer;
    final statusLabel = request.forwardedToCustomer
        ? 'Approved and sent to customer'
        : request.status.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.approval_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${request.title} | ${car?.carNumber ?? 'Vehicle'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${staff?.name ?? 'Staff'}: ${request.message}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (request.photoPath != null) ...[
            const SizedBox(height: 10),
            AppImage(
              path: request.photoPath!,
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          const SizedBox(height: 10),
          if (isDone)
            _OwnerCarMetaChip(
              icon: Icons.check_circle_outline_rounded,
              label: statusLabel,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.decideWorkApprovalRequest(
                    request.id,
                    RequestStatus.rejected,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    controller.decideWorkApprovalRequest(
                      request.id,
                      RequestStatus.approved,
                      forwardToCustomer: true,
                      ownerResponse: 'Approved by owner and sent to customer.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Approved and sent to customer.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdvanceApprovalCard extends StatelessWidget {
  const _AdvanceApprovalCard({required this.advance});

  final SalaryAdvance advance;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final staff = controller.staffById(advance.staffId);
    return _OwnerDecisionCard(
      icon: Icons.payments_outlined,
      title: '${staff?.name ?? 'Staff'} | ${formatCurrency(advance.amount)}',
      subtitle: advance.reason,
      onReject: () =>
          controller.decideSalaryAdvance(advance.id, RequestStatus.rejected),
      onApprove: () =>
          controller.decideSalaryAdvance(advance.id, RequestStatus.approved),
    );
  }
}

class _LeaveApprovalCard extends StatelessWidget {
  const _LeaveApprovalCard({required this.leave});

  final LeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final staff = controller.staffById(leave.staffId);
    return _OwnerDecisionCard(
      icon: Icons.event_busy_outlined,
      title:
          '${staff?.name ?? 'Staff'} | ${formatShortDate(leave.fromDate)}-${formatShortDate(leave.toDate)}',
      subtitle: leave.reason,
      onReject: () =>
          controller.decideLeaveRequest(leave.id, RequestStatus.rejected),
      onApprove: () =>
          controller.decideLeaveRequest(leave.id, RequestStatus.approved),
    );
  }
}

class _OwnerDecisionCard extends StatelessWidget {
  const _OwnerDecisionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onReject,
    required this.onApprove,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
              ),
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerStaffProfileCard extends StatelessWidget {
  const _OwnerStaffProfileCard({
    required this.staff,
    required this.carsHandled,
    required this.attendanceCount,
    required this.payslipCount,
    required this.pendingRequests,
    required this.onTap,
    required this.onEdit,
  });

  final StaffProfile staff;
  final int carsHandled;
  final int attendanceCount;
  final int payslipCount;
  final int pendingRequests;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessengerAvatar(
                      path: staff.profileImagePath,
                      initials: staff.name.substring(0, 1),
                      radius: 25,
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
                                  staff.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (pendingRequests > 0)
                                _OwnerApprovalBadge(count: pendingRequests)
                              else
                                LedIndicator(active: staff.isActive),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${staff.role.label} | ${staff.primarySkill}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _OwnerCarMetaChip(
                                icon: Icons.payments_outlined,
                                label: formatCurrency(staff.monthlySalary),
                              ),
                              _OwnerCarMetaChip(
                                icon: Icons.directions_car_outlined,
                                label: '$carsHandled cars',
                              ),
                              _OwnerCarMetaChip(
                                icon: Icons.how_to_reg_outlined,
                                label: '$attendanceCount attendance',
                              ),
                              _OwnerCarMetaChip(
                                icon: Icons.receipt_long_outlined,
                                label: '$payslipCount payslips',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Edit staff',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                if (pendingRequests > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.soft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_chat_unread_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingRequests request${pendingRequests == 1 ? '' : 's'} need owner action',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayrollStaffCard extends StatelessWidget {
  const _PayrollStaffCard({required this.staff});

  final StaffProfile staff;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final slips = controller.salarySlipsForStaff(staff.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    staff.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(formatCurrency(staff.monthlySalary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${staff.role.label} | ${slips.length} payslips',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    controller.generateSalarySlip(
                      staff.id,
                      '${DateTime.now().month}/${DateTime.now().year}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payslip generated for ${staff.name}.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Generate payslip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSimpleTile extends StatelessWidget {
  const _OwnerSimpleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _OwnerChatTab extends StatelessWidget {
  const _OwnerChatTab({
    required this.selectedUserId,
    required this.selectedCarId,
    required this.channel,
    required this.searchQuery,
    required this.slideForward,
    required this.replyController,
    required this.onUserChanged,
    required this.onBack,
    required this.onCarChanged,
    required this.onChannelChanged,
    required this.onSearchChanged,
    required this.onSendDocument,
    required this.onSendPhoto,
    required this.onSend,
  });

  final String? selectedUserId;
  final String? selectedCarId;
  final ChatChannel channel;
  final String searchQuery;
  final bool slideForward;
  final TextEditingController replyController;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onBack;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<ChatChannel> onChannelChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ServiceDocument> onSendDocument;
  final VoidCallback onSendPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);

    if (selectedUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.markConversationReadByOwner(selectedUserId!);
      });
    }

    return AppInnerTabs(
      currentIndex: ChatChannel.values.indexOf(channel),
      onChanged: (value) => onChannelChanged(ChatChannel.values[value]),
      tabs: ChatChannel.values
          .map(
            (item) => AppInnerTab(
              label: item.label,
              child: _OwnerChatChannelView(
                key: PageStorageKey('owner-chat-channel-${item.name}'),
                selectedUserId: selectedUserId,
                selectedCarId: selectedCarId,
                channel: item,
                searchQuery: searchQuery,
                slideForward: slideForward,
                replyController: replyController,
                onUserChanged: onUserChanged,
                onBack: onBack,
                onCarChanged: onCarChanged,
                onSearchChanged: onSearchChanged,
                onSendDocument: onSendDocument,
                onSendPhoto: onSendPhoto,
                onSend: onSend,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OwnerChatChannelView extends StatelessWidget {
  const _OwnerChatChannelView({
    super.key,
    required this.selectedUserId,
    required this.selectedCarId,
    required this.channel,
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
  final ChatChannel channel;
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

    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              final tween = Tween<Offset>(
                begin: slideForward ? const Offset(1, 0) : const Offset(-1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            child: selectedCustomer == null
                ? _OwnerInboxView(
                    key: ValueKey('owner-inbox-${channel.name}'),
                    channel: channel,
                    searchQuery: searchQuery,
                    onSearchChanged: onSearchChanged,
                    onOpenCustomer: (customer) {
                      controller.markConversationReadByOwner(customer.id);
                      onUserChanged(customer.id);
                    },
                  )
                : _OwnerChatWindow(
                    key: ValueKey(
                      'owner-chat-${selectedCustomer.id}-${channel.name}',
                    ),
                    customer: selectedCustomer,
                    selectedCarId: selectedCarId,
                    channel: channel,
                    replyController: replyController,
                    onBack: onBack,
                    onCarChanged: onCarChanged,
                    onSendDocument: onSendDocument,
                    onSendPhoto: onSendPhoto,
                    onSend: onSend,
                  ),
          ),
        ),
      ],
    );
  }
}

class _OwnerInboxView extends StatelessWidget {
  const _OwnerInboxView({
    super.key,
    required this.channel,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onOpenCustomer,
  });

  final ChatChannel channel;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<GarageUser> onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final needle = searchQuery.trim().toLowerCase();
    final customers =
        controller.customers.where((customer) {
          final messages = controller.conversationForUser(
            customer.id,
            channel: channel,
          );
          if (messages.isEmpty) return false;
          final last = messages.last.message;
          final haystack = '${customer.name} ${customer.phone} $last'
              .toLowerCase();
          return needle.isEmpty || haystack.contains(needle);
        }).toList()..sort((left, right) {
          final leftMessages = controller.conversationForUser(
            left.id,
            channel: channel,
          );
          final rightMessages = controller.conversationForUser(
            right.id,
            channel: channel,
          );
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
          child: customers.isEmpty
              ? Center(
                  child: Text(
                    'No ${channel.label.toLowerCase()} chats yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final messages = controller.conversationForUser(
                      customer.id,
                      channel: channel,
                    );
                    final last = messages.isEmpty ? null : messages.last;
                    final unread = controller.unreadIncomingCountForCustomer(
                      customer.id,
                      channel: channel,
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
    required this.channel,
    required this.replyController,
    required this.onBack,
    required this.onCarChanged,
    required this.onSendDocument,
    required this.onSendPhoto,
    required this.onSend,
  });

  final GarageUser customer;
  final String? selectedCarId;
  final ChatChannel channel;
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
      channel: channel,
    );
    final documentCars = selectedCarId == null
        ? customerCars
        : customerCars.where((car) => car.id == selectedCarId).toList();
    final documents = documentCars
        .expand((car) => controller.documentsForCar(car.id))
        .toList();
    final pendingSaleListings = channel == ChatChannel.general
        ? <CarSaleListing>[]
        : controller.pendingSaleListings
              .where((listing) => listing.sellerUserId == customer.id)
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
        if (pendingSaleListings.isNotEmpty)
          _OwnerChatApprovalPanel(listings: pendingSaleListings),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No ${channel.label.toLowerCase()} messages yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.builder(
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
                    decoration: InputDecoration(
                      hintText: 'Reply about ${channel.label.toLowerCase()}...',
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

class _OwnerChatApprovalPanel extends StatelessWidget {
  const _OwnerChatApprovalPanel({required this.listings});

  final List<CarSaleListing> listings;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppPalette.soft,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Car approvals', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...listings.map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled_outlined,
                          color: AppPalette.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(listing.price)} | ${listing.odometerKm} km | Posted ${formatShortDate(listing.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            controller.rejectSaleListing(listing.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${listing.title} rejected.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            controller.approveSaleListing(listing.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${listing.title} approved.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

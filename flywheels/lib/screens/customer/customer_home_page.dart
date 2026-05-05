import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/shared/document_pdf_viewer_page.dart';
import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/services/whatsapp_share_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _picker = ImagePicker();
  final _chatMessageController = TextEditingController();
  int _currentIndex = 0;
  bool _pickingProfilePhoto = false;
  String _chatTopic = 'General enquiry';
  String? _chatCarId;

  @override
  void dispose() {
    _chatMessageController.dispose();
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
    FlywheelsScope.of(context).updateProfilePhoto(image.path);
  }

  Future<void> _showGaragePhotoSheet(
    BuildContext context,
    CarProfile car,
  ) async {
    final noteController = TextEditingController();
    await showModalBottomSheet<void>(
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
                'Request latest images',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the garage to share fresh photos for ${car.carNumber}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What should they capture?',
                  hintText:
                      'For example: engine bay, underbody, dent area, part installation.',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    FlywheelsScope.of(context).requestGaragePhotos(
                      car.id,
                      note: noteController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Send request'),
                ),
              ),
            ],
          ),
        );
      },
    );
    noteController.dispose();
  }

  void _showAddCarSheet(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final carNumberController = TextEditingController();
    final modelController = TextEditingController();
    final fuelController = TextEditingController();
    final yearController = TextEditingController();
    const companies = {
      'MG': ['Hector', 'Astor', 'Gloster', 'ZS EV'],
      'Hyundai': ['Creta', 'Venue', 'Verna', 'i20'],
      'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Ertiga'],
      'Tata': ['Nexon', 'Harrier', 'Punch', 'Safari'],
      'Mahindra': ['XUV700', 'Scorpio N', 'Thar', 'XUV300'],
      'Toyota': ['Innova Crysta', 'Fortuner', 'Glanza', 'Urban Cruiser'],
      'Kia': ['Seltos', 'Sonet', 'Carens', 'EV6'],
      'Honda': ['City', 'Amaze', 'Elevate', 'Jazz'],
    };
    var selectedCompany = companies.keys.first;
    var selectedModel = companies[selectedCompany]!.first;
    String? selectedImagePath;
    yearController.text = DateTime.now().year.toString();
    modelController.text = '$selectedCompany $selectedModel';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final year =
                int.tryParse(yearController.text.trim()) ?? DateTime.now().year;
            final previewPath =
                selectedImagePath ??
                CarMediaService.imageForModel(modelController.text, year: year);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add a car',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    AppImage(
                      path: previewPath,
                      width: double.infinity,
                      height: 150,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: carNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Car number',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCompany,
                      decoration: const InputDecoration(labelText: 'Company'),
                      items: companies.keys
                          .map(
                            (company) => DropdownMenuItem(
                              value: company,
                              child: Text(company),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedCompany = value;
                          selectedModel = companies[value]!.first;
                          modelController.text =
                              '$selectedCompany $selectedModel';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedModel,
                      decoration: const InputDecoration(labelText: 'Model'),
                      items: companies[selectedCompany]!
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedModel = value;
                          modelController.text =
                              '$selectedCompany $selectedModel';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: modelController,
                      decoration: const InputDecoration(
                        labelText: 'Full model number / variant',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fuelController,
                      decoration: const InputDecoration(labelText: 'Fuel type'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (image == null) return;
                        setSheetState(() => selectedImagePath = image.path);
                      },
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        selectedImagePath == null
                            ? 'Use my car picture'
                            : 'Change selected picture',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          controller.addCar(
                            carNumber: carNumberController.text.trim(),
                            model: modelController.text.trim(),
                            fuelType: fuelController.text.trim().isEmpty
                                ? 'Petrol'
                                : fuelController.text.trim(),
                            year: year,
                            imagePath: selectedImagePath,
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save car'),
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
      carNumberController.dispose();
      modelController.dispose();
      fuelController.dispose();
      yearController.dispose();
    });
  }

  void _showQuotationRequestSheet(BuildContext context, CarProfile car) {
    final concernController = TextEditingController();
    final controller = FlywheelsScope.of(context);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request quotation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(car.carNumber, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: concernController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'What do you need checked?',
                  hintText: 'Describe the issue or service request.',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    controller.requestQuotation(
                      car.id,
                      concern: concernController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Send request'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(concernController.dispose);
  }

  Future<void> _showPickupScheduler(
    BuildContext context,
    CarProfile car,
  ) async {
    final controller = FlywheelsScope.of(context);
    final addressController = TextEditingController();
    DateTime pickupTime = DateTime.now().add(const Duration(hours: 3));
    bool locationAccessGranted = false;

    await showModalBottomSheet<void>(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule pickup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a pickup time for ${car.carNumber} and confirm whether the garage can access your location.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pickup time'),
                    subtitle: Text(formatDateTime(pickupTime)),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: pickupTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 60),
                          ),
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(pickupTime),
                        );
                        if (time == null) return;
                        setSheetState(() {
                          pickupTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Pickup address',
                      hintText: 'Flat, street, area, landmark',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: locationAccessGranted,
                    activeThumbColor: AppPalette.red,
                    title: const Text('Allow location access for pickup'),
                    subtitle: const Text(
                      'We will share this consent with the garage for route planning.',
                    ),
                    onChanged: (value) =>
                        setSheetState(() => locationAccessGranted = value),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        controller.requestPickupForCar(
                          car.id,
                          pickupTime: pickupTime,
                          pickupAddress: addressController.text.trim(),
                          locationAccessGranted: locationAccessGranted,
                        );
                        final sent = await WhatsappShareService.share(
                          phone: controller.ownerUser.phone,
                          message: controller.buildPickupWhatsappMessage(
                            car,
                            pickupTime: pickupTime,
                            pickupAddress: addressController.text.trim(),
                            locationAccessGranted: locationAccessGranted,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                sent
                                    ? 'Pickup scheduled and WhatsApp opened.'
                                    : 'Pickup scheduled. WhatsApp could not be opened.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Schedule pickup'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    addressController.dispose();
  }

  Future<void> _showUploadVehicleDocumentSheet(
    BuildContext context,
    CarProfile car,
  ) async {
    final titleController = TextEditingController();
    var type = PersonalDocumentType.rc;
    DateTime? validUntil;

    await showModalBottomSheet<void>(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add vehicle document',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload RC, driving license, insurance, or another file for ${car.carNumber}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PersonalDocumentType>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Document type',
                    ),
                    items: PersonalDocumentType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setSheetState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Document validity'),
                    subtitle: Text(
                      validUntil == null
                          ? 'No validity date selected'
                          : formatShortDate(validUntil!),
                    ),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            validUntil ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 3650),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => validUntil = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Insurance copy, RC back, etc.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'jpg',
                            'jpeg',
                            'png',
                            'webp',
                            'pdf',
                            'doc',
                            'docx',
                          ],
                        );
                        final path = result?.files.single.path;
                        if (path == null || !context.mounted) return;
                        FlywheelsScope.of(context).addCustomerAssetDocument(
                          carId: car.id,
                          type: type,
                          title: titleController.text.trim(),
                          filePath: path,
                          validUntil: validUntil,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Pick document or photo'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    titleController.dispose();
  }

  void _openDocument(BuildContext context, ServiceDocument document) {
    final controller = FlywheelsScope.of(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    if (car == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentPdfViewerPage(document: document, car: car),
      ),
    );
  }

  void _sendChat(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    if (_chatMessageController.text.trim().isEmpty) return;
    controller.sendCustomerMessage(
      topic: _chatTopic,
      message: _chatMessageController.text,
      carId: _chatCarId,
    );
    setState(() => _chatMessageController.clear());
  }

  Future<void> _sendChatPhoto(BuildContext context) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;
    FlywheelsScope.of(context).sendCustomerMessage(
      topic: _chatTopic,
      message: _chatMessageController.text.trim(),
      carId: _chatCarId,
      attachmentPath: image.path,
    );
    setState(() => _chatMessageController.clear());
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final activeCar = controller.activeCar;
    final titles = ['Home', 'Documents', 'Chat', 'Profile'];
    final appBarTitle = _currentIndex == 0
        ? 'Welcome back, ${controller.session!.user.name}'
        : titles[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(appBarTitle)),
          ],
        ),
      ),
      body: Column(
        children: [
          _CustomerCarStrip(
            cars: controller.cars,
            activeCarId: activeCar?.id,
            onSelect: controller.setActiveCar,
            onAddCar: () => _showAddCarSheet(context),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _CustomerHomeTab(
                  activeCar: activeCar,
                  onRequestQuotation: (car) =>
                      _showQuotationRequestSheet(context, car),
                  onRequestImages: (car) => _showGaragePhotoSheet(context, car),
                  onSchedulePickup: (car) => _showPickupScheduler(context, car),
                ),
                _CustomerDocsTab(
                  activeCar: activeCar,
                  onOpenDocument: (document) =>
                      _openDocument(context, document),
                  onUploadVehicleDocument: (car) =>
                      _showUploadVehicleDocumentSheet(context, car),
                ),
                _CustomerChatTab(
                  activeCarId: activeCar?.id,
                  chatMessageController: _chatMessageController,
                  chatTopic: _chatTopic,
                  chatCarId: _chatCarId,
                  onTopicChanged: (value) => setState(() => _chatTopic = value),
                  onCarChanged: (value) => setState(() => _chatCarId = value),
                  onSend: () => _sendChat(context),
                  onSendPhoto: () => _sendChatPhoto(context),
                ),
                _CustomerProfileTab(
                  onAddCar: () => _showAddCarSheet(context),
                  onPickProfilePhoto: _pickProfilePhoto,
                  isPickingProfilePhoto: _pickingProfilePhoto,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          AppBottomNavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
          ),
          AppBottomNavItem(
            label: 'Docs',
            icon: Icons.description_outlined,
            activeIcon: Icons.description_rounded,
          ),
          AppBottomNavItem(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
          ),
          AppBottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class _CustomerCarStrip extends StatefulWidget {
  const _CustomerCarStrip({
    required this.cars,
    required this.activeCarId,
    required this.onSelect,
    required this.onAddCar,
  });

  final List<CarProfile> cars;
  final String? activeCarId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCar;

  @override
  State<_CustomerCarStrip> createState() => _CustomerCarStripState();
}

class _CustomerCarStripState extends State<_CustomerCarStrip> {
  late final PageController _pageController;
  late int _pageIndex;

  int get _pageCount => widget.cars.length + 1;

  @override
  void initState() {
    super.initState();
    _pageIndex = _activeCarIndex();
    _pageController = PageController(
      initialPage: _pageIndex,
      viewportFraction: 0.9,
    );
  }

  @override
  void didUpdateWidget(covariant _CustomerCarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeCarId == oldWidget.activeCarId &&
        widget.cars.length == oldWidget.cars.length) {
      return;
    }

    final nextIndex = _activeCarIndex();
    if (nextIndex == _pageIndex || !_pageController.hasClients) return;
    _pageIndex = nextIndex;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _activeCarIndex() {
    final index = widget.cars.indexWhere((car) => car.id == widget.activeCarId);
    return index == -1 ? 0 : index;
  }

  void _goToPage(int nextIndex) {
    _pageController.animateToPage(
      nextIndex.clamp(0, _pageCount - 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: const BoxDecoration(
        color: AppPalette.white,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('My cars', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _pageIndex == 0
                    ? null
                    : () => _goToPage(_pageIndex - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 118,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    padEnds: false,
                    itemCount: _pageCount,
                    onPageChanged: (index) =>
                        setState(() => _pageIndex = index),
                    itemBuilder: (context, index) {
                      final isAddCard = index == widget.cars.length;
                      return isAddCard
                          ? _AddCarCard(onAddCar: widget.onAddCar)
                          : _CustomerCarCard(
                              car: widget.cars[index],
                              statusLabel:
                                  controller
                                      .latestJobForCar(widget.cars[index].id)
                                      ?.status
                                      .label
                                      .toUpperCase() ??
                                  'READY FOR A QUOTATION REQUEST',
                              isActive:
                                  widget.cars[index].id == widget.activeCarId,
                              onSelect: widget.onSelect,
                            );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _pageIndex == _pageCount - 1
                    ? null
                    : () => _goToPage(_pageIndex + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCarCard extends StatelessWidget {
  const _CustomerCarCard({
    required this.car,
    required this.statusLabel,
    required this.isActive,
    required this.onSelect,
  });

  final CarProfile car;
  final String statusLabel;
  final bool isActive;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppPalette.white : AppPalette.black;

    return GestureDetector(
      onTap: () => onSelect(car.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? AppPalette.red : AppPalette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.red, width: isActive ? 2 : 1.5),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppPalette.red.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.carNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          car.model.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isActive
                                    ? AppPalette.white.withValues(alpha: 0.86)
                                    : AppPalette.black,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          statusLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: isActive
                                    ? AppPalette.white
                                    : AppPalette.red,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImage(
                      path: car.imageUrl,
                      width: 86,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCarCard extends StatelessWidget {
  const _AddCarCard({required this.onAddCar});

  final VoidCallback onAddCar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAddCar,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.red, width: 1.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDDDDD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppPalette.black,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'ADD NEW CAR',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPalette.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerHomeTab extends StatelessWidget {
  const _CustomerHomeTab({
    required this.activeCar,
    required this.onRequestQuotation,
    required this.onRequestImages,
    required this.onSchedulePickup,
  });

  final CarProfile? activeCar;
  final ValueChanged<CarProfile> onRequestQuotation;
  final ValueChanged<CarProfile> onRequestImages;
  final ValueChanged<CarProfile> onSchedulePickup;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final job = activeCar == null
        ? null
        : controller.latestJobForCar(activeCar!.id);
    final photos = activeCar == null
        ? const <GaragePhotoUpdate>[]
        : controller.photoUpdatesForCar(activeCar!.id);

    return ListView(
      key: const PageStorageKey('customer-home'),
      padding: const EdgeInsets.all(20),
      children: [
        if (activeCar == null)
          const _EmptyStateCard(
            title: 'No car selected',
            subtitle:
                'Add a car or choose one above to view status, documents, and updates.',
          ),
        if (activeCar != null) ...[
          if (job != null) ...[
            _CompactTimelineCard(job: job),
            const SizedBox(height: 16),
          ],
          _CarOverviewCard(
            car: activeCar!,
            job: job,
            photoCount: photos.length,
            onRequestPickup: () => onSchedulePickup(activeCar!),
            onRequestQuotation: () => onRequestQuotation(activeCar!),
            onRequestImages: () => onRequestImages(activeCar!),
          ),
          const SizedBox(height: 16),
          _GaragePhotoGalleryCard(
            car: activeCar!,
            updates: photos,
            onRequestImages: () => onRequestImages(activeCar!),
          ),
        ],
      ],
    );
  }
}

class _CustomerDocsTab extends StatelessWidget {
  const _CustomerDocsTab({
    required this.activeCar,
    required this.onOpenDocument,
    required this.onUploadVehicleDocument,
  });

  final CarProfile? activeCar;
  final ValueChanged<ServiceDocument> onOpenDocument;
  final ValueChanged<CarProfile> onUploadVehicleDocument;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    if (activeCar == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: _EmptyStateCard(
          title: 'Choose a car for documents',
          subtitle:
              'Documents, insurance files, and approvals are organized per car.',
        ),
      );
    }

    final documents = controller.documentsForCar(activeCar!.id);
    final assetDocuments = controller.assetDocumentsForCar(activeCar!.id);

    return ListView(
      key: const PageStorageKey('customer-docs'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Text(
              activeCar!.carNumber,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPalette.red),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _VehicleDocumentVaultCard(
          car: activeCar!,
          documents: assetDocuments,
          onUpload: () => onUploadVehicleDocument(activeCar!),
        ),
        const SizedBox(height: 16),
        _ServiceDocumentsByDateCard(
          documents: documents,
          onOpenDocument: onOpenDocument,
        ),
      ],
    );
  }
}

class _CustomerChatTab extends StatelessWidget {
  const _CustomerChatTab({
    required this.activeCarId,
    required this.chatMessageController,
    required this.chatTopic,
    required this.chatCarId,
    required this.onTopicChanged,
    required this.onCarChanged,
    required this.onSend,
    required this.onSendPhoto,
  });

  final String? activeCarId;
  final TextEditingController chatMessageController;
  final String chatTopic;
  final String? chatCarId;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String?> onCarChanged;
  final VoidCallback onSend;
  final VoidCallback onSendPhoto;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final selectedCarId = chatCarId;
    final messages = controller.conversationForUser(
      userId,
      carId: selectedCarId,
    );
    const topics = [
      'General enquiry',
      'Quotation',
      'Service status',
      'Pickup and drop',
      'Photo request',
      'Payments',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                        return _MessageBubble(
                          message: message,
                          carLabel: controller.cars
                              .where((car) => car.id == message.carId)
                              .firstOrNull
                              ?.carNumber,
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              initialValue: chatTopic,
                              onSelected: onTopicChanged,
                              itemBuilder: (context) => topics
                                  .map(
                                    (topic) => PopupMenuItem(
                                      value: topic,
                                      child: Text(topic),
                                    ),
                                  )
                                  .toList(),
                              child: Chip(label: Text(chatTopic)),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String?>(
                              initialValue: chatCarId,
                              onSelected: onCarChanged,
                              itemBuilder: (context) => [
                                const PopupMenuItem<String?>(
                                  value: null,
                                  child: Text('No car selected'),
                                ),
                                ...controller.cars.map(
                                  (car) => PopupMenuItem<String?>(
                                    value: car.id,
                                    child: Text(
                                      '${car.carNumber} - ${car.model}',
                                    ),
                                  ),
                                ),
                              ],
                              child: Chip(
                                label: Text(
                                  chatCarId == null
                                      ? 'No car'
                                      : controller.cars
                                                .where(
                                                  (car) => car.id == chatCarId,
                                                )
                                                .firstOrNull
                                                ?.carNumber ??
                                            'Car',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: onSendPhoto,
                              icon: const Icon(Icons.photo_outlined),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: chatMessageController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Message the garage...',
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

class _CustomerProfileTab extends StatelessWidget {
  const _CustomerProfileTab({
    required this.onAddCar,
    required this.onPickProfilePhoto,
    required this.isPickingProfilePhoto,
  });

  final VoidCallback onAddCar;
  final VoidCallback onPickProfilePhoto;
  final bool isPickingProfilePhoto;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final user = controller.session!.user;

    return ListView(
      key: const PageStorageKey('customer-profile'),
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _ProfileAvatar(
                  imagePath: user.profileImagePath,
                  initials: user.name.isNotEmpty
                      ? user.name.substring(0, 1)
                      : 'F',
                  radius: 32,
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
                        'Role: ${user.role.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: isPickingProfilePhoto ? null : onPickProfilePhoto,
                  child: Text(
                    isPickingProfilePhoto ? 'Loading...' : 'Upload photo',
                  ),
                ),
              ],
            ),
          ),
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
                'Alert history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                'Open to view all service and billing alerts.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                ...controller.notifications.map(
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: controller.logout,
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }
}

class _CarOverviewCard extends StatelessWidget {
  const _CarOverviewCard({
    required this.car,
    required this.job,
    required this.photoCount,
    required this.onRequestPickup,
    required this.onRequestQuotation,
    required this.onRequestImages,
  });

  final CarProfile car;
  final ServiceJob? job;
  final int photoCount;
  final VoidCallback onRequestPickup;
  final VoidCallback onRequestQuotation;
  final VoidCallback onRequestImages;

  @override
  Widget build(BuildContext context) {
    final currentStatus = job?.status.label;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected car overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppImage(
                  path: car.imageUrl,
                  width: 100,
                  height: 82,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.carNumber,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('${car.model} | ${car.fuelType} | ${car.year}'),
                      const SizedBox(height: 4),
                      Text(
                        currentStatus == null
                            ? 'Ready for new service'
                            : 'Current status: $currentStatus',
                      ),
                      const SizedBox(height: 4),
                      Text('$photoCount garage photo updates available'),
                      if (job?.pickupAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Pickup address: ${job!.pickupAddress}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: onRequestQuotation,
                  child: const Text('Request quotation'),
                ),
                OutlinedButton(
                  onPressed: onRequestPickup,
                  child: const Text('Schedule pickup'),
                ),
                OutlinedButton(
                  onPressed: onRequestImages,
                  child: const Text('Ask for images'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTimelineCard extends StatelessWidget {
  const _CompactTimelineCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    const statuses = JobStatus.values;
    final activeIndex = statuses.indexOf(job.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live service status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final isReached = index <= activeIndex;
                final isActive = index == activeIndex;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          isReached
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isReached ? AppPalette.red : AppPalette.muted,
                          size: 22,
                        ),
                        if (index != statuses.length - 1)
                          Container(
                            width: 2,
                            height: 34,
                            color: isReached
                                ? AppPalette.red
                                : AppPalette.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          status.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isActive
                                    ? AppPalette.red
                                    : AppPalette.black,
                                fontWeight: isReached
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontStyle: isReached
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text(
                  'Expected completion: ${formatDateTime(job.expectedCompletion)}',
                ),
                Text('Pickup time: ${formatDateTime(job.pickupTime)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaragePhotoGalleryCard extends StatelessWidget {
  const _GaragePhotoGalleryCard({
    required this.car,
    required this.updates,
    required this.onRequestImages,
  });

  final CarProfile car;
  final List<GaragePhotoUpdate> updates;
  final VoidCallback onRequestImages;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Garage photo updates',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton(
                  onPressed: onRequestImages,
                  child: const Text('Request more'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Latest photos shared for ${car.carNumber}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (updates.isEmpty)
              Text(
                'The garage has not shared any images yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...updates
                .take(3)
                .map(
                  (update) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.soft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        AppImage(
                          path: update.imagePath,
                          width: 92,
                          height: 72,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update.caption,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatDateTime(update.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }
}

class _VehicleDocumentVaultCard extends StatelessWidget {
  const _VehicleDocumentVaultCard({
    required this.car,
    required this.documents,
    required this.onUpload,
  });

  final CarProfile car;
  final List<CustomerAssetDocument> documents;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vehicle document vault',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton(
                  onPressed: onUpload,
                  child: const Text('Add document'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Store RC, driving license, insurance, and related files for ${car.carNumber}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PersonalDocumentType.values
                  .map((type) => Chip(label: Text(type.label)))
                  .toList(),
            ),
            const SizedBox(height: 14),
            if (documents.isEmpty)
              Text(
                'No personal vehicle documents uploaded yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...documents.map(
              (document) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.soft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    AppImage(
                      path: document.filePath,
                      width: 76,
                      height: 60,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${document.type.label} | Uploaded ${formatShortDate(document.uploadedAt)}'
                            '${document.validUntil == null ? '' : ' | Valid till ${formatShortDate(document.validUntil!)}'}',
                            style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }
}

class _ServiceDocumentsByDateCard extends StatelessWidget {
  const _ServiceDocumentsByDateCard({
    required this.documents,
    required this.onOpenDocument,
  });

  final List<ServiceDocument> documents;
  final ValueChanged<ServiceDocument> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<ServiceDocument>>{};
    for (final document in documents) {
      final key = formatShortDate(document.updatedAt);
      groups.putIfAbsent(key, () => []).add(document);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service documents by date',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Newest quotations, estimates, invoices, and job cards appear first.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (documents.isEmpty)
              Text(
                'No service documents shared for this car yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...groups.entries.map((entry) {
              final docs = entry.value
                ..sort(
                  (left, right) => right.updatedAt.compareTo(left.updatedAt),
                );
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    ...docs.map(
                      (document) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                                    document.type.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                Text(
                                  formatDateTime(document.updatedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${document.title} | ${formatCurrency(document.total)} | ${document.approvalState.name}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => onOpenDocument(document),
                                    child: const Text('Open'),
                                  ),
                                ),
                                if (document.type != DocumentType.invoice &&
                                    document.type != DocumentType.jobCard &&
                                    document.approvalState ==
                                        ApprovalState.pending) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          FlywheelsScope.of(
                                            context,
                                          ).decideDocument(
                                            document.id,
                                            ApprovalState.approved,
                                          ),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.carLabel});

  final SupportMessage message;
  final String? carLabel;

  @override
  Widget build(BuildContext context) {
    final isOwner = message.sentByOwner;
    return Align(
      alignment: isOwner ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: isOwner ? AppPalette.white : AppPalette.red,
          border: isOwner ? Border.all(color: AppPalette.border) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carLabel == null ? message.topic : '${message.topic} | $carLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOwner ? AppPalette.black : AppPalette.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isOwner ? AppPalette.black : AppPalette.white,
              ),
            ),
            if (message.attachmentPath != null) ...[
              const SizedBox(height: 8),
              AppImage(
                path: message.attachmentPath!,
                width: 260,
                height: 150,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              formatDateTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOwner
                    ? AppPalette.muted
                    : AppPalette.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imagePath,
    required this.initials,
    required this.radius,
  });

  final String? imagePath;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppPalette.soft,
        child: Text(initials, style: Theme.of(context).textTheme.titleLarge),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.border),
      ),
      child: ClipOval(child: AppImage(path: imagePath!)),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

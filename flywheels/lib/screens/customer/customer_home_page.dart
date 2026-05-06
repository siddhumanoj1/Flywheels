import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/shared/document_pdf_viewer_page.dart';
import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/services/whatsapp_share_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
    FlywheelsScope.read(context).updateProfilePhoto(image.path);
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
                    FlywheelsScope.read(context).requestGaragePhotos(
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
    final controller = FlywheelsScope.read(context);
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
    final controller = FlywheelsScope.read(context);
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

  Future<String?> _showGoogleMapsLocationPicker(
    BuildContext context,
    CarProfile car,
  ) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick pickup location'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppPalette.soft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _MapPickerGridPainter()),
                    ),
                    const Center(
                      child: Icon(
                        Icons.location_pin,
                        color: AppPalette.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use the map pin for ${car.carNumber}, or continue with manual address entry.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Manual entry'),
          ),
          OutlinedButton(
            onPressed: () async {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=current%20location',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Open Google Maps'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop('Google Maps pin selected near current location'),
            child: const Text('Use pin'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPickupScheduler(
    BuildContext context,
    CarProfile car,
  ) async {
    final controller = FlywheelsScope.read(context);
    final addressController = TextEditingController();
    DateTime pickupTime = DateTime.now().add(const Duration(hours: 3));
    bool locationAccessGranted = false;
    bool mapsLocationSelected = false;

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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final selectedAddress =
                                await _showGoogleMapsLocationPicker(
                                  context,
                                  car,
                                );
                            if (selectedAddress == null) return;
                            if (!context.mounted) return;
                            setSheetState(() {
                              mapsLocationSelected = true;
                              locationAccessGranted = true;
                              addressController.text = selectedAddress;
                            });
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Google Maps picker'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              mapsLocationSelected = false;
                              if (addressController.text.startsWith(
                                'Google Maps pin selected',
                              )) {
                                addressController.clear();
                              }
                            });
                          },
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          label: const Text('Manual entry'),
                        ),
                      ),
                    ],
                  ),
                  if (mapsLocationSelected) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Maps pin selected. You can still edit the address below.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                        FlywheelsScope.read(context).addCustomerAssetDocument(
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
    final controller = FlywheelsScope.read(context);
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

  Future<void> _downloadDocumentPdf(ServiceDocument document) async {
    final controller = FlywheelsScope.read(context);
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

  Future<void> _shareDocumentOnWhatsapp(ServiceDocument document) async {
    final controller = FlywheelsScope.read(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    final export = await DocumentPdfExportService.exportDocument(
      document: document,
      car: car,
      customer: customer,
    );
    final message = controller.buildDocumentWhatsappMessage(document);
    final sent = await WhatsappShareService.sharePdf(
      filePath: export.filePath,
      fileName: export.fileName,
      message: message,
    );
    if (!mounted) return;
    _showMessage(
      sent
          ? 'PDF ready for WhatsApp sharing.'
          : 'PDF saved. WhatsApp share sheet could not be opened.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectTab(int index) {
    final controller = FlywheelsScope.read(context);
    if (index == 2) {
      controller.markConversationReadByCustomer(controller.session!.user.id);
    }
    setState(() => _currentIndex = index);
  }

  void _showCarHistorySheet(BuildContext context, CarProfile car) {
    final controller = FlywheelsScope.read(context);
    final history = controller.jobsForCar(car.id);
    final documents = controller.documentsForCar(car.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.76,
              child: ListView(
                children: [
                  Row(
                    children: [
                      AppImage(
                        path: car.imageUrl,
                        width: 84,
                        height: 62,
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
                            Text(
                              '${car.model} | ${car.fuelType} | ${car.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Car history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    Text(
                      'No service history yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ...history.map(
                    (job) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timeline_rounded),
                      title: Text(job.status.label),
                      subtitle: Text(
                        'ETA ${formatDateTime(job.expectedCompletion)} | Pickup ${job.pickupState.label}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Past bills',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (documents.isEmpty)
                    Text(
                      'No bills or service documents yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ...documents.map(
                    (document) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(document.title),
                      subtitle: Text(
                        '${document.type.label} | ${formatCurrency(document.total)} | ${document.paymentState.name}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'open') {
                            Navigator.of(context).pop();
                            _openDocument(context, document);
                          } else if (value == 'download') {
                            _downloadDocumentPdf(document);
                          } else if (value == 'whatsapp') {
                            _shareDocumentOnWhatsapp(document);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'open', child: Text('Open PDF')),
                          PopupMenuItem(
                            value: 'download',
                            child: Text('Download PDF'),
                          ),
                          PopupMenuItem(
                            value: 'whatsapp',
                            child: Text('Share WhatsApp'),
                          ),
                        ],
                      ),
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

  void _sendChat(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    if (_chatMessageController.text.trim().isEmpty) return;
    controller.sendCustomerMessage(
      topic: _chatTopic,
      message: _chatMessageController.text,
      carId: _chatCarId,
    );
    setState(() => _chatMessageController.clear());
  }

  void _insertQuickMessage(String message) {
    setState(() {
      _chatMessageController.text = message;
      _chatMessageController.selection = TextSelection.collapsed(
        offset: _chatMessageController.text.length,
      );
    });
  }

  Future<void> _sendChatPhoto(BuildContext context) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;
    FlywheelsScope.read(context).sendCustomerMessage(
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
    final showCarStrip = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: _currentIndex == 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          controller.session?.user.name.toUpperCase() ?? 'CUSTOMER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    )
                  : Text(titles[_currentIndex]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (showCarStrip)
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
                  onOpenChat: () => _selectTab(2),
                  onOpenHistory: (car) => _showCarHistorySheet(context, car),
                  onOpenBills: () => _selectTab(1),
                ),
                _CustomerDocsTab(
                  activeCar: activeCar,
                  onOpenDocument: (document) =>
                      _openDocument(context, document),
                  onDownloadDocument: _downloadDocumentPdf,
                  onShareDocument: _shareDocumentOnWhatsapp,
                  onUploadVehicleDocument: (car) =>
                      _showUploadVehicleDocumentSheet(context, car),
                ),
                _CustomerChatTab(
                  chatMessageController: _chatMessageController,
                  chatTopic: _chatTopic,
                  chatCarId: _chatCarId,
                  onTopicChanged: (value) => setState(() => _chatTopic = value),
                  onCarChanged: (value) => setState(() => _chatCarId = value),
                  onQuickMessage: _insertQuickMessage,
                  onSend: () => _sendChat(context),
                  onSendPhoto: () => _sendChatPhoto(context),
                ),
                _CustomerProfileTab(
                  onAddCar: () => _showAddCarSheet(context),
                  onOpenCar: (car) => _showCarHistorySheet(context, car),
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
        onTap: _selectTab,
        badgeCounts: [
          0,
          0,
          controller.unreadMessageCountForCurrentSession(),
          0,
        ],
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

class _MapPickerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppPalette.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final minorRoadPaint = Paint()
      ..color = AppPalette.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var x = size.width * 0.16; x < size.width; x += size.width * 0.22) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 18, size.height),
        minorRoadPaint,
      );
    }
    for (var y = size.height * 0.18; y < size.height; y += size.height * 0.24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), minorRoadPaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.76),
      Offset(size.width * 0.92, size.height * 0.22),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.12),
      Offset(size.width * 0.76, size.height * 0.86),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPickerGridPainter oldDelegate) => false;
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
      viewportFraction: 1,
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: const BoxDecoration(
        color: AppPalette.white,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('My cars', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _pageIndex == 0
                    ? null
                    : () => _goToPage(_pageIndex - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 96,
                  child: PageView.builder(
                    controller: _pageController,
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
              IconButton.outlined(
                onPressed: _pageIndex == _pageCount - 1
                    ? null
                    : () => _goToPage(_pageIndex + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          if (widget.cars.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPageDots(),
          ],
        ],
      ),
    );
  }

  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final isActiveLine = index == _pageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActiveLine ? 24 : 16,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            color: isActiveLine ? AppPalette.red : AppPalette.border,
          ),
        );
      }),
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isActive ? AppPalette.black : AppPalette.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppPalette.black : AppPalette.border,
            width: 1.2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppPalette.red.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppPalette.red,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      path: car.imageUrl,
                      width: 78,
                      height: 58,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.border, width: 1.2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppPalette.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
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
    required this.onOpenChat,
    required this.onOpenHistory,
    required this.onOpenBills,
  });

  final CarProfile? activeCar;
  final ValueChanged<CarProfile> onRequestQuotation;
  final ValueChanged<CarProfile> onRequestImages;
  final ValueChanged<CarProfile> onSchedulePickup;
  final VoidCallback onOpenChat;
  final ValueChanged<CarProfile> onOpenHistory;
  final VoidCallback onOpenBills;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final job = activeCar == null
        ? null
        : controller.latestJobForCar(activeCar!.id);

    return ListView(
      key: const PageStorageKey('customer-home'),
      padding: const EdgeInsets.all(16),
      children: [
        if (activeCar == null)
          const _EmptyStateCard(
            title: 'No car selected',
            subtitle: 'Add a car or choose one above to view its timeline.',
          ),
        if (activeCar != null) ...[
          if (job != null) _CompactTimelineCard(job: job),
          if (job == null)
            _EmptyStateCard(
              title: activeCar!.carNumber,
              subtitle: 'No active service timeline yet.',
            ),
          const SizedBox(height: 12),
          GearboxActionGrid(
            children: [
              AutomotiveControlButton(
                icon: Icons.receipt_long_outlined,
                label: 'Quote',
                active: true,
                onPressed: () => onRequestQuotation(activeCar!),
              ),
              AutomotiveControlButton(
                icon: Icons.local_shipping_outlined,
                label: 'Pickup',
                onPressed: () => onSchedulePickup(activeCar!),
              ),
              AutomotiveControlButton(
                icon: Icons.photo_camera_outlined,
                label: 'Images',
                onPressed: () => onRequestImages(activeCar!),
              ),
              AutomotiveControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                onPressed: onOpenChat,
              ),
              AutomotiveControlButton(
                icon: Icons.history_rounded,
                label: 'History',
                onPressed: () => onOpenHistory(activeCar!),
              ),
              AutomotiveControlButton(
                icon: Icons.receipt_long_rounded,
                label: 'Bills',
                onPressed: onOpenBills,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CustomerDocsTab extends StatefulWidget {
  const _CustomerDocsTab({
    required this.activeCar,
    required this.onOpenDocument,
    required this.onDownloadDocument,
    required this.onShareDocument,
    required this.onUploadVehicleDocument,
  });

  final CarProfile? activeCar;
  final ValueChanged<ServiceDocument> onOpenDocument;
  final ValueChanged<ServiceDocument> onDownloadDocument;
  final ValueChanged<ServiceDocument> onShareDocument;
  final ValueChanged<CarProfile> onUploadVehicleDocument;

  @override
  State<_CustomerDocsTab> createState() => _CustomerDocsTabState();
}

class _CustomerDocsTabState extends State<_CustomerDocsTab> {
  bool _showLibrary = false;
  String _query = '';
  DocumentType? _filterType;
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final activeCar = widget.activeCar;
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

    final documents = controller.documentsForCar(activeCar.id);
    final assetDocuments = controller.assetDocumentsForCar(activeCar.id);
    final needle = _query.trim().toLowerCase();
    final libraryDocuments =
        documents.where((document) {
          final carText =
              '${document.title} ${document.type.label} '
              '${document.approvalState.name} ${document.paymentState.name}';
          final matchesQuery =
              needle.isEmpty || carText.toLowerCase().contains(needle);
          final matchesFilter =
              _filterType == null || document.type == _filterType;
          return matchesQuery && matchesFilter;
        }).toList()..sort(
          (left, right) => _newestFirst
              ? right.updatedAt.compareTo(left.updatedAt)
              : left.updatedAt.compareTo(right.updatedAt),
        );

    return ListView(
      key: const PageStorageKey('customer-docs'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${activeCar.carNumber} Documents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.edit_document),
              label: Text('Document Studio'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.library_books_outlined),
              label: Text('Document Library'),
            ),
          ],
          selected: {_showLibrary},
          onSelectionChanged: (selection) =>
              setState(() => _showLibrary = selection.first),
        ),
        const SizedBox(height: 16),
        if (!_showLibrary) ...[
          _VehicleDocumentVaultCard(
            car: activeCar,
            documents: assetDocuments,
            onUpload: () => widget.onUploadVehicleDocument(activeCar),
          ),
          const SizedBox(height: 16),
          _EmptyStateCard(
            title: 'Create and upload',
            subtitle:
                'Use the studio for RC, insurance, PUC, and driving-license records. Service bills and PDFs live in Document Library.',
          ),
        ] else ...[
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search bills, estimates, invoices',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DocumentType?>(
                  initialValue: _filterType,
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
                  onChanged: (value) => setState(() => _filterType = value),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: _newestFirst ? 'Newest first' : 'Oldest first',
                onPressed: () => setState(() => _newestFirst = !_newestFirst),
                icon: Icon(
                  _newestFirst ? Icons.south_rounded : Icons.north_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (libraryDocuments.isEmpty)
            const _EmptyStateCard(
              title: 'No records found',
              subtitle: 'Try another search, filter, or car.',
            ),
          ...libraryDocuments.map(
            (document) => _CustomerDocumentLibraryTile(
              document: document,
              onOpen: () => widget.onOpenDocument(document),
              onDownload: () => widget.onDownloadDocument(document),
              onShare: () => widget.onShareDocument(document),
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomerDocumentLibraryTile extends StatelessWidget {
  const _CustomerDocumentLibraryTile({
    required this.document,
    required this.onOpen,
    required this.onDownload,
    required this.onShare,
  });

  final ServiceDocument document;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(
                document.type == DocumentType.invoice
                    ? Icons.receipt_long_rounded
                    : Icons.description_outlined,
                color: AppPalette.black,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                formatShortDate(document.updatedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${document.type.label} | ${formatCurrency(document.total)} | ${document.approvalState.name}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Open'),
              ),
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: const Text('PDF'),
              ),
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: const Text('WhatsApp'),
              ),
              if (document.type != DocumentType.invoice &&
                  document.type != DocumentType.jobCard &&
                  document.approvalState == ApprovalState.pending)
                FilledButton.icon(
                  onPressed: () => FlywheelsScope.of(
                    context,
                  ).decideDocument(document.id, ApprovalState.approved),
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Approve'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerChatTab extends StatelessWidget {
  const _CustomerChatTab({
    required this.chatMessageController,
    required this.chatTopic,
    required this.chatCarId,
    required this.onTopicChanged,
    required this.onCarChanged,
    required this.onQuickMessage,
    required this.onSend,
    required this.onSendPhoto,
  });

  final TextEditingController chatMessageController;
  final String chatTopic;
  final String? chatCarId;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String?> onCarChanged;
  final ValueChanged<String> onQuickMessage;
  final VoidCallback onSend;
  final VoidCallback onSendPhoto;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final user = controller.session!.user;
    final owner = controller.ownerUser;
    final messages = controller.conversationForUser(userId);
    const topics = [
      'General enquiry',
      'Car related query',
      'Payment query',
      'Quote approval',
      'Pickup',
    ];
    const quickTemplates = [
      (
        label: 'Approve quote',
        message:
            'Quote approval: I have reviewed the quotation and approve the recommended work.',
      ),
      (
        label: 'Need bill PDF',
        message:
            'Please share the latest bill PDF here and on WhatsApp for my records.',
      ),
      (
        label: 'Pickup reminder',
        message:
            'Pickup reminder: please confirm the pickup slot and driver details.',
      ),
      (
        label: 'Service complete?',
        message:
            'Is the service completed? Please share the final status and delivery timing.',
      ),
      (
        label: 'Payment update',
        message:
            'Payment update: I will complete the pending payment and share confirmation shortly.',
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics
                .map(
                  (topic) => ChoiceChip(
                    label: Text(topic),
                    selected: chatTopic == topic,
                    onSelected: (_) => onTopicChanged(topic),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return MessengerBubble(
                message: message,
                fromCurrentUser: !message.sentByOwner,
                avatarPath: message.sentByOwner
                    ? owner.profileImagePath
                    : user.profileImagePath,
                avatarInitials: message.sentByOwner
                    ? owner.name.substring(0, 1)
                    : user.name.substring(0, 1),
                carLabel: controller.cars
                    .where((car) => car.id == message.carId)
                    .firstOrNull
                    ?.carNumber,
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
                IconButton.outlined(
                  onPressed: onSendPhoto,
                  icon: const Icon(Icons.photo_outlined),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  initialValue: chatCarId,
                  tooltip: 'Select car',
                  onSelected: onCarChanged,
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All cars'),
                    ),
                    ...controller.cars.map(
                      (car) => PopupMenuItem<String?>(
                        value: car.id,
                        child: Text('${car.carNumber} - ${car.model}'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.directions_car_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: chatMessageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: chatCarId == null
                          ? 'Message the garage...'
                          : 'Message about selected car...',
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

class _CustomerProfileTab extends StatelessWidget {
  const _CustomerProfileTab({
    required this.onAddCar,
    required this.onOpenCar,
    required this.onPickProfilePhoto,
    required this.isPickingProfilePhoto,
  });

  final VoidCallback onAddCar;
  final ValueChanged<CarProfile> onOpenCar;
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cars',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: onAddCar,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...controller.cars.map(
                  (car) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () => onOpenCar(car),
                    leading: AppImage(
                      path: car.imageUrl,
                      width: 54,
                      height: 42,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(car.carNumber),
                    subtitle: Text(car.model),
                  ),
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

class _CompactTimelineCard extends StatelessWidget {
  const _CompactTimelineCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    const statuses = JobStatus.values;
    final activeIndex = statuses.indexOf(job.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LedIndicator(active: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live service status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  job.status.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppPalette.red,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            HorizontalServiceTimeline(status: statuses[activeIndex]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                Text(
                  'ETA ${formatDateTime(job.expectedCompletion)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Pickup ${formatDateTime(job.pickupTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vehicle documents',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (documents.isEmpty)
              Text(
                'No personal vehicle documents uploaded yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...documents.map(
              (document) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    AppImage(
                      path: document.filePath,
                      width: 64,
                      height: 52,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: Theme.of(context).textTheme.titleMedium,
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

import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/shared/document_pdf_viewer_page.dart';
import 'package:flywheels/screens/shared/wheels_marketplace_tab.dart';
import 'package:flywheels/services/document_pdf_export_service.dart';
import 'package:flywheels/services/google_maps_link_service.dart';
import 'package:flywheels/services/whatsapp_share_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/app_inner_tabs.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/car_status_tracker.dart';
import 'package:flywheels/widgets/customer_car_details_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const _defaultPickupLatitude = 17.448294;
const _defaultPickupLongitude = 78.391487;

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _picker = ImagePicker();
  final _chatMessageController = TextEditingController();
  late final PageController _pageController;
  int _currentIndex = 0;
  int _homeTrackerReplayToken = 0;
  ChatChannel _customerChatChannel = ChatChannel.general;
  bool _pickingProfilePhoto = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    String? selectedImagePath;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add a car',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                CustomerCarDetailsFields(
                  picker: _picker,
                  carNumberController: carNumberController,
                  modelController: modelController,
                  fuelController: fuelController,
                  yearController: yearController,
                  onImagePathChanged: (path) => selectedImagePath = path,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final year =
                          int.tryParse(yearController.text.trim()) ??
                          DateTime.now().year;
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

  Future<_PickupLocationDraft?> _showGoogleMapsLocationPicker(
    BuildContext context,
    CarProfile car,
    _PickupLocationDraft? initialLocation,
  ) async {
    var latitude = initialLocation?.latitude ?? _defaultPickupLatitude;
    var longitude = initialLocation?.longitude ?? _defaultPickupLongitude;
    var locating = false;
    String? errorText;
    final latitudeController = TextEditingController(
      text: initialLocation?.latitude == null
          ? ''
          : initialLocation!.latitude!.toStringAsFixed(6),
    );
    final longitudeController = TextEditingController(
      text: initialLocation?.longitude == null
          ? ''
          : initialLocation!.longitude!.toStringAsFixed(6),
    );

    void syncCoordinateFields() {
      latitudeController.text = latitude.toStringAsFixed(6);
      longitudeController.text = longitude.toStringAsFixed(6);
    }

    final result = await showModalBottomSheet<_PickupLocationDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> useCurrentLocation() async {
              setSheetState(() {
                locating = true;
                errorText = null;
              });
              try {
                final serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  throw const _PickupLocationException(
                    'Location services are off.',
                  );
                }

                var permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  throw const _PickupLocationException(
                    'Location permission was not granted.',
                  );
                }

                final position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                );
                if (!context.mounted) return;
                setSheetState(() {
                  latitude = position.latitude;
                  longitude = position.longitude;
                  locating = false;
                  syncCoordinateFields();
                });
              } on _PickupLocationException catch (error) {
                if (!context.mounted) return;
                setSheetState(() {
                  locating = false;
                  errorText = error.message;
                });
              } catch (_) {
                if (!context.mounted) return;
                setSheetState(() {
                  locating = false;
                  errorText = 'Could not read the current location.';
                });
              }
            }

            void applyManualCoordinates() {
              final parsedLatitude = double.tryParse(
                latitudeController.text.trim(),
              );
              final parsedLongitude = double.tryParse(
                longitudeController.text.trim(),
              );
              if (parsedLatitude == null ||
                  parsedLongitude == null ||
                  parsedLatitude < -90 ||
                  parsedLatitude > 90 ||
                  parsedLongitude < -180 ||
                  parsedLongitude > 180) {
                setSheetState(() {
                  errorText = 'Enter valid latitude and longitude values.';
                });
                return;
              }
              setSheetState(() {
                latitude = parsedLatitude;
                longitude = parsedLongitude;
                errorText = null;
              });
            }

            final mapUrl = GoogleMapsLinkService.mapUrlForCoordinates(
              latitude: latitude,
              longitude: longitude,
            );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle location',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  car.carNumber,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PickupMapPreview(
                        latitude: latitude,
                        longitude: longitude,
                        interactive: true,
                        onTap: (position) {
                          setSheetState(() {
                            latitude = position.latitude;
                            longitude = position.longitude;
                            errorText = null;
                            syncCoordinateFields();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: locating ? null : useCurrentLocation,
                              icon: Icon(
                                locating
                                    ? Icons.hourglass_top_rounded
                                    : Icons.my_location_rounded,
                              ),
                              label: Text(
                                locating ? 'Locating' : 'Use current',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(mapUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Open Maps'),
                            ),
                          ),
                        ],
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppPalette.red),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: applyManualCoordinates,
                        icon: const Icon(Icons.pin_drop_outlined),
                        label: const Text('Apply coordinates'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _PickupLocationDraft(
                                latitude: latitude,
                                longitude: longitude,
                                mapUrl: mapUrl,
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Use this location'),
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
    latitudeController.dispose();
    longitudeController.dispose();
    return result;
  }

  Future<void> _showPickupScheduler(
    BuildContext context,
    CarProfile car,
  ) async {
    final controller = FlywheelsScope.read(context);
    final addressController = TextEditingController();
    final existingJob = controller.latestJobForCar(car.id);
    final schedulingDelivery =
        existingJob?.status == JobStatus.completed ||
        existingJob?.status == JobStatus.deliveryScheduled;
    final tripLabel = schedulingDelivery ? 'delivery' : 'pickup';
    final tripTitle = existingJob?.pickupRequired == true
        ? 'Reschedule $tripLabel'
        : 'Schedule $tripLabel';
    DateTime pickupTime =
        existingJob?.pickupTime ?? DateTime.now().add(const Duration(hours: 3));
    bool locationAccessGranted = existingJob?.locationAccessGranted ?? false;
    var selectedLocation =
        existingJob?.hasPickupCoordinates == true ||
            existingJob?.pickupMapUrl?.trim().isNotEmpty == true
        ? _PickupLocationDraft(
            latitude: existingJob?.pickupLatitude,
            longitude: existingJob?.pickupLongitude,
            mapUrl: existingJob?.pickupMapUrl,
          )
        : null;
    String? pickupPhotoPath = existingJob?.pickupPhotoPath;
    addressController.text = existingJob?.pickupAddress ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickVehiclePhoto(ImageSource source) async {
              final image = await _picker.pickImage(
                source: source,
                imageQuality: 85,
              );
              if (image == null || !context.mounted) return;
              setSheetState(() => pickupPhotoPath = image.path);
            }

            Future<void> pickDate() async {
              final date = await showDatePicker(
                context: context,
                initialDate: pickupTime,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (date == null || !context.mounted) return;
              setSheetState(() {
                pickupTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  pickupTime.hour,
                  pickupTime.minute,
                );
              });
            }

            Future<void> pickTime() async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(pickupTime),
              );
              if (time == null || !context.mounted) return;
              setSheetState(() {
                pickupTime = DateTime(
                  pickupTime.year,
                  pickupTime.month,
                  pickupTime.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            void applySlot(int hour, int minute) {
              final now = DateTime.now();
              var slot = DateTime(
                pickupTime.year,
                pickupTime.month,
                pickupTime.day,
                hour,
                minute,
              );
              if (slot.isBefore(now.add(const Duration(minutes: 30)))) {
                slot = slot.add(const Duration(days: 1));
              }
              setSheetState(() => pickupTime = slot);
            }

            Future<void> pickMapLocation() async {
              final location = await _showGoogleMapsLocationPicker(
                context,
                car,
                selectedLocation,
              );
              if (location == null || !context.mounted) return;
              setSheetState(() {
                selectedLocation = location;
                locationAccessGranted = true;
              });
            }

            Future<void> openMaps() async {
              final location = selectedLocation;
              Uri? uri;
              if (location?.hasCoordinates == true) {
                uri = GoogleMapsLinkService.mapUriForCoordinates(
                  latitude: location!.latitude!,
                  longitude: location.longitude!,
                );
              } else if (addressController.text.trim().isNotEmpty) {
                uri = GoogleMapsLinkService.mapUriForAddress(
                  addressController.text.trim(),
                );
              }
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tripTitle,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${car.carNumber} | ${car.model}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PickupVehiclePhotoSection(
                        car: car,
                        photoPath: pickupPhotoPath,
                        onCamera: () => pickVehiclePhoto(ImageSource.camera),
                        onGallery: () => pickVehiclePhoto(ImageSource.gallery),
                        onRemove: pickupPhotoPath == null
                            ? null
                            : () => setSheetState(() => pickupPhotoPath = null),
                      ),
                      const SizedBox(height: 12),
                      _PickupScheduleSection(
                        pickupTime: pickupTime,
                        onPickDate: pickDate,
                        onPickTime: pickTime,
                        onSlotSelected: applySlot,
                      ),
                      const SizedBox(height: 12),
                      _PickupLocationSection(
                        addressController: addressController,
                        location: selectedLocation,
                        locationAccessGranted: locationAccessGranted,
                        onLocationAccessChanged: (value) =>
                            setSheetState(() => locationAccessGranted = value),
                        onPickMap: pickMapLocation,
                        onOpenMaps: openMaps,
                        onClearMap: selectedLocation == null
                            ? null
                            : () => setSheetState(() {
                                selectedLocation = null;
                                locationAccessGranted = false;
                              }),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final mapUrl = selectedLocation?.mapUrl;
                            controller.requestPickupForCar(
                              car.id,
                              pickupTime: pickupTime,
                              pickupAddress: addressController.text.trim(),
                              pickupLatitude: selectedLocation?.latitude,
                              pickupLongitude: selectedLocation?.longitude,
                              pickupMapUrl: mapUrl,
                              pickupPhotoPath: pickupPhotoPath,
                              locationAccessGranted: locationAccessGranted,
                            );
                            final sent = await WhatsappShareService.share(
                              phone: controller.ownerUser.phone,
                              message: controller.buildPickupWhatsappMessage(
                                car,
                                pickupTime: pickupTime,
                                pickupAddress: addressController.text.trim(),
                                pickupLatitude: selectedLocation?.latitude,
                                pickupLongitude: selectedLocation?.longitude,
                                pickupMapUrl: mapUrl,
                                pickupPhotoPath: pickupPhotoPath,
                                locationAccessGranted: locationAccessGranted,
                              ),
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sent
                                        ? '${_sentenceCase(tripLabel)} scheduled and WhatsApp opened.'
                                        : '${_sentenceCase(tripLabel)} scheduled. WhatsApp could not be opened.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: Text(tripTitle),
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

  Future<void> _shareDocumentOnWhatsapp(ServiceDocument document) async {
    final controller = FlywheelsScope.read(context);
    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    _showMessage('Preparing PDF for sharing...');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
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
            ? 'PDF ready for sharing.'
            : 'PDF saved. Share sheet could not be opened.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('PDF share failed: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectTab(int index) {
    if (index < 0 || index > 4) return;
    final controller = FlywheelsScope.read(context);
    if (index == 3) {
      controller.markConversationReadByCustomer(controller.session!.user.id);
    }
    setState(() {
      _currentIndex = index;
      if (index == 0) _homeTrackerReplayToken += 1;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openBuyingChat() {
    if (_customerChatChannel != ChatChannel.buying) {
      setState(() => _customerChatChannel = ChatChannel.buying);
    }
    _selectTab(3);
  }

  void _handleParentPageChanged(int index) {
    final controller = FlywheelsScope.read(context);
    if (index == 3) {
      controller.markConversationReadByCustomer(controller.session!.user.id);
    }
    setState(() {
      _currentIndex = index;
      if (index == 0) _homeTrackerReplayToken += 1;
    });
  }

  void _selectActiveCar(String carId) {
    FlywheelsScope.read(context).setActiveCar(carId);
    if (_currentIndex == 0) {
      setState(() => _homeTrackerReplayToken += 1);
    }
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
      topic: 'General enquiry',
      message: _chatMessageController.text,
      channel: _customerChatChannel,
      carId: controller.activeCar?.id,
    );
    setState(() => _chatMessageController.clear());
  }

  Future<void> _sendChatPhoto(BuildContext context) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;
    final controller = FlywheelsScope.read(context);
    controller.sendCustomerMessage(
      topic: 'Photo',
      message: _chatMessageController.text.trim(),
      channel: _customerChatChannel,
      carId: controller.activeCar?.id,
      attachmentPath: image.path,
    );
    setState(() => _chatMessageController.clear());
  }

  Future<void> _sendChatDocument(BuildContext context) async {
    final controller = FlywheelsScope.read(context);
    final documents = controller.documents.toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    if (documents.isEmpty) {
      _showMessage('No documents available in Document Library.');
      return;
    }

    final document = await showModalBottomSheet<ServiceDocument>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: documents.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final document = documents[index];
              final car = controller.cars
                  .where((item) => item.id == document.carId)
                  .firstOrNull;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(document.title),
                subtitle: Text(
                  car == null
                      ? document.type.label
                      : '${document.type.label} | ${car.carNumber}',
                ),
                trailing: const Icon(Icons.attach_file_rounded),
                onTap: () => Navigator.of(sheetContext).pop(document),
              );
            },
          ),
        );
      },
    );

    if (document == null || !mounted) return;

    final car = controller.cars
        .where((item) => item.id == document.carId)
        .firstOrNull;
    final customer = car == null ? null : controller.customerForCar(car.id);
    _showMessage('Preparing document attachment...');

    try {
      final export = await DocumentPdfExportService.exportDocument(
        document: document,
        car: car,
        customer: customer,
      );
      if (!mounted) return;
      controller.sendCustomerMessage(
        topic: document.type.label,
        message: _chatMessageController.text.trim().isEmpty
            ? '${document.type.label} ${document.title} shared.'
            : _chatMessageController.text,
        channel: _customerChatChannel,
        carId: document.carId.isEmpty ? null : document.carId,
        attachmentPath: export.filePath,
      );
      setState(() => _chatMessageController.clear());
      _showMessage('${document.title} attached to chat.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Document attachment failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final activeCar = controller.activeCar;
    final titles = ['Home', 'Documents', 'Wheels', 'Chat', 'Profile'];
    final showCarStrip = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 33),
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
                          controller.session?.user.name.toUpperCase() ??
                              'CUSTOMER',
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
              onSelect: _selectActiveCar,
              onAddCar: () => _showAddCarSheet(context),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _handleParentPageChanged,
              children: [
                _CustomerHomeTab(
                  activeCar: activeCar,
                  trackerReplayToken: _homeTrackerReplayToken,
                  onRequestQuotation: (car) =>
                      _showQuotationRequestSheet(context, car),
                  onRequestImages: (car) => _showGaragePhotoSheet(context, car),
                  onSchedulePickup: (car) => _showPickupScheduler(context, car),
                  onOpenChat: () => _selectTab(3),
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
                WheelsMarketplaceTab(onBuyingContactStarted: _openBuyingChat),
                _CustomerChatTab(
                  chatMessageController: _chatMessageController,
                  channel: _customerChatChannel,
                  onChannelChanged: (value) =>
                      setState(() => _customerChatChannel = value),
                  onOpenWheels: () => _selectTab(2),
                  onSend: () => _sendChat(context),
                  onSendPhoto: () => _sendChatPhoto(context),
                  onSendDocument: () => _sendChatDocument(context),
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
            label: 'Wheels',
            icon: Icons.motion_photos_auto_outlined,
            activeIcon: Icons.motion_photos_auto_rounded,
            color: AppPalette.red,
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

class _PickupLocationException implements Exception {
  const _PickupLocationException(this.message);

  final String message;
}

class _PickupLocationDraft {
  const _PickupLocationDraft({
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
  });

  final double? latitude;
  final double? longitude;
  final String? mapUrl;

  bool get hasCoordinates => latitude != null && longitude != null;
}

class _PickupPlannerSection extends StatelessWidget {
  const _PickupPlannerSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickupVehiclePhotoSection extends StatelessWidget {
  const _PickupVehiclePhotoSection({
    required this.car,
    required this.photoPath,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final CarProfile car;
  final String? photoPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final previewPath = photoPath ?? car.imageUrl;
    return _PickupPlannerSection(
      icon: Icons.photo_camera_outlined,
      title: 'Vehicle photo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                path: previewPath,
                width: 104,
                height: 76,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photoPath == null
                          ? 'Using garage profile photo'
                          : 'Photo ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.carNumber,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              if (onRemove != null)
                IconButton.outlined(
                  tooltip: 'Remove vehicle photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupScheduleSection extends StatelessWidget {
  const _PickupScheduleSection({
    required this.pickupTime,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSlotSelected,
  });

  final DateTime pickupTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final void Function(int hour, int minute) onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return _PickupPlannerSection(
      icon: Icons.event_available_outlined,
      title: 'Date and time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PickupInfoPill(
                  icon: Icons.calendar_month_outlined,
                  label: formatShortDate(pickupTime),
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickupInfoPill(
                  icon: Icons.schedule_rounded,
                  label:
                      '${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('10:00'),
                selected: pickupTime.hour == 10 && pickupTime.minute == 0,
                onSelected: (_) => onSlotSelected(10, 0),
              ),
              ChoiceChip(
                label: const Text('14:00'),
                selected: pickupTime.hour == 14 && pickupTime.minute == 0,
                onSelected: (_) => onSlotSelected(14, 0),
              ),
              ChoiceChip(
                label: const Text('18:00'),
                selected: pickupTime.hour == 18 && pickupTime.minute == 0,
                onSelected: (_) => onSlotSelected(18, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupLocationSection extends StatelessWidget {
  const _PickupLocationSection({
    required this.addressController,
    required this.location,
    required this.locationAccessGranted,
    required this.onLocationAccessChanged,
    required this.onPickMap,
    required this.onOpenMaps,
    required this.onClearMap,
  });

  final TextEditingController addressController;
  final _PickupLocationDraft? location;
  final bool locationAccessGranted;
  final ValueChanged<bool> onLocationAccessChanged;
  final VoidCallback onPickMap;
  final VoidCallback onOpenMaps;
  final VoidCallback? onClearMap;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        location?.hasCoordinates == true ||
        location?.mapUrl?.trim().isNotEmpty == true;
    return _PickupPlannerSection(
      icon: Icons.location_on_outlined,
      title: 'Vehicle location',
      trailing: hasLocation
          ? IconButton.outlined(
              tooltip: 'Clear map pin',
              onPressed: onClearMap,
              icon: const Icon(Icons.location_off_outlined),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PickupMapPreview(
            latitude: location?.latitude,
            longitude: location?.longitude,
            interactive: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPickMap,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Set pin'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open Maps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Flat, street, area, landmark',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: locationAccessGranted,
            activeThumbColor: AppPalette.red,
            title: const Text('Share location with garage'),
            subtitle: const Text('Google Maps link included for routing.'),
            onChanged: onLocationAccessChanged,
          ),
        ],
      ),
    );
  }
}

class _PickupInfoPill extends StatelessWidget {
  const _PickupInfoPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupMapPreview extends StatelessWidget {
  const _PickupMapPreview({
    required this.latitude,
    required this.longitude,
    required this.interactive,
    this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final bool interactive;
  final ValueChanged<LatLng>? onTap;

  bool get _hasCoordinates => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final canRenderGoogleMap =
        _hasCoordinates &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (canRenderGoogleMap) {
      final position = LatLng(latitude!, longitude!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: interactive ? 240 : 150,
          width: double.infinity,
          child: GoogleMap(
            key: ValueKey(
              'pickup-map-${latitude!.toStringAsFixed(5)}-${longitude!.toStringAsFixed(5)}',
            ),
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: interactive ? 16 : 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pickup-location'),
                position: position,
              ),
            },
            onTap: interactive ? onTap : null,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: interactive,
            compassEnabled: false,
          ),
        ),
      );
    }

    return Container(
      height: interactive ? 220 : 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_pin, color: AppPalette.red, size: 38),
                const SizedBox(height: 6),
                Text(
                  _hasCoordinates
                      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                      : 'No map pin set',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

class _MapGridPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
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

  void _handleCarPageChanged(int index) {
    setState(() => _pageIndex = index);
    if (index >= widget.cars.length) return;

    final carId = widget.cars[index].id;
    if (carId != widget.activeCarId) {
      widget.onSelect(carId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: const BoxDecoration(
        color: AppPalette.white,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        children: [
          _CustomerCarCarouselFrame(
            canGoBack: _pageIndex > 0,
            canGoForward: _pageIndex < _pageCount - 1,
            onBack: () => _goToPage(_pageIndex - 1),
            onForward: () => _goToPage(_pageIndex + 1),
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: _pageCount,
              onPageChanged: _handleCarPageChanged,
              itemBuilder: (context, index) {
                final isAddCard = index == widget.cars.length;
                if (isAddCard) {
                  return _AddCarCard(onAddCar: widget.onAddCar);
                }
                final car = widget.cars[index];
                return _CustomerCarCard(
                  car: car,
                  isActive: car.id == widget.activeCarId,
                  onSelect: widget.onSelect,
                );
              },
            ),
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

class _CustomerCarCarouselFrame extends StatelessWidget {
  const _CustomerCarCarouselFrame({
    required this.child,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final Widget child;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  static const _arrowHitWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(top: 6, bottom: 6, child: child),
          Positioned(
            left: 3,
            top: 0,
            bottom: 0,
            width: _arrowHitWidth,
            child: _CarouselMatrixArrowButton(
              label: 'Previous car',
              type: AppMatrixIcon.left,
              enabled: canGoBack,
              onTap: onBack,
              alignment: Alignment.centerLeft,
            ),
          ),
          Positioned(
            right: 3,
            top: 0,
            bottom: 0,
            width: _arrowHitWidth,
            child: _CarouselMatrixArrowButton(
              label: 'Next car',
              type: AppMatrixIcon.right,
              enabled: canGoForward,
              onTap: onForward,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselMatrixArrowButton extends StatelessWidget {
  const _CarouselMatrixArrowButton({
    required this.label,
    required this.type,
    required this.enabled,
    required this.onTap,
    required this.alignment,
  });

  final String label;
  final AppMatrixIcon type;
  final bool enabled;
  final VoidCallback onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: enabled ? onTap : null,
        child: Align(
          alignment: alignment,
          child: Opacity(
            opacity: enabled ? 1 : 0.2,
            child: SizedBox.square(
              dimension: 41.4,
              child: MatrixIconSurface(
                type: type,
                active: true,
                showBackground: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerCarCard extends StatelessWidget {
  const _CustomerCarCard({
    required this.car,
    required this.isActive,
    required this.onSelect,
  });

  final CarProfile car;
  final bool isActive;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppPalette.white : AppPalette.black;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final modelStyle = Theme.of(context).textTheme.labelSmall;

    return GestureDetector(
      onTap: () => onSelect(car.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(53, 11, 53, 11),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          car.carNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle?.copyWith(
                            color: foreground,
                            fontSize: (titleStyle.fontSize ?? 16) * 1.02,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          car.model.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: modelStyle?.copyWith(
                            color: isActive
                                ? AppPalette.white.withValues(alpha: 0.86)
                                : AppPalette.black,
                            fontSize: (modelStyle.fontSize ?? 11) * 1.02,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      path: car.imageUrl,
                      width: 93.8,
                      height: 71.4,
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
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return GestureDetector(
      onTap: onAddCar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(53, 12, 53, 12),
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
                    width: 48,
                    height: 48,
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
                      style: titleStyle?.copyWith(
                        color: AppPalette.red,
                        fontSize: (titleStyle.fontSize ?? 16) * 1.02,
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
    required this.trackerReplayToken,
    required this.onRequestQuotation,
    required this.onRequestImages,
    required this.onSchedulePickup,
    required this.onOpenChat,
    required this.onOpenHistory,
    required this.onOpenBills,
  });

  final CarProfile? activeCar;
  final int trackerReplayToken;
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
    final workflowState = job?.workflowState ?? CarWorkflowState.registered;
    final activeTransit = _hasActiveTransit(job);
    final photos = activeCar == null
        ? const <GaragePhotoUpdate>[]
        : controller.photoUpdatesForCar(activeCar!.id);
    final documents = activeCar == null
        ? const <ServiceDocument>[]
        : controller.documentsForCar(activeCar!.id);
    final pendingDocument = documents
        .where((document) => document.approvalState == ApprovalState.pending)
        .firstOrNull;
    final unpaidInvoice = documents
        .where(
          (document) =>
              document.type == DocumentType.invoice &&
              document.paymentState != PaymentState.paid,
        )
        .firstOrNull;
    final actions = activeCar == null
        ? const <Widget>[]
        : _customerActions(
            activeCar!,
            job,
            documents: documents,
            pendingDocument: pendingDocument,
            unpaidInvoice: unpaidInvoice,
          );
    final showPhotoFeed =
        photos.isNotEmpty &&
        (workflowState == CarWorkflowState.underInspection ||
            workflowState == CarWorkflowState.workInProgress ||
            workflowState == CarWorkflowState.readyForDelivery);

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
          GarageServiceTracker(
            status: job?.status ?? JobStatus.onRoad,
            replayToken: 'customer-home:$trackerReplayToken:${activeCar!.id}',
          ),
          const SizedBox(height: 12),
          _CustomerNextStepCard(
            car: activeCar!,
            job: job,
            pendingDocument: pendingDocument,
            unpaidInvoice: unpaidInvoice,
            onSchedulePickup: onSchedulePickup,
            onRequestQuotation: onRequestQuotation,
            onOpenBills: onOpenBills,
            onOpenChat: onOpenChat,
          ),
          const SizedBox(height: 12),
          if (activeTransit && job != null) _PickupStatusCard(job: job),
          if (job == null)
            _EmptyStateCard(
              title: activeCar!.carNumber,
              subtitle:
                  'Registered in your garage account. Schedule pickup when you are ready.',
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GearboxActionGrid(children: actions),
          ],
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CustomerDocumentDigest(
              documents: documents,
              onOpenBills: onOpenBills,
            ),
          ],
          if (showPhotoFeed) ...[
            const SizedBox(height: 12),
            _GaragePhotoFeed(photos: photos),
          ],
        ],
      ],
    );
  }

  List<Widget> _customerActions(
    CarProfile car,
    ServiceJob? job, {
    required List<ServiceDocument> documents,
    required ServiceDocument? pendingDocument,
    required ServiceDocument? unpaidInvoice,
  }) {
    final hasDocuments = documents.isNotEmpty;
    if (job == null) {
      return [
        AutomotiveControlButton(
          icon: Icons.local_shipping_outlined,
          label: 'Pickup',
          active: true,
          onPressed: () => onSchedulePickup(car),
        ),
      ];
    }

    if (_hasActiveTransit(job)) {
      return [
        AutomotiveControlButton(
          icon: Icons.schedule_rounded,
          label: 'Reschedule',
          active: true,
          onPressed: () => onSchedulePickup(car),
        ),
        AutomotiveControlButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          onPressed: onOpenChat,
        ),
      ];
    }

    if (job.workflowState == CarWorkflowState.onRoad) {
      return <Widget>[
        AutomotiveControlButton(
          icon: Icons.receipt_long_outlined,
          label: 'Quote',
          active: true,
          onPressed: () => onRequestQuotation(car),
        ),
        AutomotiveControlButton(
          icon: Icons.local_shipping_outlined,
          label: 'Pickup',
          onPressed: () => onSchedulePickup(car),
        ),
        AutomotiveControlButton(
          icon: Icons.history_rounded,
          label: 'History',
          onPressed: () => onOpenHistory(car),
        ),
        if (hasDocuments)
          AutomotiveControlButton(
            icon: Icons.receipt_long_rounded,
            label: 'Bills',
            onPressed: onOpenBills,
          ),
      ];
    }

    if (job.workflowState == CarWorkflowState.pickupDone) {
      return [
        AutomotiveControlButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          onPressed: onOpenChat,
        ),
      ];
    }

    final workflowState = job.workflowState;
    final readyForDelivery = workflowState == CarWorkflowState.readyForDelivery;
    if (readyForDelivery) {
      return [
        AutomotiveControlButton(
          icon: Icons.local_shipping_outlined,
          label: 'Delivery',
          active: true,
          onPressed: () => onSchedulePickup(car),
        ),
        if (unpaidInvoice != null || pendingDocument != null || hasDocuments)
          AutomotiveControlButton(
            icon: Icons.receipt_long_rounded,
            label: unpaidInvoice == null ? 'Docs' : 'Invoice',
            active: unpaidInvoice != null || pendingDocument != null,
            onPressed: onOpenBills,
          ),
        AutomotiveControlButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          onPressed: onOpenChat,
        ),
      ];
    }

    final canRequestQuote =
        workflowState == CarWorkflowState.received ||
        workflowState == CarWorkflowState.underInspection;
    final canRequestImages =
        workflowState == CarWorkflowState.underInspection ||
        workflowState == CarWorkflowState.workInProgress;

    return <Widget>[
      if (canRequestQuote)
        AutomotiveControlButton(
          icon: Icons.receipt_long_outlined,
          label: 'Quote',
          active: true,
          onPressed: () => onRequestQuotation(car),
        ),
      if (canRequestImages)
        AutomotiveControlButton(
          icon: Icons.photo_camera_outlined,
          label: 'Images',
          active: true,
          onPressed: () => onRequestImages(car),
        ),
      AutomotiveControlButton(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        onPressed: onOpenChat,
      ),
      if (hasDocuments)
        AutomotiveControlButton(
          icon: Icons.receipt_long_rounded,
          label: pendingDocument == null ? 'Docs' : 'Review',
          active: pendingDocument != null || unpaidInvoice != null,
          onPressed: onOpenBills,
        ),
    ];
  }
}

class _CustomerNextStepCard extends StatelessWidget {
  const _CustomerNextStepCard({
    required this.car,
    required this.job,
    required this.pendingDocument,
    required this.unpaidInvoice,
    required this.onSchedulePickup,
    required this.onRequestQuotation,
    required this.onOpenBills,
    required this.onOpenChat,
  });

  final CarProfile car;
  final ServiceJob? job;
  final ServiceDocument? pendingDocument;
  final ServiceDocument? unpaidInvoice;
  final ValueChanged<CarProfile> onSchedulePickup;
  final ValueChanged<CarProfile> onRequestQuotation;
  final VoidCallback onOpenBills;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final data = _nextStepData();
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
              child: Icon(data.icon, color: AppPalette.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: data.tooltip,
              onPressed: data.onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }

  _CustomerNextStepData _nextStepData() {
    if (job == null) {
      return _CustomerNextStepData(
        icon: Icons.local_shipping_outlined,
        title: 'Schedule pickup',
        subtitle: 'Your car is registered but not in the garage yet.',
        tooltip: 'Schedule pickup',
        onTap: () => onSchedulePickup(car),
      );
    }
    final workflowState = job!.workflowState;
    if (_hasActiveTransit(job)) {
      final isDelivery = _isDeliveryTransit(workflowState);
      final requested = job!.pickupState == PickupState.requested;
      return _CustomerNextStepData(
        icon: Icons.schedule_rounded,
        title: requested
            ? '${_sentenceCase(isDelivery ? 'delivery' : 'pickup')} requested'
            : '${_sentenceCase(isDelivery ? 'delivery' : 'pickup')} assigned',
        subtitle: job!.pickupPersonName == null
            ? 'Garage will assign a ${isDelivery ? 'delivery' : 'pickup'} person soon. You can reschedule if needed.'
            : '${job!.pickupPersonName} will ${isDelivery ? 'deliver' : 'pick up'} the car at ${formatDateTime(job!.pickupTime)}.',
        tooltip: 'Reschedule ${isDelivery ? 'delivery' : 'pickup'}',
        onTap: () => onSchedulePickup(car),
      );
    }
    if (workflowState == CarWorkflowState.pickupDone) {
      return _CustomerNextStepData(
        icon: Icons.task_alt_rounded,
        title: 'Pickup completed',
        subtitle:
            'Your car has reached the garage. The team will check it in before inspection starts.',
        tooltip: 'Open chat',
        onTap: onOpenChat,
      );
    }
    if (pendingDocument != null) {
      return _CustomerNextStepData(
        icon: Icons.request_quote_rounded,
        title: 'Review ${pendingDocument!.type.label}',
        subtitle: '${pendingDocument!.title} is waiting for your approval.',
        tooltip: 'Open documents',
        onTap: onOpenBills,
      );
    }
    if (unpaidInvoice != null) {
      return _CustomerNextStepData(
        icon: Icons.payments_rounded,
        title: 'Invoice pending',
        subtitle: '${unpaidInvoice!.title} is ready in your document library.',
        tooltip: 'Open invoice',
        onTap: onOpenBills,
      );
    }
    if (workflowState == CarWorkflowState.readyForDelivery) {
      return _CustomerNextStepData(
        icon: Icons.local_shipping_outlined,
        title: 'Ready for delivery',
        subtitle:
            'Service is complete. Schedule delivery when you are ready to receive the car.',
        tooltip: 'Schedule delivery',
        onTap: () => onSchedulePickup(car),
      );
    }
    if (workflowState == CarWorkflowState.onRoad) {
      return _CustomerNextStepData(
        icon: Icons.route_rounded,
        title: 'On-Road',
        subtitle:
            'Your car is back with you. You can request a quote or schedule pickup anytime.',
        tooltip: 'Request quote',
        onTap: () => onRequestQuotation(car),
      );
    }
    if (workflowState == CarWorkflowState.underInspection) {
      return _CustomerNextStepData(
        icon: Icons.search_rounded,
        title: 'Inspection in progress',
        subtitle:
            'The garage can share photos and prepare quotation or job card.',
        tooltip: 'Open chat',
        onTap: onOpenChat,
      );
    }
    if (workflowState == CarWorkflowState.received) {
      return _CustomerNextStepData(
        icon: Icons.home_repair_service_outlined,
        title: 'Vehicle received',
        subtitle:
            'Your car is checked in at the garage and will move into inspection.',
        tooltip: 'Open chat',
        onTap: onOpenChat,
      );
    }
    if (workflowState == CarWorkflowState.workInProgress) {
      return _CustomerNextStepData(
        icon: Icons.photo_camera_outlined,
        title: 'Work is happening',
        subtitle: 'Track photos and messages while the service is in progress.',
        tooltip: 'Open chat',
        onTap: onOpenChat,
      );
    }
    return _CustomerNextStepData(
      icon: Icons.task_alt_rounded,
      title: 'Service status: ${workflowState.label}',
      subtitle: 'Documents, photos, and chat updates are available below.',
      tooltip: 'Open bills',
      onTap: onOpenBills,
    );
  }
}

class _CustomerNextStepData {
  const _CustomerNextStepData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tooltip;
  final VoidCallback onTap;
}

bool _hasActiveTransit(ServiceJob? job) {
  if (job == null || !job.pickupRequired) return false;
  final state = job.workflowState;
  return state == CarWorkflowState.pickupRequested ||
      state == CarWorkflowState.pickupAssigned ||
      state == CarWorkflowState.deliveryRequested ||
      state == CarWorkflowState.deliveryAssigned;
}

bool _isDeliveryTransit(CarWorkflowState state) {
  return state == CarWorkflowState.deliveryRequested ||
      state == CarWorkflowState.deliveryAssigned;
}

String _sentenceCase(String value) {
  if (value.isEmpty) return value;
  return '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
}

class _CustomerDocumentDigest extends StatelessWidget {
  const _CustomerDocumentDigest({
    required this.documents,
    required this.onOpenBills,
  });

  final List<ServiceDocument> documents;
  final VoidCallback onOpenBills;

  @override
  Widget build(BuildContext context) {
    final latest = documents.first;
    final pending = documents
        .where((document) => document.approvalState == ApprovalState.pending)
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.folder_copy_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documents and bills',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latest ${latest.type.label} ${latest.title} | $pending approvals pending',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: 'Open document library',
              onPressed: onOpenBills,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupStatusCard extends StatelessWidget {
  const _PickupStatusCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    final state = job.workflowState;
    final isDelivery = _isDeliveryTransit(state);
    final tripLabel = isDelivery ? 'delivery' : 'pickup';
    final mapUri = _pickupMapUriForJob(job);
    final assignee = job.pickupPersonName == null
        ? 'Garage will assign a $tripLabel person'
        : '${job.pickupPersonName}'
              '${job.pickupPersonPhone == null || job.pickupPersonPhone!.isEmpty ? '' : ' | ${job.pickupPersonPhone}'}';
    final title = job.pickupState == PickupState.assigned
        ? '${_sentenceCase(tripLabel)} assigned'
        : '${_sentenceCase(tripLabel)} requested';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                LedIndicator(active: job.pickupState == PickupState.assigned),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Slot ${formatDateTime(job.pickupTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(assignee, style: Theme.of(context).textTheme.bodySmall),
            if (job.pickupAddress != null && job.pickupAddress!.isNotEmpty)
              Text(
                job.pickupAddress!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (mapUri != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    launchUrl(mapUri, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.map_outlined),
                label: Text('Open $tripLabel map'),
              ),
            ],
          ],
        ),
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

class _GaragePhotoFeed extends StatelessWidget {
  const _GaragePhotoFeed({required this.photos});

  final List<GaragePhotoUpdate> photos;

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
                const Icon(Icons.photo_library_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Garage photos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...photos
                .take(4)
                .map(
                  (photo) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        AppImage(
                          path: photo.imagePath,
                          width: 72,
                          height: 56,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDateTime(photo.createdAt),
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

    return AppInnerTabs(
      title: '${activeCar.carNumber} Docs',
      tabs: [
        AppInnerTab(
          label: 'Document Studio',
          child: _buildStudioView(activeCar, assetDocuments),
        ),
        AppInnerTab(
          label: 'Document Library',
          child: _buildLibraryView(libraryDocuments),
        ),
      ],
    );
  }

  Widget _buildStudioView(
    CarProfile activeCar,
    List<CustomerAssetDocument> assetDocuments,
  ) {
    return ListView(
      key: const PageStorageKey('customer-document-studio'),
      padding: const EdgeInsets.all(16),
      children: [
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
      ],
    );
  }

  Widget _buildLibraryView(List<ServiceDocument> libraryDocuments) {
    return ListView(
      key: const PageStorageKey('customer-document-library'),
      padding: const EdgeInsets.all(16),
      children: [
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
    required this.channel,
    required this.onChannelChanged,
    required this.onOpenWheels,
    required this.onSend,
    required this.onSendPhoto,
    required this.onSendDocument,
  });

  final TextEditingController chatMessageController;
  final ChatChannel channel;
  final ValueChanged<ChatChannel> onChannelChanged;
  final VoidCallback onOpenWheels;
  final VoidCallback onSend;
  final VoidCallback onSendPhoto;
  final VoidCallback onSendDocument;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final visibleChannels = [
      ChatChannel.general,
      for (final item in ChatChannel.values)
        if (item != ChatChannel.general &&
            controller.conversationForUser(userId, channel: item).isNotEmpty)
          item,
    ];
    final effectiveChannel = visibleChannels.contains(channel)
        ? channel
        : ChatChannel.general;

    if (effectiveChannel != channel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChannelChanged(effectiveChannel);
      });
    }

    final index = visibleChannels.indexOf(effectiveChannel);
    return AppInnerTabs(
      currentIndex: index,
      onChanged: (value) => onChannelChanged(visibleChannels[value]),
      tabs: visibleChannels
          .map(
            (item) => AppInnerTab(
              label: item.label,
              child: _CustomerChatChannelView(
                key: PageStorageKey('customer-chat-${item.name}'),
                chatMessageController: chatMessageController,
                channel: item,
                onOpenWheels: onOpenWheels,
                onSend: onSend,
                onSendPhoto: onSendPhoto,
                onSendDocument: onSendDocument,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CustomerChatEmptyState extends StatelessWidget {
  const _CustomerChatEmptyState({
    required this.channel,
    required this.onOpenWheels,
  });

  final ChatChannel channel;
  final VoidCallback onOpenWheels;

  @override
  Widget build(BuildContext context) {
    final showWheelsButton =
        channel == ChatChannel.buying || channel == ChatChannel.selling;
    final message = switch (channel) {
      ChatChannel.buying =>
        'No cars from your buy history yet. Search in Wheels to find cars.',
      ChatChannel.selling =>
        'No cars from your sell history yet. Open Wheels and tap the plus button to list a car.',
      ChatChannel.general => 'No general messages yet.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showWheelsButton
                    ? Icons.motion_photos_auto_outlined
                    : Icons.chat_bubble_outline_rounded,
                color: AppPalette.red,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (showWheelsButton) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenWheels,
                  icon: const Icon(Icons.motion_photos_auto_outlined),
                  label: const Text('Open Wheels'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerChatChannelView extends StatelessWidget {
  const _CustomerChatChannelView({
    super.key,
    required this.chatMessageController,
    required this.channel,
    required this.onOpenWheels,
    required this.onSend,
    required this.onSendPhoto,
    required this.onSendDocument,
  });

  final TextEditingController chatMessageController;
  final ChatChannel channel;
  final VoidCallback onOpenWheels;
  final VoidCallback onSend;
  final VoidCallback onSendPhoto;
  final VoidCallback onSendDocument;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final user = controller.session!.user;
    final owner = controller.ownerUser;
    final messages = controller.conversationForUser(userId, channel: channel);

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _CustomerChatEmptyState(
                  channel: channel,
                  onOpenWheels: onOpenWheels,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                PopupMenuButton<String>(
                  tooltip: 'Attach',
                  onSelected: (value) {
                    if (value == 'document') {
                      onSendDocument();
                    } else if (value == 'photo') {
                      onSendPhoto();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'document',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.receipt_long_outlined),
                        title: Text('Document Library'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'photo',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.photo_library_outlined),
                        title: Text('Gallery Photo'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.attach_file_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: chatMessageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Message the garage about ${channel.label.toLowerCase()}...',
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

import 'dart:async';

import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/api_client.dart';
import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/services/demo_seed.dart';
import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  AppController({FlywheelsApiClient? apiClient})
    : _apiClient = apiClient ?? const FlywheelsApiClient();

  final FlywheelsApiClient _apiClient;

  bool isBootstrapping = true;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  String? requestedPhone;
  String? generatedOtp;
  String? errorMessage;
  AppSession? session;
  Timer? _bootstrapTimer;

  final List<GarageUser> _users = List<GarageUser>.from(DemoSeed.users);
  final List<CarProfile> _cars = List<CarProfile>.from(DemoSeed.cars);
  final List<ServiceJob> _jobs = List<ServiceJob>.from(DemoSeed.jobs);
  final List<ServiceDocument> _documents = List<ServiceDocument>.from(
    DemoSeed.documents,
  );
  final List<AppNotification> _notifications = List<AppNotification>.from(
    DemoSeed.notifications,
  );
  final List<SupportMessage> _messages = List<SupportMessage>.from(
    DemoSeed.messages,
  );
  final List<GaragePhotoUpdate> _photoUpdates = List<GaragePhotoUpdate>.from(
    DemoSeed.photoUpdates,
  );
  final List<CustomerAssetDocument> _assetDocuments =
      List<CustomerAssetDocument>.from(DemoSeed.assetDocuments);

  GarageUser get ownerUser => _users.firstWhere(
    (user) => user.role == UserRole.owner,
    orElse: () => DemoSeed.ownerUser,
  );

  List<GarageUser> get customers =>
      List.unmodifiable(_users.where((user) => user.role == UserRole.customer));

  List<CarProfile> get cars {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_cars);
    return List.unmodifiable(_cars.where((car) => car.userId == userId));
  }

  List<ServiceJob> get jobs {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_jobs);
    final carIds = _cars
        .where((car) => car.userId == userId)
        .map((car) => car.id)
        .toSet();
    return List.unmodifiable(_jobs.where((job) => carIds.contains(job.carId)));
  }

  List<ServiceDocument> get documents {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_documents);
    return List.unmodifiable(
      _documents.where((document) => document.userId == userId),
    );
  }

  List<AppNotification> get notifications {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_notifications);
    return List.unmodifiable(
      _notifications.where((notification) => notification.userId == userId),
    );
  }

  List<SupportMessage> get messages {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_messages);
    return List.unmodifiable(
      _messages.where((message) => message.userId == userId),
    );
  }

  List<GaragePhotoUpdate> get photoUpdates {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_photoUpdates);
    final carIds = _cars
        .where((car) => car.userId == userId)
        .map((car) => car.id)
        .toSet();
    return List.unmodifiable(
      _photoUpdates.where((update) => carIds.contains(update.carId)),
    );
  }

  List<CustomerAssetDocument> get customerAssetDocuments {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_assetDocuments);
    return List.unmodifiable(
      _assetDocuments.where((document) => document.userId == userId),
    );
  }

  CarProfile? get activeCar {
    if (cars.isEmpty) return null;
    return cars.firstWhere((car) => car.isActive, orElse: () => cars.first);
  }

  Future<void> bootstrap() async {
    _bootstrapTimer?.cancel();
    final completer = Completer<void>();
    _bootstrapTimer = Timer(const Duration(milliseconds: 1600), () {
      isBootstrapping = false;
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    });
    return completer.future;
  }

  @override
  void dispose() {
    _bootstrapTimer?.cancel();
    super.dispose();
  }

  Future<void> requestOtp(String phone) async {
    isSendingOtp = true;
    errorMessage = null;
    requestedPhone = phone;
    generatedOtp = null;
    notifyListeners();

    try {
      final response = await _apiClient.requestOtp(phone);
      generatedOtp = response.devOtp ?? '123456';
    } catch (_) {
      generatedOtp = '123456';
    } finally {
      isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (requestedPhone == null) {
      errorMessage = 'Request an OTP before verification.';
      notifyListeners();
      return false;
    }

    isVerifyingOtp = true;
    errorMessage = null;
    notifyListeners();

    try {
      final remoteSession = await _apiClient.verifyOtp(requestedPhone!, code);
      session =
          remoteSession ?? DemoSeed.sessionForPhone(requestedPhone!, code);
    } catch (_) {
      session = DemoSeed.sessionForPhone(requestedPhone!, code);
    } finally {
      isVerifyingOtp = false;
      notifyListeners();
    }

    if (session == null) {
      errorMessage =
          'Invalid OTP. Use the development OTP if the backend is offline.';
      notifyListeners();
      return false;
    }

    final existingUser = _users
        .where((user) => user.id == session!.user.id)
        .firstOrNull;
    if (existingUser == null) {
      _users.insert(0, session!.user);
    }

    return true;
  }

  void logout() {
    session = null;
    requestedPhone = null;
    generatedOtp = null;
    errorMessage = null;
    notifyListeners();
  }

  void updateProfilePhoto(String imagePath) {
    final currentSession = session;
    if (currentSession == null) return;
    final userIndex = _users.indexWhere(
      (user) => user.id == currentSession.user.id,
    );
    if (userIndex >= 0) {
      _users[userIndex] = _users[userIndex].copyWith(
        profileImagePath: imagePath,
      );
    }
    session = currentSession.copyWith(
      user: currentSession.user.copyWith(profileImagePath: imagePath),
    );
    notifyListeners();
  }

  void setActiveCar(String carId) {
    for (var index = 0; index < _cars.length; index++) {
      final car = _cars[index];
      if (car.userId != session?.user.id) continue;
      _cars[index] = car.copyWith(isActive: car.id == carId);
    }
    notifyListeners();
  }

  void addCar({
    required String carNumber,
    required String model,
    required String fuelType,
    required int year,
    String? imagePath,
  }) {
    final userId = session?.user.id;
    if (userId == null) return;

    _cars.insert(
      0,
      CarProfile(
        id: 'car-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        carNumber: carNumber,
        model: model,
        fuelType: fuelType,
        year: year,
        isActive: _cars.where((car) => car.userId == userId).isEmpty,
        imageUrl: imagePath == null || imagePath.trim().isEmpty
            ? CarMediaService.imageForModel(model, year: year)
            : imagePath.trim(),
      ),
    );
    notifyListeners();
  }

  void addOwnerCarForCustomer({
    required String customerUserId,
    required String carNumber,
    required String model,
    required String fuelType,
    required int year,
    String? imagePath,
  }) {
    final customer = userById(customerUserId);
    if (customer == null || customer.role != UserRole.customer) return;
    final normalizedNumber = carNumber.trim();
    if (normalizedNumber.isEmpty || model.trim().isEmpty) return;

    _cars.insert(
      0,
      CarProfile(
        id: 'car-${DateTime.now().millisecondsSinceEpoch}',
        userId: customerUserId,
        carNumber: normalizedNumber,
        model: model.trim(),
        fuelType: fuelType.trim().isEmpty ? 'Petrol' : fuelType.trim(),
        year: year,
        isActive: false,
        imageUrl: imagePath == null || imagePath.trim().isEmpty
            ? CarMediaService.imageForModel(model, year: year)
            : imagePath.trim(),
      ),
    );
    notifyListeners();
  }

  List<ServiceJob> jobsForCar(String carId) {
    return jobs.where((job) => job.carId == carId).toList();
  }

  ServiceJob? latestJobForCar(String carId) {
    final matches = jobsForCar(carId);
    if (matches.isEmpty) return null;
    matches.sort(
      (left, right) =>
          right.expectedCompletion.compareTo(left.expectedCompletion),
    );
    return matches.first;
  }

  List<ServiceDocument> documentsForCar(String carId) {
    return documents.where((document) => document.carId == carId).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  List<CustomerAssetDocument> assetDocumentsForCar(String carId) {
    return customerAssetDocuments
        .where((document) => document.carId == carId)
        .toList()
      ..sort((left, right) => right.uploadedAt.compareTo(left.uploadedAt));
  }

  List<GaragePhotoUpdate> photoUpdatesForCar(String carId) {
    return photoUpdates.where((update) => update.carId == carId).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  GaragePhotoUpdate? latestPhotoForCar(String carId) {
    final updates = photoUpdatesForCar(carId);
    return updates.isEmpty ? null : updates.first;
  }

  GarageUser? userById(String userId) {
    if (session?.user.id == userId) return session?.user;
    return _users.where((user) => user.id == userId).firstOrNull;
  }

  GarageUser? customerForCar(String carId) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return null;
    return userById(car.userId);
  }

  List<SupportMessage> conversationForUser(String userId, {String? carId}) {
    final filtered =
        _messages.where((message) {
            if (message.userId != userId) return false;
            if (carId == null) return true;
            return message.carId == carId;
          }).toList()
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return filtered;
  }

  List<GarageUser> get customersWithConversations {
    final userIds = <String>{};
    final ordered = _messages.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final users = <GarageUser>[];
    for (final message in ordered) {
      if (userIds.contains(message.userId)) continue;
      final user = userById(message.userId);
      if (user == null || user.role != UserRole.customer) continue;
      userIds.add(message.userId);
      users.add(user);
    }
    return users;
  }

  List<CarProfile> carsForCustomer(String customerUserId) {
    return _cars.where((car) => car.userId == customerUserId).toList()
      ..sort((left, right) => left.carNumber.compareTo(right.carNumber));
  }

  GarageUser? customerByPhone(String phone) {
    final normalized = _normalizeIndianPhoneForStorage(phone);
    return customers
        .where(
          (user) => _normalizeIndianPhoneForStorage(user.phone) == normalized,
        )
        .firstOrNull;
  }

  void decideDocument(
    String documentId,
    ApprovalState decision, {
    String? comment,
  }) {
    final index = _documents.indexWhere(
      (document) => document.id == documentId,
    );
    if (index == -1) return;
    final existing = _documents[index];
    _documents[index] = existing.copyWith(
      approvalState: decision,
      customerComment: comment,
      updatedAt: DateTime.now(),
    );

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: DemoSeed.ownerUser.id,
        title: '${existing.type.label} ${decision.name}',
        message: '${existing.title} was ${decision.name} by the customer.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void advanceJobStatus(String jobId) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null) return;
    setJobStatus(jobId, job.status.next);
  }

  void setJobStatus(String jobId, JobStatus status) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(status: status);
    final car = _cars
        .where((item) => item.id == _jobs[index].carId)
        .firstOrNull;
    if (car != null) {
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          title: 'Car status updated',
          message: '${car.carNumber} is now ${status.label}.',
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void assignPickup(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupTime: DateTime.now().add(const Duration(hours: 3)),
    );
    notifyListeners();
  }

  void requestPickupForCar(
    String carId, {
    required DateTime pickupTime,
    String? pickupAddress,
    required bool locationAccessGranted,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final existingIndex = _jobs.indexWhere((job) => job.carId == carId);
    if (existingIndex >= 0) {
      _jobs[existingIndex] = _jobs[existingIndex].copyWith(
        pickupRequired: true,
        pickupState: PickupState.requested,
        pickupTime: pickupTime,
        pickupAddress: pickupAddress,
        locationAccessGranted: locationAccessGranted,
      );
    } else {
      _jobs.insert(
        0,
        ServiceJob(
          id: 'job-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          carId: car.id,
          status: JobStatus.received,
          expectedCompletion: DateTime.now().add(const Duration(days: 1)),
          pickupTime: pickupTime,
          pickupRequired: true,
          pickupState: PickupState.requested,
          pickupAddress: pickupAddress,
          locationAccessGranted: locationAccessGranted,
        ),
      );
    }

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: ownerUser.id,
        title: 'Pickup and drop requested',
        message:
            '${car.carNumber} requested pickup for ${_formatWhatsappDate(pickupTime)}.',
        createdAt: DateTime.now(),
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
        userId: car.userId,
        title: 'Pickup and drop requested',
        message:
            'Pickup and drop is requested for ${car.carNumber} at ${_formatWhatsappDate(pickupTime)}.',
        createdAt: DateTime.now(),
      ),
    );
    _messages.add(
      SupportMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        userId: car.userId,
        topic: 'Pickup and drop',
        message:
            'Pickup requested for ${_formatWhatsappDate(pickupTime)}${pickupAddress == null || pickupAddress.isEmpty ? '' : ' at $pickupAddress'}.',
        createdAt: DateTime.now(),
        carId: car.id,
      ),
    );
    notifyListeners();
  }

  void completePickup(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: true,
      pickupState: PickupState.completed,
    );
    notifyListeners();
  }

  void sendStatusUpdate(String jobId, String message) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    final car = job == null
        ? null
        : _cars.where((item) => item.id == job.carId).firstOrNull;
    if (job == null || car == null) return;

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: car.userId,
        title: 'Garage update',
        message: '${car.carNumber}: $message',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addGaragePhoto({
    required String carId,
    required String imagePath,
    required String caption,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final now = DateTime.now();

    _photoUpdates.insert(
      0,
      GaragePhotoUpdate(
        id: 'photo-${now.millisecondsSinceEpoch}',
        userId: car.userId,
        carId: carId,
        imagePath: imagePath,
        caption: caption.trim().isEmpty
            ? 'Garage progress update'
            : caption.trim(),
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: car.userId,
        title: 'New garage photos',
        message: 'Fresh progress photos were added for ${car.carNumber}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void requestGaragePhotos(String carId, {String? note}) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final now = DateTime.now();
    final detail = note == null || note.trim().isEmpty
        ? 'Please share the latest photos.'
        : note.trim();

    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch}',
        userId: car.userId,
        topic: 'Photo request',
        message: detail,
        createdAt: now,
        carId: car.id,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Customer requested photos',
        message: '${car.carNumber}: $detail',
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 2}',
        userId: car.userId,
        title: 'Photo request sent',
        message:
            'The garage has been asked to share the latest images for ${car.carNumber}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  ServiceDocument? sendDocument(
    DocumentDraft draft, {
    String? customerUserId,
    String? fuelType,
    int? year,
  }) {
    final targetCar = _resolveDraftCar(
      draft,
      fuelType: fuelType,
      year: year,
      customerUserId: customerUserId,
    );
    final customerId =
        targetCar?.userId ?? customerUserId ?? DemoSeed.customerUser.id;
    final relatedJob = targetCar == null ? null : latestJobForCar(targetCar.id);
    final now = DateTime.now();

    final document = ServiceDocument(
      id: 'doc-${now.millisecondsSinceEpoch}',
      userId: customerId,
      carId: targetCar?.id ?? '',
      jobId: relatedJob?.id ?? '',
      type: draft.type,
      title: draft.documentNumber,
      items: draft.items,
      total: draft.total,
      approvalState:
          draft.type == DocumentType.invoice ||
              draft.type == DocumentType.jobCard
          ? ApprovalState.approved
          : ApprovalState.pending,
      paymentState: PaymentState.pending,
      createdAt: now,
      updatedAt: now,
      pdfLabel: '${draft.type.label} PDF',
    );
    _documents.insert(0, document);

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: customerId,
        title: '${draft.type.label} shared',
        message: '${draft.documentNumber} was sent for ${draft.vehicleNumber}.',
        createdAt: now,
      ),
    );
    notifyListeners();
    return document;
  }

  CarProfile? _resolveDraftCar(
    DocumentDraft draft, {
    String? customerUserId,
    String? fuelType,
    int? year,
  }) {
    if (draft.selectedCarId != null) {
      return _cars.where((car) => car.id == draft.selectedCarId).firstOrNull;
    }

    final resolvedCustomerId =
        customerUserId ?? _resolveOrCreateCustomer(draft).id;
    final existingCar = _cars
        .where(
          (car) =>
              car.userId == resolvedCustomerId &&
              car.carNumber.toLowerCase() == draft.vehicleNumber.toLowerCase(),
        )
        .firstOrNull;
    if (existingCar != null) {
      return existingCar;
    }

    final newCar = DemoSeed.buildCar(
      id: 'car-${DateTime.now().millisecondsSinceEpoch}',
      userId: resolvedCustomerId,
      carNumber: draft.vehicleNumber,
      model: draft.carModel,
      fuelType: fuelType?.trim().isEmpty ?? true ? 'Petrol' : fuelType!.trim(),
      year: year ?? DateTime.now().year,
      isActive: false,
    );
    _cars.insert(0, newCar);
    return newCar;
  }

  GarageUser _resolveOrCreateCustomer(DocumentDraft draft) {
    final existingByPhone = draft.customerPhone.trim().isEmpty
        ? null
        : customerByPhone(draft.customerPhone);
    if (existingByPhone != null) {
      return existingByPhone;
    }
    final user = GarageUser(
      id: 'customer-${DateTime.now().millisecondsSinceEpoch}',
      name: draft.customerName.isEmpty ? 'New Customer' : draft.customerName,
      phone: _normalizeIndianPhoneForStorage(draft.customerPhone),
      role: UserRole.customer,
    );
    _users.insert(0, user);
    return user;
  }

  void requestQuotation(String carId, {String? concern}) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: ownerUser.id,
        title: 'Quotation requested',
        message:
            '${car.carNumber} requested a quotation${concern == null || concern.isEmpty ? '' : ': $concern'}.',
        createdAt: DateTime.now(),
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
        userId: car.userId,
        title: 'Quotation request sent',
        message:
            'Your quotation request for ${car.carNumber} has been shared with the garage.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void sendCustomerMessage({
    required String topic,
    required String message,
    String? carId,
    String? attachmentPath,
  }) {
    final userId = session?.user.id;
    if (userId == null ||
        (message.trim().isEmpty &&
            (attachmentPath == null || attachmentPath.trim().isEmpty))) {
      return;
    }
    final carNumber = _cars
        .where((item) => item.id == carId)
        .firstOrNull
        ?.carNumber;
    final now = DateTime.now();

    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch}',
        userId: userId,
        topic: topic,
        message: message.trim().isEmpty ? 'Photo shared' : message.trim(),
        createdAt: now,
        carId: carId,
        attachmentPath: attachmentPath,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Customer enquiry',
        message:
            '$topic enquiry received${carNumber == null ? '' : ' for $carNumber'}.',
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 2}',
        userId: userId,
        title: 'Message sent to owner',
        message: 'Your enquiry has been sent.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void sendOwnerMessage({
    required String customerUserId,
    required String topic,
    required String message,
    String? carId,
    String? attachmentPath,
  }) {
    if (message.trim().isEmpty &&
        (attachmentPath == null || attachmentPath.trim().isEmpty)) {
      return;
    }
    final now = DateTime.now();
    final carNumber = _cars
        .where((item) => item.id == carId)
        .firstOrNull
        ?.carNumber;

    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch}',
        userId: customerUserId,
        topic: topic,
        message: message.trim().isEmpty ? 'Photo shared' : message.trim(),
        createdAt: now,
        carId: carId,
        attachmentPath: attachmentPath,
        sentByOwner: true,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: customerUserId,
        title: 'Owner replied',
        message:
            '${topic.isEmpty ? 'Garage update' : topic}${carNumber == null ? '' : ' for $carNumber'}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void sendDocumentInChat(ServiceDocument document, {String? attachmentPath}) {
    final car = _cars.where((item) => item.id == document.carId).firstOrNull;
    final customerId = car?.userId ?? document.userId;
    if (customerId.isEmpty) return;

    sendOwnerMessage(
      customerUserId: customerId,
      topic: document.type.label,
      message:
          '${document.type.label} ${document.title} shared. Total: ${document.total.toStringAsFixed(0)}. PDF attached for WhatsApp sharing.',
      carId: document.carId.isEmpty ? null : document.carId,
      attachmentPath: attachmentPath,
    );
  }

  void markConversationReadByOwner(String customerUserId) {
    var changed = false;
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (message.userId == customerUserId &&
          !message.sentByOwner &&
          !message.isRead) {
        _messages[index] = message.copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void markConversationReadByCustomer(String customerUserId) {
    var changed = false;
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (message.userId == customerUserId &&
          message.sentByOwner &&
          !message.isRead) {
        _messages[index] = message.copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  int unreadMessageCountForCurrentSession() {
    final currentSession = session;
    if (currentSession == null) return 0;
    if (currentSession.role.isOwner) {
      return _messages
          .where((message) => !message.sentByOwner && !message.isRead)
          .length;
    }
    return _messages
        .where(
          (message) =>
              message.userId == currentSession.user.id &&
              message.sentByOwner &&
              !message.isRead,
        )
        .length;
  }

  int unreadIncomingCountForCustomer(String customerUserId) {
    return _messages
        .where(
          (message) =>
              message.userId == customerUserId &&
              !message.sentByOwner &&
              !message.isRead,
        )
        .length;
  }

  void markDocumentPaid(String documentId) {
    final index = _documents.indexWhere(
      (document) => document.id == documentId,
    );
    if (index == -1) return;
    _documents[index] = _documents[index].copyWith(
      paymentState: PaymentState.paid,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addCustomerAssetDocument({
    required String carId,
    required PersonalDocumentType type,
    required String title,
    required String filePath,
    DateTime? validUntil,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    _assetDocuments.insert(
      0,
      CustomerAssetDocument(
        id: 'asset-${DateTime.now().millisecondsSinceEpoch}',
        userId: car.userId,
        carId: carId,
        type: type,
        title: title.trim().isEmpty ? type.label : title.trim(),
        filePath: filePath,
        uploadedAt: DateTime.now(),
        validUntil: validUntil,
      ),
    );
    notifyListeners();
  }

  String buildDocumentWhatsappMessage(ServiceDocument document) {
    final car = _cars.where((item) => item.id == document.carId).firstOrNull;
    return 'FLYWHEELS AUTO\n'
        '${document.type.label}: ${document.title}\n'
        'Vehicle: ${car?.carNumber ?? '-'}\n'
        'Date: ${_formatWhatsappDate(document.updatedAt)}\n'
        'Total: ${document.total.toStringAsFixed(0)}\n'
        'Status: ${document.approvalState.name}\n'
        'PDF: ${document.title}.pdf';
  }

  String buildPaymentReminderMessage(ServiceDocument document) {
    final car = _cars.where((item) => item.id == document.carId).firstOrNull;
    return 'FLYWHEELS AUTO payment reminder\n'
        'Invoice: ${document.title}\n'
        'Vehicle: ${car?.carNumber ?? '-'}\n'
        'Amount due: ${document.total.toStringAsFixed(0)}\n'
        'Please complete the payment for your service bill.';
  }

  String buildPickupWhatsappMessage(
    CarProfile car, {
    required DateTime pickupTime,
    String? pickupAddress,
    required bool locationAccessGranted,
  }) {
    return 'FLYWHEELS AUTO pickup request\n'
        'Vehicle: ${car.carNumber}\n'
        'Model: ${car.model}\n'
        'Pickup time: ${_formatWhatsappDate(pickupTime)}\n'
        '${pickupAddress == null || pickupAddress.isEmpty ? '' : 'Address: $pickupAddress\n'}'
        'Location access: ${locationAccessGranted ? 'Approved' : 'Not approved'}';
  }

  String _formatWhatsappDate(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  String _normalizeIndianPhoneForStorage(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

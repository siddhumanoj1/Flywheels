import 'dart:async';

import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/api_client.dart';
import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/services/demo_seed.dart';
import 'package:flywheels/services/google_maps_link_service.dart';
import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  AppController({FlywheelsApiClient? apiClient})
    : _apiClient = apiClient ?? const FlywheelsApiClient();

  final FlywheelsApiClient _apiClient;

  bool isBootstrapping = true;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  bool isLoggingIn = false;
  String? requestedPhone;
  String? generatedOtp;
  String? errorMessage;
  AppSession? session;
  Timer? _bootstrapTimer;
  int _authFlowRevision = 0;

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
  final List<CarSaleListing> _saleListings = List<CarSaleListing>.from(
    DemoSeed.saleListings,
  );
  final List<StaffProfile> _staffProfiles = List<StaffProfile>.from(
    DemoSeed.staffProfiles,
  );
  final List<AttendanceEntry> _attendanceEntries = List<AttendanceEntry>.from(
    DemoSeed.attendanceEntries,
  );
  final List<SalaryAdvance> _salaryAdvances = List<SalaryAdvance>.from(
    DemoSeed.salaryAdvances,
  );
  final List<LeaveRequest> _leaveRequests = List<LeaveRequest>.from(
    DemoSeed.leaveRequests,
  );
  final List<SalarySlip> _salarySlips = List<SalarySlip>.from(
    DemoSeed.salarySlips,
  );
  final List<StaffAssignmentProposal> _staffAssignmentProposals =
      List<StaffAssignmentProposal>.from(DemoSeed.staffAssignmentProposals);
  final List<WorkApprovalRequest> _workApprovalRequests =
      List<WorkApprovalRequest>.from(DemoSeed.workApprovalRequests);

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

  List<CarSaleListing> get allSaleListings {
    final listings = _saleListings.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(listings);
  }

  List<CarSaleListing> get saleListings => activeSaleListings;

  List<CarSaleListing> get activeSaleListings {
    final listings =
        _saleListings
            .where((listing) => listing.status == CarSaleStatus.active)
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(listings);
  }

  List<CarSaleListing> get pendingSaleListings {
    final listings =
        _saleListings
            .where((listing) => listing.status == CarSaleStatus.pendingApproval)
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(listings);
  }

  List<CarSaleListing> get soldSaleListings {
    final listings =
        _saleListings
            .where((listing) => listing.status == CarSaleStatus.sold)
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(listings);
  }

  List<StaffProfile> get staffProfiles {
    final staff = _staffProfiles.toList()
      ..sort((left, right) {
        if (left.role != right.role) {
          return left.role.index.compareTo(right.role.index);
        }
        return left.name.compareTo(right.name);
      });
    return List.unmodifiable(staff);
  }

  List<StaffProfile> get masterMechanics => List.unmodifiable(
    _staffProfiles.where((staff) => staff.role == StaffRole.masterMechanic),
  );

  List<StaffProfile> get mechanics => List.unmodifiable(
    _staffProfiles.where((staff) => staff.role == StaffRole.mechanic),
  );

  List<AttendanceEntry> get attendanceEntries {
    final entries = _attendanceEntries.toList()
      ..sort((left, right) => right.loggedAt.compareTo(left.loggedAt));
    return List.unmodifiable(entries);
  }

  List<SalaryAdvance> get salaryAdvances {
    final advances = _salaryAdvances.toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
    return List.unmodifiable(advances);
  }

  List<LeaveRequest> get leaveRequests {
    final requests = _leaveRequests.toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
    return List.unmodifiable(requests);
  }

  List<SalarySlip> get salarySlips {
    final slips = _salarySlips.toList()
      ..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
    return List.unmodifiable(slips);
  }

  List<StaffAssignmentProposal> get staffAssignmentProposals {
    final proposals = _staffAssignmentProposals.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(proposals);
  }

  List<WorkApprovalRequest> get workApprovalRequests {
    final requests = _workApprovalRequests.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(requests);
  }

  CarProfile? get activeCar {
    if (cars.isEmpty) return null;
    return cars.firstWhere((car) => car.isActive, orElse: () => cars.first);
  }

  CarWorkflowState workflowStateForCar(String carId) {
    final job = latestJobForCar(carId);
    return job?.workflowState ?? CarWorkflowState.registered;
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
    _authFlowRevision++;
    isSendingOtp = true;
    isVerifyingOtp = false;
    isLoggingIn = false;
    errorMessage = null;
    requestedPhone = phone;
    generatedOtp = null;
    notifyListeners();

    try {
      final response = await _apiClient.requestOtp(phone);
      generatedOtp = response.devOtp ?? '12345';
    } catch (_) {
      generatedOtp = '12345';
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

    final flowRevision = ++_authFlowRevision;
    isVerifyingOtp = true;
    isLoggingIn = false;
    errorMessage = null;
    notifyListeners();

    AppSession? resolvedSession;
    AppSession? remoteSession;
    try {
      remoteSession = await _apiClient.verifyOtp(requestedPhone!, code);
    } catch (_) {
    } finally {
      isVerifyingOtp = false;
    }
    resolvedSession = _sessionForRequestedPhone(
      requestedPhone!,
      code,
      remoteSession: remoteSession,
    );

    if (flowRevision != _authFlowRevision) {
      notifyListeners();
      return false;
    }

    if (resolvedSession == null) {
      errorMessage =
          'Invalid OTP. Use the development OTP if the backend is offline.';
      notifyListeners();
      return false;
    }

    final existingUser = _users
        .where((user) => user.id == resolvedSession!.user.id)
        .firstOrNull;
    if (existingUser == null) {
      _users.insert(0, resolvedSession.user);
    }

    isLoggingIn = true;
    notifyListeners();
    unawaited(_finishLogin(resolvedSession, flowRevision));
    return true;
  }

  AppSession? _sessionForRequestedPhone(
    String phone,
    String code, {
    AppSession? remoteSession,
  }) {
    final expectedOtp = generatedOtp ?? '12345';
    if (code == expectedOtp) {
      final localUser = userByPhone(phone);
      if (localUser != null) {
        return AppSession(
          user: localUser,
          token: 'demo-${localUser.role.name}-token',
        );
      }
    }

    return remoteSession ?? DemoSeed.sessionForPhone(phone, code);
  }

  Future<void> _finishLogin(
    AppSession resolvedSession,
    int flowRevision,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (flowRevision != _authFlowRevision) return;

    session = resolvedSession;
    isLoggingIn = false;
    notifyListeners();
  }

  void cancelLogin() {
    _authFlowRevision++;
    final hadActiveLogin = isVerifyingOtp || isLoggingIn;
    isVerifyingOtp = false;
    isLoggingIn = false;
    if (hadActiveLogin) notifyListeners();
  }

  void logout() {
    _authFlowRevision++;
    session = null;
    requestedPhone = null;
    generatedOtp = null;
    errorMessage = null;
    isLoggingIn = false;
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

    _insertCarForUser(
      userId: userId,
      carNumber: carNumber,
      model: model,
      fuelType: fuelType,
      year: year,
      imagePath: imagePath,
      isActive: _cars.where((car) => car.userId == userId).isEmpty,
    );
    notifyListeners();
  }

  Future<GarageUser?> createCustomerAccount({
    required String name,
    required String phone,
    String? email,
    required bool dataSharingConsent,
    String? carNumber,
    String? model,
    String? fuelType,
    int? year,
    String? imagePath,
  }) async {
    final normalizedPhone = _normalizeIndianPhoneForStorage(phone);
    final normalizedName = name.trim();
    if (normalizedName.isEmpty ||
        normalizedPhone.length != 10 ||
        !dataSharingConsent ||
        userByPhone(normalizedPhone) != null) {
      return null;
    }

    try {
      await _apiClient.createCustomerAccount(
        name: normalizedName,
        phone: normalizedPhone,
        email: email,
        dataSharingConsent: dataSharingConsent,
        carNumber: carNumber,
        model: model,
        fuelType: fuelType,
        year: year,
      );
    } on CustomerAccountAlreadyExistsException {
      return null;
    } catch (_) {
      // Keep the demo app usable when the backend is offline.
    }

    final now = DateTime.now();
    final user = GarageUser(
      id: 'customer-${now.microsecondsSinceEpoch}',
      name: normalizedName,
      phone: normalizedPhone,
      role: UserRole.customer,
      email: email == null || email.trim().isEmpty ? null : email.trim(),
      dataSharingConsent: dataSharingConsent,
    );
    _users.insert(0, user);

    final normalizedCarNumber = carNumber?.trim().toUpperCase() ?? '';
    final normalizedModel = model?.trim() ?? '';
    if (normalizedCarNumber.isNotEmpty && normalizedModel.isNotEmpty) {
      _insertCarForUser(
        userId: user.id,
        carNumber: normalizedCarNumber,
        model: normalizedModel,
        fuelType: fuelType ?? '',
        year: year ?? now.year,
        imagePath: imagePath,
        isActive: true,
      );
    }

    notifyListeners();
    return user;
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

    _insertCarForUser(
      userId: customerUserId,
      carNumber: normalizedNumber,
      model: model,
      fuelType: fuelType,
      year: year,
      imagePath: imagePath,
      isActive: false,
    );
    notifyListeners();
  }

  void _insertCarForUser({
    required String userId,
    required String carNumber,
    required String model,
    required String fuelType,
    required int year,
    required bool isActive,
    String? imagePath,
  }) {
    final safeYear = _normalizeCarYear(year);
    final normalizedModel = model.trim();
    _cars.insert(
      0,
      CarProfile(
        id: 'car-${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        carNumber: carNumber.trim().toUpperCase(),
        model: normalizedModel,
        fuelType: fuelType.trim().isEmpty ? 'Petrol' : fuelType.trim(),
        year: safeYear,
        isActive: isActive,
        imageUrl: imagePath == null || imagePath.trim().isEmpty
            ? CarMediaService.imageForModel(normalizedModel, year: safeYear)
            : imagePath.trim(),
      ),
    );
  }

  void addSaleListing({
    String? carNumber,
    required String title,
    required String model,
    required String fuelType,
    required int year,
    required double price,
    required int odometerKm,
    required String transmission,
    required String location,
    required String description,
    required List<CarSaleMedia> media,
    bool returnAssurance = false,
    String bodyType = 'SUV',
    String color = 'White',
    List<String> features = const [],
    int seats = 5,
    int ownerCount = 1,
    String rto = 'TS',
    String safetyRating = 'Not rated',
    int discountPercent = 0,
    bool isGarageVerified = false,
  }) {
    final currentSession = session;
    if (currentSession == null) return;

    final isOwnerPost = currentSession.role.isOwner;
    final cleanModel = model.trim().isEmpty ? 'Car for sale' : model.trim();
    final cleanFuel = fuelType.trim().isEmpty ? 'Petrol' : fuelType.trim();
    final cleanMedia = media
        .where((item) => item.path.trim().isNotEmpty)
        .toList(growable: false);
    final normalizedMedia = cleanMedia.isEmpty
        ? [
            CarSaleMedia(
              path: CarMediaService.imageForModel(cleanModel, year: year),
              type: CarSaleMediaType.image,
              caption: 'Listing photo',
            ),
          ]
        : cleanMedia;

    final now = DateTime.now();
    _saleListings.insert(
      0,
      CarSaleListing(
        id: 'sale-${now.millisecondsSinceEpoch}',
        sellerUserId: currentSession.user.id,
        sellerName: currentSession.user.name,
        title: title.trim().isEmpty ? '$year $cleanModel' : title.trim(),
        model: cleanModel,
        fuelType: cleanFuel,
        year: year,
        price: price < 0 ? 0.0 : price,
        odometerKm: odometerKm < 0 ? 0 : odometerKm,
        transmission: transmission.trim().isEmpty
            ? 'Manual'
            : transmission.trim(),
        location: location.trim().isEmpty ? 'Garage' : location.trim(),
        description: description.trim().isEmpty
            ? 'Car listed for sale.'
            : description.trim(),
        media: normalizedMedia,
        createdAt: now,
        status: isOwnerPost
            ? CarSaleStatus.active
            : CarSaleStatus.pendingApproval,
        returnAssurance: returnAssurance,
        bodyType: bodyType.trim().isEmpty ? 'SUV' : bodyType.trim(),
        color: color.trim().isEmpty ? 'White' : color.trim(),
        features: features
            .map((feature) => feature.trim())
            .where((feature) => feature.isNotEmpty)
            .toList(growable: false),
        seats: seats <= 0 ? 5 : seats,
        ownerCount: ownerCount <= 0 ? 1 : ownerCount,
        rto: rto.trim().isEmpty ? 'TS' : rto.trim().toUpperCase(),
        safetyRating: safetyRating.trim().isEmpty
            ? 'Not rated'
            : safetyRating.trim(),
        discountPercent: discountPercent.clamp(0, 100).toInt(),
        carNumber: carNumber == null || carNumber.trim().isEmpty
            ? null
            : carNumber.trim().toUpperCase(),
        contactPhone: currentSession.user.phone,
        postedByOwner: isOwnerPost,
        isGarageVerified: isOwnerPost && (isGarageVerified || isOwnerPost),
      ),
    );

    if (!isOwnerPost) {
      _messages.add(
        SupportMessage(
          id: 'msg-${now.millisecondsSinceEpoch}',
          userId: currentSession.user.id,
          topic: 'Selling',
          message: 'Car submitted for sale approval.',
          createdAt: now,
          channel: ChatChannel.selling,
        ),
      );
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${now.millisecondsSinceEpoch + 1}',
          userId: ownerUser.id,
          title: 'Car submitted for sale',
          message:
              '${currentSession.user.name} submitted ${title.trim().isEmpty ? cleanModel : title.trim()} to Wheels.',
          createdAt: now,
        ),
      );
    }
    notifyListeners();
  }

  void addSaleListingFromCar({
    required String carId,
    required double price,
    required int odometerKm,
    required String transmission,
    required String location,
    required String description,
    required List<CarSaleMedia> media,
    bool returnAssurance = false,
    String bodyType = 'SUV',
    String color = 'White',
    List<String> features = const [],
    int seats = 5,
    int ownerCount = 1,
    String rto = 'TS',
    String safetyRating = 'Not rated',
    int discountPercent = 0,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;

    addSaleListing(
      carNumber: car.carNumber,
      title: '${car.year} ${car.model}',
      model: car.model,
      fuelType: car.fuelType,
      year: car.year,
      price: price,
      odometerKm: odometerKm,
      transmission: transmission,
      location: location,
      description: description,
      media: media.isEmpty
          ? [
              CarSaleMedia(
                path: car.imageUrl,
                type: CarSaleMediaType.image,
                caption: 'Garage listing photo',
              ),
            ]
          : media,
      returnAssurance: returnAssurance,
      bodyType: bodyType,
      color: color,
      features: features,
      seats: seats,
      ownerCount: ownerCount,
      rto: rto,
      safetyRating: safetyRating,
      discountPercent: discountPercent,
      isGarageVerified: true,
    );
  }

  void approveSaleListing(String listingId) {
    final index = _saleListings.indexWhere(
      (listing) => listing.id == listingId,
    );
    if (index == -1) return;
    final listing = _saleListings[index];
    _saleListings[index] = listing.copyWith(
      status: CarSaleStatus.active,
      isGarageVerified: true,
    );

    if (!listing.postedByOwner) {
      sendOwnerMessage(
        customerUserId: listing.sellerUserId,
        topic: 'Selling',
        message: '${listing.title} is approved for Wheels.',
        channel: ChatChannel.selling,
      );
    } else {
      notifyListeners();
    }
  }

  void rejectSaleListing(String listingId) {
    final index = _saleListings.indexWhere(
      (listing) => listing.id == listingId,
    );
    if (index == -1) return;
    final listing = _saleListings[index];
    _saleListings[index] = listing.copyWith(status: CarSaleStatus.rejected);

    if (!listing.postedByOwner) {
      sendOwnerMessage(
        customerUserId: listing.sellerUserId,
        topic: 'Selling',
        message: '${listing.title} was not approved for Wheels.',
        channel: ChatChannel.selling,
      );
    } else {
      notifyListeners();
    }
  }

  void markSaleListingSold(String listingId) {
    final index = _saleListings.indexWhere(
      (listing) => listing.id == listingId,
    );
    if (index == -1) return;
    _saleListings[index] = _saleListings[index].copyWith(
      status: CarSaleStatus.sold,
    );
    notifyListeners();
  }

  void updateSaleListing({
    required String listingId,
    String? carNumber,
    required String title,
    required String model,
    required String fuelType,
    required int year,
    required double price,
    required int odometerKm,
    required String transmission,
    required String location,
    required String description,
    required List<CarSaleMedia> media,
    String bodyType = 'SUV',
    String color = 'White',
    List<String> features = const [],
    int seats = 5,
    int ownerCount = 1,
    String rto = 'TS',
  }) {
    final currentSession = session;
    if (currentSession == null || !currentSession.role.isOwner) return;
    final index = _saleListings.indexWhere(
      (listing) => listing.id == listingId,
    );
    if (index == -1) return;

    final existing = _saleListings[index];
    final cleanModel = model.trim().isEmpty ? existing.model : model.trim();
    final cleanFuel = fuelType.trim().isEmpty
        ? existing.fuelType
        : fuelType.trim();
    final cleanMedia = media
        .where((item) => item.path.trim().isNotEmpty)
        .toList(growable: false);
    final cleanFeatures = features
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toList(growable: false);
    final newPrice = price < 0 ? existing.price : price;
    final priceChanged = newPrice != existing.price;

    _saleListings[index] = existing.copyWith(
      title: title.trim().isEmpty ? existing.title : title.trim(),
      model: cleanModel,
      fuelType: cleanFuel,
      year: year <= 0 ? existing.year : year,
      price: newPrice,
      previousPrice: priceChanged ? existing.price : existing.previousPrice,
      odometerKm: odometerKm < 0 ? existing.odometerKm : odometerKm,
      transmission: transmission.trim().isEmpty
          ? existing.transmission
          : transmission.trim(),
      location: location.trim().isEmpty ? existing.location : location.trim(),
      description: description.trim().isEmpty
          ? existing.description
          : description.trim(),
      media: cleanMedia,
      bodyType: bodyType.trim().isEmpty ? existing.bodyType : bodyType.trim(),
      color: color.trim().isEmpty ? existing.color : color.trim(),
      features: cleanFeatures,
      seats: seats <= 0 ? existing.seats : seats,
      ownerCount: ownerCount <= 0 ? existing.ownerCount : ownerCount,
      rto: rto.trim().isEmpty ? existing.rto : rto.trim().toUpperCase(),
      carNumber: carNumber == null || carNumber.trim().isEmpty
          ? existing.carNumber
          : carNumber.trim().toUpperCase(),
    );
    notifyListeners();
  }

  List<ServiceJob> jobsForCar(String carId) {
    return jobs.where((job) => job.carId == carId).toList()
      ..sort(_compareJobsByRecency);
  }

  ServiceJob? latestJobForCar(String carId) {
    final matches = jobsForCar(carId);
    if (matches.isEmpty) return null;
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

  List<SupportMessage> conversationForUser(
    String userId, {
    String? carId,
    ChatChannel? channel,
  }) {
    final filtered =
        _messages.where((message) {
            if (message.userId != userId) return false;
            if (channel != null && message.channel != channel) return false;
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

  GarageUser? userByPhone(String phone) {
    final normalized = _normalizeIndianPhoneForStorage(phone);
    if (normalized.isEmpty) return null;
    return _users
        .where(
          (user) => _normalizeIndianPhoneForStorage(user.phone) == normalized,
        )
        .firstOrNull;
  }

  GarageUser? customerByPhone(String phone) {
    final normalized = _normalizeIndianPhoneForStorage(phone);
    return customers
        .where(
          (user) => _normalizeIndianPhoneForStorage(user.phone) == normalized,
        )
        .firstOrNull;
  }

  StaffProfile? staffById(String staffId) {
    return _staffProfiles.where((staff) => staff.id == staffId).firstOrNull;
  }

  StaffProfile? staffForUser(String userId) {
    return _staffProfiles.where((staff) => staff.userId == userId).firstOrNull;
  }

  List<ServiceJob> jobsForStaff(String staffId) {
    return jobs
        .where(
          (job) =>
              job.masterMechanicId == staffId ||
              job.mechanicIds.contains(staffId) ||
              job.pickupPersonName == staffById(staffId)?.name,
        )
        .toList()
      ..sort(_compareJobsByRecency);
  }

  List<StaffAssignmentProposal> proposalsForJob(String jobId) {
    return _staffAssignmentProposals
        .where((proposal) => proposal.jobId == jobId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<WorkApprovalRequest> workRequestsForJob(String jobId) {
    return _workApprovalRequests
        .where((request) => request.jobId == jobId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<AttendanceEntry> attendanceForStaff(String staffId) {
    return _attendanceEntries
        .where((entry) => entry.staffId == staffId)
        .toList()
      ..sort((left, right) => right.loggedAt.compareTo(left.loggedAt));
  }

  List<SalaryAdvance> advancesForStaff(String staffId) {
    return _salaryAdvances
        .where((advance) => advance.staffId == staffId)
        .toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
  }

  List<LeaveRequest> leavesForStaff(String staffId) {
    return _leaveRequests.where((leave) => leave.staffId == staffId).toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
  }

  List<SalarySlip> salarySlipsForStaff(String staffId) {
    return _salarySlips.where((slip) => slip.staffId == staffId).toList()
      ..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
  }

  void upsertStaffProfile({
    String? staffId,
    required String name,
    required String phone,
    required StaffRole role,
    required String primarySkill,
    required double monthlySalary,
    bool isActive = true,
  }) {
    final trimmedName = name.trim().isEmpty ? role.label : name.trim();
    final normalizedPhone = _normalizeIndianPhoneForStorage(phone);
    if (staffId != null) {
      final staffIndex = _staffProfiles.indexWhere(
        (staff) => staff.id == staffId,
      );
      if (staffIndex == -1) return;
      final existing = _staffProfiles[staffIndex];
      _staffProfiles[staffIndex] = existing.copyWith(
        name: trimmedName,
        phone: normalizedPhone,
        role: role,
        primarySkill: primarySkill.trim().isEmpty
            ? existing.primarySkill
            : primarySkill.trim(),
        monthlySalary: monthlySalary <= 0
            ? existing.monthlySalary
            : monthlySalary,
        isActive: isActive,
      );
      final userIndex = _users.indexWhere((user) => user.id == existing.userId);
      if (userIndex >= 0) {
        _users[userIndex] = _users[userIndex].copyWith(
          name: trimmedName,
          phone: normalizedPhone,
          role: role.userRole,
        );
      }
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final userId = 'staff-user-${now.millisecondsSinceEpoch}';
    final newUser = GarageUser(
      id: userId,
      name: trimmedName,
      phone: normalizedPhone,
      role: role.userRole,
    );
    final profile = StaffProfile(
      id: 'staff-${now.millisecondsSinceEpoch}',
      userId: userId,
      name: trimmedName,
      phone: normalizedPhone,
      role: role,
      primarySkill: primarySkill.trim().isEmpty
          ? 'General garage work'
          : primarySkill.trim(),
      monthlySalary: monthlySalary < 0 ? 0 : monthlySalary,
      isActive: isActive,
      createdAt: now,
    );
    _users.add(newUser);
    _staffProfiles.add(profile);
    notifyListeners();
  }

  void assignMasterMechanicToJob(String jobId, String masterMechanicId) {
    final staff = staffById(masterMechanicId);
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1 ||
        staff == null ||
        staff.role != StaffRole.masterMechanic) {
      return;
    }
    _jobs[index] = _jobs[index].copyWith(
      masterMechanicId: masterMechanicId,
      status: _jobs[index].status == JobStatus.received
          ? JobStatus.underInspection
          : _jobs[index].status,
    );
    final car = _cars
        .where((item) => item.id == _jobs[index].carId)
        .firstOrNull;
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: staff.userId,
        title: 'Car assigned',
        message:
            '${car?.carNumber ?? 'A vehicle'} is assigned for inspection and job card.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void proposeMechanicTeam({
    required String jobId,
    required String masterMechanicId,
    required List<String> mechanicIds,
  }) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    final master = staffById(masterMechanicId);
    if (job == null ||
        master == null ||
        master.role != StaffRole.masterMechanic ||
        job.masterMechanicId != masterMechanicId) {
      return;
    }
    final cleanMechanicIds = mechanicIds
        .where((id) => staffById(id)?.role == StaffRole.mechanic)
        .toSet()
        .toList();
    if (cleanMechanicIds.isEmpty) return;

    final now = DateTime.now();
    _staffAssignmentProposals.insert(
      0,
      StaffAssignmentProposal(
        id: 'proposal-${now.millisecondsSinceEpoch}',
        jobId: jobId,
        masterMechanicId: masterMechanicId,
        mechanicIds: cleanMechanicIds,
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Mechanic team requested',
        message:
            '${master.name} requested ${cleanMechanicIds.length} mechanics for ${carForJob(job)?.carNumber ?? 'a car'}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void decideMechanicTeamProposal(
    String proposalId,
    RequestStatus decision, {
    String? ownerNote,
  }) {
    final index = _staffAssignmentProposals.indexWhere(
      (proposal) => proposal.id == proposalId,
    );
    if (index == -1 || decision == RequestStatus.pending) return;
    final proposal = _staffAssignmentProposals[index];
    _staffAssignmentProposals[index] = proposal.copyWith(
      status: decision,
      ownerNote: ownerNote,
    );
    if (decision == RequestStatus.approved) {
      final jobIndex = _jobs.indexWhere((job) => job.id == proposal.jobId);
      if (jobIndex >= 0) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(
          mechanicIds: proposal.mechanicIds,
        );
      }
    }
    final master = staffById(proposal.masterMechanicId);
    if (master != null) {
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${DateTime.now().millisecondsSinceEpoch}',
          userId: master.userId,
          title: 'Mechanic team ${decision.label.toLowerCase()}',
          message:
              'Owner ${decision == RequestStatus.approved ? 'approved' : 'rejected'} your mechanic team request.',
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  ServiceDocument? createMasterJobCard({
    required String jobId,
    required String masterMechanicId,
    required String observations,
    required List<DocumentLineItem> items,
    List<VehicleInspectionMark> inspectionMarks = const [],
  }) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    final car = job == null ? null : carForJob(job);
    final customer = car == null ? null : customerForCar(car.id);
    final master = staffById(masterMechanicId);
    if (job == null ||
        car == null ||
        customer == null ||
        master == null ||
        job.masterMechanicId != masterMechanicId ||
        (job.status != JobStatus.pickupDone &&
            job.status != JobStatus.received &&
            job.status != JobStatus.underInspection)) {
      return null;
    }
    final documentItems = [
      ...(items.isEmpty
          ? [
              DocumentLineItem(
                description: observations.trim().isEmpty
                    ? 'Master mechanic inspection'
                    : observations.trim(),
                quantity: 1,
                unitPrice: 0,
                total: 0,
              ),
            ]
          : items),
      ...inspectionMarks.map(
        (mark) => DocumentLineItem(
          description: mark.summary,
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
      ),
    ];

    final document = sendDocument(
      DocumentDraft(
        documentNumber: 'JOB-${DateTime.now().millisecondsSinceEpoch % 10000}',
        type: DocumentType.jobCard,
        customerName: customer.name,
        customerPhone: customer.phone,
        vehicleNumber: car.carNumber,
        carModel: car.model,
        items: documentItems,
        selectedCarId: car.id,
        rawText: observations,
        inspectionMarks: inspectionMarks,
      ),
      customerUserId: customer.id,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Job card prepared',
        message: '${master.name} prepared a job card for ${car.carNumber}.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return document;
  }

  void submitWorkApprovalRequest({
    required String jobId,
    required String staffId,
    required String title,
    required String message,
    String? photoPath,
  }) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    final staff = staffById(staffId);
    if (job == null || staff == null) return;
    final now = DateTime.now();
    _workApprovalRequests.insert(
      0,
      WorkApprovalRequest(
        id: 'work-${now.millisecondsSinceEpoch}',
        jobId: jobId,
        staffId: staffId,
        title: title.trim().isEmpty ? 'Work approval requested' : title.trim(),
        message: message.trim().isEmpty ? 'Approval needed.' : message.trim(),
        photoPath: photoPath,
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Work approval requested',
        message:
            '${staff.name} requested approval for ${carForJob(job)?.carNumber ?? 'a vehicle'}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void decideWorkApprovalRequest(
    String requestId,
    RequestStatus decision, {
    bool forwardToCustomer = false,
    String? ownerResponse,
  }) {
    final index = _workApprovalRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1 || decision == RequestStatus.pending) return;
    final request = _workApprovalRequests[index];
    _workApprovalRequests[index] = request.copyWith(
      status: decision,
      forwardedToCustomer: forwardToCustomer,
      ownerResponse: ownerResponse,
    );
    final job = _jobs.where((item) => item.id == request.jobId).firstOrNull;
    final car = job == null ? null : carForJob(job);
    if (forwardToCustomer && car != null) {
      _messages.add(
        SupportMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          topic: request.title,
          message: request.message,
          createdAt: DateTime.now(),
          carId: car.id,
          attachmentPath: request.photoPath,
          sentByOwner: true,
        ),
      );
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
          userId: car.userId,
          title: 'Approval requested',
          message: request.title,
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void logAttendance({
    required String staffId,
    AttendanceStatus status = AttendanceStatus.present,
    bool faceVerified = true,
    bool locationVerified = true,
    String? note,
  }) {
    final staff = staffById(staffId);
    if (staff == null) return;
    final today = DateTime.now();
    final existingIndex = _attendanceEntries.indexWhere(
      (entry) =>
          entry.staffId == staffId &&
          entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day,
    );
    final entry = AttendanceEntry(
      id: existingIndex == -1
          ? 'att-${today.millisecondsSinceEpoch}'
          : _attendanceEntries[existingIndex].id,
      staffId: staffId,
      date: DateTime(today.year, today.month, today.day),
      status: status,
      loggedAt: today,
      latitude: 17.4484,
      longitude: 78.3915,
      faceVerified: faceVerified,
      locationVerified: locationVerified,
      note: note,
    );
    if (existingIndex == -1) {
      _attendanceEntries.insert(0, entry);
    } else {
      _attendanceEntries[existingIndex] = entry;
    }
    notifyListeners();
  }

  void requestSalaryAdvance({
    required String staffId,
    required double amount,
    required String reason,
  }) {
    final staff = staffById(staffId);
    if (staff == null || amount <= 0) return;
    final now = DateTime.now();
    _salaryAdvances.insert(
      0,
      SalaryAdvance(
        id: 'adv-${now.millisecondsSinceEpoch}',
        staffId: staffId,
        amount: amount,
        reason: reason.trim().isEmpty
            ? 'Salary advance requested'
            : reason.trim(),
        requestedAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Salary advance requested',
        message: '${staff.name} requested ${amount.toStringAsFixed(0)}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void decideSalaryAdvance(
    String advanceId,
    RequestStatus decision, {
    String? ownerNote,
  }) {
    final index = _salaryAdvances.indexWhere(
      (advance) => advance.id == advanceId,
    );
    if (index == -1 || decision == RequestStatus.pending) return;
    _salaryAdvances[index] = _salaryAdvances[index].copyWith(
      status: decision,
      ownerNote: ownerNote,
    );
    notifyListeners();
  }

  void requestLeave({
    required String staffId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) {
    final staff = staffById(staffId);
    if (staff == null) return;
    final now = DateTime.now();
    _leaveRequests.insert(
      0,
      LeaveRequest(
        id: 'leave-${now.millisecondsSinceEpoch}',
        staffId: staffId,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason.trim().isEmpty ? 'Leave requested' : reason.trim(),
        requestedAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Leave requested',
        message: '${staff.name} requested leave.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void decideLeaveRequest(
    String leaveId,
    RequestStatus decision, {
    String? ownerNote,
  }) {
    final index = _leaveRequests.indexWhere((leave) => leave.id == leaveId);
    if (index == -1 || decision == RequestStatus.pending) return;
    _leaveRequests[index] = _leaveRequests[index].copyWith(
      status: decision,
      ownerNote: ownerNote,
    );
    notifyListeners();
  }

  SalarySlip generateSalarySlip(String staffId, String monthLabel) {
    final staff = staffById(staffId);
    if (staff == null) {
      throw StateError('Staff not found.');
    }
    final approvedAdvances = advancesForStaff(staffId)
        .where((advance) => advance.status == RequestStatus.approved)
        .fold<double>(0, (sum, advance) => sum + advance.amount);
    final leaveDeduction =
        leavesForStaff(
          staffId,
        ).where((leave) => leave.status == RequestStatus.approved).length *
        (staff.monthlySalary / 30);
    final netPay = staff.monthlySalary - approvedAdvances - leaveDeduction;
    final slip = SalarySlip(
      id: 'slip-${DateTime.now().millisecondsSinceEpoch}',
      staffId: staffId,
      monthLabel: monthLabel.trim().isEmpty ? 'Current Month' : monthLabel,
      grossPay: staff.monthlySalary,
      advanceDeduction: approvedAdvances,
      leaveDeduction: leaveDeduction,
      netPay: netPay < 0 ? 0 : netPay,
      generatedAt: DateTime.now(),
    );
    _salarySlips.insert(0, slip);
    notifyListeners();
    return slip;
  }

  CarProfile? carForJob(ServiceJob job) {
    return _cars.where((car) => car.id == job.carId).firstOrNull;
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
    if (existing.type == DocumentType.jobCard &&
        decision == ApprovalState.approved &&
        existing.jobId.isNotEmpty) {
      setJobStatus(existing.jobId, JobStatus.workInProgress);
    }
    notifyListeners();
  }

  void advanceJobStatus(String jobId) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null) return;
    if (job.status == JobStatus.pickupDone) return;
    setJobStatus(jobId, job.status.next);
  }

  void setJobStatus(
    String jobId,
    JobStatus status, {
    bool allowPickupDoneReceipt = false,
  }) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    if (_jobs[index].status == JobStatus.pickupDone &&
        status != JobStatus.pickupDone &&
        !(allowPickupDoneReceipt && status == JobStatus.received)) {
      return;
    }
    final startsTransit =
        status == JobStatus.pickupScheduled ||
        status == JobStatus.deliveryScheduled;
    _jobs[index] = _jobs[index].copyWith(
      status: status,
      pickupRequired: startsTransit,
      pickupState: startsTransit
          ? PickupState.requested
          : PickupState.completed,
    );
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

  void assignPickup(
    String jobId, {
    required String personName,
    required String personPhone,
  }) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    final isDelivery =
        job.status == JobStatus.completed ||
        job.status == JobStatus.deliveryScheduled;
    final cleanName = personName.trim().isEmpty
        ? isDelivery
              ? 'Delivery executive'
              : 'Pickup executive'
        : personName.trim();
    final cleanPhone = personPhone.trim();
    final assignedStaff = _staffProfiles
        .where(
          (staff) =>
              staff.role == StaffRole.mechanic &&
              (staff.name.toLowerCase() == cleanName.toLowerCase() ||
                  _normalizeIndianPhoneForStorage(staff.phone) ==
                      _normalizeIndianPhoneForStorage(cleanPhone)),
        )
        .firstOrNull;
    final mechanicIds = {
      ...job.mechanicIds,
      if (assignedStaff != null) assignedStaff.id,
    }.toList();
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupPersonName: cleanName,
      pickupPersonPhone: cleanPhone,
      mechanicIds: mechanicIds,
    );
    if (car != null) {
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          title: isDelivery
              ? 'Delivery person assigned'
              : 'Pickup person assigned',
          message:
              '$cleanName${cleanPhone.isEmpty ? '' : ' ($cleanPhone)'} is assigned for ${car.carNumber}.',
          createdAt: DateTime.now(),
        ),
      );
      _messages.add(
        SupportMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          topic: isDelivery ? 'Delivery' : 'Pickup',
          message:
              '${isDelivery ? 'Delivery' : 'Pickup'} assigned to $cleanName${cleanPhone.isEmpty ? '' : ' ($cleanPhone)'}. Scheduled at ${_formatWhatsappDate(_jobs[index].pickupTime)}.',
          createdAt: DateTime.now(),
          carId: car.id,
          sentByOwner: true,
        ),
      );
    }
    notifyListeners();
  }

  void requestPickupForCar(
    String carId, {
    required DateTime pickupTime,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupMapUrl,
    String? pickupPhotoPath,
    required bool locationAccessGranted,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final cleanAddress = pickupAddress?.trim();
    final cleanPhotoPath = pickupPhotoPath?.trim();
    final resolvedMapUrl = pickupMapUrl?.trim().isNotEmpty == true
        ? pickupMapUrl!.trim()
        : pickupLatitude != null && pickupLongitude != null
        ? GoogleMapsLinkService.mapUrlForCoordinates(
            latitude: pickupLatitude,
            longitude: pickupLongitude,
          )
        : null;
    final existingIndex = _jobs.indexWhere(
      (job) => job.carId == carId && job.status != JobStatus.onRoad,
    );
    final isDeliveryRequest =
        existingIndex >= 0 &&
        (_jobs[existingIndex].status == JobStatus.completed ||
            _jobs[existingIndex].status == JobStatus.deliveryScheduled);
    if (existingIndex >= 0) {
      _jobs[existingIndex] = _jobs[existingIndex].copyWith(
        pickupRequired: true,
        pickupState: PickupState.requested,
        pickupTime: pickupTime,
        pickupAddress: cleanAddress == null || cleanAddress.isEmpty
            ? null
            : cleanAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        pickupMapUrl: resolvedMapUrl,
        pickupPhotoPath: cleanPhotoPath == null || cleanPhotoPath.isEmpty
            ? null
            : cleanPhotoPath,
        locationAccessGranted: locationAccessGranted,
        status: isDeliveryRequest
            ? JobStatus.deliveryScheduled
            : JobStatus.pickupScheduled,
      );
    } else {
      _jobs.insert(
        0,
        ServiceJob(
          id: 'job-${DateTime.now().millisecondsSinceEpoch}',
          userId: car.userId,
          carId: car.id,
          status: JobStatus.pickupScheduled,
          expectedCompletion: DateTime.now().add(const Duration(days: 1)),
          pickupTime: pickupTime,
          pickupRequired: true,
          pickupState: PickupState.requested,
          pickupAddress: cleanAddress == null || cleanAddress.isEmpty
              ? null
              : cleanAddress,
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
          pickupMapUrl: resolvedMapUrl,
          pickupPhotoPath: cleanPhotoPath == null || cleanPhotoPath.isEmpty
              ? null
              : cleanPhotoPath,
          locationAccessGranted: locationAccessGranted,
        ),
      );
    }

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: ownerUser.id,
        title: isDeliveryRequest
            ? 'Delivery requested'
            : 'Pickup and drop requested',
        message:
            '${car.carNumber} requested ${isDeliveryRequest ? 'delivery' : 'pickup'} for ${_formatWhatsappDate(pickupTime)}.',
        createdAt: DateTime.now(),
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
        userId: car.userId,
        title: isDeliveryRequest
            ? 'Delivery requested'
            : 'Pickup and drop requested',
        message:
            '${isDeliveryRequest ? 'Delivery' : 'Pickup and drop'} is requested for ${car.carNumber} at ${_formatWhatsappDate(pickupTime)}.',
        createdAt: DateTime.now(),
      ),
    );
    _messages.add(
      SupportMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        userId: car.userId,
        topic: isDeliveryRequest ? 'Delivery' : 'Pickup and drop',
        message:
            '${isDeliveryRequest ? 'Delivery' : 'Pickup'} requested for ${_formatWhatsappDate(pickupTime)}'
            '${cleanAddress == null || cleanAddress.isEmpty ? '' : ' at $cleanAddress'}'
            '${resolvedMapUrl == null ? '' : '. Map: $resolvedMapUrl'}.',
        createdAt: DateTime.now(),
        carId: car.id,
        attachmentPath: cleanPhotoPath == null || cleanPhotoPath.isEmpty
            ? null
            : cleanPhotoPath,
      ),
    );
    notifyListeners();
  }

  void completePickup(String jobId, {String? proofImagePath}) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final car = _cars
        .where((item) => item.id == _jobs[index].carId)
        .firstOrNull;
    final isDelivery =
        _jobs[index].status == JobStatus.completed ||
        _jobs[index].status == JobStatus.deliveryScheduled;
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: false,
      pickupState: PickupState.completed,
      status: isDelivery ? JobStatus.onRoad : JobStatus.pickupDone,
    );
    if (car != null) {
      if (proofImagePath != null && proofImagePath.trim().isNotEmpty) {
        _photoUpdates.insert(
          0,
          GaragePhotoUpdate(
            id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
            userId: car.userId,
            carId: car.id,
            imagePath: proofImagePath.trim(),
            caption: isDelivery
                ? 'Delivery completed and vehicle handed over.'
                : 'Pickup completed and vehicle received at garage.',
            createdAt: DateTime.now(),
          ),
        );
      }
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${DateTime.now().millisecondsSinceEpoch + 1}',
          userId: car.userId,
          title: isDelivery ? 'Delivery completed' : 'Pickup completed',
          message: isDelivery
              ? '${car.carNumber} is back on road.'
              : '${car.carNumber} has been received by the garage.',
          createdAt: DateTime.now(),
        ),
      );
      _messages.add(
        SupportMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch + 2}',
          userId: car.userId,
          topic: isDelivery ? 'Delivery' : 'Pickup',
          message: isDelivery
              ? '${car.carNumber} delivery is complete. Vehicle is back on road.'
              : '${car.carNumber} pickup is complete. Vehicle is now at the garage.',
          createdAt: DateTime.now(),
          carId: car.id,
          sentByOwner: true,
          attachmentPath: proofImagePath,
        ),
      );
    }
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
    JobStatus? status,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final now = DateTime.now();
    final latestJob = latestJobForCar(carId);
    final jobIndex = latestJob == null
        ? -1
        : _jobs.indexWhere((job) => job.id == latestJob.id);
    final effectiveStatus =
        status != null &&
            jobIndex >= 0 &&
            _jobs[jobIndex].status != JobStatus.pickupDone
        ? status
        : null;
    if (effectiveStatus != null && jobIndex >= 0) {
      _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: effectiveStatus);
    }

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
        title: effectiveStatus == null
            ? 'New garage photos'
            : 'Status photo update',
        message: effectiveStatus == null
            ? 'Fresh progress photos were added for ${car.carNumber}.'
            : '${car.carNumber} is now ${effectiveStatus.label} with a photo update.',
        createdAt: now,
      ),
    );
    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch + 2}',
        userId: car.userId,
        topic: effectiveStatus == null
            ? 'Garage photos'
            : effectiveStatus.label,
        message: caption.trim().isEmpty
            ? 'Photo update shared from the garage.'
            : caption.trim(),
        createdAt: now,
        carId: car.id,
        attachmentPath: imagePath,
        sentByOwner: true,
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
      inspectionMarks: draft.inspectionMarks,
      approvalState: draft.type == DocumentType.invoice
          ? ApprovalState.approved
          : ApprovalState.pending,
      paymentState: PaymentState.pending,
      createdAt: now,
      updatedAt: now,
      pdfLabel: '${draft.type.label} PDF',
    );
    _documents.insert(0, document);
    if (relatedJob != null) {
      switch (draft.type) {
        case DocumentType.quotation:
        case DocumentType.estimation:
          if (relatedJob.status == JobStatus.received) {
            setJobStatus(relatedJob.id, JobStatus.underInspection);
          }
          break;
        case DocumentType.jobCard:
          if (relatedJob.status == JobStatus.pickupDone) {
            setJobStatus(
              relatedJob.id,
              JobStatus.received,
              allowPickupDoneReceipt: true,
            );
          } else if (relatedJob.status == JobStatus.received ||
              relatedJob.status == JobStatus.underInspection) {
            setJobStatus(relatedJob.id, JobStatus.underInspection);
          }
          break;
        case DocumentType.invoice:
          if (relatedJob.status == JobStatus.workInProgress) {
            setJobStatus(relatedJob.id, JobStatus.completed);
          }
          break;
      }
    }

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
    unawaited(
      _apiClient
          .createCustomerAccount(
            name: user.name,
            phone: user.phone,
            dataSharingConsent: true,
            carNumber: draft.vehicleNumber.trim(),
            model: draft.carModel.trim(),
          )
          .catchError((_) {}),
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
    ChatChannel channel = ChatChannel.general,
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
        channel: channel,
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
    ChatChannel channel = ChatChannel.general,
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
        channel: channel,
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

  void sendDocumentInChat(
    ServiceDocument document, {
    String? attachmentPath,
    ChatChannel channel = ChatChannel.general,
  }) {
    final car = _cars.where((item) => item.id == document.carId).firstOrNull;
    final customerId = car?.userId ?? document.userId;
    if (customerId.isEmpty) return;

    sendOwnerMessage(
      customerUserId: customerId,
      topic: document.type.label,
      message:
          '${document.type.label} ${document.title} shared. Total: ${document.total.toStringAsFixed(0)}. PDF attached for WhatsApp sharing.',
      channel: channel,
      carId: document.carId.isEmpty ? null : document.carId,
      attachmentPath: attachmentPath,
    );
  }

  bool sendBuyingInterest(CarSaleListing listing) {
    final currentSession = session;
    if (currentSession == null || currentSession.role.isOwner) return false;
    final now = DateTime.now();
    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch}',
        userId: currentSession.user.id,
        topic: listing.title,
        message: 'Im Intrested',
        createdAt: now,
        channel: ChatChannel.buying,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 1}',
        userId: ownerUser.id,
        title: 'Buying enquiry',
        message:
            '${currentSession.user.name} is interested in ${listing.title}.',
        createdAt: now,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.millisecondsSinceEpoch + 2}',
        userId: currentSession.user.id,
        title: 'Interest sent',
        message: 'Your interest in ${listing.title} has been sent.',
        createdAt: now,
      ),
    );
    notifyListeners();
    return true;
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

  int unreadIncomingCountForCustomer(
    String customerUserId, {
    ChatChannel? channel,
  }) {
    return _messages
        .where(
          (message) =>
              message.userId == customerUserId &&
              (channel == null || message.channel == channel) &&
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

  void deleteDocument(String documentId) {
    _documents.removeWhere((document) => document.id == documentId);
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
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupMapUrl,
    String? pickupPhotoPath,
    required bool locationAccessGranted,
  }) {
    final cleanMapUrl = pickupMapUrl?.trim().isNotEmpty == true
        ? pickupMapUrl!.trim()
        : pickupLatitude != null && pickupLongitude != null
        ? GoogleMapsLinkService.mapUrlForCoordinates(
            latitude: pickupLatitude,
            longitude: pickupLongitude,
          )
        : null;
    final cleanPhotoPath = pickupPhotoPath?.trim();
    return 'FLYWHEELS AUTO pickup request\n'
        'Vehicle: ${car.carNumber}\n'
        'Model: ${car.model}\n'
        'Pickup time: ${_formatWhatsappDate(pickupTime)}\n'
        '${pickupAddress == null || pickupAddress.isEmpty ? '' : 'Address: $pickupAddress\n'}'
        '${cleanMapUrl == null ? '' : 'Google Maps: $cleanMapUrl\n'}'
        'Location access: ${locationAccessGranted ? 'Approved' : 'Not approved'}'
        '${cleanPhotoPath == null || cleanPhotoPath.isEmpty ? '' : '\nPickup car photo: attached in app'}';
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

  int _normalizeCarYear(int year) {
    final currentYear = DateTime.now().year;
    if (year < 1980 || year > currentYear + 1) {
      return currentYear;
    }
    return year;
  }

  int _compareJobsByRecency(ServiceJob left, ServiceJob right) {
    if (left.status != JobStatus.onRoad && right.status == JobStatus.onRoad) {
      return -1;
    }
    if (left.status == JobStatus.onRoad && right.status != JobStatus.onRoad) {
      return 1;
    }
    return _jobRecency(right).compareTo(_jobRecency(left));
  }

  DateTime _jobRecency(ServiceJob job) {
    return job.pickupTime.isAfter(job.expectedCompletion)
        ? job.pickupTime
        : job.expectedCompletion;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

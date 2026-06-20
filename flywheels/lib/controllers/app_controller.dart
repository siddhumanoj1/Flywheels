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
  final List<MechanicWorkTask> _workTasks = List<MechanicWorkTask>.from(
    DemoSeed.workTasks,
  );
  final List<ApprovalRequest> _approvalRequests = List<ApprovalRequest>.from(
    DemoSeed.approvalRequests,
  );
  final List<ProgressUpdate> _progressUpdates = List<ProgressUpdate>.from(
    DemoSeed.progressUpdates,
  );
  final List<StaffAttendance> _attendanceRecords = List<StaffAttendance>.from(
    DemoSeed.attendanceRecords,
  );
  final List<LeaveRequest> _leaveRequests = List<LeaveRequest>.from(
    DemoSeed.leaveRequests,
  );
  final List<StaffAdvance> _advances = List<StaffAdvance>.from(
    DemoSeed.advances,
  );
  final List<SalaryRecord> _salaryRecords = List<SalaryRecord>.from(
    DemoSeed.salaryRecords,
  );
  final List<StaffDocument> _staffDocuments = List<StaffDocument>.from(
    DemoSeed.staffDocuments,
  );
  final List<CarTimelineEvent> _timelineEvents = List<CarTimelineEvent>.from(
    DemoSeed.timelineEvents,
  );

  GarageUser get ownerUser => _users.firstWhere(
    (user) => user.role == UserRole.owner,
    orElse: () => DemoSeed.ownerUser,
  );

  List<GarageUser> get customers =>
      List.unmodifiable(_users.where((user) => user.role == UserRole.customer));

  List<GarageUser> get staffUsers =>
      List.unmodifiable(_users.where((user) => user.role.isStaff));

  List<StaffProfile> get staffProfiles {
    final profiles = _staffProfiles.toList()
      ..sort((left, right) {
        final roleOrder = left.role == right.role
            ? 0
            : left.role.isMasterMechanic
            ? -1
            : 1;
        if (roleOrder != 0) return roleOrder;
        return left.name.compareTo(right.name);
      });
    return List.unmodifiable(profiles);
  }

  List<StaffProfile> get activeStaffProfiles =>
      List.unmodifiable(staffProfiles.where((profile) => profile.isActive));

  List<StaffProfile> get masterMechanicProfiles => List.unmodifiable(
    staffProfiles.where((profile) => profile.role == UserRole.masterMechanic),
  );

  List<StaffProfile> get mechanicProfiles => List.unmodifiable(
    staffProfiles.where((profile) => profile.role == UserRole.mechanic),
  );

  List<CarProfile> get cars {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_cars);
    if (session!.role.isStaff) {
      final carIds = _jobs
          .where((job) => _jobVisibleToStaff(job, userId))
          .map((job) => job.carId)
          .toSet();
      return List.unmodifiable(_cars.where((car) => carIds.contains(car.id)));
    }
    return List.unmodifiable(_cars.where((car) => car.userId == userId));
  }

  List<ServiceJob> get jobs {
    final userId = session?.user.id;
    if (userId == null) return const [];
    if (session!.role.isOwner) return List.unmodifiable(_jobs);
    if (session!.role.isStaff) {
      return List.unmodifiable(
        _jobs.where((job) => _jobVisibleToStaff(job, userId)),
      );
    }
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
    if (session!.role.isStaff) {
      final jobIds = jobs.map((job) => job.id).toSet();
      return List.unmodifiable(
        _documents.where((document) => jobIds.contains(document.jobId)),
      );
    }
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
    if (session!.role.isStaff) {
      final carIds = cars.map((car) => car.id).toSet();
      return List.unmodifiable(
        _photoUpdates.where((update) => carIds.contains(update.carId)),
      );
    }
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

  List<MechanicWorkTask> get workTasks {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_workTasks);
    if (currentSession.role.isMasterMechanic) {
      return List.unmodifiable(
        _workTasks.where(
          (task) => task.masterMechanicId == currentSession.user.id,
        ),
      );
    }
    if (currentSession.role.isMechanic) {
      return List.unmodifiable(
        _workTasks.where((task) => task.mechanicId == currentSession.user.id),
      );
    }
    return const [];
  }

  List<ApprovalRequest> get approvalRequests {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) {
      return List.unmodifiable(_approvalRequests);
    }
    if (currentSession.role.isCustomer) {
      final carIds = _cars
          .where((car) => car.userId == currentSession.user.id)
          .map((car) => car.id)
          .toSet();
      return List.unmodifiable(
        _approvalRequests.where(
          (request) =>
              request.forwardedToCustomer && carIds.contains(request.carId),
        ),
      );
    }
    return List.unmodifiable(
      _approvalRequests.where((request) {
        if (request.requesterId == currentSession.user.id) return true;
        final job = _jobs.where((item) => item.id == request.jobId).firstOrNull;
        return job != null && _jobVisibleToStaff(job, currentSession.user.id);
      }),
    );
  }

  List<ApprovalRequest> get pendingApprovalRequests => List.unmodifiable(
    approvalRequests.where(
      (request) => request.status == ApprovalState.pending,
    ),
  );

  List<ProgressUpdate> get progressUpdates {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_progressUpdates);
    if (currentSession.role.isCustomer) {
      final carIds = _cars
          .where((car) => car.userId == currentSession.user.id)
          .map((car) => car.id)
          .toSet();
      return List.unmodifiable(
        _progressUpdates.where(
          (update) =>
              update.forwardedToCustomer && carIds.contains(update.carId),
        ),
      );
    }
    return List.unmodifiable(
      _progressUpdates.where((update) {
        if (update.senderId == currentSession.user.id) return true;
        final job = _jobs.where((item) => item.id == update.jobId).firstOrNull;
        return job != null && _jobVisibleToStaff(job, currentSession.user.id);
      }),
    );
  }

  List<ProgressUpdate> get pendingStaffUpdates => List.unmodifiable(
    _progressUpdates.where(
      (update) => !update.forwardedToCustomer && !update.keptInternal,
    ),
  );

  List<StaffAttendance> get attendanceRecords {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) {
      return List.unmodifiable(_attendanceRecords);
    }
    if (currentSession.role.isStaff) {
      return List.unmodifiable(
        _attendanceRecords.where(
          (record) => record.staffUserId == currentSession.user.id,
        ),
      );
    }
    return const [];
  }

  List<LeaveRequest> get leaveRequests {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_leaveRequests);
    if (currentSession.role.isStaff) {
      return List.unmodifiable(
        _leaveRequests.where(
          (request) => request.staffUserId == currentSession.user.id,
        ),
      );
    }
    return const [];
  }

  List<StaffAdvance> get advances {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_advances);
    if (currentSession.role.isStaff) {
      return List.unmodifiable(
        _advances.where(
          (advance) => advance.staffUserId == currentSession.user.id,
        ),
      );
    }
    return const [];
  }

  List<SalaryRecord> get salaryRecords {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_salaryRecords);
    if (currentSession.role.isStaff) {
      return List.unmodifiable(
        _salaryRecords.where(
          (record) => record.staffUserId == currentSession.user.id,
        ),
      );
    }
    return const [];
  }

  List<StaffDocument> get staffDocuments {
    final currentSession = session;
    if (currentSession == null) return const [];
    if (currentSession.role.isOwner) return List.unmodifiable(_staffDocuments);
    if (currentSession.role.isStaff) {
      return List.unmodifiable(
        _staffDocuments.where(
          (document) => document.staffUserId == currentSession.user.id,
        ),
      );
    }
    return const [];
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
    try {
      final remoteSession = await _apiClient.verifyOtp(requestedPhone!, code);
      resolvedSession =
          remoteSession ?? DemoSeed.sessionForPhone(requestedPhone!, code);
    } catch (_) {
      resolvedSession = DemoSeed.sessionForPhone(requestedPhone!, code);
    } finally {
      isVerifyingOtp = false;
    }

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

  GarageUser? customerByPhone(String phone) {
    final normalized = _normalizeIndianPhoneForStorage(phone);
    return customers
        .where(
          (user) => _normalizeIndianPhoneForStorage(user.phone) == normalized,
        )
        .firstOrNull;
  }

  StaffProfile? staffProfileForUser(String userId) {
    return _staffProfiles
        .where((profile) => profile.userId == userId)
        .firstOrNull;
  }

  String staffName(String? userId) {
    if (userId == null || userId.isEmpty) return 'Not assigned';
    final profile = staffProfileForUser(userId);
    return profile?.name ?? userById(userId)?.name ?? 'Staff member';
  }

  List<StaffProfile> mechanicsUnderMaster(String masterMechanicId) {
    return mechanicProfiles
        .where((profile) => profile.masterMechanicId == masterMechanicId)
        .toList();
  }

  List<ServiceJob> jobsForStaff(String staffUserId) {
    return _jobs.where((job) => _jobVisibleToStaff(job, staffUserId)).toList()
      ..sort(_compareJobsByRecency);
  }

  List<MechanicWorkTask> tasksForJob(String jobId) {
    return _workTasks.where((task) => task.jobId == jobId).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  List<MechanicWorkTask> tasksForMechanic(String mechanicUserId) {
    return _workTasks
        .where((task) => task.mechanicId == mechanicUserId)
        .toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  List<ApprovalRequest> approvalRequestsForJob(String jobId) {
    return approvalRequests.where((request) => request.jobId == jobId).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  List<ProgressUpdate> progressUpdatesForJob(String jobId) {
    return progressUpdates.where((update) => update.jobId == jobId).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<StaffAttendance> attendanceForStaff(String staffUserId) {
    return _attendanceRecords
        .where((record) => record.staffUserId == staffUserId)
        .toList()
      ..sort((left, right) => right.date.compareTo(left.date));
  }

  StaffAttendance? todayAttendanceForStaff(String staffUserId) {
    final now = DateTime.now();
    return _attendanceRecords
        .where(
          (record) =>
              record.staffUserId == staffUserId &&
              record.date.year == now.year &&
              record.date.month == now.month &&
              record.date.day == now.day,
        )
        .firstOrNull;
  }

  List<LeaveRequest> leaveRequestsForStaff(String staffUserId) {
    return _leaveRequests
        .where((request) => request.staffUserId == staffUserId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<StaffAdvance> advancesForStaff(String staffUserId) {
    return _advances
        .where((advance) => advance.staffUserId == staffUserId)
        .toList()
      ..sort((left, right) => right.date.compareTo(left.date));
  }

  List<SalaryRecord> salaryRecordsForStaff(String staffUserId) {
    return _salaryRecords
        .where((record) => record.staffUserId == staffUserId)
        .toList()
      ..sort((left, right) => right.generatedAt.compareTo(left.generatedAt));
  }

  List<StaffDocument> staffDocumentsForStaff(String staffUserId) {
    return _staffDocuments
        .where((document) => document.staffUserId == staffUserId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<CarTimelineEvent> timelineForCar(String carId) {
    final currentSession = session;
    var audience = TimelineAudience.owner;
    if (currentSession?.role.isCustomer ?? false) {
      audience = TimelineAudience.customer;
    } else if (currentSession?.role.isStaff ?? false) {
      audience = TimelineAudience.staff;
    }
    return _timelineEvents
        .where(
          (event) => event.carId == carId && event.audiences.contains(audience),
        )
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  int workloadCountForStaff(String staffUserId) {
    final pickupJobs = _jobs
        .where(
          (job) =>
              job.pickupMechanicId == staffUserId &&
              job.status != JobStatus.onRoad,
        )
        .length;
    final assignedJobs = _jobs
        .where(
          (job) =>
              job.masterMechanicId == staffUserId ||
              job.assignedMechanicIds.contains(staffUserId),
        )
        .length;
    final activeTasks = _workTasks
        .where(
          (task) =>
              task.mechanicId == staffUserId &&
              task.status != WorkTaskStatus.reviewed,
        )
        .length;
    return pickupJobs + assignedJobs + activeTasks;
  }

  void createStaffProfile({
    required String name,
    required String phone,
    required UserRole role,
    required double salary,
    required DateTime joiningDate,
    required String emergencyContact,
    required String address,
    required String skillNotes,
    String? masterMechanicId,
  }) {
    if (!role.isStaff || name.trim().isEmpty || phone.trim().isEmpty) return;
    final now = DateTime.now();
    final user = GarageUser(
      id: 'staff-user-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      phone: _normalizeIndianPhoneForStorage(phone),
      role: role,
    );
    _users.insert(0, user);
    _staffProfiles.insert(
      0,
      StaffProfile(
        id: 'staff-${now.microsecondsSinceEpoch}',
        userId: user.id,
        name: user.name,
        phone: user.phone,
        role: role,
        salary: salary < 0 ? 0 : salary,
        joiningDate: joiningDate,
        emergencyContact: emergencyContact.trim(),
        address: address.trim(),
        skillNotes: skillNotes.trim(),
        workStatus: StaffWorkStatus.free,
        isActive: true,
        masterMechanicId: role == UserRole.mechanic ? masterMechanicId : null,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${now.microsecondsSinceEpoch}',
        userId: ownerUser.id,
        title: 'Staff profile created',
        message: '${user.name} was added as ${role.label}.',
        createdAt: now,
      ),
    );
    notifyListeners();
  }

  void updateStaffProfile({
    required String staffUserId,
    required String name,
    required String phone,
    required UserRole role,
    required double salary,
    required DateTime joiningDate,
    required String emergencyContact,
    required String address,
    required String skillNotes,
    required bool isActive,
    String? masterMechanicId,
  }) {
    if (!role.isStaff || name.trim().isEmpty || phone.trim().isEmpty) return;
    final index = _staffProfiles.indexWhere(
      (profile) => profile.userId == staffUserId,
    );
    if (index == -1) return;
    final cleanPhone = _normalizeIndianPhoneForStorage(phone);
    _staffProfiles[index] = _staffProfiles[index].copyWith(
      name: name.trim(),
      phone: cleanPhone,
      role: role,
      salary: salary < 0 ? 0 : salary,
      joiningDate: joiningDate,
      emergencyContact: emergencyContact.trim(),
      address: address.trim(),
      skillNotes: skillNotes.trim(),
      isActive: isActive,
      workStatus: isActive
          ? _staffProfiles[index].workStatus
          : StaffWorkStatus.inactive,
      masterMechanicId: role == UserRole.mechanic ? masterMechanicId : null,
    );
    final userIndex = _users.indexWhere((user) => user.id == staffUserId);
    if (userIndex >= 0) {
      _users[userIndex] = _users[userIndex].copyWith(
        name: name.trim(),
        phone: cleanPhone,
        role: role,
      );
    }
    if (session?.user.id == staffUserId && userIndex >= 0) {
      session = session!.copyWith(user: _users[userIndex]);
    }
    notifyListeners();
  }

  void setStaffActive(String staffUserId, bool isActive) {
    final index = _staffProfiles.indexWhere(
      (profile) => profile.userId == staffUserId,
    );
    if (index == -1) return;
    _staffProfiles[index] = _staffProfiles[index].copyWith(
      isActive: isActive,
      workStatus: isActive ? StaffWorkStatus.free : StaffWorkStatus.inactive,
    );
    notifyListeners();
  }

  void assignPickupMechanic(String jobId, String mechanicUserId) {
    final mechanic = staffProfileForUser(mechanicUserId);
    if (mechanic == null || mechanic.role != UserRole.mechanic) return;
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    final now = DateTime.now();
    _jobs[index] = job.copyWith(
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupMechanicId: mechanic.userId,
      pickupPersonName: mechanic.name,
      pickupPersonPhone: mechanic.phone,
    );
    _setStaffWorkStatus(mechanic.userId, StaffWorkStatus.onPickup);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Pickup mechanic assigned',
        message: '${mechanic.name} is assigned for ${car.carNumber}.',
        createdAt: now,
      );
      _notify(
        userId: mechanic.userId,
        title: 'Pickup assigned',
        message: '${car.carNumber} pickup is assigned to you.',
        createdAt: now,
      );
      _notify(
        userId: car.userId,
        title: 'Pickup mechanic assigned',
        message:
            '${mechanic.name} (${mechanic.phone}) will pick up ${car.carNumber}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void markPickupDone(String jobId, {String? proofImagePath}) {
    completePickup(jobId, proofImagePath: proofImagePath);
  }

  void markCarReceived(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final now = DateTime.now();
    _jobs[index] = _jobs[index].copyWith(
      status: JobStatus.received,
      pickupRequired: false,
      pickupState: PickupState.completed,
    );
    final car = _cars
        .where((item) => item.id == _jobs[index].carId)
        .firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: jobId,
        title: 'Car received',
        message: '${car.carNumber} is accepted at the garage.',
        createdAt: now,
        audiences: const [TimelineAudience.owner, TimelineAudience.staff],
      );
      _notify(
        userId: ownerUser.id,
        title: 'Car received',
        message: '${car.carNumber} is ready for Master Mechanic assignment.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void assignMasterMechanic(String jobId, String masterMechanicId) {
    final master = staffProfileForUser(masterMechanicId);
    if (master == null || master.role != UserRole.masterMechanic) return;
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    if (job.status != JobStatus.received &&
        job.status != JobStatus.underInspection &&
        job.status != JobStatus.workInProgress) {
      return;
    }
    final now = DateTime.now();
    _jobs[index] = job.copyWith(masterMechanicId: master.userId);
    _setStaffWorkStatus(master.userId, StaffWorkStatus.assigned);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Master Mechanic assigned',
        message: '${master.name} is assigned for inspection and job card.',
        createdAt: now,
      );
      _notify(
        userId: master.userId,
        title: 'Car assigned',
        message: '${car.carNumber} is assigned to you.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void startInspection(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    final now = DateTime.now();
    _jobs[index] = job.copyWith(status: JobStatus.underInspection);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Inspection started',
        message: '${car.carNumber} is Under Inspection.',
        createdAt: now,
      );
      _notify(
        userId: ownerUser.id,
        title: 'Inspection started',
        message: '${staffName(job.masterMechanicId)} started ${car.carNumber}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  ServiceDocument? prepareJobCard({
    required String jobId,
    required String complaint,
    required String inspectionNotes,
    required List<DocumentLineItem> labourItems,
    required List<DocumentLineItem> partsItems,
    required DateTime expectedCompletion,
    required String remarks,
    List<String> photoPaths = const [],
  }) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return null;
    final job = _jobs[index];
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car == null) return null;
    final now = DateTime.now();
    final items = [
      DocumentLineItem(
        description:
            'Complaint: ${complaint.trim().isEmpty ? job.customerConcern : complaint.trim()}',
        quantity: 1,
        unitPrice: 0,
        total: 0,
      ),
      DocumentLineItem(
        description: 'Inspection notes: ${inspectionNotes.trim()}',
        quantity: 1,
        unitPrice: 0,
        total: 0,
      ),
      ...labourItems,
      ...partsItems,
      if (remarks.trim().isNotEmpty)
        DocumentLineItem(
          description: 'Remarks: ${remarks.trim()}',
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
    ];
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final document = ServiceDocument(
      id: 'doc-${now.microsecondsSinceEpoch}',
      userId: car.userId,
      carId: car.id,
      jobId: job.id,
      type: DocumentType.jobCard,
      title: 'JOB-${now.millisecondsSinceEpoch.toString().substring(7)}',
      items: items,
      total: total,
      approvalState: ApprovalState.pending,
      paymentState: PaymentState.pending,
      createdAt: now,
      updatedAt: now,
      pdfLabel: 'Job card PDF',
    );
    _documents.insert(0, document);
    _jobs[index] = job.copyWith(
      status: JobStatus.underInspection,
      expectedCompletion: expectedCompletion,
      customerConcern: complaint.trim().isEmpty
          ? job.customerConcern
          : complaint.trim(),
    );
    for (final photoPath in photoPaths.where(
      (path) => path.trim().isNotEmpty,
    )) {
      _photoUpdates.insert(
        0,
        GaragePhotoUpdate(
          id: 'photo-${now.microsecondsSinceEpoch}-${_photoUpdates.length}',
          userId: car.userId,
          carId: car.id,
          imagePath: photoPath.trim(),
          caption: 'Inspection photo for ${document.title}',
          createdAt: now,
        ),
      );
    }
    _addTimelineEvent(
      carId: car.id,
      jobId: job.id,
      title: 'Job card sent for approval',
      message:
          '${document.title} was sent for approval. Estimate ${document.total.toStringAsFixed(0)}.',
      createdAt: now,
    );
    _notify(
      userId: car.userId,
      title: 'Job card needs approval',
      message: '${document.title} is ready for ${car.carNumber}.',
      createdAt: now,
    );
    _notify(
      userId: ownerUser.id,
      title: 'Job card prepared',
      message: '${staffName(job.masterMechanicId)} prepared ${document.title}.',
      createdAt: now,
    );
    notifyListeners();
    return document;
  }

  void assignMechanicTask({
    required String jobId,
    required String mechanicUserId,
    required String title,
    required String instructions,
  }) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    final mechanic = staffProfileForUser(mechanicUserId);
    if (index == -1 || mechanic == null || mechanic.role != UserRole.mechanic) {
      return;
    }
    final job = _jobs[index];
    if (job.status != JobStatus.workInProgress) return;
    final now = DateTime.now();
    final assigned = {...job.assignedMechanicIds, mechanic.userId}.toList();
    _jobs[index] = job.copyWith(assignedMechanicIds: assigned);
    _workTasks.insert(
      0,
      MechanicWorkTask(
        id: 'task-${now.microsecondsSinceEpoch}',
        jobId: job.id,
        carId: job.carId,
        masterMechanicId: job.masterMechanicId ?? session?.user.id ?? '',
        mechanicId: mechanic.userId,
        title: title.trim().isEmpty ? 'Garage work' : title.trim(),
        instructions: instructions.trim(),
        status: WorkTaskStatus.waiting,
        updatedAt: now,
      ),
    );
    _setStaffWorkStatus(mechanic.userId, StaffWorkStatus.onWork);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Mechanic assigned',
        message: '${mechanic.name} received work instructions.',
        createdAt: now,
        audiences: const [TimelineAudience.owner, TimelineAudience.staff],
      );
      _notify(
        userId: mechanic.userId,
        title: 'Work assigned',
        message:
            '${car.carNumber}: ${title.trim().isEmpty ? 'Garage work' : title.trim()}',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void updateTaskProgress({
    required String taskId,
    required WorkTaskStatus status,
    String? notes,
    List<String> photoPaths = const [],
  }) {
    final index = _workTasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final now = DateTime.now();
    final task = _workTasks[index];
    _workTasks[index] = task.copyWith(
      status: status,
      notes: notes == null || notes.trim().isEmpty ? task.notes : notes.trim(),
      photoPaths: [
        ...task.photoPaths,
        ...photoPaths.where((path) => path.trim().isNotEmpty),
      ],
      updatedAt: now,
    );
    final car = _cars.where((item) => item.id == task.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: task.jobId,
        title: 'Work update',
        message:
            '${staffName(task.mechanicId)} marked ${task.title} as ${status.label}.',
        createdAt: now,
        audiences: const [TimelineAudience.owner, TimelineAudience.staff],
      );
      _notify(
        userId: ownerUser.id,
        title: 'Mechanic update',
        message: '${car.carNumber}: ${task.title} is ${status.label}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void reviewTask(String taskId) {
    updateTaskProgress(taskId: taskId, status: WorkTaskStatus.reviewed);
  }

  void markWorkCompleteForReview(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    final now = DateTime.now();
    _jobs[index] = job.copyWith(status: JobStatus.completed);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Work completed',
        message: '${car.carNumber} is Completed - Waiting For Pickup.',
        createdAt: now,
      );
      _notify(
        userId: ownerUser.id,
        title: 'Work complete',
        message: '${car.carNumber} is waiting for pickup or delivery.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void sendApprovalRequest({
    required String jobId,
    required String message,
    required String reason,
    double amount = 0,
    RequestUrgency urgency = RequestUrgency.normal,
    List<String> photoPaths = const [],
    bool blocksWork = false,
  }) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null || message.trim().isEmpty) return;
    final now = DateTime.now();
    final requesterId =
        session?.user.id ?? job.masterMechanicId ?? ownerUser.id;
    final request = ApprovalRequest(
      id: 'approval-${now.microsecondsSinceEpoch}',
      jobId: job.id,
      carId: job.carId,
      requesterId: requesterId,
      message: message.trim(),
      reason: reason.trim(),
      amount: amount < 0 ? 0 : amount,
      photoPaths: photoPaths.where((path) => path.trim().isNotEmpty).toList(),
      urgency: urgency,
      status: ApprovalState.pending,
      createdAt: now,
      updatedAt: now,
      blocksWork: blocksWork,
    );
    _approvalRequests.insert(0, request);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Approval request sent',
        message:
            '${staffName(requesterId)} asked for a decision: ${request.message}.',
        createdAt: now,
        audiences: const [TimelineAudience.owner, TimelineAudience.staff],
      );
      _notify(
        userId: ownerUser.id,
        title: 'Approval request',
        message: '${car.carNumber}: ${request.message}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void decideApprovalRequest(
    String requestId,
    ApprovalState decision, {
    bool forwardToCustomer = false,
    String? comment,
  }) {
    final index = _approvalRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) return;
    final request = _approvalRequests[index];
    final now = DateTime.now();
    final car = _cars.where((item) => item.id == request.carId).firstOrNull;
    if (forwardToCustomer && car != null) {
      _approvalRequests[index] = request.copyWith(
        forwardedToCustomer: true,
        ownerComment: comment,
        updatedAt: now,
      );
      _addTimelineEvent(
        carId: car.id,
        jobId: request.jobId,
        title: 'Approval sent to customer',
        message: request.message,
        createdAt: now,
      );
      _notify(
        userId: car.userId,
        title: 'Approval needed',
        message: '${car.carNumber}: ${request.message}.',
        createdAt: now,
      );
    } else {
      _approvalRequests[index] = request.copyWith(
        status: decision,
        ownerComment: comment,
        updatedAt: now,
      );
      if (car != null) {
        _addTimelineEvent(
          carId: car.id,
          jobId: request.jobId,
          title: 'Owner decision',
          message: '${request.message} was ${decision.label}.',
          createdAt: now,
          audiences: const [TimelineAudience.owner, TimelineAudience.staff],
        );
      }
    }
    notifyListeners();
  }

  void customerDecideApprovalRequest(
    String requestId,
    ApprovalState decision, {
    String? comment,
  }) {
    final index = _approvalRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) return;
    final request = _approvalRequests[index];
    if (!request.forwardedToCustomer) return;
    final now = DateTime.now();
    _approvalRequests[index] = request.copyWith(
      status: decision,
      customerComment: comment,
      updatedAt: now,
    );
    final car = _cars.where((item) => item.id == request.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: request.jobId,
        title: 'Customer decision',
        message: '${request.message} was ${decision.label}.',
        createdAt: now,
      );
      _notify(
        userId: ownerUser.id,
        title: 'Customer decision',
        message: '${car.carNumber}: ${request.message} was ${decision.label}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void sendStaffProgressUpdate({
    required String jobId,
    required String message,
    List<String> photoPaths = const [],
  }) {
    final job = _jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null || message.trim().isEmpty) return;
    final now = DateTime.now();
    final senderId = session?.user.id ?? job.masterMechanicId ?? ownerUser.id;
    final update = ProgressUpdate(
      id: 'update-${now.microsecondsSinceEpoch}',
      jobId: job.id,
      carId: job.carId,
      senderId: senderId,
      message: message.trim(),
      photoPaths: photoPaths.where((path) => path.trim().isNotEmpty).toList(),
      createdAt: now,
    );
    _progressUpdates.insert(0, update);
    final car = _cars.where((item) => item.id == job.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: 'Progress update',
        message: '${staffName(senderId)} shared: ${update.message}',
        createdAt: now,
        audiences: const [TimelineAudience.owner, TimelineAudience.staff],
      );
      _notify(
        userId: ownerUser.id,
        title: 'Staff update',
        message: '${car.carNumber}: ${update.message}.',
        createdAt: now,
      );
    }
    notifyListeners();
  }

  void ownerHandleProgressUpdate(String updateId, {required bool forward}) {
    final index = _progressUpdates.indexWhere(
      (update) => update.id == updateId,
    );
    if (index == -1) return;
    final update = _progressUpdates[index];
    final now = DateTime.now();
    _progressUpdates[index] = update.copyWith(
      forwardedToCustomer: forward,
      keptInternal: !forward,
    );
    final car = _cars.where((item) => item.id == update.carId).firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: update.jobId,
        title: forward ? 'Update sent to customer' : 'Update kept internal',
        message: update.message,
        createdAt: now,
        audiences: forward
            ? const [
                TimelineAudience.owner,
                TimelineAudience.staff,
                TimelineAudience.customer,
              ]
            : const [TimelineAudience.owner, TimelineAudience.staff],
      );
      if (forward) {
        _notify(
          userId: car.userId,
          title: 'Garage update',
          message: '${car.carNumber}: ${update.message}.',
          createdAt: now,
        );
        _messages.add(
          SupportMessage(
            id: 'msg-${now.microsecondsSinceEpoch}',
            userId: car.userId,
            topic: 'Garage update',
            message: update.message,
            createdAt: now,
            carId: car.id,
            sentByOwner: true,
            attachmentPath: update.photoPaths.isEmpty
                ? null
                : update.photoPaths.first,
          ),
        );
      }
    }
    notifyListeners();
  }

  void submitAttendance({
    String? staffUserId,
    AttendanceStatus status = AttendanceStatus.present,
    String notes = '',
  }) {
    final userId = staffUserId ?? session?.user.id;
    if (userId == null) return;
    final existing = todayAttendanceForStaff(userId);
    if (existing != null) return;
    final now = DateTime.now();
    _attendanceRecords.insert(
      0,
      StaffAttendance(
        id: 'att-${now.microsecondsSinceEpoch}',
        staffUserId: userId,
        date: DateTime(now.year, now.month, now.day),
        checkInTime: now,
        status: status,
        locationVerification: VerificationResult.verified,
        faceVerification: VerificationResult.unavailable,
        notes: notes.trim().isEmpty
            ? 'Face verification placeholder is ready for setup.'
            : notes.trim(),
      ),
    );
    _notify(
      userId: ownerUser.id,
      title: 'Attendance marked',
      message: '${staffName(userId)} marked ${status.label}.',
      createdAt: now,
    );
    notifyListeners();
  }

  void correctAttendance({
    required String attendanceId,
    required AttendanceStatus status,
    required String reason,
  }) {
    final index = _attendanceRecords.indexWhere(
      (record) => record.id == attendanceId,
    );
    if (index == -1) return;
    _attendanceRecords[index] = _attendanceRecords[index].copyWith(
      status: status,
      correctedByOwner: true,
      correctionReason: reason.trim(),
    );
    notifyListeners();
  }

  void applyLeave({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String reason,
    String? attachmentPath,
  }) {
    final currentSession = session;
    if (currentSession == null || !currentSession.role.isStaff) return;
    final now = DateTime.now();
    _leaveRequests.insert(
      0,
      LeaveRequest(
        id: 'leave-${now.microsecondsSinceEpoch}',
        staffUserId: currentSession.user.id,
        startDate: startDate,
        endDate: endDate,
        leaveType: leaveType.trim().isEmpty ? 'Leave' : leaveType.trim(),
        reason: reason.trim(),
        status: ApprovalState.pending,
        attachmentPath: attachmentPath,
        createdAt: now,
      ),
    );
    _notify(
      userId: ownerUser.id,
      title: 'Leave request',
      message: '${currentSession.user.name} submitted a leave request.',
      createdAt: now,
    );
    notifyListeners();
  }

  void decideLeaveRequest(
    String leaveRequestId,
    ApprovalState decision, {
    String? comment,
  }) {
    final index = _leaveRequests.indexWhere(
      (request) => request.id == leaveRequestId,
    );
    if (index == -1) return;
    final request = _leaveRequests[index];
    _leaveRequests[index] = request.copyWith(
      status: decision,
      ownerComment: comment,
    );
    _notify(
      userId: request.staffUserId,
      title: 'Leave ${decision.label}',
      message: 'Your leave request was ${decision.label}.',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void recordAdvance({
    required String staffUserId,
    required double amount,
    required String reason,
    required String cutMethod,
  }) {
    if (staffProfileForUser(staffUserId) == null || amount <= 0) return;
    final now = DateTime.now();
    _advances.insert(
      0,
      StaffAdvance(
        id: 'advance-${now.microsecondsSinceEpoch}',
        staffUserId: staffUserId,
        amount: amount,
        date: now,
        reason: reason.trim(),
        cutMethod: cutMethod.trim().isEmpty
            ? 'Deduct from salary'
            : cutMethod.trim(),
        remainingAmount: amount,
        status: AdvanceStatus.active,
      ),
    );
    _notify(
      userId: staffUserId,
      title: 'Advance recorded',
      message: 'Advance of ${amount.toStringAsFixed(0)} was recorded.',
      createdAt: now,
    );
    notifyListeners();
  }

  SalaryRecord? generateSalaryRecord({
    required String staffUserId,
    required String monthLabel,
    double bonus = 0,
    double manualDeduction = 0,
  }) {
    final profile = staffProfileForUser(staffUserId);
    if (profile == null) return null;
    final records = attendanceForStaff(staffUserId);
    final presentDays = records
        .where((record) => record.status == AttendanceStatus.present)
        .length;
    final leaveDays = records
        .where((record) => record.status == AttendanceStatus.leave)
        .length;
    final absentDays = records
        .where((record) => record.status == AttendanceStatus.absent)
        .length;
    final halfDays = records
        .where((record) => record.status == AttendanceStatus.halfDay)
        .length;
    final lateMarks = records
        .where((record) => record.status == AttendanceStatus.late)
        .length;
    final advanceDeduction = advancesForStaff(staffUserId)
        .where((advance) => advance.status == AdvanceStatus.active)
        .fold<double>(
          0,
          (sum, advance) =>
              sum + advance.remainingAmount.clamp(0, 2500).toDouble(),
        );
    final dailyRate = profile.salary / 26;
    final finalPayable =
        profile.salary -
        (absentDays * dailyRate) -
        (halfDays * dailyRate * 0.5) -
        advanceDeduction -
        manualDeduction +
        bonus;
    final now = DateTime.now();
    final record = SalaryRecord(
      id: 'salary-${now.microsecondsSinceEpoch}',
      staffUserId: staffUserId,
      monthLabel: monthLabel.trim().isEmpty
          ? 'Current Month'
          : monthLabel.trim(),
      baseSalary: profile.salary,
      presentDays: presentDays,
      leaveDays: leaveDays,
      absentDays: absentDays,
      halfDays: halfDays,
      lateMarks: lateMarks,
      advanceDeduction: advanceDeduction,
      bonus: bonus,
      manualDeduction: manualDeduction,
      finalPayable: finalPayable < 0 ? 0 : finalPayable,
      generatedAt: now,
    );
    _salaryRecords.insert(0, record);
    _staffDocuments.insert(
      0,
      StaffDocument(
        id: 'staff-doc-${now.microsecondsSinceEpoch}',
        staffUserId: staffUserId,
        title: '${record.monthLabel} Payslip',
        category: 'Payslip',
        amount: record.finalPayable,
        createdAt: now,
      ),
    );
    _notify(
      userId: staffUserId,
      title: 'Payslip generated',
      message: '${record.monthLabel} salary record is ready.',
      createdAt: now,
    );
    notifyListeners();
    return record;
  }

  void markSalaryPaid(String salaryRecordId) {
    final index = _salaryRecords.indexWhere(
      (record) => record.id == salaryRecordId,
    );
    if (index == -1) return;
    _salaryRecords[index] = _salaryRecords[index].copyWith(isPaid: true);
    notifyListeners();
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
    final jobIndex = _jobs.indexWhere((job) => job.id == existing.jobId);
    final car = _cars.where((item) => item.id == existing.carId).firstOrNull;
    if (existing.type == DocumentType.jobCard && jobIndex >= 0) {
      final job = _jobs[jobIndex];
      if (decision == ApprovalState.approved) {
        _jobs[jobIndex] = job.copyWith(status: JobStatus.workInProgress);
        if (car != null) {
          _addTimelineEvent(
            carId: car.id,
            jobId: job.id,
            title: 'Customer approved',
            message:
                '${existing.title} was approved. Work In Progress can begin.',
            createdAt: DateTime.now(),
          );
        }
      } else if (decision == ApprovalState.rejected && car != null) {
        _addTimelineEvent(
          carId: car.id,
          jobId: job.id,
          title: 'Customer rejected',
          message:
              '${existing.title} needs changes${comment == null || comment.isEmpty ? '.' : ': $comment'}',
          createdAt: DateTime.now(),
        );
      }
      if (job.masterMechanicId != null) {
        _notify(
          userId: job.masterMechanicId!,
          title: 'Job card ${decision.label}',
          message: '${existing.title} was ${decision.label}.',
          createdAt: DateTime.now(),
        );
      }
    }

    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${DateTime.now().millisecondsSinceEpoch}',
        userId: DemoSeed.ownerUser.id,
        title: '${existing.type.label} ${decision.label}',
        message: '${existing.title} was ${decision.label} by the customer.',
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
    _jobs[index] = _jobs[index].copyWith(
      status: status,
      pickupRequired: status == JobStatus.onRoad
          ? false
          : status == JobStatus.deliveryScheduled
          ? true
          : _jobs[index].pickupRequired,
      pickupState:
          status == JobStatus.onRoad ||
              status == JobStatus.received ||
              status == JobStatus.pickUpDone
          ? PickupState.completed
          : _jobs[index].pickupState,
    );
    final car = _cars
        .where((item) => item.id == _jobs[index].carId)
        .firstOrNull;
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: jobId,
        title: status.label,
        message: '${car.carNumber} moved to ${status.label}.',
        createdAt: DateTime.now(),
      );
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
    final matchingMechanic = mechanicProfiles
        .where(
          (profile) =>
              _normalizeIndianPhoneForStorage(profile.phone) ==
              _normalizeIndianPhoneForStorage(personPhone),
        )
        .firstOrNull;
    if (matchingMechanic != null) {
      assignPickupMechanic(jobId, matchingMechanic.userId);
      return;
    }
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
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupPersonName: cleanName,
      pickupPersonPhone: cleanPhone,
    );
    if (car != null) {
      _addTimelineEvent(
        carId: car.id,
        jobId: job.id,
        title: isDelivery ? 'Delivery scheduled' : 'Pickup mechanic assigned',
        message:
            '$cleanName${cleanPhone.isEmpty ? '' : ' ($cleanPhone)'} is assigned for ${car.carNumber}.',
        createdAt: DateTime.now(),
      );
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
    required bool locationAccessGranted,
  }) {
    final car = _cars.where((item) => item.id == carId).firstOrNull;
    if (car == null) return;
    final existingIndex = _jobs.indexWhere(
      (job) => job.carId == carId && job.status != JobStatus.onRoad,
    );
    final isDeliveryRequest =
        existingIndex >= 0 &&
        _jobs[existingIndex].status == JobStatus.completed;
    if (existingIndex >= 0) {
      _jobs[existingIndex] = _jobs[existingIndex].copyWith(
        status: isDeliveryRequest
            ? JobStatus.deliveryScheduled
            : JobStatus.pickUpScheduled,
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
          status: JobStatus.pickUpScheduled,
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
        title: isDeliveryRequest ? 'Delivery scheduled' : 'Pickup scheduled',
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
        title: isDeliveryRequest ? 'Delivery Scheduled' : 'Pick Up Scheduled',
        message:
            '${isDeliveryRequest ? 'Delivery' : 'Pickup'} is scheduled for ${car.carNumber} at ${_formatWhatsappDate(pickupTime)}.',
        createdAt: DateTime.now(),
      ),
    );
    _addTimelineEvent(
      carId: car.id,
      jobId: existingIndex >= 0
          ? _jobs[existingIndex].id
          : _jobs.firstWhere((job) => job.carId == car.id).id,
      title: isDeliveryRequest ? 'Delivery scheduled' : 'Pickup scheduled',
      message:
          '${isDeliveryRequest ? 'Delivery' : 'Pickup'} scheduled for ${_formatWhatsappDate(pickupTime)}.',
      createdAt: DateTime.now(),
    );
    _messages.add(
      SupportMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        userId: car.userId,
        topic: isDeliveryRequest ? 'Delivery' : 'Pickup',
        message:
            '${isDeliveryRequest ? 'Delivery' : 'Pickup'} requested for ${_formatWhatsappDate(pickupTime)}${pickupAddress == null || pickupAddress.isEmpty ? '' : ' at $pickupAddress'}.',
        createdAt: DateTime.now(),
        carId: car.id,
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
    final now = DateTime.now();
    _jobs[index] = _jobs[index].copyWith(
      pickupRequired: !isDelivery,
      pickupState: PickupState.completed,
      status: isDelivery ? JobStatus.onRoad : JobStatus.pickUpDone,
    );
    if (car != null) {
      if (proofImagePath != null && proofImagePath.trim().isNotEmpty) {
        _photoUpdates.insert(
          0,
          GaragePhotoUpdate(
            id: 'photo-${now.microsecondsSinceEpoch}',
            userId: car.userId,
            carId: car.id,
            imagePath: proofImagePath.trim(),
            caption: isDelivery
                ? 'Delivery completed and vehicle handed over.'
                : 'Pickup done and vehicle is on the way to garage receiving.',
            createdAt: now,
          ),
        );
      }
      _addTimelineEvent(
        carId: car.id,
        jobId: _jobs[index].id,
        title: isDelivery ? 'On Road' : 'Pick Up Done',
        message: isDelivery
            ? '${car.carNumber} is On Road.'
            : '${car.carNumber} pickup is done.',
        createdAt: now,
      );
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${now.microsecondsSinceEpoch + 1}',
          userId: car.userId,
          title: isDelivery ? 'Delivery completed' : 'Pick Up Done',
          message: isDelivery
              ? '${car.carNumber} is back on road.'
              : '${car.carNumber} pickup is done and receiving is next.',
          createdAt: now,
        ),
      );
      _notifications.insert(
        0,
        AppNotification(
          id: 'note-${now.microsecondsSinceEpoch + 2}',
          userId: ownerUser.id,
          title: isDelivery ? 'Delivery completed' : 'Pick Up Done',
          message: isDelivery
              ? '${car.carNumber} is On Road.'
              : '${car.carNumber} is ready to be marked Received.',
          createdAt: now,
        ),
      );
      _messages.add(
        SupportMessage(
          id: 'msg-${now.microsecondsSinceEpoch + 3}',
          userId: car.userId,
          topic: isDelivery ? 'Delivery' : 'Pickup',
          message: isDelivery
              ? '${car.carNumber} delivery is complete. Vehicle is On Road.'
              : '${car.carNumber} pickup is done. Garage receiving will be updated soon.',
          createdAt: now,
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
    if (status != null && jobIndex >= 0) {
      _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: status);
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
        title: status == null ? 'New garage photos' : 'Status photo update',
        message: status == null
            ? 'Fresh progress photos were added for ${car.carNumber}.'
            : '${car.carNumber} is now ${status.label} with a photo update.',
        createdAt: now,
      ),
    );
    _messages.add(
      SupportMessage(
        id: 'msg-${now.millisecondsSinceEpoch + 2}',
        userId: car.userId,
        topic: status == null ? 'Garage photos' : status.label,
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
          if (relatedJob.status == JobStatus.received) {
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
    required bool locationAccessGranted,
  }) {
    return 'FLYWHEELS AUTO pickup request\n'
        'Vehicle: ${car.carNumber}\n'
        'Model: ${car.model}\n'
        'Pickup time: ${_formatWhatsappDate(pickupTime)}\n'
        '${pickupAddress == null || pickupAddress.isEmpty ? '' : 'Address: $pickupAddress\n'}'
        'Location access: ${locationAccessGranted ? 'Approved' : 'Not approved'}';
  }

  bool _jobVisibleToStaff(ServiceJob job, String staffUserId) {
    if (job.pickupMechanicId == staffUserId) return true;
    if (job.masterMechanicId == staffUserId) return true;
    if (job.assignedMechanicIds.contains(staffUserId)) return true;
    return _workTasks.any(
      (task) =>
          task.jobId == job.id &&
          (task.mechanicId == staffUserId ||
              task.masterMechanicId == staffUserId),
    );
  }

  void _setStaffWorkStatus(String staffUserId, StaffWorkStatus status) {
    final index = _staffProfiles.indexWhere(
      (profile) => profile.userId == staffUserId,
    );
    if (index == -1) return;
    _staffProfiles[index] = _staffProfiles[index].copyWith(workStatus: status);
  }

  void _notify({
    required String userId,
    required String title,
    required String message,
    required DateTime createdAt,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'note-${createdAt.microsecondsSinceEpoch}-${_notifications.length}',
        userId: userId,
        title: title,
        message: message,
        createdAt: createdAt,
      ),
    );
  }

  void _addTimelineEvent({
    required String carId,
    required String jobId,
    required String title,
    required String message,
    required DateTime createdAt,
    List<TimelineAudience> audiences = const [
      TimelineAudience.owner,
      TimelineAudience.staff,
      TimelineAudience.customer,
    ],
  }) {
    _timelineEvents.insert(
      0,
      CarTimelineEvent(
        id: 'timeline-${createdAt.microsecondsSinceEpoch}-${_timelineEvents.length}',
        carId: carId,
        jobId: jobId,
        title: title,
        message: message,
        createdAt: createdAt,
        audiences: audiences,
        actorUserId: session?.user.id,
      ),
    );
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

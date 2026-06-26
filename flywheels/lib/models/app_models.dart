enum UserRole { customer, owner, masterMechanic, mechanic }

extension UserRoleX on UserRole {
  bool get isOwner => this == UserRole.owner;
  bool get isMasterMechanic => this == UserRole.masterMechanic;
  bool get isMechanic => this == UserRole.mechanic;
  bool get isStaff => isMasterMechanic || isMechanic;

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.owner:
        return 'Owner';
      case UserRole.masterMechanic:
        return 'Master Mechanic';
      case UserRole.mechanic:
        return 'Mechanic';
    }
  }
}

enum JobStatus {
  pickupScheduled,
  pickupDone,
  received,
  underInspection,
  workInProgress,
  completed,
  deliveryScheduled,
  onRoad,
}

extension JobStatusX on JobStatus {
  JobStatus get next {
    switch (this) {
      case JobStatus.pickupScheduled:
        return JobStatus.pickupDone;
      case JobStatus.pickupDone:
        return JobStatus.received;
      case JobStatus.received:
        return JobStatus.underInspection;
      case JobStatus.underInspection:
        return JobStatus.workInProgress;
      case JobStatus.workInProgress:
        return JobStatus.completed;
      case JobStatus.completed:
        return JobStatus.deliveryScheduled;
      case JobStatus.deliveryScheduled:
        return JobStatus.onRoad;
      case JobStatus.onRoad:
        return JobStatus.onRoad;
    }
  }

  String get label {
    switch (this) {
      case JobStatus.pickupScheduled:
        return 'Pick Up Scheduled';
      case JobStatus.pickupDone:
        return 'Pick Up Done';
      case JobStatus.received:
        return 'Received';
      case JobStatus.underInspection:
        return 'Under Inspection';
      case JobStatus.workInProgress:
        return 'Work in Progress';
      case JobStatus.completed:
        return 'Completed - Waiting For Pickup';
      case JobStatus.deliveryScheduled:
        return 'Delivery Scheduled';
      case JobStatus.onRoad:
        return 'On-Road';
    }
  }
}

enum PickupState { requested, assigned, completed }

extension PickupStateX on PickupState {
  String get label {
    switch (this) {
      case PickupState.requested:
        return 'Requested';
      case PickupState.assigned:
        return 'Assigned';
      case PickupState.completed:
        return 'Completed';
    }
  }
}

enum CarWorkflowState {
  registered,
  pickupRequested,
  pickupAssigned,
  pickupDone,
  received,
  underInspection,
  workInProgress,
  readyForDelivery,
  deliveryRequested,
  deliveryAssigned,
  onRoad,
}

extension CarWorkflowStateX on CarWorkflowState {
  String get label {
    switch (this) {
      case CarWorkflowState.registered:
        return 'Registered';
      case CarWorkflowState.pickupRequested:
        return 'Pickup Requested';
      case CarWorkflowState.pickupAssigned:
        return 'Pickup Assigned';
      case CarWorkflowState.pickupDone:
        return 'Pick Up Done';
      case CarWorkflowState.received:
        return 'Received';
      case CarWorkflowState.underInspection:
        return 'Under Inspection';
      case CarWorkflowState.workInProgress:
        return 'Work in Progress';
      case CarWorkflowState.readyForDelivery:
        return 'Completed - Waiting For Pickup';
      case CarWorkflowState.deliveryRequested:
        return 'Delivery Requested';
      case CarWorkflowState.deliveryAssigned:
        return 'Delivery Assigned';
      case CarWorkflowState.onRoad:
        return 'On-Road';
    }
  }

  bool get isTransit =>
      this == CarWorkflowState.pickupRequested ||
      this == CarWorkflowState.pickupAssigned ||
      this == CarWorkflowState.pickupDone ||
      this == CarWorkflowState.deliveryRequested ||
      this == CarWorkflowState.deliveryAssigned;

  bool get isInGarage =>
      this == CarWorkflowState.received ||
      this == CarWorkflowState.underInspection ||
      this == CarWorkflowState.workInProgress;

  bool get isAvailable =>
      this == CarWorkflowState.registered || this == CarWorkflowState.onRoad;

  bool get needsOwnerAction =>
      isTransit ||
      this == CarWorkflowState.received ||
      this == CarWorkflowState.underInspection ||
      this == CarWorkflowState.workInProgress ||
      this == CarWorkflowState.readyForDelivery;
}

extension ServiceJobWorkflowX on ServiceJob {
  CarWorkflowState get workflowState {
    if (status == JobStatus.pickupScheduled) {
      return pickupState == PickupState.assigned
          ? CarWorkflowState.pickupAssigned
          : CarWorkflowState.pickupRequested;
    }
    if (status == JobStatus.pickupDone) {
      return CarWorkflowState.pickupDone;
    }
    if (status == JobStatus.deliveryScheduled) {
      return pickupState == PickupState.assigned
          ? CarWorkflowState.deliveryAssigned
          : CarWorkflowState.deliveryRequested;
    }

    final isOpenTransit =
        pickupRequired && pickupState != PickupState.completed;
    if (status == JobStatus.completed && isOpenTransit) {
      return pickupState == PickupState.assigned
          ? CarWorkflowState.deliveryAssigned
          : CarWorkflowState.deliveryRequested;
    }
    if (isOpenTransit) {
      return pickupState == PickupState.assigned
          ? CarWorkflowState.pickupAssigned
          : CarWorkflowState.pickupRequested;
    }

    switch (status) {
      case JobStatus.pickupScheduled:
        return pickupState == PickupState.assigned
            ? CarWorkflowState.pickupAssigned
            : CarWorkflowState.pickupRequested;
      case JobStatus.pickupDone:
        return CarWorkflowState.pickupDone;
      case JobStatus.received:
        return CarWorkflowState.received;
      case JobStatus.underInspection:
        return CarWorkflowState.underInspection;
      case JobStatus.workInProgress:
        return CarWorkflowState.workInProgress;
      case JobStatus.completed:
        return CarWorkflowState.readyForDelivery;
      case JobStatus.deliveryScheduled:
        return pickupState == PickupState.assigned
            ? CarWorkflowState.deliveryAssigned
            : CarWorkflowState.deliveryRequested;
      case JobStatus.onRoad:
        return CarWorkflowState.onRoad;
    }
  }
}

enum DocumentType { quotation, estimation, invoice, jobCard }

enum PersonalDocumentType { rc, drivingLicense, insurance, puc, other }

extension DocumentTypeX on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.quotation:
        return 'Quotation';
      case DocumentType.estimation:
        return 'Receipt';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.jobCard:
        return 'Job Card';
    }
  }

  String get prefix {
    switch (this) {
      case DocumentType.quotation:
        return 'QTN';
      case DocumentType.estimation:
        return 'REC';
      case DocumentType.invoice:
        return 'INV';
      case DocumentType.jobCard:
        return 'JOB';
    }
  }
}

extension PersonalDocumentTypeX on PersonalDocumentType {
  String get label {
    switch (this) {
      case PersonalDocumentType.rc:
        return 'RC';
      case PersonalDocumentType.drivingLicense:
        return 'Driving License';
      case PersonalDocumentType.insurance:
        return 'Insurance';
      case PersonalDocumentType.puc:
        return 'PUC';
      case PersonalDocumentType.other:
        return 'Other';
    }
  }
}

enum ApprovalState { pending, approved, rejected }

enum PaymentState { pending, paid, failed }

class GarageUser {
  const GarageUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImagePath,
    this.email,
    this.dataSharingConsent = false,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImagePath;
  final String? email;
  final bool dataSharingConsent;

  GarageUser copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? profileImagePath,
    String? email,
    bool? dataSharingConsent,
  }) {
    return GarageUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      email: email ?? this.email,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
    );
  }
}

class AppSession {
  const AppSession({required this.user, required this.token});

  final GarageUser user;
  final String token;

  UserRole get role => user.role;

  AppSession copyWith({GarageUser? user, String? token}) {
    return AppSession(user: user ?? this.user, token: token ?? this.token);
  }
}

class CarProfile {
  const CarProfile({
    required this.id,
    required this.userId,
    required this.carNumber,
    required this.model,
    required this.fuelType,
    required this.year,
    required this.isActive,
    required this.imageUrl,
  });

  final String id;
  final String userId;
  final String carNumber;
  final String model;
  final String fuelType;
  final int year;
  final bool isActive;
  final String imageUrl;

  CarProfile copyWith({bool? isActive, String? imageUrl}) {
    return CarProfile(
      id: id,
      userId: userId,
      carNumber: carNumber,
      model: model,
      fuelType: fuelType,
      year: year,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum CarSaleMediaType { image, video }

extension CarSaleMediaTypeX on CarSaleMediaType {
  String get label => this == CarSaleMediaType.image ? 'Photo' : 'Video';
}

enum CarSaleStatus { pendingApproval, active, sold, rejected }

extension CarSaleStatusX on CarSaleStatus {
  String get label {
    switch (this) {
      case CarSaleStatus.pendingApproval:
        return 'Pending Approval';
      case CarSaleStatus.active:
        return 'Live';
      case CarSaleStatus.sold:
        return 'Sold';
      case CarSaleStatus.rejected:
        return 'Rejected';
    }
  }
}

class CarSaleMedia {
  const CarSaleMedia({required this.path, required this.type, this.caption});

  final String path;
  final CarSaleMediaType type;
  final String? caption;
}

class CarSaleListing {
  const CarSaleListing({
    required this.id,
    required this.sellerUserId,
    required this.sellerName,
    required this.title,
    required this.model,
    required this.fuelType,
    required this.year,
    required this.price,
    required this.odometerKm,
    required this.transmission,
    required this.location,
    required this.description,
    required this.media,
    required this.createdAt,
    this.status = CarSaleStatus.active,
    this.previousPrice,
    this.returnAssurance = false,
    this.bodyType = 'SUV',
    this.color = 'White',
    this.features = const [],
    this.seats = 5,
    this.ownerCount = 1,
    this.rto = 'TS',
    this.safetyRating = 'Not rated',
    this.discountPercent = 0,
    this.carNumber,
    this.contactPhone,
    this.postedByOwner = false,
    this.isGarageVerified = false,
  });

  final String id;
  final String sellerUserId;
  final String sellerName;
  final String title;
  final String model;
  final String fuelType;
  final int year;
  final double price;
  final double? previousPrice;
  final int odometerKm;
  final String transmission;
  final String location;
  final String description;
  final List<CarSaleMedia> media;
  final DateTime createdAt;
  final CarSaleStatus status;
  final bool returnAssurance;
  final String bodyType;
  final String color;
  final List<String> features;
  final int seats;
  final int ownerCount;
  final String rto;
  final String safetyRating;
  final int discountPercent;
  final String? carNumber;
  final String? contactPhone;
  final bool postedByOwner;
  final bool isGarageVerified;

  CarSaleMedia? get primaryMedia {
    if (media.isEmpty) return null;
    final image = media.where((item) => item.type == CarSaleMediaType.image);
    return image.isEmpty ? media.first : image.first;
  }

  int get videoCount =>
      media.where((item) => item.type == CarSaleMediaType.video).length;

  CarSaleListing copyWith({
    String? title,
    String? model,
    String? fuelType,
    int? year,
    double? price,
    double? previousPrice,
    int? odometerKm,
    String? transmission,
    String? location,
    String? description,
    List<CarSaleMedia>? media,
    CarSaleStatus? status,
    bool? returnAssurance,
    String? bodyType,
    String? color,
    List<String>? features,
    int? seats,
    int? ownerCount,
    String? rto,
    String? safetyRating,
    int? discountPercent,
    String? carNumber,
    String? contactPhone,
    bool? isGarageVerified,
  }) {
    return CarSaleListing(
      id: id,
      sellerUserId: sellerUserId,
      sellerName: sellerName,
      title: title ?? this.title,
      model: model ?? this.model,
      fuelType: fuelType ?? this.fuelType,
      year: year ?? this.year,
      price: price ?? this.price,
      previousPrice: previousPrice ?? this.previousPrice,
      odometerKm: odometerKm ?? this.odometerKm,
      transmission: transmission ?? this.transmission,
      location: location ?? this.location,
      description: description ?? this.description,
      media: media ?? this.media,
      createdAt: createdAt,
      status: status ?? this.status,
      returnAssurance: returnAssurance ?? this.returnAssurance,
      bodyType: bodyType ?? this.bodyType,
      color: color ?? this.color,
      features: features ?? this.features,
      seats: seats ?? this.seats,
      ownerCount: ownerCount ?? this.ownerCount,
      rto: rto ?? this.rto,
      safetyRating: safetyRating ?? this.safetyRating,
      discountPercent: discountPercent ?? this.discountPercent,
      carNumber: carNumber ?? this.carNumber,
      contactPhone: contactPhone ?? this.contactPhone,
      postedByOwner: postedByOwner,
      isGarageVerified: isGarageVerified ?? this.isGarageVerified,
    );
  }
}

const Object _copyWithUnset = Object();

class ServiceJob {
  const ServiceJob({
    required this.id,
    required this.userId,
    required this.carId,
    required this.status,
    required this.expectedCompletion,
    required this.pickupTime,
    required this.pickupRequired,
    required this.pickupState,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupMapUrl,
    this.pickupPhotoPath,
    this.pickupPersonName,
    this.pickupPersonPhone,
    this.locationAccessGranted = false,
    this.masterMechanicId,
    this.mechanicIds = const [],
  });

  final String id;
  final String userId;
  final String carId;
  final JobStatus status;
  final DateTime expectedCompletion;
  final DateTime pickupTime;
  final bool pickupRequired;
  final PickupState pickupState;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupMapUrl;
  final String? pickupPhotoPath;
  final String? pickupPersonName;
  final String? pickupPersonPhone;
  final bool locationAccessGranted;
  final String? masterMechanicId;
  final List<String> mechanicIds;

  bool get hasPickupCoordinates =>
      pickupLatitude != null && pickupLongitude != null;

  ServiceJob copyWith({
    JobStatus? status,
    DateTime? expectedCompletion,
    DateTime? pickupTime,
    bool? pickupRequired,
    PickupState? pickupState,
    Object? pickupAddress = _copyWithUnset,
    Object? pickupLatitude = _copyWithUnset,
    Object? pickupLongitude = _copyWithUnset,
    Object? pickupMapUrl = _copyWithUnset,
    Object? pickupPhotoPath = _copyWithUnset,
    String? pickupPersonName,
    String? pickupPersonPhone,
    bool? locationAccessGranted,
    String? masterMechanicId,
    List<String>? mechanicIds,
  }) {
    return ServiceJob(
      id: id,
      userId: userId,
      carId: carId,
      status: status ?? this.status,
      expectedCompletion: expectedCompletion ?? this.expectedCompletion,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupRequired: pickupRequired ?? this.pickupRequired,
      pickupState: pickupState ?? this.pickupState,
      pickupAddress: pickupAddress == _copyWithUnset
          ? this.pickupAddress
          : pickupAddress as String?,
      pickupLatitude: pickupLatitude == _copyWithUnset
          ? this.pickupLatitude
          : pickupLatitude as double?,
      pickupLongitude: pickupLongitude == _copyWithUnset
          ? this.pickupLongitude
          : pickupLongitude as double?,
      pickupMapUrl: pickupMapUrl == _copyWithUnset
          ? this.pickupMapUrl
          : pickupMapUrl as String?,
      pickupPhotoPath: pickupPhotoPath == _copyWithUnset
          ? this.pickupPhotoPath
          : pickupPhotoPath as String?,
      pickupPersonName: pickupPersonName ?? this.pickupPersonName,
      pickupPersonPhone: pickupPersonPhone ?? this.pickupPersonPhone,
      locationAccessGranted:
          locationAccessGranted ?? this.locationAccessGranted,
      masterMechanicId: masterMechanicId ?? this.masterMechanicId,
      mechanicIds: mechanicIds ?? this.mechanicIds,
    );
  }
}

class DocumentLineItem {
  const DocumentLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  DocumentLineItem copyWith({
    String? description,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return DocumentLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}

class ServiceDocument {
  const ServiceDocument({
    required this.id,
    required this.userId,
    required this.carId,
    required this.jobId,
    required this.type,
    required this.title,
    required this.items,
    required this.total,
    required this.approvalState,
    required this.paymentState,
    required this.createdAt,
    required this.updatedAt,
    required this.pdfLabel,
    this.customerComment,
  });

  final String id;
  final String userId;
  final String carId;
  final String jobId;
  final DocumentType type;
  final String title;
  final List<DocumentLineItem> items;
  final double total;
  final ApprovalState approvalState;
  final PaymentState paymentState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String pdfLabel;
  final String? customerComment;

  ServiceDocument copyWith({
    String? title,
    List<DocumentLineItem>? items,
    double? total,
    ApprovalState? approvalState,
    PaymentState? paymentState,
    String? customerComment,
    DateTime? updatedAt,
    String? pdfLabel,
  }) {
    return ServiceDocument(
      id: id,
      userId: userId,
      carId: carId,
      jobId: jobId,
      type: type,
      title: title ?? this.title,
      items: items ?? this.items,
      total: total ?? this.total,
      approvalState: approvalState ?? this.approvalState,
      paymentState: paymentState ?? this.paymentState,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pdfLabel: pdfLabel ?? this.pdfLabel,
      customerComment: customerComment ?? this.customerComment,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
}

class GaragePhotoUpdate {
  const GaragePhotoUpdate({
    required this.id,
    required this.userId,
    required this.carId,
    required this.imagePath,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String carId;
  final String imagePath;
  final String caption;
  final DateTime createdAt;
}

class CustomerAssetDocument {
  const CustomerAssetDocument({
    required this.id,
    required this.userId,
    required this.carId,
    required this.type,
    required this.title,
    required this.filePath,
    required this.uploadedAt,
    this.validUntil,
  });

  final String id;
  final String userId;
  final String carId;
  final PersonalDocumentType type;
  final String title;
  final String filePath;
  final DateTime uploadedAt;
  final DateTime? validUntil;
}

enum ChatChannel { general, buying, selling }

extension ChatChannelX on ChatChannel {
  String get label {
    switch (this) {
      case ChatChannel.general:
        return 'General';
      case ChatChannel.buying:
        return 'Buying';
      case ChatChannel.selling:
        return 'Selling';
    }
  }
}

enum StaffRole { masterMechanic, mechanic }

extension StaffRoleX on StaffRole {
  String get label =>
      this == StaffRole.masterMechanic ? 'Master Mechanic' : 'Mechanic';

  UserRole get userRole => this == StaffRole.masterMechanic
      ? UserRole.masterMechanic
      : UserRole.mechanic;
}

enum AttendanceStatus { present, halfDay, leave, absent }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
}

enum RequestStatus { pending, approved, rejected }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
}

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    required this.primarySkill,
    required this.monthlySalary,
    this.profileImagePath,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final StaffRole role;
  final String primarySkill;
  final double monthlySalary;
  final String? profileImagePath;
  final bool isActive;
  final DateTime? createdAt;

  StaffProfile copyWith({
    String? name,
    String? phone,
    StaffRole? role,
    String? primarySkill,
    double? monthlySalary,
    String? profileImagePath,
    bool? isActive,
  }) {
    return StaffProfile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      primarySkill: primarySkill ?? this.primarySkill,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.staffId,
    required this.date,
    required this.status,
    required this.loggedAt,
    this.latitude,
    this.longitude,
    this.faceVerified = false,
    this.locationVerified = false,
    this.note,
  });

  final String id;
  final String staffId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime loggedAt;
  final double? latitude;
  final double? longitude;
  final bool faceVerified;
  final bool locationVerified;
  final String? note;
}

class SalaryAdvance {
  const SalaryAdvance({
    required this.id,
    required this.staffId,
    required this.amount,
    required this.reason,
    required this.requestedAt,
    this.status = RequestStatus.pending,
    this.ownerNote,
  });

  final String id;
  final String staffId;
  final double amount;
  final String reason;
  final DateTime requestedAt;
  final RequestStatus status;
  final String? ownerNote;

  SalaryAdvance copyWith({RequestStatus? status, String? ownerNote}) {
    return SalaryAdvance(
      id: id,
      staffId: staffId,
      amount: amount,
      reason: reason,
      requestedAt: requestedAt,
      status: status ?? this.status,
      ownerNote: ownerNote ?? this.ownerNote,
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.staffId,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.requestedAt,
    this.status = RequestStatus.pending,
    this.ownerNote,
  });

  final String id;
  final String staffId;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final DateTime requestedAt;
  final RequestStatus status;
  final String? ownerNote;

  LeaveRequest copyWith({RequestStatus? status, String? ownerNote}) {
    return LeaveRequest(
      id: id,
      staffId: staffId,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      requestedAt: requestedAt,
      status: status ?? this.status,
      ownerNote: ownerNote ?? this.ownerNote,
    );
  }
}

class SalarySlip {
  const SalarySlip({
    required this.id,
    required this.staffId,
    required this.monthLabel,
    required this.grossPay,
    required this.advanceDeduction,
    required this.leaveDeduction,
    required this.netPay,
    required this.generatedAt,
  });

  final String id;
  final String staffId;
  final String monthLabel;
  final double grossPay;
  final double advanceDeduction;
  final double leaveDeduction;
  final double netPay;
  final DateTime generatedAt;
}

class StaffAssignmentProposal {
  const StaffAssignmentProposal({
    required this.id,
    required this.jobId,
    required this.masterMechanicId,
    required this.mechanicIds,
    required this.createdAt,
    this.status = RequestStatus.pending,
    this.ownerNote,
  });

  final String id;
  final String jobId;
  final String masterMechanicId;
  final List<String> mechanicIds;
  final DateTime createdAt;
  final RequestStatus status;
  final String? ownerNote;

  StaffAssignmentProposal copyWith({RequestStatus? status, String? ownerNote}) {
    return StaffAssignmentProposal(
      id: id,
      jobId: jobId,
      masterMechanicId: masterMechanicId,
      mechanicIds: mechanicIds,
      createdAt: createdAt,
      status: status ?? this.status,
      ownerNote: ownerNote ?? this.ownerNote,
    );
  }
}

class WorkApprovalRequest {
  const WorkApprovalRequest({
    required this.id,
    required this.jobId,
    required this.staffId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.photoPath,
    this.status = RequestStatus.pending,
    this.forwardedToCustomer = false,
    this.ownerResponse,
  });

  final String id;
  final String jobId;
  final String staffId;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? photoPath;
  final RequestStatus status;
  final bool forwardedToCustomer;
  final String? ownerResponse;

  WorkApprovalRequest copyWith({
    RequestStatus? status,
    bool? forwardedToCustomer,
    String? ownerResponse,
  }) {
    return WorkApprovalRequest(
      id: id,
      jobId: jobId,
      staffId: staffId,
      title: title,
      message: message,
      createdAt: createdAt,
      photoPath: photoPath,
      status: status ?? this.status,
      forwardedToCustomer: forwardedToCustomer ?? this.forwardedToCustomer,
      ownerResponse: ownerResponse ?? this.ownerResponse,
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.userId,
    required this.topic,
    required this.message,
    required this.createdAt,
    this.channel = ChatChannel.general,
    this.carId,
    this.attachmentPath,
    this.sentByOwner = false,
    this.isDelivered = true,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String topic;
  final String message;
  final DateTime createdAt;
  final ChatChannel channel;
  final String? carId;
  final String? attachmentPath;
  final bool sentByOwner;
  final bool isDelivered;
  final bool isRead;

  SupportMessage copyWith({
    String? topic,
    String? message,
    ChatChannel? channel,
    String? carId,
    String? attachmentPath,
    bool? sentByOwner,
    bool? isDelivered,
    bool? isRead,
  }) {
    return SupportMessage(
      id: id,
      userId: userId,
      topic: topic ?? this.topic,
      message: message ?? this.message,
      createdAt: createdAt,
      channel: channel ?? this.channel,
      carId: carId ?? this.carId,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      sentByOwner: sentByOwner ?? this.sentByOwner,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
    );
  }
}

class DocumentDraft {
  const DocumentDraft({
    required this.documentNumber,
    required this.type,
    required this.customerName,
    this.customerPhone = '',
    required this.vehicleNumber,
    required this.carModel,
    required this.items,
    this.selectedCarId,
    this.rawText = '',
  });

  final String documentNumber;
  final DocumentType type;
  final String customerName;
  final String customerPhone;
  final String vehicleNumber;
  final String carModel;
  final List<DocumentLineItem> items;
  final String? selectedCarId;
  final String rawText;

  double get total => items.fold<double>(0, (sum, item) => sum + item.total);

  DocumentDraft copyWith({
    String? documentNumber,
    DocumentType? type,
    String? customerName,
    String? customerPhone,
    String? vehicleNumber,
    String? carModel,
    List<DocumentLineItem>? items,
    String? selectedCarId,
    String? rawText,
  }) {
    return DocumentDraft(
      documentNumber: documentNumber ?? this.documentNumber,
      type: type ?? this.type,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      carModel: carModel ?? this.carModel,
      items: items ?? this.items,
      selectedCarId: selectedCarId ?? this.selectedCarId,
      rawText: rawText ?? this.rawText,
    );
  }
}

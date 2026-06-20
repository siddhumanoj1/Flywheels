enum UserRole { customer, owner, masterMechanic, mechanic }

extension UserRoleX on UserRole {
  bool get isOwner => this == UserRole.owner;
  bool get isCustomer => this == UserRole.customer;
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
  pickUpScheduled,
  pickUpDone,
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
      case JobStatus.pickUpScheduled:
        return JobStatus.pickUpDone;
      case JobStatus.pickUpDone:
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
      case JobStatus.pickUpScheduled:
        return 'Pick Up Scheduled';
      case JobStatus.pickUpDone:
        return 'Pick Up Done';
      case JobStatus.received:
        return 'Received';
      case JobStatus.underInspection:
        return 'Under Inspection';
      case JobStatus.workInProgress:
        return 'Work In Progress';
      case JobStatus.completed:
        return 'Completed - Waiting For Pickup';
      case JobStatus.deliveryScheduled:
        return 'Delivery Scheduled';
      case JobStatus.onRoad:
        return 'On Road';
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
  deliveryScheduled,
  onRoad,
}

extension CarWorkflowStateX on CarWorkflowState {
  String get label {
    switch (this) {
      case CarWorkflowState.registered:
        return 'Registered';
      case CarWorkflowState.pickupRequested:
        return 'Pick Up Scheduled';
      case CarWorkflowState.pickupAssigned:
        return 'Pick Up Scheduled';
      case CarWorkflowState.pickupDone:
        return 'Pick Up Done';
      case CarWorkflowState.received:
        return 'Received';
      case CarWorkflowState.underInspection:
        return 'Under Inspection';
      case CarWorkflowState.workInProgress:
        return 'Work In Progress';
      case CarWorkflowState.readyForDelivery:
        return 'Completed - Waiting For Pickup';
      case CarWorkflowState.deliveryRequested:
        return 'Delivery Scheduled';
      case CarWorkflowState.deliveryAssigned:
        return 'Delivery Scheduled';
      case CarWorkflowState.deliveryScheduled:
        return 'Delivery Scheduled';
      case CarWorkflowState.onRoad:
        return 'On Road';
    }
  }

  bool get isTransit =>
      this == CarWorkflowState.pickupRequested ||
      this == CarWorkflowState.pickupAssigned ||
      this == CarWorkflowState.pickupDone ||
      this == CarWorkflowState.deliveryRequested ||
      this == CarWorkflowState.deliveryAssigned ||
      this == CarWorkflowState.deliveryScheduled;

  bool get isInGarage =>
      this == CarWorkflowState.received ||
      this == CarWorkflowState.underInspection ||
      this == CarWorkflowState.workInProgress;

  bool get isAvailable =>
      this == CarWorkflowState.registered || this == CarWorkflowState.onRoad;

  bool get needsOwnerAction =>
      isTransit ||
      this == CarWorkflowState.underInspection ||
      this == CarWorkflowState.workInProgress ||
      this == CarWorkflowState.readyForDelivery;
}

extension ServiceJobWorkflowX on ServiceJob {
  CarWorkflowState get workflowState {
    switch (status) {
      case JobStatus.pickUpScheduled:
        return pickupState == PickupState.assigned
            ? CarWorkflowState.pickupAssigned
            : CarWorkflowState.pickupRequested;
      case JobStatus.pickUpDone:
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
            : CarWorkflowState.deliveryScheduled;
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
        return 'Estimation';
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
        return 'EST';
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

extension ApprovalStateX on ApprovalState {
  String get label {
    switch (this) {
      case ApprovalState.pending:
        return 'Waiting';
      case ApprovalState.approved:
        return 'Approved';
      case ApprovalState.rejected:
        return 'Rejected';
    }
  }
}

extension PaymentStateX on PaymentState {
  String get label {
    switch (this) {
      case PaymentState.pending:
        return 'Waiting';
      case PaymentState.paid:
        return 'Paid';
      case PaymentState.failed:
        return 'Failed';
    }
  }
}

enum StaffWorkStatus { free, assigned, onPickup, onWork, onLeave, inactive }

extension StaffWorkStatusX on StaffWorkStatus {
  String get label {
    switch (this) {
      case StaffWorkStatus.free:
        return 'Available';
      case StaffWorkStatus.assigned:
        return 'Assigned';
      case StaffWorkStatus.onPickup:
        return 'On Pickup';
      case StaffWorkStatus.onWork:
        return 'On Work';
      case StaffWorkStatus.onLeave:
        return 'On Leave';
      case StaffWorkStatus.inactive:
        return 'Inactive';
    }
  }
}

enum WorkTaskStatus { waiting, inProgress, blocked, done, reviewed }

extension WorkTaskStatusX on WorkTaskStatus {
  String get label {
    switch (this) {
      case WorkTaskStatus.waiting:
        return 'Waiting';
      case WorkTaskStatus.inProgress:
        return 'In Progress';
      case WorkTaskStatus.blocked:
        return 'Needs Decision';
      case WorkTaskStatus.done:
        return 'Done';
      case WorkTaskStatus.reviewed:
        return 'Reviewed';
    }
  }
}

enum AttendanceStatus { present, absent, late, halfDay, leave }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
    }
  }
}

enum VerificationResult { verified, pending, unavailable, failed }

extension VerificationResultX on VerificationResult {
  String get label {
    switch (this) {
      case VerificationResult.verified:
        return 'Verified';
      case VerificationResult.pending:
        return 'Checking';
      case VerificationResult.unavailable:
        return 'Ready For Setup';
      case VerificationResult.failed:
        return 'Failed';
    }
  }
}

enum RequestUrgency { normal, urgent, vehicleStopped }

extension RequestUrgencyX on RequestUrgency {
  String get label {
    switch (this) {
      case RequestUrgency.normal:
        return 'Normal';
      case RequestUrgency.urgent:
        return 'Urgent';
      case RequestUrgency.vehicleStopped:
        return 'Vehicle Stopped';
    }
  }
}

enum AdvanceStatus { active, deducted, closed }

extension AdvanceStatusX on AdvanceStatus {
  String get label {
    switch (this) {
      case AdvanceStatus.active:
        return 'Active';
      case AdvanceStatus.deducted:
        return 'Deducted';
      case AdvanceStatus.closed:
        return 'Closed';
    }
  }
}

enum TimelineAudience { owner, staff, customer }

class GarageUser {
  const GarageUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImagePath,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImagePath;

  GarageUser copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? profileImagePath,
  }) {
    return GarageUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImagePath: profileImagePath ?? this.profileImagePath,
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
    this.pickupPersonName,
    this.pickupPersonPhone,
    this.locationAccessGranted = false,
    this.pickupMechanicId,
    this.masterMechanicId,
    this.assignedMechanicIds = const [],
    this.customerConcern = '',
    this.workInstructions = '',
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
  final String? pickupPersonName;
  final String? pickupPersonPhone;
  final bool locationAccessGranted;
  final String? pickupMechanicId;
  final String? masterMechanicId;
  final List<String> assignedMechanicIds;
  final String customerConcern;
  final String workInstructions;

  ServiceJob copyWith({
    JobStatus? status,
    DateTime? expectedCompletion,
    DateTime? pickupTime,
    bool? pickupRequired,
    PickupState? pickupState,
    String? pickupAddress,
    String? pickupPersonName,
    String? pickupPersonPhone,
    bool? locationAccessGranted,
    String? pickupMechanicId,
    String? masterMechanicId,
    List<String>? assignedMechanicIds,
    String? customerConcern,
    String? workInstructions,
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
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupPersonName: pickupPersonName ?? this.pickupPersonName,
      pickupPersonPhone: pickupPersonPhone ?? this.pickupPersonPhone,
      locationAccessGranted:
          locationAccessGranted ?? this.locationAccessGranted,
      pickupMechanicId: pickupMechanicId ?? this.pickupMechanicId,
      masterMechanicId: masterMechanicId ?? this.masterMechanicId,
      assignedMechanicIds: assignedMechanicIds ?? this.assignedMechanicIds,
      customerConcern: customerConcern ?? this.customerConcern,
      workInstructions: workInstructions ?? this.workInstructions,
    );
  }
}

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    required this.salary,
    required this.joiningDate,
    required this.emergencyContact,
    required this.address,
    required this.skillNotes,
    required this.workStatus,
    required this.isActive,
    this.masterMechanicId,
    this.profileImagePath,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final UserRole role;
  final double salary;
  final DateTime joiningDate;
  final String emergencyContact;
  final String address;
  final String skillNotes;
  final StaffWorkStatus workStatus;
  final bool isActive;
  final String? masterMechanicId;
  final String? profileImagePath;

  StaffProfile copyWith({
    String? name,
    String? phone,
    UserRole? role,
    double? salary,
    DateTime? joiningDate,
    String? emergencyContact,
    String? address,
    String? skillNotes,
    StaffWorkStatus? workStatus,
    bool? isActive,
    String? masterMechanicId,
    String? profileImagePath,
  }) {
    return StaffProfile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      joiningDate: joiningDate ?? this.joiningDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      skillNotes: skillNotes ?? this.skillNotes,
      workStatus: workStatus ?? this.workStatus,
      isActive: isActive ?? this.isActive,
      masterMechanicId: masterMechanicId ?? this.masterMechanicId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class MechanicWorkTask {
  const MechanicWorkTask({
    required this.id,
    required this.jobId,
    required this.carId,
    required this.masterMechanicId,
    required this.mechanicId,
    required this.title,
    required this.instructions,
    required this.status,
    required this.updatedAt,
    this.notes = '',
    this.photoPaths = const [],
  });

  final String id;
  final String jobId;
  final String carId;
  final String masterMechanicId;
  final String mechanicId;
  final String title;
  final String instructions;
  final WorkTaskStatus status;
  final String notes;
  final List<String> photoPaths;
  final DateTime updatedAt;

  MechanicWorkTask copyWith({
    String? title,
    String? instructions,
    WorkTaskStatus? status,
    String? notes,
    List<String>? photoPaths,
    DateTime? updatedAt,
  }) {
    return MechanicWorkTask(
      id: id,
      jobId: jobId,
      carId: carId,
      masterMechanicId: masterMechanicId,
      mechanicId: mechanicId,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.jobId,
    required this.carId,
    required this.requesterId,
    required this.message,
    required this.reason,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.amount = 0,
    this.photoPaths = const [],
    this.forwardedToCustomer = false,
    this.ownerComment,
    this.customerComment,
    this.blocksWork = false,
  });

  final String id;
  final String jobId;
  final String carId;
  final String requesterId;
  final String message;
  final String reason;
  final double amount;
  final List<String> photoPaths;
  final RequestUrgency urgency;
  final ApprovalState status;
  final bool forwardedToCustomer;
  final String? ownerComment;
  final String? customerComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool blocksWork;

  ApprovalRequest copyWith({
    String? message,
    String? reason,
    double? amount,
    List<String>? photoPaths,
    RequestUrgency? urgency,
    ApprovalState? status,
    bool? forwardedToCustomer,
    String? ownerComment,
    String? customerComment,
    DateTime? updatedAt,
    bool? blocksWork,
  }) {
    return ApprovalRequest(
      id: id,
      jobId: jobId,
      carId: carId,
      requesterId: requesterId,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      photoPaths: photoPaths ?? this.photoPaths,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      forwardedToCustomer: forwardedToCustomer ?? this.forwardedToCustomer,
      ownerComment: ownerComment ?? this.ownerComment,
      customerComment: customerComment ?? this.customerComment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blocksWork: blocksWork ?? this.blocksWork,
    );
  }
}

class ProgressUpdate {
  const ProgressUpdate({
    required this.id,
    required this.jobId,
    required this.carId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.photoPaths = const [],
    this.forwardedToCustomer = false,
    this.keptInternal = false,
  });

  final String id;
  final String jobId;
  final String carId;
  final String senderId;
  final String message;
  final List<String> photoPaths;
  final bool forwardedToCustomer;
  final bool keptInternal;
  final DateTime createdAt;

  ProgressUpdate copyWith({
    String? message,
    List<String>? photoPaths,
    bool? forwardedToCustomer,
    bool? keptInternal,
  }) {
    return ProgressUpdate(
      id: id,
      jobId: jobId,
      carId: carId,
      senderId: senderId,
      message: message ?? this.message,
      photoPaths: photoPaths ?? this.photoPaths,
      forwardedToCustomer: forwardedToCustomer ?? this.forwardedToCustomer,
      keptInternal: keptInternal ?? this.keptInternal,
      createdAt: createdAt,
    );
  }
}

class StaffAttendance {
  const StaffAttendance({
    required this.id,
    required this.staffUserId,
    required this.date,
    required this.checkInTime,
    required this.status,
    required this.locationVerification,
    required this.faceVerification,
    this.checkOutTime,
    this.notes = '',
    this.correctedByOwner = false,
    this.correctionReason,
  });

  final String id;
  final String staffUserId;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final VerificationResult locationVerification;
  final VerificationResult faceVerification;
  final String notes;
  final bool correctedByOwner;
  final String? correctionReason;

  StaffAttendance copyWith({
    DateTime? checkOutTime,
    AttendanceStatus? status,
    VerificationResult? locationVerification,
    VerificationResult? faceVerification,
    String? notes,
    bool? correctedByOwner,
    String? correctionReason,
  }) {
    return StaffAttendance(
      id: id,
      staffUserId: staffUserId,
      date: date,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      locationVerification: locationVerification ?? this.locationVerification,
      faceVerification: faceVerification ?? this.faceVerification,
      notes: notes ?? this.notes,
      correctedByOwner: correctedByOwner ?? this.correctedByOwner,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.staffUserId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.attachmentPath,
    this.ownerComment,
  });

  final String id;
  final String staffUserId;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String reason;
  final ApprovalState status;
  final String? attachmentPath;
  final String? ownerComment;
  final DateTime createdAt;

  LeaveRequest copyWith({
    ApprovalState? status,
    String? ownerComment,
    String? attachmentPath,
  }) {
    return LeaveRequest(
      id: id,
      staffUserId: staffUserId,
      startDate: startDate,
      endDate: endDate,
      leaveType: leaveType,
      reason: reason,
      status: status ?? this.status,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      ownerComment: ownerComment ?? this.ownerComment,
      createdAt: createdAt,
    );
  }
}

class StaffAdvance {
  const StaffAdvance({
    required this.id,
    required this.staffUserId,
    required this.amount,
    required this.date,
    required this.reason,
    required this.cutMethod,
    required this.remainingAmount,
    required this.status,
  });

  final String id;
  final String staffUserId;
  final double amount;
  final DateTime date;
  final String reason;
  final String cutMethod;
  final double remainingAmount;
  final AdvanceStatus status;

  StaffAdvance copyWith({double? remainingAmount, AdvanceStatus? status}) {
    return StaffAdvance(
      id: id,
      staffUserId: staffUserId,
      amount: amount,
      date: date,
      reason: reason,
      cutMethod: cutMethod,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
    );
  }
}

class SalaryRecord {
  const SalaryRecord({
    required this.id,
    required this.staffUserId,
    required this.monthLabel,
    required this.baseSalary,
    required this.presentDays,
    required this.leaveDays,
    required this.absentDays,
    required this.halfDays,
    required this.lateMarks,
    required this.advanceDeduction,
    required this.bonus,
    required this.manualDeduction,
    required this.finalPayable,
    required this.generatedAt,
    this.isPaid = false,
  });

  final String id;
  final String staffUserId;
  final String monthLabel;
  final double baseSalary;
  final int presentDays;
  final int leaveDays;
  final int absentDays;
  final int halfDays;
  final int lateMarks;
  final double advanceDeduction;
  final double bonus;
  final double manualDeduction;
  final double finalPayable;
  final bool isPaid;
  final DateTime generatedAt;

  SalaryRecord copyWith({bool? isPaid}) {
    return SalaryRecord(
      id: id,
      staffUserId: staffUserId,
      monthLabel: monthLabel,
      baseSalary: baseSalary,
      presentDays: presentDays,
      leaveDays: leaveDays,
      absentDays: absentDays,
      halfDays: halfDays,
      lateMarks: lateMarks,
      advanceDeduction: advanceDeduction,
      bonus: bonus,
      manualDeduction: manualDeduction,
      finalPayable: finalPayable,
      isPaid: isPaid ?? this.isPaid,
      generatedAt: generatedAt,
    );
  }
}

class StaffDocument {
  const StaffDocument({
    required this.id,
    required this.staffUserId,
    required this.title,
    required this.category,
    required this.createdAt,
    this.filePath,
    this.amount,
  });

  final String id;
  final String staffUserId;
  final String title;
  final String category;
  final String? filePath;
  final double? amount;
  final DateTime createdAt;
}

class CarTimelineEvent {
  const CarTimelineEvent({
    required this.id,
    required this.carId,
    required this.jobId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.audiences = const [
      TimelineAudience.owner,
      TimelineAudience.staff,
      TimelineAudience.customer,
    ],
    this.actorUserId,
  });

  final String id;
  final String carId;
  final String jobId;
  final String title;
  final String message;
  final DateTime createdAt;
  final List<TimelineAudience> audiences;
  final String? actorUserId;
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

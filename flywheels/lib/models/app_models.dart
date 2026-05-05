enum UserRole { customer, owner }

extension UserRoleX on UserRole {
  bool get isOwner => this == UserRole.owner;

  String get label => this == UserRole.owner ? 'Owner' : 'Customer';
}

enum JobStatus {
  received,
  underInspection,
  workInProgress,
  completed,
  readyForDelivery,
}

extension JobStatusX on JobStatus {
  JobStatus get next {
    switch (this) {
      case JobStatus.received:
        return JobStatus.underInspection;
      case JobStatus.underInspection:
        return JobStatus.workInProgress;
      case JobStatus.workInProgress:
        return JobStatus.completed;
      case JobStatus.completed:
        return JobStatus.readyForDelivery;
      case JobStatus.readyForDelivery:
        return JobStatus.readyForDelivery;
    }
  }

  String get label {
    switch (this) {
      case JobStatus.received:
        return 'Received';
      case JobStatus.underInspection:
        return 'Under Inspection';
      case JobStatus.workInProgress:
        return 'Work in Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.readyForDelivery:
        return 'Ready for Delivery';
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
    this.locationAccessGranted = false,
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
  final bool locationAccessGranted;

  ServiceJob copyWith({
    JobStatus? status,
    DateTime? expectedCompletion,
    DateTime? pickupTime,
    bool? pickupRequired,
    PickupState? pickupState,
    String? pickupAddress,
    bool? locationAccessGranted,
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
      locationAccessGranted:
          locationAccessGranted ?? this.locationAccessGranted,
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

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.userId,
    required this.topic,
    required this.message,
    required this.createdAt,
    this.carId,
    this.attachmentPath,
    this.sentByOwner = false,
  });

  final String id;
  final String userId;
  final String topic;
  final String message;
  final DateTime createdAt;
  final String? carId;
  final String? attachmentPath;
  final bool sentByOwner;
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

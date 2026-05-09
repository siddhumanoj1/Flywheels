import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/car_media_service.dart';

abstract final class DemoSeed {
  static const customerUser = GarageUser(
    id: 'customer-1',
    name: 'Sai Hemaja',
    phone: '9123456789',
    role: UserRole.customer,
    profileImagePath:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
  );

  static const ownerUser = GarageUser(
    id: 'owner-1',
    name: 'Flywheels Garage',
    phone: '9876543210',
    role: UserRole.owner,
    profileImagePath:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
  );

  static const users = <GarageUser>[customerUser, ownerUser];

  static final cars = <CarProfile>[
    const CarProfile(
      id: 'car-1',
      userId: 'customer-1',
      carNumber: 'TS19F2222',
      model: 'MG HECTOR 2.0D',
      fuelType: 'Diesel',
      year: 2022,
      isActive: true,
      imageUrl:
          'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-2',
      userId: 'customer-1',
      carNumber: 'TS09AB9088',
      model: 'Hyundai Creta',
      fuelType: 'Petrol',
      year: 2021,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1553440569-bcc63803a83d?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static final jobs = <ServiceJob>[
    ServiceJob(
      id: 'job-1',
      userId: customerUser.id,
      carId: 'car-1',
      status: JobStatus.workInProgress,
      expectedCompletion: DateTime.now().add(const Duration(hours: 6)),
      pickupTime: DateTime.now().add(const Duration(hours: 20)),
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupAddress: 'Madhapur, Hyderabad',
      pickupPersonName: 'Ravi Kumar',
      pickupPersonPhone: '9000012345',
      locationAccessGranted: true,
    ),
    ServiceJob(
      id: 'job-2',
      userId: customerUser.id,
      carId: 'car-2',
      status: JobStatus.onRoad,
      expectedCompletion: DateTime.now().subtract(const Duration(days: 8)),
      pickupTime: DateTime.now()
          .subtract(const Duration(days: 8))
          .add(const Duration(hours: 2)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      pickupAddress: 'Kondapur, Hyderabad',
    ),
  ];

  static final documents = <ServiceDocument>[
    ServiceDocument(
      id: 'doc-1',
      userId: customerUser.id,
      carId: 'car-1',
      jobId: 'job-1',
      type: DocumentType.quotation,
      title: 'QTN-3059',
      items: const [
        DocumentLineItem(
          description: 'Oilfilter',
          quantity: 1,
          unitPrice: 690,
          total: 690,
        ),
        DocumentLineItem(
          description: 'Airfilter',
          quantity: 1,
          unitPrice: 1050,
          total: 1050,
        ),
        DocumentLineItem(
          description: 'Engineoil(fullysynth 5w30)',
          quantity: 5,
          unitPrice: 800,
          total: 4000,
        ),
      ],
      total: 5740,
      approvalState: ApprovalState.pending,
      paymentState: PaymentState.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      pdfLabel: 'PDF ready',
    ),
    ServiceDocument(
      id: 'doc-2',
      userId: customerUser.id,
      carId: 'car-2',
      jobId: 'job-2',
      type: DocumentType.invoice,
      title: 'INV-2988',
      items: const [
        DocumentLineItem(
          description: 'Periodic service',
          quantity: 1,
          unitPrice: 3200,
          total: 3200,
        ),
        DocumentLineItem(
          description: 'Brake cleaning',
          quantity: 1,
          unitPrice: 800,
          total: 800,
        ),
      ],
      total: 4000,
      approvalState: ApprovalState.approved,
      paymentState: PaymentState.paid,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 8)),
      pdfLabel: 'Invoice PDF',
    ),
    ServiceDocument(
      id: 'doc-3',
      userId: customerUser.id,
      carId: 'car-1',
      jobId: 'job-1',
      type: DocumentType.jobCard,
      title: 'JOB-4112',
      items: const [
        DocumentLineItem(
          description: 'Inspection checklist',
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
        DocumentLineItem(
          description: 'Customer concern noted and approved',
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
      ],
      total: 0,
      approvalState: ApprovalState.approved,
      paymentState: PaymentState.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      pdfLabel: 'Job card PDF',
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(
      id: 'note-1',
      userId: customerUser.id,
      title: 'Work started',
      message: 'Your MG Hector service job has moved into work in progress.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'note-2',
      userId: customerUser.id,
      title: 'Quotation ready',
      message: 'A new quotation is waiting for approval.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  static final photoUpdates = <GaragePhotoUpdate>[
    GaragePhotoUpdate(
      id: 'photo-1',
      userId: customerUser.id,
      carId: 'car-1',
      imagePath:
          'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=1200&q=80',
      caption: 'Engine bay inspection completed and consumables are staged.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
    ),
    GaragePhotoUpdate(
      id: 'photo-2',
      userId: customerUser.id,
      carId: 'car-1',
      imagePath:
          'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=1200&q=80',
      caption: 'Rear defogger assembly opened for fitment check.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
  ];

  static final messages = <SupportMessage>[
    SupportMessage(
      id: 'msg-1',
      userId: customerUser.id,
      topic: 'Service status',
      carId: 'car-1',
      message: 'Please confirm if the RR defogger part has arrived.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    SupportMessage(
      id: 'msg-2',
      userId: customerUser.id,
      topic: 'Service status',
      carId: 'car-1',
      message: 'The part is in stock and installation is under way.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
      sentByOwner: true,
    ),
  ];

  static final assetDocuments = <CustomerAssetDocument>[
    CustomerAssetDocument(
      id: 'asset-1',
      userId: customerUser.id,
      carId: 'car-1',
      type: PersonalDocumentType.rc,
      title: 'RC Front',
      filePath:
          'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
      uploadedAt: DateTime.now().subtract(const Duration(days: 18)),
      validUntil: DateTime.now().add(const Duration(days: 900)),
    ),
    CustomerAssetDocument(
      id: 'asset-2',
      userId: customerUser.id,
      carId: 'car-1',
      type: PersonalDocumentType.insurance,
      title: 'Insurance copy',
      filePath:
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1200&q=80',
      uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
      validUntil: DateTime.now().add(const Duration(days: 210)),
    ),
    CustomerAssetDocument(
      id: 'asset-3',
      userId: customerUser.id,
      carId: 'car-2',
      type: PersonalDocumentType.drivingLicense,
      title: 'Driver license',
      filePath:
          'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=1200&q=80',
      uploadedAt: DateTime.now().subtract(const Duration(days: 9)),
      validUntil: DateTime.now().add(const Duration(days: 540)),
    ),
  ];

  static AppSession? sessionForPhone(String phone, String code) {
    if (code != '123456') return null;
    if (phone == ownerUser.phone) {
      return const AppSession(user: ownerUser, token: 'demo-owner-token');
    }
    if (phone == customerUser.phone) {
      return const AppSession(user: customerUser, token: 'demo-customer-token');
    }
    return AppSession(
      user: GarageUser(
        id: 'customer-new',
        name: 'New Customer',
        phone: phone,
        role: UserRole.customer,
        profileImagePath: null,
      ),
      token: 'demo-customer-token',
    );
  }

  static CarProfile buildCar({
    required String id,
    required String userId,
    required String carNumber,
    required String model,
    required String fuelType,
    required int year,
    required bool isActive,
  }) {
    return CarProfile(
      id: id,
      userId: userId,
      carNumber: carNumber,
      model: model,
      fuelType: fuelType,
      year: year,
      isActive: isActive,
      imageUrl: CarMediaService.imageForModel(model, year: year),
    );
  }
}

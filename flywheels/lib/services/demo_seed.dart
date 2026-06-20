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

  static const secondCustomerUser = GarageUser(
    id: 'customer-2',
    name: 'Ananya Rao',
    phone: '9012345678',
    role: UserRole.customer,
    profileImagePath:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=800&q=80',
  );

  static const ownerUser = GarageUser(
    id: 'owner-1',
    name: 'Flywheels Garage',
    phone: '9876543210',
    role: UserRole.owner,
    profileImagePath:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
  );

  static const masterMechanicOne = GarageUser(
    id: 'master-1',
    name: 'Ramesh Naik',
    phone: '9000001001',
    role: UserRole.masterMechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1600486913747-55e5470d6f40?auto=format&fit=crop&w=800&q=80',
  );

  static const masterMechanicTwo = GarageUser(
    id: 'master-2',
    name: 'Imran Shaikh',
    phone: '9000001002',
    role: UserRole.masterMechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=800&q=80',
  );

  static const mechanicOne = GarageUser(
    id: 'mechanic-1',
    name: 'Vijay Kumar',
    phone: '9000002001',
    role: UserRole.mechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
  );

  static const mechanicTwo = GarageUser(
    id: 'mechanic-2',
    name: 'Kiran Goud',
    phone: '9000002002',
    role: UserRole.mechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
  );

  static const mechanicThree = GarageUser(
    id: 'mechanic-3',
    name: 'Arjun Reddy',
    phone: '9000002003',
    role: UserRole.mechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80',
  );

  static const mechanicFour = GarageUser(
    id: 'mechanic-4',
    name: 'Mahesh Patil',
    phone: '9000002004',
    role: UserRole.mechanic,
    profileImagePath:
        'https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=800&q=80',
  );

  static const users = <GarageUser>[
    customerUser,
    secondCustomerUser,
    ownerUser,
    masterMechanicOne,
    masterMechanicTwo,
    mechanicOne,
    mechanicTwo,
    mechanicThree,
    mechanicFour,
  ];

  static final staffProfiles = <StaffProfile>[
    StaffProfile(
      id: 'staff-1',
      userId: masterMechanicOne.id,
      name: masterMechanicOne.name,
      phone: masterMechanicOne.phone,
      role: UserRole.masterMechanic,
      salary: 52000,
      joiningDate: DateTime(2021, 7, 12),
      emergencyContact: 'Lakshmi Naik - 9000090001',
      address: 'Borabanda, Hyderabad',
      skillNotes: 'Diagnostics, diesel SUVs, scan tool reporting',
      workStatus: StaffWorkStatus.onWork,
      isActive: true,
      profileImagePath: masterMechanicOne.profileImagePath,
    ),
    StaffProfile(
      id: 'staff-2',
      userId: masterMechanicTwo.id,
      name: masterMechanicTwo.name,
      phone: masterMechanicTwo.phone,
      role: UserRole.masterMechanic,
      salary: 48500,
      joiningDate: DateTime(2022, 2, 4),
      emergencyContact: 'Sana Shaikh - 9000090002',
      address: 'Tolichowki, Hyderabad',
      skillNotes: 'Electrical diagnosis, AC work, petrol engines',
      workStatus: StaffWorkStatus.assigned,
      isActive: true,
      profileImagePath: masterMechanicTwo.profileImagePath,
    ),
    StaffProfile(
      id: 'staff-3',
      userId: mechanicOne.id,
      name: mechanicOne.name,
      phone: mechanicOne.phone,
      role: UserRole.mechanic,
      salary: 27500,
      joiningDate: DateTime(2022, 9, 20),
      emergencyContact: 'Suresh Kumar - 9000090003',
      address: 'Kukatpally, Hyderabad',
      skillNotes: 'Suspension, brakes, periodic service',
      workStatus: StaffWorkStatus.onWork,
      isActive: true,
      masterMechanicId: masterMechanicOne.id,
      profileImagePath: mechanicOne.profileImagePath,
    ),
    StaffProfile(
      id: 'staff-4',
      userId: mechanicTwo.id,
      name: mechanicTwo.name,
      phone: mechanicTwo.phone,
      role: UserRole.mechanic,
      salary: 26000,
      joiningDate: DateTime(2023, 1, 9),
      emergencyContact: 'Padma Goud - 9000090004',
      address: 'Miyapur, Hyderabad',
      skillNotes: 'Engine oil service, AC gas, final wash handover',
      workStatus: StaffWorkStatus.onWork,
      isActive: true,
      masterMechanicId: masterMechanicOne.id,
      profileImagePath: mechanicTwo.profileImagePath,
    ),
    StaffProfile(
      id: 'staff-5',
      userId: mechanicThree.id,
      name: mechanicThree.name,
      phone: mechanicThree.phone,
      role: UserRole.mechanic,
      salary: 24500,
      joiningDate: DateTime(2023, 5, 16),
      emergencyContact: 'Madhavi Reddy - 9000090005',
      address: 'Ameerpet, Hyderabad',
      skillNotes: 'Pickup, delivery, wheel alignment support',
      workStatus: StaffWorkStatus.onPickup,
      isActive: true,
      masterMechanicId: masterMechanicTwo.id,
      profileImagePath: mechanicThree.profileImagePath,
    ),
    StaffProfile(
      id: 'staff-6',
      userId: mechanicFour.id,
      name: mechanicFour.name,
      phone: mechanicFour.phone,
      role: UserRole.mechanic,
      salary: 23000,
      joiningDate: DateTime(2024, 3, 1),
      emergencyContact: 'Anil Patil - 9000090006',
      address: 'Chandanagar, Hyderabad',
      skillNotes: 'Body trim, battery, road test support',
      workStatus: StaffWorkStatus.free,
      isActive: true,
      masterMechanicId: masterMechanicTwo.id,
      profileImagePath: mechanicFour.profileImagePath,
    ),
  ];

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
    const CarProfile(
      id: 'car-3',
      userId: 'customer-2',
      carNumber: 'TS07GK4141',
      model: 'Honda City ZX',
      fuelType: 'Petrol',
      year: 2020,
      isActive: true,
      imageUrl:
          'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-4',
      userId: 'customer-1',
      carNumber: 'TS10EV5599',
      model: 'Tata Nexon EV',
      fuelType: 'Electric',
      year: 2023,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-5',
      userId: 'customer-2',
      carNumber: 'TS12CR7788',
      model: 'Maruti Suzuki Brezza',
      fuelType: 'Petrol',
      year: 2019,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-6',
      userId: 'customer-1',
      carNumber: 'TS08HY6421',
      model: 'Toyota Innova Crysta',
      fuelType: 'Diesel',
      year: 2018,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-7',
      userId: 'customer-2',
      carNumber: 'TS11KA8080',
      model: 'Kia Seltos HTX',
      fuelType: 'Diesel',
      year: 2021,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-8',
      userId: 'customer-1',
      carNumber: 'TS13BN3322',
      model: 'Mahindra XUV700',
      fuelType: 'Diesel',
      year: 2022,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1542362567-b07e54358753?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-9',
      userId: 'customer-2',
      carNumber: 'TS15AD2244',
      model: 'Honda Amaze',
      fuelType: 'Petrol',
      year: 2017,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1550355291-bbee04a92027?auto=format&fit=crop&w=1200&q=80',
    ),
    const CarProfile(
      id: 'car-10',
      userId: 'customer-1',
      carNumber: 'TS16QW9898',
      model: 'Maruti Suzuki Swift',
      fuelType: 'Petrol',
      year: 2020,
      isActive: false,
      imageUrl:
          'https://images.unsplash.com/photo-1609521263047-f8f205293f24?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static final saleListings = <CarSaleListing>[
    CarSaleListing(
      id: 'sale-1',
      sellerUserId: ownerUser.id,
      sellerName: ownerUser.name,
      title: 'MG Hector 2.0D Sharp',
      model: 'MG Hector 2.0D Sharp',
      fuelType: 'Diesel',
      year: 2022,
      price: 1690000,
      odometerKm: 38200,
      transmission: 'Manual',
      location: 'Madhapur, Hyderabad',
      description:
          'Garage-inspected single-owner SUV with service records, fresh detailing, and clean tyres.',
      media: const [
        CarSaleMedia(
          path:
              'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&w=1200&q=80',
          type: CarSaleMediaType.image,
          caption: 'Front three-quarter view',
        ),
        CarSaleMedia(
          path: 'garage-video-sale-1.mp4',
          type: CarSaleMediaType.video,
          caption: 'Walkaround video',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      returnAssurance: true,
      bodyType: 'SUV',
      color: 'White',
      features: const ['Sunroof', '360 camera', 'Connected car'],
      seats: 5,
      ownerCount: 1,
      rto: 'TS19',
      safetyRating: '5 star',
      discountPercent: 4,
      carNumber: 'TS19F2222',
      contactPhone: ownerUser.phone,
      postedByOwner: true,
      isGarageVerified: true,
    ),
    CarSaleListing(
      id: 'sale-2',
      sellerUserId: ownerUser.id,
      sellerName: ownerUser.name,
      title: 'Hyundai Creta SX',
      model: 'Hyundai Creta SX',
      fuelType: 'Petrol',
      year: 2021,
      price: 1245000,
      odometerKm: 45200,
      transmission: 'Automatic',
      location: 'Kondapur, Hyderabad',
      description:
          'Smooth automatic, owner-maintained, insurance active, and available for inspection at Flywheels Garage.',
      media: const [
        CarSaleMedia(
          path:
              'https://images.unsplash.com/photo-1553440569-bcc63803a83d?auto=format&fit=crop&w=1200&q=80',
          type: CarSaleMediaType.image,
          caption: 'Exterior view',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      returnAssurance: true,
      bodyType: 'SUV',
      color: 'Black',
      features: const ['Automatic', 'Touchscreen', 'Reverse camera'],
      seats: 5,
      ownerCount: 1,
      rto: 'TS09',
      safetyRating: '3 star',
      discountPercent: 0,
      carNumber: 'TS09AB9088',
      contactPhone: ownerUser.phone,
      postedByOwner: true,
      isGarageVerified: true,
    ),
    CarSaleListing(
      id: 'sale-3',
      sellerUserId: customerUser.id,
      sellerName: customerUser.name,
      title: 'Honda City ZX',
      model: 'Honda City ZX',
      fuelType: 'Petrol',
      year: 2020,
      price: 875000,
      odometerKm: 58300,
      transmission: 'Manual',
      location: 'Gachibowli, Hyderabad',
      description:
          'Customer-submitted sedan with clean interiors and regular maintenance history.',
      media: const [
        CarSaleMedia(
          path:
              'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?auto=format&fit=crop&w=1200&q=80',
          type: CarSaleMediaType.image,
          caption: 'Customer photo',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: CarSaleStatus.pendingApproval,
      bodyType: 'Sedan',
      color: 'Silver',
      features: const ['Cruise control', 'Alloy wheels'],
      seats: 5,
      ownerCount: 2,
      rto: 'TS07',
      safetyRating: '4 star',
      discountPercent: 2,
      contactPhone: customerUser.phone,
    ),
  ];

  static final jobs = <ServiceJob>[
    ServiceJob(
      id: 'job-1',
      userId: customerUser.id,
      carId: 'car-1',
      status: JobStatus.workInProgress,
      expectedCompletion: DateTime.now().add(const Duration(hours: 6)),
      pickupTime: DateTime.now().subtract(const Duration(hours: 8)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      pickupAddress: 'Madhapur, Hyderabad',
      pickupPersonName: mechanicThree.name,
      pickupPersonPhone: mechanicThree.phone,
      locationAccessGranted: true,
      pickupMechanicId: mechanicThree.id,
      masterMechanicId: masterMechanicOne.id,
      assignedMechanicIds: [mechanicOne.id, mechanicTwo.id],
      customerConcern: 'Periodic service and rear defogger not working.',
      workInstructions:
          'Finish consumables first, then fit rear defogger connector.',
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
      customerConcern: 'Regular service completed.',
    ),
    ServiceJob(
      id: 'job-3',
      userId: secondCustomerUser.id,
      carId: 'car-3',
      status: JobStatus.pickUpScheduled,
      expectedCompletion: DateTime.now().add(const Duration(days: 2)),
      pickupTime: DateTime.now().add(const Duration(hours: 2)),
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupAddress: 'Jubilee Hills Road 36, Hyderabad',
      pickupPersonName: mechanicThree.name,
      pickupPersonPhone: mechanicThree.phone,
      locationAccessGranted: true,
      pickupMechanicId: mechanicThree.id,
      customerConcern: 'Brake noise and steering vibration.',
    ),
    ServiceJob(
      id: 'job-4',
      userId: customerUser.id,
      carId: 'car-4',
      status: JobStatus.received,
      expectedCompletion: DateTime.now().add(const Duration(days: 1)),
      pickupTime: DateTime.now().subtract(const Duration(hours: 2)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      pickupAddress: 'Hitech City, Hyderabad',
      customerConcern: 'Battery warning and slow charging.',
    ),
    ServiceJob(
      id: 'job-5',
      userId: secondCustomerUser.id,
      carId: 'car-5',
      status: JobStatus.underInspection,
      expectedCompletion: DateTime.now().add(const Duration(days: 1)),
      pickupTime: DateTime.now().subtract(const Duration(hours: 5)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      masterMechanicId: masterMechanicTwo.id,
      customerConcern: 'AC cooling weak and rattling noise over bumps.',
    ),
    ServiceJob(
      id: 'job-6',
      userId: customerUser.id,
      carId: 'car-6',
      status: JobStatus.underInspection,
      expectedCompletion: DateTime.now().add(const Duration(days: 2)),
      pickupTime: DateTime.now().subtract(const Duration(hours: 7)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      masterMechanicId: masterMechanicOne.id,
      customerConcern: 'Long trip checkup with suspension complaint.',
    ),
    ServiceJob(
      id: 'job-7',
      userId: secondCustomerUser.id,
      carId: 'car-7',
      status: JobStatus.workInProgress,
      expectedCompletion: DateTime.now().add(const Duration(hours: 9)),
      pickupTime: DateTime.now().subtract(const Duration(days: 1)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      masterMechanicId: masterMechanicOne.id,
      assignedMechanicIds: [mechanicOne.id, mechanicFour.id],
      customerConcern: 'Engine mount vibration and wheel alignment.',
      workInstructions: 'Replace mount after customer approved part.',
    ),
    ServiceJob(
      id: 'job-8',
      userId: customerUser.id,
      carId: 'car-8',
      status: JobStatus.completed,
      expectedCompletion: DateTime.now().subtract(const Duration(hours: 1)),
      pickupTime: DateTime.now().add(const Duration(hours: 4)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      masterMechanicId: masterMechanicTwo.id,
      assignedMechanicIds: [mechanicTwo.id],
      customerConcern: 'Periodic service and wheel balancing.',
    ),
    ServiceJob(
      id: 'job-9',
      userId: secondCustomerUser.id,
      carId: 'car-9',
      status: JobStatus.deliveryScheduled,
      expectedCompletion: DateTime.now().subtract(const Duration(hours: 3)),
      pickupTime: DateTime.now().add(const Duration(hours: 1)),
      pickupRequired: true,
      pickupState: PickupState.assigned,
      pickupAddress: 'Manikonda, Hyderabad',
      pickupPersonName: mechanicFour.name,
      pickupPersonPhone: mechanicFour.phone,
      pickupMechanicId: mechanicFour.id,
      masterMechanicId: masterMechanicTwo.id,
      assignedMechanicIds: [mechanicFour.id],
      customerConcern: 'Minor dent touch-up and inspection.',
    ),
    ServiceJob(
      id: 'job-10',
      userId: customerUser.id,
      carId: 'car-10',
      status: JobStatus.onRoad,
      expectedCompletion: DateTime.now().subtract(const Duration(days: 3)),
      pickupTime: DateTime.now().subtract(const Duration(days: 3)),
      pickupRequired: false,
      pickupState: PickupState.completed,
      masterMechanicId: masterMechanicTwo.id,
      assignedMechanicIds: [mechanicTwo.id],
      customerConcern: 'Annual service completed.',
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
          description: 'Oil filter',
          quantity: 1,
          unitPrice: 690,
          total: 690,
        ),
        DocumentLineItem(
          description: 'Air filter',
          quantity: 1,
          unitPrice: 1050,
          total: 1050,
        ),
        DocumentLineItem(
          description: 'Engine oil fully synthetic 5W30',
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
          description: 'Customer concern and inspection notes',
          quantity: 1,
          unitPrice: 0,
          total: 0,
        ),
        DocumentLineItem(
          description: 'Rear defogger connector fitment',
          quantity: 1,
          unitPrice: 2200,
          total: 2200,
        ),
      ],
      total: 2200,
      approvalState: ApprovalState.approved,
      paymentState: PaymentState.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      pdfLabel: 'Job card PDF',
    ),
    ServiceDocument(
      id: 'doc-4',
      userId: customerUser.id,
      carId: 'car-6',
      jobId: 'job-6',
      type: DocumentType.jobCard,
      title: 'JOB-4124',
      items: const [
        DocumentLineItem(
          description: 'Full trip inspection',
          quantity: 1,
          unitPrice: 1600,
          total: 1600,
        ),
        DocumentLineItem(
          description: 'Front lower arm bush replacement',
          quantity: 2,
          unitPrice: 2400,
          total: 4800,
        ),
        DocumentLineItem(
          description: 'Wheel alignment',
          quantity: 1,
          unitPrice: 900,
          total: 900,
        ),
      ],
      total: 7300,
      approvalState: ApprovalState.pending,
      paymentState: PaymentState.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 35)),
      pdfLabel: 'Job card PDF',
    ),
    ServiceDocument(
      id: 'doc-5',
      userId: secondCustomerUser.id,
      carId: 'car-7',
      jobId: 'job-7',
      type: DocumentType.jobCard,
      title: 'JOB-4121',
      items: const [
        DocumentLineItem(
          description: 'Engine mount replacement labour',
          quantity: 1,
          unitPrice: 1800,
          total: 1800,
        ),
        DocumentLineItem(
          description: 'Right engine mount',
          quantity: 1,
          unitPrice: 6400,
          total: 6400,
        ),
      ],
      total: 8200,
      approvalState: ApprovalState.approved,
      paymentState: PaymentState.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 7)),
      pdfLabel: 'Job card PDF',
    ),
  ];

  static final workTasks = <MechanicWorkTask>[
    MechanicWorkTask(
      id: 'task-1',
      jobId: 'job-1',
      carId: 'car-1',
      masterMechanicId: masterMechanicOne.id,
      mechanicId: mechanicOne.id,
      title: 'Engine service',
      instructions: 'Replace oil, oil filter, and air filter.',
      status: WorkTaskStatus.inProgress,
      notes: 'Oil drained, filters opened.',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    MechanicWorkTask(
      id: 'task-2',
      jobId: 'job-1',
      carId: 'car-1',
      masterMechanicId: masterMechanicOne.id,
      mechanicId: mechanicTwo.id,
      title: 'Rear defogger',
      instructions: 'Fit connector and test switch.',
      status: WorkTaskStatus.waiting,
      notes: 'Connector kept near job bay.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    MechanicWorkTask(
      id: 'task-3',
      jobId: 'job-7',
      carId: 'car-7',
      masterMechanicId: masterMechanicOne.id,
      mechanicId: mechanicOne.id,
      title: 'Engine mount',
      instructions: 'Replace mount after bay lift is free.',
      status: WorkTaskStatus.inProgress,
      notes: 'Vehicle lifted and support stand placed.',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    MechanicWorkTask(
      id: 'task-4',
      jobId: 'job-7',
      carId: 'car-7',
      masterMechanicId: masterMechanicOne.id,
      mechanicId: mechanicFour.id,
      title: 'Road test and alignment',
      instructions: 'Complete after mount replacement.',
      status: WorkTaskStatus.waiting,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static final approvalRequests = <ApprovalRequest>[
    ApprovalRequest(
      id: 'approval-1',
      jobId: 'job-7',
      carId: 'car-7',
      requesterId: masterMechanicOne.id,
      message: 'Engine mount part approval needed',
      reason: 'Existing mount is cracked and causing cabin vibration.',
      amount: 6400,
      urgency: RequestUrgency.urgent,
      status: ApprovalState.pending,
      forwardedToCustomer: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      photoPaths: const [
        'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=1200&q=80',
      ],
      blocksWork: false,
    ),
    ApprovalRequest(
      id: 'approval-2',
      jobId: 'job-1',
      carId: 'car-1',
      requesterId: mechanicTwo.id,
      message: 'Extra cleaning needed near connector',
      reason: 'Dust and corrosion around the rear glass connector.',
      amount: 450,
      urgency: RequestUrgency.normal,
      status: ApprovalState.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 55)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 55)),
      blocksWork: false,
    ),
  ];

  static final progressUpdates = <ProgressUpdate>[
    ProgressUpdate(
      id: 'update-1',
      jobId: 'job-1',
      carId: 'car-1',
      senderId: masterMechanicOne.id,
      message: 'Engine bay inspection completed and consumables are staged.',
      photoPaths: const [
        'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=1200&q=80',
      ],
      forwardedToCustomer: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
    ),
    ProgressUpdate(
      id: 'update-2',
      jobId: 'job-7',
      carId: 'car-7',
      senderId: mechanicOne.id,
      message: 'Vehicle is on lift and old mount is being removed.',
      keptInternal: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  static final attendanceRecords = <StaffAttendance>[
    StaffAttendance(
      id: 'att-1',
      staffUserId: masterMechanicOne.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 5),
      status: AttendanceStatus.present,
      locationVerification: VerificationResult.verified,
      faceVerification: VerificationResult.unavailable,
      notes: 'Face setup pending in demo.',
    ),
    StaffAttendance(
      id: 'att-2',
      staffUserId: masterMechanicTwo.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 42),
      status: AttendanceStatus.late,
      locationVerification: VerificationResult.verified,
      faceVerification: VerificationResult.unavailable,
      notes: 'Late due to road work near Tolichowki.',
    ),
    StaffAttendance(
      id: 'att-3',
      staffUserId: mechanicOne.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 8, minute: 58),
      status: AttendanceStatus.present,
      locationVerification: VerificationResult.verified,
      faceVerification: VerificationResult.unavailable,
    ),
    StaffAttendance(
      id: 'att-4',
      staffUserId: mechanicTwo.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 15),
      status: AttendanceStatus.present,
      locationVerification: VerificationResult.verified,
      faceVerification: VerificationResult.unavailable,
    ),
    StaffAttendance(
      id: 'att-5',
      staffUserId: mechanicThree.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 8, minute: 50),
      status: AttendanceStatus.present,
      locationVerification: VerificationResult.verified,
      faceVerification: VerificationResult.unavailable,
      notes: 'Out for pickup duty.',
    ),
    StaffAttendance(
      id: 'att-6',
      staffUserId: mechanicFour.id,
      date: DateTime.now(),
      checkInTime: DateTime.now().copyWith(hour: 0, minute: 0),
      status: AttendanceStatus.leave,
      locationVerification: VerificationResult.pending,
      faceVerification: VerificationResult.pending,
      notes: 'Half-day leave approved for morning.',
    ),
  ];

  static final leaveRequests = <LeaveRequest>[
    LeaveRequest(
      id: 'leave-1',
      staffUserId: mechanicFour.id,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      leaveType: 'Half Day',
      reason: 'Family appointment in the morning.',
      status: ApprovalState.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LeaveRequest(
      id: 'leave-2',
      staffUserId: mechanicTwo.id,
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      leaveType: 'Personal Leave',
      reason: 'Travel to native place.',
      status: ApprovalState.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  static final advances = <StaffAdvance>[
    StaffAdvance(
      id: 'advance-1',
      staffUserId: mechanicOne.id,
      amount: 5000,
      date: DateTime.now().subtract(const Duration(days: 12)),
      reason: 'School fees',
      cutMethod: 'Deduct 2500 for two months',
      remainingAmount: 2500,
      status: AdvanceStatus.active,
    ),
    StaffAdvance(
      id: 'advance-2',
      staffUserId: masterMechanicTwo.id,
      amount: 8000,
      date: DateTime.now().subtract(const Duration(days: 20)),
      reason: 'Medical expense',
      cutMethod: 'Deduct from current month',
      remainingAmount: 0,
      status: AdvanceStatus.deducted,
    ),
  ];

  static final salaryRecords = <SalaryRecord>[
    SalaryRecord(
      id: 'salary-1',
      staffUserId: masterMechanicOne.id,
      monthLabel: 'May 2026',
      baseSalary: 52000,
      presentDays: 25,
      leaveDays: 1,
      absentDays: 0,
      halfDays: 0,
      lateMarks: 1,
      advanceDeduction: 0,
      bonus: 2500,
      manualDeduction: 0,
      finalPayable: 54500,
      isPaid: true,
      generatedAt: DateTime(2026, 5, 31),
    ),
    SalaryRecord(
      id: 'salary-2',
      staffUserId: mechanicOne.id,
      monthLabel: 'May 2026',
      baseSalary: 27500,
      presentDays: 24,
      leaveDays: 1,
      absentDays: 1,
      halfDays: 0,
      lateMarks: 2,
      advanceDeduction: 2500,
      bonus: 800,
      manualDeduction: 500,
      finalPayable: 25300,
      isPaid: true,
      generatedAt: DateTime(2026, 5, 31),
    ),
    SalaryRecord(
      id: 'salary-3',
      staffUserId: mechanicTwo.id,
      monthLabel: 'June 2026',
      baseSalary: 26000,
      presentDays: 14,
      leaveDays: 0,
      absentDays: 0,
      halfDays: 0,
      lateMarks: 0,
      advanceDeduction: 0,
      bonus: 0,
      manualDeduction: 0,
      finalPayable: 26000,
      generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static final staffDocuments = <StaffDocument>[
    StaffDocument(
      id: 'staff-doc-1',
      staffUserId: mechanicOne.id,
      title: 'May 2026 Payslip',
      category: 'Payslip',
      amount: 25300,
      createdAt: DateTime(2026, 5, 31),
    ),
    StaffDocument(
      id: 'staff-doc-2',
      staffUserId: masterMechanicOne.id,
      title: 'May 2026 Payslip',
      category: 'Payslip',
      amount: 54500,
      createdAt: DateTime(2026, 5, 31),
    ),
    StaffDocument(
      id: 'staff-doc-3',
      staffUserId: mechanicThree.id,
      title: 'Driving License Copy',
      category: 'Staff Document',
      filePath:
          'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
  ];

  static final timelineEvents = <CarTimelineEvent>[
    CarTimelineEvent(
      id: 'timeline-1',
      carId: 'car-3',
      jobId: 'job-3',
      title: 'Pickup mechanic assigned',
      message: 'Arjun Reddy will pick up the car today.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    CarTimelineEvent(
      id: 'timeline-2',
      carId: 'car-4',
      jobId: 'job-4',
      title: 'Car received',
      message: 'Vehicle is accepted at the garage and waiting for assignment.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      audiences: const [TimelineAudience.owner, TimelineAudience.staff],
    ),
    CarTimelineEvent(
      id: 'timeline-3',
      carId: 'car-6',
      jobId: 'job-6',
      title: 'Job card sent for approval',
      message: 'Trip inspection job card is waiting for customer approval.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    CarTimelineEvent(
      id: 'timeline-4',
      carId: 'car-7',
      jobId: 'job-7',
      title: 'Work started',
      message: 'Approved work has started with assigned mechanics.',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(
      id: 'note-1',
      userId: customerUser.id,
      title: 'Work started',
      message: 'Your MG Hector service job has moved into Work In Progress.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'note-2',
      userId: customerUser.id,
      title: 'Job card ready',
      message: 'A job card is waiting for approval.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'note-3',
      userId: ownerUser.id,
      title: 'Pickup scheduled',
      message: 'Honda City ZX pickup is scheduled for Ananya Rao.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    AppNotification(
      id: 'note-4',
      userId: mechanicThree.id,
      title: 'Pickup assigned',
      message: 'Honda City ZX pickup is assigned to you.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AppNotification(
      id: 'note-5',
      userId: masterMechanicOne.id,
      title: 'Job card waiting',
      message:
          'Toyota Innova Crysta job card is waiting for customer approval.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
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
    GaragePhotoUpdate(
      id: 'photo-3',
      userId: secondCustomerUser.id,
      carId: 'car-7',
      imagePath:
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=1200&q=80',
      caption: 'Engine mount crack shown before replacement.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static final messages = <SupportMessage>[
    SupportMessage(
      id: 'msg-1',
      userId: customerUser.id,
      topic: 'Service status',
      carId: 'car-1',
      message: 'Please confirm if the rear defogger part has arrived.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      channel: ChatChannel.general,
    ),
    SupportMessage(
      id: 'msg-2',
      userId: customerUser.id,
      topic: 'Service status',
      carId: 'car-1',
      message: 'The part is in stock and installation is under way.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
      channel: ChatChannel.general,
      sentByOwner: true,
    ),
    SupportMessage(
      id: 'msg-3',
      userId: customerUser.id,
      topic: 'Job card',
      carId: 'car-6',
      message: 'Job card JOB-4124 is ready for approval.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      channel: ChatChannel.general,
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
    if (code != '12345') return null;
    final normalized = _normalizeIndianPhoneForStorage(phone);
    for (final user in users) {
      if (_normalizeIndianPhoneForStorage(user.phone) == normalized) {
        return AppSession(user: user, token: 'demo-token');
      }
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

  static String _normalizeIndianPhoneForStorage(String phone) {
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

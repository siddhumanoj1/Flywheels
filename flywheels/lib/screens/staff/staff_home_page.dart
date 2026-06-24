import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MasterMechanicHomePage extends StatelessWidget {
  const MasterMechanicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaffHomePage(isMasterMechanic: true);
  }
}

class MechanicHomePage extends StatelessWidget {
  const MechanicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaffHomePage(isMasterMechanic: false);
  }
}

class _StaffHomePage extends StatefulWidget {
  const _StaffHomePage({required this.isMasterMechanic});

  final bool isMasterMechanic;

  @override
  State<_StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<_StaffHomePage> {
  final _picker = ImagePicker();
  int _currentIndex = 0;

  Future<void> _showTeamSheet(ServiceJob job, StaffProfile staff) async {
    final controller = FlywheelsScope.read(context);
    final selected = <String>{...job.mechanicIds};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request mechanic team',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...controller.mechanics.map(
                      (mechanic) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(mechanic.id),
                        title: Text(mechanic.name),
                        subtitle: Text(mechanic.primarySkill),
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              selected.add(mechanic.id);
                            } else {
                              selected.remove(mechanic.id);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () {
                                controller.proposeMechanicTeam(
                                  jobId: job.id,
                                  masterMechanicId: staff.id,
                                  mechanicIds: selected.toList(),
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Send to owner for approval'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showJobCardSheet(ServiceJob job, StaffProfile staff) async {
    final controller = FlywheelsScope.read(context);
    final observationController = TextEditingController();
    final actionController = TextEditingController();
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
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prepare job card',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observationController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Inspection observations',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: actionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Recommended work',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.createMasterJobCard(
                        jobId: job.id,
                        masterMechanicId: staff.id,
                        observations: observationController.text,
                        items: [
                          DocumentLineItem(
                            description:
                                observationController.text.trim().isEmpty
                                ? 'Inspection observations'
                                : observationController.text.trim(),
                            quantity: 1,
                            unitPrice: 0,
                            total: 0,
                          ),
                          if (actionController.text.trim().isNotEmpty)
                            DocumentLineItem(
                              description: actionController.text.trim(),
                              quantity: 1,
                              unitPrice: 0,
                              total: 0,
                            ),
                        ],
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.assignment_rounded),
                    label: const Text('Send job card to owner'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    observationController.dispose();
    actionController.dispose();
  }

  Future<void> _showWorkRequestSheet(ServiceJob job, StaffProfile staff) async {
    final controller = FlywheelsScope.read(context);
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String? photoPath;
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
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request approval',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Part / work title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Why is approval needed?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (photoPath != null)
                        AppImage(
                          path: photoPath!,
                          width: double.infinity,
                          height: 130,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image == null) return;
                          setSheetState(() => photoPath = image.path);
                        },
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(
                          photoPath == null ? 'Attach photo' : 'Change photo',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.submitWorkApprovalRequest(
                              jobId: job.id,
                              staffId: staff.id,
                              title: titleController.text,
                              message: messageController.text,
                              photoPath: photoPath,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.approval_outlined),
                          label: const Text('Send to owner'),
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
    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _showProgressUpdateSheet(
    ServiceJob job,
    StaffProfile staff,
  ) async {
    final controller = FlywheelsScope.read(context);
    final messageController = TextEditingController();
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
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send update',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Progress update',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final detail = messageController.text.trim();
                      controller.sendStatusUpdate(
                        job.id,
                        detail.isEmpty
                            ? '${staff.name} shared a progress update.'
                            : '${staff.name}: $detail',
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Update sent to owner.')),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Send to owner'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    messageController.dispose();
  }

  Future<void> _showAdvanceSheet(StaffProfile staff) async {
    final controller = FlywheelsScope.read(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
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
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request salary advance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.requestSalaryAdvance(
                        staffId: staff.id,
                        amount:
                            double.tryParse(
                              amountController.text.replaceAll(
                                RegExp(r'[^0-9.]'),
                                '',
                              ),
                            ) ??
                            0,
                        reason: reasonController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Send request'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    amountController.dispose();
    reasonController.dispose();
  }

  Future<void> _showLeaveSheet(StaffProfile staff) async {
    final controller = FlywheelsScope.read(context);
    final reasonController = TextEditingController();
    var fromDate = DateTime.now().add(const Duration(days: 1));
    var toDate = fromDate;
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
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request leave',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('From'),
                            subtitle: Text(formatShortDate(fromDate)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fromDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 180),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  fromDate = picked;
                                  if (toDate.isBefore(fromDate)) {
                                    toDate = fromDate;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('To'),
                            subtitle: Text(formatShortDate(toDate)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: toDate,
                                firstDate: fromDate,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 180),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => toDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          controller.requestLeave(
                            staffId: staff.id,
                            fromDate: fromDate,
                            toDate: toDate,
                            reason: reasonController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.event_busy_outlined),
                        label: const Text('Send leave request'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final staff = controller.staffForUser(controller.session!.user.id);
    if (staff == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff')),
        body: const Center(child: Text('No staff profile found.')),
      );
    }

    final tabs = [
      _StaffDashboardTab(staff: staff),
      _StaffChatTab(staff: staff, onSendUpdate: _showProgressUpdateSheet),
      _StaffCarsTab(
        staff: staff,
        isMasterMechanic: widget.isMasterMechanic,
        onRequestApproval: _showWorkRequestSheet,
        onSendUpdate: _showProgressUpdateSheet,
        onProposeTeam: widget.isMasterMechanic ? _showTeamSheet : null,
        onCreateJobCard: widget.isMasterMechanic ? _showJobCardSheet : null,
      ),
      _StaffAttendanceTab(staff: staff, onRequestLeave: _showLeaveSheet),
      _StaffSalaryTab(staff: staff, onRequestAdvance: _showAdvanceSheet),
    ];

    const items = [
      AppBottomNavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
      AppBottomNavItem(
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      AppBottomNavItem(
        label: 'Car',
        icon: Icons.directions_car_outlined,
        activeIcon: Icons.directions_car_rounded,
      ),
      AppBottomNavItem(
        label: 'Attendance',
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg_rounded,
      ),
      AppBottomNavItem(
        label: 'Salary',
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments_rounded,
      ),
    ];
    final pendingApprovalCount = controller.workApprovalRequests
        .where((request) => request.staffId == staff.id)
        .where((request) => request.status == RequestStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 33),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _currentIndex == 0
                    ? staff.role.label
                    : items[_currentIndex].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        badgeCounts: [0, 0, pendingApprovalCount, 0, 0],
      ),
    );
  }
}

class _StaffDashboardTab extends StatelessWidget {
  const _StaffDashboardTab({required this.staff});

  final StaffProfile staff;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final jobs = controller.jobsForStaff(staff.id);
    final todayAttendance = controller.attendanceForStaff(staff.id).firstOrNull;
    final advances = controller.advancesForStaff(staff.id);
    final pendingApprovals = controller.workApprovalRequests
        .where((request) => request.staffId == staff.id)
        .where((request) => request.status == RequestStatus.pending)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              MessengerAvatar(
                path: staff.profileImagePath,
                initials: staff.name.substring(0, 1),
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppPalette.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff.role.label} | ${staff.primarySkill}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.28,
          children: [
            _StaffMetricCard(
              icon: Icons.directions_car_rounded,
              label: 'Assigned cars',
              value: jobs.length.toString(),
            ),
            _StaffMetricCard(
              icon: Icons.how_to_reg_rounded,
              label: 'Attendance',
              value: todayAttendance?.status.label ?? 'Not marked',
            ),
            _StaffMetricCard(
              icon: Icons.approval_rounded,
              label: 'Approvals',
              value: pendingApprovals.toString(),
            ),
            _StaffMetricCard(
              icon: Icons.payments_rounded,
              label: 'Salary',
              value: formatCurrency(staff.monthlySalary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Assigned cars', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          const _StaffEmptyCard(message: 'No cars assigned right now.'),
        ...jobs.take(4).map((job) => _StaffJobTile(job: job)),
        if (advances.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Advance requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...advances
              .take(3)
              .map(
                (advance) => _StaffRequestTile(
                  title: formatCurrency(advance.amount),
                  subtitle: '${advance.reason} | ${advance.status.label}',
                  icon: Icons.payments_outlined,
                ),
              ),
        ],
      ],
    );
  }
}

class _StaffChatTab extends StatelessWidget {
  const _StaffChatTab({required this.staff, required this.onSendUpdate});

  final StaffProfile staff;
  final void Function(ServiceJob job, StaffProfile staff) onSendUpdate;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final jobs = controller.jobsForStaff(staff.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner chat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send progress updates through the owner.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Car messages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (jobs.isEmpty)
          const _StaffEmptyCard(message: 'No assigned cars available.'),
        ...jobs.map(
          (job) => _StaffCommunicationCard(
            job: job,
            staff: staff,
            onSendUpdate: onSendUpdate,
          ),
        ),
      ],
    );
  }
}

class _StaffCommunicationCard extends StatelessWidget {
  const _StaffCommunicationCard({
    required this.job,
    required this.staff,
    required this.onSendUpdate,
  });

  final ServiceJob job;
  final StaffProfile staff;
  final void Function(ServiceJob job, StaffProfile staff) onSendUpdate;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final car = controller.carForJob(job);
    final customer = car == null ? null : controller.customerForCar(car.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (car != null)
                  AppImage(
                    path: car.imageUrl,
                    width: 64,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                  ),
                if (car != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car?.carNumber ?? 'Assigned car',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${customer?.name ?? 'Customer'} | ${job.status.label}',
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
                FilledButton.icon(
                  onPressed: () => onSendUpdate(job, staff),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Send update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffCarsTab extends StatelessWidget {
  const _StaffCarsTab({
    required this.staff,
    required this.isMasterMechanic,
    required this.onRequestApproval,
    required this.onSendUpdate,
    this.onProposeTeam,
    this.onCreateJobCard,
  });

  final StaffProfile staff;
  final bool isMasterMechanic;
  final void Function(ServiceJob job, StaffProfile staff) onRequestApproval;
  final void Function(ServiceJob job, StaffProfile staff) onSendUpdate;
  final void Function(ServiceJob job, StaffProfile staff)? onProposeTeam;
  final void Function(ServiceJob job, StaffProfile staff)? onCreateJobCard;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final jobs = controller.jobsForStaff(staff.id);
    final approvalMessages =
        controller.workApprovalRequests
            .where((request) => request.staffId == staff.id)
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final jobCards = isMasterMechanic
        ? jobs
              .expand((job) => controller.documentsForCar(job.carId))
              .where((document) => document.type == DocumentType.jobCard)
              .toList()
        : <ServiceDocument>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (jobs.isEmpty)
          const _StaffEmptyCard(message: 'No car assignments yet.'),
        ...jobs.map((job) {
          final car = controller.carForJob(job);
          final customer = car == null
              ? null
              : controller.customerForCar(car.id);
          final workRequests = controller.workRequestsForJob(job.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (car != null)
                        AppImage(
                          path: car.imageUrl,
                          width: 76,
                          height: 58,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      if (car != null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car?.carNumber ?? 'Assigned car',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${customer?.name ?? 'Customer'} | ${job.status.label}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HorizontalServiceTimeline(status: job.status, compact: true),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isMasterMechanic) ...[
                        OutlinedButton.icon(
                          onPressed: () => onProposeTeam?.call(job, staff),
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Mechanics'),
                        ),
                        FilledButton.icon(
                          onPressed: () => onCreateJobCard?.call(job, staff),
                          icon: const Icon(Icons.assignment_rounded),
                          label: const Text('Job card'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => onRequestApproval(job, staff),
                        icon: const Icon(Icons.approval_outlined),
                        label: const Text('Approval'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onSendUpdate(job, staff),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Update'),
                      ),
                    ],
                  ),
                  if (workRequests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...workRequests
                        .take(2)
                        .map(
                          (request) => _StaffRequestTile(
                            title: request.title,
                            subtitle:
                                '${request.status.label}${request.forwardedToCustomer ? ' | Customer' : ''}',
                            icon: Icons.approval_outlined,
                          ),
                        ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          'Approval messages',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (approvalMessages.isEmpty)
          const _StaffEmptyCard(message: 'No approval messages yet.'),
        ...approvalMessages.map((request) {
          final job = jobs
              .where((item) => item.id == request.jobId)
              .firstOrNull;
          final car = job == null ? null : controller.carForJob(job);
          return _StaffRequestTile(
            title: request.title,
            subtitle:
                '${request.status.label} | ${car?.carNumber ?? 'Assigned car'} | ${request.message}',
            icon: _requestStatusIcon(request.status),
          );
        }),
        if (isMasterMechanic) ...[
          const SizedBox(height: 16),
          Text('Job cards', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (jobCards.isEmpty)
            const _StaffEmptyCard(message: 'No job cards sent yet.'),
          ...jobCards.map(
            (document) => _StaffRequestTile(
              title: document.title,
              subtitle:
                  '${_approvalStateLabel(document.approvalState)} | ${formatCurrency(document.total)}',
              icon: Icons.assignment_outlined,
            ),
          ),
        ],
      ],
    );
  }
}

class _StaffAttendanceTab extends StatelessWidget {
  const _StaffAttendanceTab({
    required this.staff,
    required this.onRequestLeave,
  });

  final StaffProfile staff;
  final ValueChanged<StaffProfile> onRequestLeave;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final entries = controller.attendanceForStaff(staff.id);
    final leaves = controller.leavesForStaff(staff.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily attendance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Face and location checks are recorded with the attendance entry.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => controller.logAttendance(
                          staffId: staff.id,
                          status: AttendanceStatus.present,
                          note: 'Face ID and garage location verified',
                        ),
                        icon: const Icon(Icons.face_retouching_natural),
                        label: const Text('Check in'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onRequestLeave(staff),
                        icon: const Icon(Icons.event_busy_outlined),
                        label: const Text('Leave'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Attendance history',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const _StaffEmptyCard(message: 'No attendance records yet.'),
        ...entries.map(
          (entry) => _StaffRequestTile(
            title: '${entry.status.label} | ${formatShortDate(entry.date)}',
            subtitle:
                'Face ${entry.faceVerified ? 'verified' : 'pending'} | Location ${entry.locationVerified ? 'verified' : 'pending'}',
            icon: Icons.how_to_reg_outlined,
          ),
        ),
        const SizedBox(height: 14),
        Text('Leave requests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (leaves.isEmpty)
          const _StaffEmptyCard(message: 'No leave requests.'),
        ...leaves.map(
          (leave) => _StaffRequestTile(
            title:
                '${formatShortDate(leave.fromDate)} - ${formatShortDate(leave.toDate)}',
            subtitle: '${leave.reason} | ${leave.status.label}',
            icon: Icons.event_busy_outlined,
          ),
        ),
      ],
    );
  }
}

class _StaffSalaryTab extends StatelessWidget {
  const _StaffSalaryTab({required this.staff, required this.onRequestAdvance});

  final StaffProfile staff;
  final ValueChanged<StaffProfile> onRequestAdvance;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final advances = controller.advancesForStaff(staff.id);
    final slips = controller.salarySlipsForStaff(staff.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(staff.monthlySalary),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => onRequestAdvance(staff),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Request advance'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Payslips', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (slips.isEmpty)
          const _StaffEmptyCard(message: 'No salary slips yet.'),
        ...slips.map(
          (slip) => _StaffRequestTile(
            title: '${slip.monthLabel} | ${formatCurrency(slip.netPay)}',
            subtitle:
                'Gross ${formatCurrency(slip.grossPay)} | Advance ${formatCurrency(slip.advanceDeduction)} | Leave ${formatCurrency(slip.leaveDeduction)}',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(height: 14),
        Text('Advances', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (advances.isEmpty)
          const _StaffEmptyCard(message: 'No advance requests.'),
        ...advances.map(
          (advance) => _StaffRequestTile(
            title:
                '${formatCurrency(advance.amount)} | ${advance.status.label}',
            subtitle: advance.reason,
            icon: Icons.payments_outlined,
          ),
        ),
      ],
    );
  }
}

class _StaffJobTile extends StatelessWidget {
  const _StaffJobTile({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final car = controller.carForJob(job);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.directions_car_outlined),
      title: Text(car?.carNumber ?? 'Assigned car'),
      subtitle: Text('${car?.model ?? '-'} | ${job.status.label}'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _StaffMetricCard extends StatelessWidget {
  const _StaffMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StaffRequestTile extends StatelessWidget {
  const _StaffRequestTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffEmptyCard extends StatelessWidget {
  const _StaffEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

String _approvalStateLabel(ApprovalState state) {
  switch (state) {
    case ApprovalState.pending:
      return 'Pending';
    case ApprovalState.approved:
      return 'Approved';
    case ApprovalState.rejected:
      return 'Rejected';
  }
}

IconData _requestStatusIcon(RequestStatus status) {
  switch (status) {
    case RequestStatus.pending:
      return Icons.hourglass_top_outlined;
    case RequestStatus.approved:
      return Icons.check_circle_outline_rounded;
    case RequestStatus.rejected:
      return Icons.cancel_outlined;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

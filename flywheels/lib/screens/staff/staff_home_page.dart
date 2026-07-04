import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/google_maps_link_service.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/car_anatomy_inspection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final car = controller.carForJob(job);
    final observationController = TextEditingController();
    final actionController = TextEditingController();
    var inspectionMarks = <VehicleInspectionMark>[];
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
                      Text(
                        'Vehicle inspection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      CarAnatomyInspectionEditor(
                        marks: inspectionMarks,
                        initialBodyType: vehicleBodyTypeForModel(
                          car?.model ?? '',
                        ),
                        onChanged: (marks) =>
                            setSheetState(() => inspectionMarks = marks),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final document = controller.createMasterJobCard(
                              jobId: job.id,
                              masterMechanicId: staff.id,
                              observations: observationController.text,
                              inspectionMarks: inspectionMarks,
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
                            if (document == null) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Job card is available after vehicle receipt.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.assignment_rounded),
                          label: const Text('Send job card to owner'),
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

  Future<void> _showGaragePhotoSheet(
    CarProfile car,
    StaffProfile staff, {
    JobStatus? status,
  }) async {
    final controller = FlywheelsScope.read(context);
    final captionController = TextEditingController();
    final caption = await showModalBottomSheet<String>(
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
                  'Add photo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  status == null
                      ? 'Add a progress photo for ${car.carNumber}.'
                      : 'This photo will update ${car.carNumber} to ${status.label}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Photo note'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(captionController.text),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Choose photo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    captionController.dispose();
    if (!mounted || caption == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;

    controller.addGaragePhoto(
      carId: car.id,
      imagePath: image.path,
      caption: caption.trim().isEmpty
          ? '${staff.name} shared a progress photo.'
          : '${staff.name}: ${caption.trim()}',
      status: status,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Photo update sent.')));
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
        onAddPhoto: _showGaragePhotoSheet,
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
    final mapUri = _pickupMapUriForJob(job);

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
            if (job.pickupAddress != null && job.pickupAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pickup address: ${job.pickupAddress}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (job.pickupPhotoPath != null &&
                job.pickupPhotoPath!.trim().isNotEmpty) ...[
              AppImage(
                path: job.pickupPhotoPath!,
                width: double.infinity,
                height: 132,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mapUri != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        launchUrl(mapUri, mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pickup map'),
                  ),
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

enum _StaffCarFilter {
  all,
  approvals,
  pickupScheduled,
  pickupDone,
  received,
  underInspection,
  workInProgress,
  completed,
  deliveryScheduled,
  onRoad,
}

extension _StaffCarFilterX on _StaffCarFilter {
  String get label {
    switch (this) {
      case _StaffCarFilter.all:
        return 'All';
      case _StaffCarFilter.approvals:
        return 'Approvals';
      case _StaffCarFilter.pickupScheduled:
        return JobStatus.pickupScheduled.label;
      case _StaffCarFilter.pickupDone:
        return JobStatus.pickupDone.label;
      case _StaffCarFilter.received:
        return JobStatus.received.label;
      case _StaffCarFilter.underInspection:
        return JobStatus.underInspection.label;
      case _StaffCarFilter.workInProgress:
        return JobStatus.workInProgress.label;
      case _StaffCarFilter.completed:
        return JobStatus.completed.label;
      case _StaffCarFilter.deliveryScheduled:
        return JobStatus.deliveryScheduled.label;
      case _StaffCarFilter.onRoad:
        return JobStatus.onRoad.label;
    }
  }

  IconData get icon {
    switch (this) {
      case _StaffCarFilter.all:
        return Icons.directions_car_outlined;
      case _StaffCarFilter.approvals:
        return Icons.mark_chat_unread_outlined;
      case _StaffCarFilter.pickupScheduled:
        return Icons.local_shipping_outlined;
      case _StaffCarFilter.pickupDone:
        return Icons.inventory_2_outlined;
      case _StaffCarFilter.received:
        return Icons.home_repair_service_outlined;
      case _StaffCarFilter.underInspection:
        return Icons.search_rounded;
      case _StaffCarFilter.workInProgress:
        return Icons.handyman_outlined;
      case _StaffCarFilter.completed:
        return Icons.task_alt_rounded;
      case _StaffCarFilter.deliveryScheduled:
        return Icons.local_shipping_outlined;
      case _StaffCarFilter.onRoad:
        return Icons.route_rounded;
    }
  }
}

enum _StaffCarSort { approvalsFirst, status, carNumber, customer }

extension _StaffCarSortX on _StaffCarSort {
  String get label {
    switch (this) {
      case _StaffCarSort.approvalsFirst:
        return 'Approvals first';
      case _StaffCarSort.status:
        return 'Status';
      case _StaffCarSort.carNumber:
        return 'Car number';
      case _StaffCarSort.customer:
        return 'Customer';
    }
  }
}

class _StaffCarsTab extends StatefulWidget {
  const _StaffCarsTab({
    required this.staff,
    required this.isMasterMechanic,
    required this.onRequestApproval,
    required this.onSendUpdate,
    required this.onAddPhoto,
    this.onProposeTeam,
    this.onCreateJobCard,
  });

  final StaffProfile staff;
  final bool isMasterMechanic;
  final void Function(ServiceJob job, StaffProfile staff) onRequestApproval;
  final void Function(ServiceJob job, StaffProfile staff) onSendUpdate;
  final void Function(CarProfile car, StaffProfile staff, {JobStatus? status})
  onAddPhoto;
  final void Function(ServiceJob job, StaffProfile staff)? onProposeTeam;
  final void Function(ServiceJob job, StaffProfile staff)? onCreateJobCard;

  @override
  State<_StaffCarsTab> createState() => _StaffCarsTabState();
}

class _StaffCarsTabState extends State<_StaffCarsTab> {
  _StaffCarFilter _filter = _StaffCarFilter.all;
  _StaffCarSort _sort = _StaffCarSort.approvalsFirst;
  String _searchQuery = '';

  List<WorkApprovalRequest> _approvalRequestsForJob(
    AppController controller,
    ServiceJob job,
  ) {
    return controller
        .workRequestsForJob(job.id)
        .where(
          (request) =>
              widget.isMasterMechanic || request.staffId == widget.staff.id,
        )
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<WorkApprovalRequest> _pendingApprovalRequestsForJob(
    AppController controller,
    ServiceJob job,
  ) {
    return _approvalRequestsForJob(
      controller,
      job,
    ).where((request) => request.status == RequestStatus.pending).toList();
  }

  bool _matchesFilter(
    ServiceJob job,
    List<WorkApprovalRequest> pendingApprovals,
  ) {
    switch (_filter) {
      case _StaffCarFilter.all:
        return true;
      case _StaffCarFilter.approvals:
        return pendingApprovals.isNotEmpty;
      case _StaffCarFilter.pickupScheduled:
        return job.status == JobStatus.pickupScheduled;
      case _StaffCarFilter.pickupDone:
        return job.status == JobStatus.pickupDone;
      case _StaffCarFilter.received:
        return job.status == JobStatus.received;
      case _StaffCarFilter.underInspection:
        return job.status == JobStatus.underInspection;
      case _StaffCarFilter.workInProgress:
        return job.status == JobStatus.workInProgress;
      case _StaffCarFilter.completed:
        return job.status == JobStatus.completed;
      case _StaffCarFilter.deliveryScheduled:
        return job.status == JobStatus.deliveryScheduled;
      case _StaffCarFilter.onRoad:
        return job.status == JobStatus.onRoad;
    }
  }

  bool _matchesSearch(
    AppController controller,
    ServiceJob job,
    CarProfile car,
    List<WorkApprovalRequest> approvals,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final customer = controller.customerForCar(car.id);
    final assignedNames = _assignedPeople(
      controller,
      job,
    ).map((person) => '${person.name} ${person.roleLabel}').join(' ');
    final approvalText = approvals
        .map((request) => '${request.title} ${request.message}')
        .join(' ');
    final text = [
      car.carNumber,
      car.model,
      car.fuelType,
      car.year.toString(),
      customer?.name ?? '',
      customer?.phone ?? '',
      job.status.label,
      assignedNames,
      approvalText,
    ].join(' ').toLowerCase();
    return text.contains(query);
  }

  List<ServiceJob> _visibleJobs(AppController controller) {
    final jobs = controller.jobsForStaff(widget.staff.id).where((job) {
      final car = controller.carForJob(job);
      if (car == null) return false;
      final approvals = _approvalRequestsForJob(controller, job);
      final pendingApprovals = approvals
          .where((request) => request.status == RequestStatus.pending)
          .toList();
      return _matchesFilter(job, pendingApprovals) &&
          _matchesSearch(controller, job, car, approvals);
    }).toList();
    jobs.sort((left, right) => _compareJobs(controller, left, right));
    return jobs;
  }

  int _compareJobs(
    AppController controller,
    ServiceJob left,
    ServiceJob right,
  ) {
    final leftCar = controller.carForJob(left);
    final rightCar = controller.carForJob(right);
    final leftApprovals = _pendingApprovalRequestsForJob(controller, left);
    final rightApprovals = _pendingApprovalRequestsForJob(controller, right);

    int compareApprovalsFirst() {
      final approvalCompare = rightApprovals.length.compareTo(
        leftApprovals.length,
      );
      if (approvalCompare != 0) return approvalCompare;
      final leftLatest = leftApprovals.firstOrNull?.createdAt;
      final rightLatest = rightApprovals.firstOrNull?.createdAt;
      if (leftLatest != null && rightLatest != null) {
        final dateCompare = rightLatest.compareTo(leftLatest);
        if (dateCompare != 0) return dateCompare;
      }
      return (leftCar?.carNumber ?? '').compareTo(rightCar?.carNumber ?? '');
    }

    switch (_sort) {
      case _StaffCarSort.approvalsFirst:
        return compareApprovalsFirst();
      case _StaffCarSort.status:
        final statusCompare = left.status.index.compareTo(right.status.index);
        if (statusCompare != 0) return statusCompare;
        return compareApprovalsFirst();
      case _StaffCarSort.carNumber:
        return (leftCar?.carNumber ?? '').compareTo(rightCar?.carNumber ?? '');
      case _StaffCarSort.customer:
        final leftCustomer = leftCar == null
            ? ''
            : controller.customerForCar(leftCar.id)?.name ?? '';
        final rightCustomer = rightCar == null
            ? ''
            : controller.customerForCar(rightCar.id)?.name ?? '';
        final customerCompare = leftCustomer.compareTo(rightCustomer);
        if (customerCompare != 0) return customerCompare;
        return (leftCar?.carNumber ?? '').compareTo(rightCar?.carNumber ?? '');
    }
  }

  IconData _statusIcon(ServiceJob job) {
    switch (job.status) {
      case JobStatus.pickupScheduled:
        return Icons.local_shipping_outlined;
      case JobStatus.pickupDone:
        return Icons.inventory_2_outlined;
      case JobStatus.received:
        return Icons.home_repair_service_outlined;
      case JobStatus.underInspection:
        return Icons.search_rounded;
      case JobStatus.workInProgress:
        return Icons.handyman_outlined;
      case JobStatus.completed:
        return Icons.task_alt_rounded;
      case JobStatus.deliveryScheduled:
        return Icons.local_shipping_outlined;
      case JobStatus.onRoad:
        return Icons.route_rounded;
    }
  }

  bool _isPickupAssignedToStaff(ServiceJob job) {
    final staff = widget.staff;
    return job.pickupState == PickupState.assigned &&
        (job.pickupPersonName?.toLowerCase() == staff.name.toLowerCase() ||
            job.pickupPersonPhone == staff.phone ||
            job.mechanicIds.contains(staff.id));
  }

  void _markPickupDone(
    BuildContext context,
    AppController controller,
    ServiceJob job,
  ) {
    controller.completePickup(job.id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pickup marked done.')));
  }

  void _setStatus(
    BuildContext context,
    AppController controller,
    ServiceJob job,
    JobStatus status,
    String message,
  ) {
    controller.setJobStatus(job.id, status);
    controller.sendStatusUpdate(job.id, message);
    Navigator.of(context).pop();
  }

  void _showCarDetail(
    BuildContext context,
    AppController controller,
    ServiceJob job,
  ) {
    final car = controller.carForJob(job);
    if (car == null) return;
    final customer = controller.customerForCar(car.id);
    final documents = controller.documentsForCar(car.id);
    final history = controller.jobsForCar(car.id);
    final photos = controller.photoUpdatesForCar(car.id);
    final approvals = _approvalRequestsForJob(controller, job);
    final pendingApprovals = _pendingApprovalRequestsForJob(controller, job);
    final mapUri = _pickupMapUriForJob(job);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.80,
              child: ListView(
                children: [
                  Row(
                    children: [
                      AppImage(
                        path: car.imageUrl,
                        width: 84,
                        height: 64,
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
                            Text('${customer?.name ?? '-'} | ${car.model}'),
                            Text(
                              customer?.phone ?? '-',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StaffCarStateCard(job: job),
                  const SizedBox(height: 12),
                  _StaffAssignedPeopleStrip(job: job),
                  const SizedBox(height: 12),
                  _StaffPickupInfoCard(job: job),
                  const SizedBox(height: 12),
                  if (pendingApprovals.isNotEmpty) ...[
                    Text(
                      'Approval messages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...pendingApprovals.map(_StaffApprovalMessageTile.new),
                    const SizedBox(height: 12),
                  ],
                  GearboxActionGrid(
                    children: [
                      if (widget.isMasterMechanic) ...[
                        AutomotiveControlButton(
                          icon: Icons.search_rounded,
                          label: 'Inspect',
                          active: job.status == JobStatus.underInspection,
                          onPressed:
                              job.status == JobStatus.received ||
                                  job.status == JobStatus.underInspection
                              ? () => _setStatus(
                                  context,
                                  controller,
                                  job,
                                  JobStatus.underInspection,
                                  '${widget.staff.name} started inspection.',
                                )
                              : null,
                        ),
                        AutomotiveControlButton(
                          icon: Icons.assignment_rounded,
                          label: 'Job card',
                          active: job.status == JobStatus.underInspection,
                          onPressed:
                              job.status == JobStatus.received ||
                                  job.status == JobStatus.underInspection
                              ? () => widget.onCreateJobCard?.call(
                                  job,
                                  widget.staff,
                                )
                              : null,
                        ),
                        AutomotiveControlButton(
                          icon: Icons.group_add_outlined,
                          label: 'Mechanics',
                          onPressed: () =>
                              widget.onProposeTeam?.call(job, widget.staff),
                        ),
                        AutomotiveControlButton(
                          icon: Icons.task_alt_rounded,
                          label: 'Complete',
                          active: job.status == JobStatus.completed,
                          onPressed: job.status == JobStatus.workInProgress
                              ? () => _setStatus(
                                  context,
                                  controller,
                                  job,
                                  JobStatus.completed,
                                  '${widget.staff.name} marked work complete.',
                                )
                              : null,
                        ),
                      ] else ...[
                        AutomotiveControlButton(
                          icon: Icons.local_shipping_outlined,
                          label: 'Pickup done',
                          active: job.pickupState == PickupState.completed,
                          onPressed:
                              _isPickupAssignedToStaff(job) &&
                                  job.status == JobStatus.pickupScheduled
                              ? () => _markPickupDone(context, controller, job)
                              : null,
                        ),
                        AutomotiveControlButton(
                          icon: Icons.task_alt_rounded,
                          label: 'Task done',
                          onPressed: job.status == JobStatus.workInProgress
                              ? () {
                                  controller.sendStatusUpdate(
                                    job.id,
                                    '${widget.staff.name} marked assigned work done.',
                                  );
                                  Navigator.of(context).pop();
                                }
                              : null,
                        ),
                      ],
                      AutomotiveControlButton(
                        icon: Icons.approval_outlined,
                        label: 'Approval',
                        active: pendingApprovals.isNotEmpty,
                        onPressed: () =>
                            widget.onRequestApproval(job, widget.staff),
                      ),
                      AutomotiveControlButton(
                        icon: Icons.notifications_active_outlined,
                        label: 'Update',
                        onPressed: () => widget.onSendUpdate(job, widget.staff),
                      ),
                      AutomotiveControlButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Photo',
                        onPressed: () => widget.onAddPhoto(car, widget.staff),
                      ),
                      if (widget.isMasterMechanic)
                        AutomotiveControlButton(
                          icon: Icons.handyman_outlined,
                          label: 'Work photo',
                          active: job.status == JobStatus.workInProgress,
                          onPressed: () => widget.onAddPhoto(
                            car,
                            widget.staff,
                            status: JobStatus.workInProgress,
                          ),
                        ),
                      if (mapUri != null)
                        AutomotiveControlButton(
                          icon: Icons.map_outlined,
                          label: 'Map',
                          onPressed: () => launchUrl(
                            mapUri,
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Approval messages',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (approvals.isEmpty)
                    const _StaffEmptyCard(message: 'No approval messages yet.'),
                  ...approvals.map(_StaffApprovalMessageTile.new),
                  const SizedBox(height: 14),
                  Text(
                    'Job history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...history.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.timeline_rounded),
                      title: Text(item.status.label),
                      subtitle: Text(
                        'ETA ${formatDateTime(item.expectedCompletion)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Documents',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (documents.isEmpty)
                    const _StaffEmptyCard(message: 'No documents yet.'),
                  ...documents.map(
                    (document) => _StaffRequestTile(
                      title: document.title,
                      subtitle:
                          '${document.type.label} | ${_approvalStateLabel(document.approvalState)} | ${formatCurrency(document.total)}',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Photos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (photos.isEmpty)
                    const _StaffEmptyCard(message: 'No photos yet.'),
                  ...photos
                      .take(4)
                      .map(
                        (photo) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: AppImage(
                            path: photo.imagePath,
                            width: 48,
                            height: 38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(photo.caption),
                          subtitle: Text(formatDateTime(photo.createdAt)),
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

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final jobs = _visibleJobs(controller);
    final allJobs = controller.jobsForStaff(widget.staff.id);
    final approvalMessages = allJobs
        .expand((job) => _approvalRequestsForJob(controller, job))
        .toList();
    final jobCards = widget.isMasterMechanic
        ? jobs
              .expand((job) => controller.documentsForCar(job.carId))
              .where((document) => document.type == DocumentType.jobCard)
              .toList()
        : <ServiceDocument>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Car profiles', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _searchQuery,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Search cars, customers, approvals',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<_StaffCarFilter>(
                initialValue: _filter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _StaffCarFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Icon(value.icon, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                value.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _filter = value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<_StaffCarSort>(
                initialValue: _sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort'),
                items: _StaffCarSort.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          const _StaffEmptyCard(message: 'No car profiles match this view.'),
        ...jobs.map((job) {
          final car = controller.carForJob(job);
          if (car == null) return const SizedBox.shrink();
          final customer = controller.customerForCar(car.id);
          final documents = controller.documentsForCar(car.id);
          final pendingApprovals = _pendingApprovalRequestsForJob(
            controller,
            job,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCarDetail(context, controller, job),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppImage(
                            path: car.imageUrl,
                            width: 76,
                            height: 58,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        car.carNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (pendingApprovals.isNotEmpty)
                                      _StaffApprovalBadge(
                                        count: pendingApprovals.length,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${customer?.name ?? '-'} | ${car.model}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                HorizontalServiceTimeline(
                                  status: job.status,
                                  compact: true,
                                ),
                                const SizedBox(height: 8),
                                _StaffAssignedPeopleStrip(job: job),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _StaffMetaChip(
                                      icon: _statusIcon(job),
                                      label: job.status.label,
                                    ),
                                    _StaffMetaChip(
                                      icon: Icons.description_outlined,
                                      label: '${documents.length} docs',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      if (pendingApprovals.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _StaffApprovalPreview(requests: pendingApprovals),
                      ],
                    ],
                  ),
                ),
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
        ...approvalMessages.map(_StaffApprovalMessageTile.new),
        if (widget.isMasterMechanic) ...[
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

class _StaffCarStateCard extends StatelessWidget {
  const _StaffCarStateCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.route_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.status.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HorizontalServiceTimeline(status: job.status),
        ],
      ),
    );
  }
}

class _StaffPickupInfoCard extends StatelessWidget {
  const _StaffPickupInfoCard({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    final mapUri = _pickupMapUriForJob(job);
    return Container(
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
              const Icon(Icons.local_shipping_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup ${job.pickupState.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Time ${formatDateTime(job.pickupTime)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Person ${job.pickupPersonName == null || job.pickupPersonName!.isEmpty ? 'Not assigned' : job.pickupPersonName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (job.pickupAddress != null && job.pickupAddress!.isNotEmpty)
            Text(
              'Address ${job.pickupAddress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (job.pickupPhotoPath != null &&
              job.pickupPhotoPath!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            AppImage(
              path: job.pickupPhotoPath!,
              width: double.infinity,
              height: 124,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          if (mapUri != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(mapUri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open map'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffAssignedPeopleStrip extends StatelessWidget {
  const _StaffAssignedPeopleStrip({required this.job});

  final ServiceJob job;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final people = _assignedPeople(controller, job);
    if (people.isEmpty) {
      return const _StaffMetaChip(
        icon: Icons.person_off_outlined,
        label: 'No person assigned',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: people
          .map(
            (person) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MessengerAvatar(
                    path: person.profileImagePath,
                    initials: _initials(person.name),
                    radius: 13,
                  ),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        person.roleLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StaffAssignedPerson {
  const _StaffAssignedPerson({
    required this.name,
    required this.roleLabel,
    this.profileImagePath,
  });

  final String name;
  final String roleLabel;
  final String? profileImagePath;
}

List<_StaffAssignedPerson> _assignedPeople(
  AppController controller,
  ServiceJob job,
) {
  final people = <_StaffAssignedPerson>[];
  final seen = <String>{};

  void addStaff(String staffId, String roleLabel) {
    final staff = controller.staffById(staffId);
    if (staff == null || !seen.add(staff.id)) return;
    people.add(
      _StaffAssignedPerson(
        name: staff.name,
        roleLabel: roleLabel,
        profileImagePath: staff.profileImagePath,
      ),
    );
  }

  if (job.masterMechanicId != null && job.masterMechanicId!.isNotEmpty) {
    addStaff(job.masterMechanicId!, 'Master Mechanic');
  }
  for (final mechanicId in job.mechanicIds) {
    addStaff(mechanicId, 'Mechanic');
  }
  if (job.pickupPersonName != null && job.pickupPersonName!.isNotEmpty) {
    final matchedStaff = controller.staffProfiles
        .where(
          (staff) =>
              staff.name.toLowerCase() == job.pickupPersonName!.toLowerCase() ||
              staff.phone == job.pickupPersonPhone,
        )
        .firstOrNull;
    final key = matchedStaff?.id ?? 'pickup-${job.pickupPersonName}';
    if (seen.add(key)) {
      people.add(
        _StaffAssignedPerson(
          name: job.pickupPersonName!,
          roleLabel: 'Pickup',
          profileImagePath: matchedStaff?.profileImagePath,
        ),
      );
    }
  }
  return people;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class _StaffMetaChip extends StatelessWidget {
  const _StaffMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StaffApprovalBadge extends StatelessWidget {
  const _StaffApprovalBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_chat_unread_outlined,
            color: AppPalette.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffApprovalPreview extends StatelessWidget {
  const _StaffApprovalPreview({required this.requests});

  final List<WorkApprovalRequest> requests;

  @override
  Widget build(BuildContext context) {
    final latest = requests.first;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_chat_unread_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${requests.length} approval message${requests.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${latest.title} | ${latest.status.label} | ${formatShortDate(latest.createdAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _StaffApprovalMessageTile extends StatelessWidget {
  const _StaffApprovalMessageTile(this.request);

  final WorkApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final staff = controller.staffById(request.staffId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Icon(_requestStatusIcon(request.status)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StaffMetaChip(
                icon: _requestStatusIcon(request.status),
                label: request.forwardedToCustomer
                    ? 'Sent to customer'
                    : request.status.label,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${staff?.name ?? 'Staff'}: ${request.message}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (request.ownerResponse != null &&
              request.ownerResponse!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.ownerResponse!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (request.photoPath != null) ...[
            const SizedBox(height: 10),
            AppImage(
              path: request.photoPath!,
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ],
      ),
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
      subtitle: Text(
        '${car?.model ?? '-'} | ${job.status.label}'
        '${job.pickupAddress == null || job.pickupAddress!.isEmpty ? '' : ' | ${job.pickupAddress}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
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

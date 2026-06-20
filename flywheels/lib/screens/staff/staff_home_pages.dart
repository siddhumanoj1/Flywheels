import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/app_bottom_nav_bar.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/exact_icon.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MasterMechanicHomePage extends StatefulWidget {
  const MasterMechanicHomePage({super.key});

  @override
  State<MasterMechanicHomePage> createState() => _MasterMechanicHomePageState();
}

class _MasterMechanicHomePageState extends State<MasterMechanicHomePage> {
  int _currentIndex = 0;

  void _showJobCardSheet(ServiceJob job) {
    final complaintController = TextEditingController(
      text: job.customerConcern,
    );
    final inspectionController = TextEditingController();
    final labourController = TextEditingController(text: 'General labour');
    final labourAmountController = TextEditingController(text: '1800');
    final partController = TextEditingController(text: 'Part item');
    final partAmountController = TextEditingController(text: '0');
    final remarksController = TextEditingController();
    var expectedCompletion = job.expectedCompletion;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Prepare job card',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: complaintController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Complaint or concern',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: inspectionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Inspection notes',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: labourController,
                              decoration: const InputDecoration(
                                labelText: 'Labour item',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: labourAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Labour amount',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: partController,
                              decoration: const InputDecoration(
                                labelText: 'Parts item',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: partAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Parts amount',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expectedCompletion,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 45),
                            ),
                          );
                          if (picked != null) {
                            setSheetState(() => expectedCompletion = picked);
                          }
                        },
                        icon: const ExactIcon(Icons.calendar_month_rounded),
                        label: Text(
                          'Expected ${formatShortDate(expectedCompletion)}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: remarksController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Remarks'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            FlywheelsScope.read(context).prepareJobCard(
                              jobId: job.id,
                              complaint: complaintController.text,
                              inspectionNotes: inspectionController.text,
                              labourItems: [
                                DocumentLineItem(
                                  description: labourController.text.trim(),
                                  quantity: 1,
                                  unitPrice:
                                      double.tryParse(
                                        labourAmountController.text.trim(),
                                      ) ??
                                      0,
                                  total:
                                      double.tryParse(
                                        labourAmountController.text.trim(),
                                      ) ??
                                      0,
                                ),
                              ],
                              partsItems: [
                                DocumentLineItem(
                                  description: partController.text.trim(),
                                  quantity: 1,
                                  unitPrice:
                                      double.tryParse(
                                        partAmountController.text.trim(),
                                      ) ??
                                      0,
                                  total:
                                      double.tryParse(
                                        partAmountController.text.trim(),
                                      ) ??
                                      0,
                                ),
                              ],
                              expectedCompletion: expectedCompletion,
                              remarks: remarksController.text,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const ExactIcon(Icons.assignment_rounded),
                          label: const Text('Send for approval'),
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
    ).whenComplete(() {
      complaintController.dispose();
      inspectionController.dispose();
      labourController.dispose();
      labourAmountController.dispose();
      partController.dispose();
      partAmountController.dispose();
      remarksController.dispose();
    });
  }

  void _showTaskSheet(ServiceJob job) {
    final controller = FlywheelsScope.read(context);
    final titleController = TextEditingController();
    final instructionController = TextEditingController();
    final mechanics = controller.mechanicsUnderMaster(
      controller.session!.user.id,
    );
    var mechanicId = mechanics.isEmpty ? null : mechanics.first.userId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Assign mechanic',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mechanicId,
                      decoration: const InputDecoration(labelText: 'Mechanic'),
                      items: mechanics
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile.userId,
                              child: Text(profile.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => mechanicId = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Work title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: instructionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Work instructions',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: mechanicId == null
                            ? null
                            : () {
                                controller.assignMechanicTask(
                                  jobId: job.id,
                                  mechanicUserId: mechanicId!,
                                  title: titleController.text,
                                  instructions: instructionController.text,
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const ExactIcon(Icons.assignment_ind_outlined),
                        label: const Text('Assign work'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      instructionController.dispose();
    });
  }

  void _showDecisionSheet(ServiceJob job, {required bool approval}) {
    final messageController = TextEditingController();
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    var urgency = RequestUrgency.normal;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval ? 'Request approval' : 'Send progress update',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: approval ? 'Message' : 'Update',
                        ),
                      ),
                      if (approval) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: reasonController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Reason',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Amount if needed',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<RequestUrgency>(
                                initialValue: urgency,
                                decoration: const InputDecoration(
                                  labelText: 'Urgency',
                                ),
                                items: RequestUrgency.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => urgency = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final controller = FlywheelsScope.read(context);
                            if (approval) {
                              controller.sendApprovalRequest(
                                jobId: job.id,
                                message: messageController.text,
                                reason: reasonController.text,
                                amount:
                                    double.tryParse(
                                      amountController.text.trim(),
                                    ) ??
                                    0,
                                urgency: urgency,
                              );
                            } else {
                              controller.sendStaffProgressUpdate(
                                jobId: job.id,
                                message: messageController.text,
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          icon: ExactIcon(
                            approval
                                ? Icons.pending_actions_rounded
                                : Icons.send_rounded,
                          ),
                          label: Text(
                            approval ? 'Send request' : 'Send update',
                          ),
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
    ).whenComplete(() {
      messageController.dispose();
      reasonController.dispose();
      amountController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final titles = ['Dashboard', 'Jobs', 'Approvals', 'Docs', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 33),
            const SizedBox(width: 14),
            Text(titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: controller.logout,
            icon: const ExactIcon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MasterDashboardTab(
            onOpenJobs: () => setState(() => _currentIndex = 1),
          ),
          _MasterJobsTab(
            onStartInspection: controller.startInspection,
            onPrepareJobCard: _showJobCardSheet,
            onAssignMechanic: _showTaskSheet,
            onApproval: (job) => _showDecisionSheet(job, approval: true),
            onUpdate: (job) => _showDecisionSheet(job, approval: false),
            onComplete: controller.markWorkCompleteForReview,
          ),
          const _StaffApprovalsTab(),
          const _StaffDocsTab(),
          const _StaffProfileTab(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        badgeCounts: [0, 0, controller.pendingApprovalRequests.length, 0, 0],
        items: const [
          AppBottomNavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          AppBottomNavItem(
            label: 'Jobs',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
          ),
          AppBottomNavItem(
            label: 'Approvals',
            icon: Icons.pending_actions_outlined,
            activeIcon: Icons.pending_actions_rounded,
            color: AppPalette.red,
          ),
          AppBottomNavItem(
            label: 'Docs',
            icon: Icons.folder_copy_outlined,
            activeIcon: Icons.folder_copy_rounded,
          ),
          AppBottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class MechanicHomePage extends StatefulWidget {
  const MechanicHomePage({super.key});

  @override
  State<MechanicHomePage> createState() => _MechanicHomePageState();
}

class _MechanicHomePageState extends State<MechanicHomePage> {
  int _currentIndex = 0;

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTaskUpdateSheet(MechanicWorkTask task) {
    final notesController = TextEditingController(text: task.notes);
    var status = task.status == WorkTaskStatus.waiting
        ? WorkTaskStatus.inProgress
        : task.status;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update task',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<WorkTaskStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: WorkTaskStatus.values
                          .where((item) => item != WorkTaskStatus.reviewed)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => status = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          FlywheelsScope.read(context).updateTaskProgress(
                            taskId: task.id,
                            status: status,
                            notes: notesController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const ExactIcon(Icons.save_rounded),
                        label: const Text('Save update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(notesController.dispose);
  }

  void _showDecisionSheet(ServiceJob job, {required bool approval}) {
    final messageController = TextEditingController();
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  approval ? 'Request approval' : 'Send progress update',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: approval ? 'Message' : 'Update',
                  ),
                ),
                if (approval) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount if needed',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final controller = FlywheelsScope.read(context);
                      if (approval) {
                        controller.sendApprovalRequest(
                          jobId: job.id,
                          message: messageController.text,
                          reason: reasonController.text,
                          amount:
                              double.tryParse(amountController.text.trim()) ??
                              0,
                        );
                      } else {
                        controller.sendStaffProgressUpdate(
                          jobId: job.id,
                          message: messageController.text,
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    icon: ExactIcon(
                      approval
                          ? Icons.pending_actions_rounded
                          : Icons.send_rounded,
                    ),
                    label: Text(approval ? 'Send request' : 'Send update'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      messageController.dispose();
      reasonController.dispose();
      amountController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final titles = ['Dashboard', 'Tasks', 'Attendance', 'Docs', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 33),
            const SizedBox(width: 14),
            Text(titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: controller.logout,
            icon: const ExactIcon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MechanicDashboardTab(
            onOpenTasks: () => setState(() => _currentIndex = 1),
          ),
          _MechanicTasksTab(
            onCall: _call,
            onOpenMap: _openMap,
            onPickupDone: controller.markPickupDone,
            onUpdateTask: _showTaskUpdateSheet,
            onApproval: (job) => _showDecisionSheet(job, approval: true),
            onUpdate: (job) => _showDecisionSheet(job, approval: false),
          ),
          const _StaffAttendanceTab(),
          const _StaffDocsTab(),
          const _StaffProfileTab(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        badgeCounts: [
          0,
          controller.jobs.length + controller.workTasks.length,
          0,
          0,
          0,
        ],
        items: const [
          AppBottomNavItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          AppBottomNavItem(
            label: 'Tasks',
            icon: Icons.task_alt_outlined,
            activeIcon: Icons.task_alt_rounded,
            color: AppPalette.red,
          ),
          AppBottomNavItem(
            label: 'Attendance',
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check_rounded,
          ),
          AppBottomNavItem(
            label: 'Docs',
            icon: Icons.folder_copy_outlined,
            activeIcon: Icons.folder_copy_rounded,
          ),
          AppBottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class _MasterDashboardTab extends StatelessWidget {
  const _MasterDashboardTab({required this.onOpenJobs});

  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final jobs = controller.jobsForStaff(userId);
    final mechanics = controller.mechanicsUnderMaster(userId);
    final waitingInspection = jobs
        .where((job) => job.status == JobStatus.received)
        .length;
    final preparing = jobs
        .where((job) => job.status == JobStatus.underInspection)
        .length;
    final waitingApproval = controller.documents
        .where(
          (document) =>
              document.type == DocumentType.jobCard &&
              document.approvalState == ApprovalState.pending,
        )
        .length;
    final work = jobs
        .where((job) => job.status == JobStatus.workInProgress)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeroCard(
          title: 'Today attendance',
          subtitle: controller.todayAttendanceForStaff(userId) == null
              ? 'Not marked yet'
              : controller.todayAttendanceForStaff(userId)!.status.label,
          icon: Icons.speed_rounded,
          actionLabel: 'Mark',
          onAction: controller.todayAttendanceForStaff(userId) == null
              ? () => controller.submitAttendance()
              : null,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          metrics: [
            _StaffMetric(
              'Assigned cars',
              jobs.length,
              Icons.directions_car_rounded,
            ),
            _StaffMetric(
              'Waiting inspection',
              waitingInspection,
              Icons.search_rounded,
            ),
            _StaffMetric(
              'Preparing cards',
              preparing,
              Icons.assignment_rounded,
            ),
            _StaffMetric(
              'Waiting approval',
              waitingApproval,
              Icons.pending_actions_rounded,
            ),
            _StaffMetric('Work progress', work, Icons.handyman_outlined),
            _StaffMetric(
              'Mechanics under you',
              mechanics.length,
              Icons.groups_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenJobs,
          icon: const ExactIcon(Icons.assignment_rounded),
          label: const Text('Open jobs'),
        ),
      ],
    );
  }
}

class _MasterJobsTab extends StatelessWidget {
  const _MasterJobsTab({
    required this.onStartInspection,
    required this.onPrepareJobCard,
    required this.onAssignMechanic,
    required this.onApproval,
    required this.onUpdate,
    required this.onComplete,
  });

  final ValueChanged<String> onStartInspection;
  final ValueChanged<ServiceJob> onPrepareJobCard;
  final ValueChanged<ServiceJob> onAssignMechanic;
  final ValueChanged<ServiceJob> onApproval;
  final ValueChanged<ServiceJob> onUpdate;
  final ValueChanged<String> onComplete;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final jobs = controller.jobs;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (jobs.isEmpty)
          const _StaffEmptyCard(message: 'No assigned cars yet.'),
        ...jobs.map((job) {
          final car = controller.cars
              .where((item) => item.id == job.carId)
              .firstOrNull;
          if (car == null) return const SizedBox.shrink();
          final customer = controller.customerForCar(car.id);
          return _StaffJobCard(
            job: job,
            car: car,
            customer: customer,
            tasks: controller.tasksForJob(job.id),
            documents: controller.documentsForCar(car.id),
            onStartInspection: job.status == JobStatus.received
                ? () => onStartInspection(job.id)
                : null,
            onPrepareJobCard: job.status == JobStatus.underInspection
                ? () => onPrepareJobCard(job)
                : null,
            onAssignMechanic: job.status == JobStatus.workInProgress
                ? () => onAssignMechanic(job)
                : null,
            onApproval: () => onApproval(job),
            onUpdate: () => onUpdate(job),
            onComplete: job.status == JobStatus.workInProgress
                ? () => onComplete(job.id)
                : null,
          );
        }),
      ],
    );
  }
}

class _MechanicDashboardTab extends StatelessWidget {
  const _MechanicDashboardTab({required this.onOpenTasks});

  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final pickupTasks = controller.jobs
        .where(
          (job) =>
              job.pickupMechanicId == userId &&
              (job.status == JobStatus.pickUpScheduled ||
                  job.status == JobStatus.deliveryScheduled),
        )
        .length;
    final tasks = controller.workTasks.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeroCard(
          title: 'Today attendance',
          subtitle: controller.todayAttendanceForStaff(userId) == null
              ? 'Not marked yet'
              : controller.todayAttendanceForStaff(userId)!.status.label,
          icon: Icons.speed_rounded,
          actionLabel: 'Mark',
          onAction: controller.todayAttendanceForStaff(userId) == null
              ? () => controller.submitAttendance()
              : null,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          metrics: [
            _StaffMetric(
              'Pickup tasks',
              pickupTasks,
              Icons.local_shipping_outlined,
            ),
            _StaffMetric('Car tasks', tasks, Icons.task_alt_outlined),
            _StaffMetric(
              'Approval sent',
              controller.approvalRequests.length,
              Icons.pending_actions_outlined,
            ),
            _StaffMetric(
              'Payslips',
              controller.salaryRecords.length,
              Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenTasks,
          icon: const ExactIcon(Icons.task_alt_rounded),
          label: const Text('Open tasks'),
        ),
      ],
    );
  }
}

class _MechanicTasksTab extends StatelessWidget {
  const _MechanicTasksTab({
    required this.onCall,
    required this.onOpenMap,
    required this.onPickupDone,
    required this.onUpdateTask,
    required this.onApproval,
    required this.onUpdate,
  });

  final ValueChanged<String> onCall;
  final ValueChanged<String> onOpenMap;
  final ValueChanged<String> onPickupDone;
  final ValueChanged<MechanicWorkTask> onUpdateTask;
  final ValueChanged<ServiceJob> onApproval;
  final ValueChanged<ServiceJob> onUpdate;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final pickupJobs = controller.jobs
        .where(
          (job) =>
              job.pickupMechanicId == userId &&
              (job.status == JobStatus.pickUpScheduled ||
                  job.status == JobStatus.deliveryScheduled),
        )
        .toList();
    final workTasks = controller.workTasks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pickupJobs.isNotEmpty)
          Text('Pickup tasks', style: Theme.of(context).textTheme.titleLarge),
        if (pickupJobs.isNotEmpty) const SizedBox(height: 8),
        ...pickupJobs.map((job) {
          final car = controller.cars
              .where((item) => item.id == job.carId)
              .firstOrNull;
          final customer = car == null
              ? null
              : controller.customerForCar(car.id);
          if (car == null) return const SizedBox.shrink();
          return _PickupTaskCard(
            job: job,
            car: car,
            customer: customer,
            onCall: customer == null ? null : () => onCall(customer.phone),
            onOpenMap: job.pickupAddress == null || job.pickupAddress!.isEmpty
                ? null
                : () => onOpenMap(job.pickupAddress!),
            onDone: () => onPickupDone(job.id),
          );
        }),
        const SizedBox(height: 12),
        Text('Work tasks', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (workTasks.isEmpty)
          const _StaffEmptyCard(message: 'No car tasks assigned yet.'),
        ...workTasks.map((task) {
          final job = controller.jobs
              .where((item) => item.id == task.jobId)
              .firstOrNull;
          final car = controller.cars
              .where((item) => item.id == task.carId)
              .firstOrNull;
          if (job == null || car == null) return const SizedBox.shrink();
          return _MechanicTaskCard(
            task: task,
            car: car,
            onUpdateTask: () => onUpdateTask(task),
            onApproval: () => onApproval(job),
            onUpdate: () => onUpdate(job),
          );
        }),
      ],
    );
  }
}

class _StaffApprovalsTab extends StatelessWidget {
  const _StaffApprovalsTab();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final approvals = controller.approvalRequests;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (approvals.isEmpty)
          const _StaffEmptyCard(message: 'No approval requests yet.'),
        ...approvals.map(
          (request) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const ExactIcon(Icons.pending_actions_outlined),
              title: Text(request.message),
              subtitle: Text(
                '${request.reason} | ${formatCurrency(request.amount)} | ${request.urgency.label}',
              ),
              trailing: Text(request.status.label),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffAttendanceTab extends StatelessWidget {
  const _StaffAttendanceTab();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final userId = controller.session!.user.id;
    final today = controller.todayAttendanceForStaff(userId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeroCard(
          title: 'Daily attendance',
          subtitle: today == null
              ? 'Location check is ready. Face check placeholder is ready.'
              : 'Marked ${today.status.label}',
          icon: Icons.fact_check_rounded,
          actionLabel: 'Mark attendance',
          onAction: today == null ? () => controller.submitAttendance() : null,
        ),
        const SizedBox(height: 12),
        ...controller.attendanceRecords.map(
          (record) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const ExactIcon(Icons.calendar_month_outlined),
              title: Text(
                '${formatShortDate(record.date)} - ${record.status.label}',
              ),
              subtitle: Text(
                'Location ${record.locationVerification.label} | Face ${record.faceVerification.label}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffDocsTab extends StatelessWidget {
  const _StaffDocsTab();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeroCard(
          title: 'Documents',
          subtitle:
              'Payslips, attendance, leave records, advances, job cards, and task history.',
          icon: Icons.folder_copy_rounded,
        ),
        const SizedBox(height: 12),
        ...controller.staffDocuments.map(
          (document) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const ExactIcon(Icons.description_outlined),
              title: Text(document.title),
              subtitle: Text(document.category),
              trailing: document.amount == null
                  ? null
                  : Text(formatCurrency(document.amount!)),
            ),
          ),
        ),
        ...controller.documents.map(
          (document) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const ExactIcon(Icons.assignment_outlined),
              title: Text(document.title),
              subtitle: Text(
                '${document.type.label} | ${document.approvalState.label}',
              ),
              trailing: Text(formatCurrency(document.total)),
            ),
          ),
        ),
        ...controller.salaryRecords.map(
          (record) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const ExactIcon(Icons.receipt_long_outlined),
              title: Text('${record.monthLabel} salary'),
              subtitle: Text(record.isPaid ? 'Paid' : 'Waiting'),
              trailing: Text(formatCurrency(record.finalPayable)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffProfileTab extends StatelessWidget {
  const _StaffProfileTab();

  void _showLeaveSheet(BuildContext context) {
    final typeController = TextEditingController(text: 'Personal Leave');
    final reasonController = TextEditingController();
    var startDate = DateTime.now().add(const Duration(days: 1));
    var endDate = startDate;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply leave',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Leave type',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              }
                            },
                            icon: const ExactIcon(Icons.today_rounded),
                            label: Text(formatShortDate(startDate)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => endDate = picked);
                              }
                            },
                            icon: const ExactIcon(Icons.event_rounded),
                            label: Text(formatShortDate(endDate)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          FlywheelsScope.read(context).applyLeave(
                            startDate: startDate,
                            endDate: endDate,
                            leaveType: typeController.text,
                            reason: reasonController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const ExactIcon(Icons.event_busy_rounded),
                        label: const Text('Submit leave'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      typeController.dispose();
      reasonController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final user = controller.session!.user;
    final profile = controller.staffProfileForUser(user.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MessengerAvatar(
                  path: user.profileImagePath,
                  initials: user.name.isEmpty ? 'F' : user.name[0],
                  radius: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('${user.role.label} | ${user.phone}'),
                      if (profile != null)
                        Text(
                          'Salary ${formatCurrency(profile.salary)} | ${profile.workStatus.label}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showLeaveSheet(context),
          icon: const ExactIcon(Icons.event_busy_rounded),
          label: const Text('Apply leave'),
        ),
        const SizedBox(height: 12),
        _StaffSectionTitle('Leaves'),
        ...controller.leaveRequests.map(
          (request) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(request.leaveType),
            subtitle: Text(
              '${formatShortDate(request.startDate)} to ${formatShortDate(request.endDate)}',
            ),
            trailing: Text(request.status.label),
          ),
        ),
        _StaffSectionTitle('Advances'),
        ...controller.advances.map(
          (advance) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(formatCurrency(advance.amount)),
            subtitle: Text(advance.reason),
            trailing: Text(advance.status.label),
          ),
        ),
        _StaffSectionTitle('Salary'),
        ...controller.salaryRecords.map(
          (record) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(record.monthLabel),
            subtitle: Text(record.isPaid ? 'Paid' : 'Waiting'),
            trailing: Text(formatCurrency(record.finalPayable)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: controller.logout,
          icon: const ExactIcon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _StaffJobCard extends StatelessWidget {
  const _StaffJobCard({
    required this.job,
    required this.car,
    required this.customer,
    required this.tasks,
    required this.documents,
    required this.onStartInspection,
    required this.onPrepareJobCard,
    required this.onAssignMechanic,
    required this.onApproval,
    required this.onUpdate,
    required this.onComplete,
  });

  final ServiceJob job;
  final CarProfile car;
  final GarageUser? customer;
  final List<MechanicWorkTask> tasks;
  final List<ServiceDocument> documents;
  final VoidCallback? onStartInspection;
  final VoidCallback? onPrepareJobCard;
  final VoidCallback? onAssignMechanic;
  final VoidCallback onApproval;
  final VoidCallback onUpdate;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CarHeader(car: car, customer: customer, status: job.status.label),
            const SizedBox(height: 10),
            Text(
              job.customerConcern.isEmpty
                  ? 'No concern added.'
                  : job.customerConcern,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(
                  Icons.assignment_outlined,
                  '${documents.length} job docs',
                ),
                _MiniPill(Icons.task_alt_outlined, '${tasks.length} tasks'),
                _MiniPill(
                  Icons.schedule_rounded,
                  formatDateTime(job.expectedCompletion),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onStartInspection != null)
                  FilledButton.icon(
                    onPressed: onStartInspection,
                    icon: const ExactIcon(Icons.search_rounded),
                    label: const Text('Start inspection'),
                  ),
                if (onPrepareJobCard != null)
                  FilledButton.icon(
                    onPressed: onPrepareJobCard,
                    icon: const ExactIcon(Icons.assignment_rounded),
                    label: const Text('Prepare job card'),
                  ),
                if (onAssignMechanic != null)
                  FilledButton.icon(
                    onPressed: onAssignMechanic,
                    icon: const ExactIcon(Icons.assignment_ind_outlined),
                    label: const Text('Assign mechanic'),
                  ),
                OutlinedButton.icon(
                  onPressed: onApproval,
                  icon: const ExactIcon(Icons.pending_actions_rounded),
                  label: const Text('Approval'),
                ),
                OutlinedButton.icon(
                  onPressed: onUpdate,
                  icon: const ExactIcon(Icons.send_rounded),
                  label: const Text('Update'),
                ),
                if (onComplete != null)
                  OutlinedButton.icon(
                    onPressed: onComplete,
                    icon: const ExactIcon(Icons.verified_rounded),
                    label: const Text('Work complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupTaskCard extends StatelessWidget {
  const _PickupTaskCard({
    required this.job,
    required this.car,
    required this.customer,
    required this.onCall,
    required this.onOpenMap,
    required this.onDone,
  });

  final ServiceJob job;
  final CarProfile car;
  final GarageUser? customer;
  final VoidCallback? onCall;
  final VoidCallback? onOpenMap;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CarHeader(car: car, customer: customer, status: job.status.label),
            const SizedBox(height: 8),
            Text(
              '${formatDateTime(job.pickupTime)}${job.pickupAddress == null || job.pickupAddress!.isEmpty ? '' : ' | ${job.pickupAddress}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const ExactIcon(Icons.call_rounded),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const ExactIcon(Icons.map_outlined),
                  label: const Text('Map'),
                ),
                FilledButton.icon(
                  onPressed: onDone,
                  icon: const ExactIcon(Icons.task_alt_rounded),
                  label: Text(
                    job.status == JobStatus.deliveryScheduled
                        ? 'On Road'
                        : 'Pick Up Done',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MechanicTaskCard extends StatelessWidget {
  const _MechanicTaskCard({
    required this.task,
    required this.car,
    required this.onUpdateTask,
    required this.onApproval,
    required this.onUpdate,
  });

  final MechanicWorkTask task;
  final CarProfile car;
  final VoidCallback onUpdateTask;
  final VoidCallback onApproval;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImage(
                  path: car.imageUrl,
                  width: 68,
                  height: 50,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${car.carNumber} | ${task.status.label}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.instructions,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (task.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.notes, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onUpdateTask,
                  icon: const ExactIcon(Icons.edit_note_rounded),
                  label: const Text('Update'),
                ),
                OutlinedButton.icon(
                  onPressed: onApproval,
                  icon: const ExactIcon(Icons.pending_actions_rounded),
                  label: const Text('Approval'),
                ),
                OutlinedButton.icon(
                  onPressed: onUpdate,
                  icon: const ExactIcon(Icons.send_rounded),
                  label: const Text('Progress'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarHeader extends StatelessWidget {
  const _CarHeader({
    required this.car,
    required this.customer,
    required this.status,
  });

  final CarProfile car;
  final GarageUser? customer;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppImage(
          path: car.imageUrl,
          width: 74,
          height: 54,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                car.carNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${customer?.name ?? 'Customer'} | ${car.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _StatusChip(status),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffHeroCard extends StatelessWidget {
  const _StaffHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ExactIcon(icon, color: AppPalette.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppPalette.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.white,
                side: BorderSide(
                  color: AppPalette.white.withValues(alpha: 0.28),
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_StaffMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: metrics
          .map(
            (metric) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExactIcon(metric.icon),
                    const Spacer(),
                    Text(
                      metric.value.toString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      metric.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StaffMetric {
  const _StaffMetric(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExactIcon(icon, size: 15),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppPalette.red),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppPalette.red,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StaffSectionTitle extends StatelessWidget {
  const _StaffSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
        padding: const EdgeInsets.all(16),
        child: Text(message, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

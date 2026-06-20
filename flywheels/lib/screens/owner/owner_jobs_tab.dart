import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/exact_icon.dart';
import 'package:flutter/material.dart';

class OwnerJobsTab extends StatefulWidget {
  const OwnerJobsTab({
    super.key,
    required this.onOpenDocuments,
    required this.onOpenChat,
    required this.onOpenWheels,
  });

  final ValueChanged<String> onOpenDocuments;
  final ValueChanged<CarProfile> onOpenChat;
  final VoidCallback onOpenWheels;

  @override
  State<OwnerJobsTab> createState() => _OwnerJobsTabState();
}

class _OwnerJobsTabState extends State<OwnerJobsTab> {
  JobStatus? _statusFilter;
  String _query = '';

  List<ServiceJob> _filteredJobs(AppController controller) {
    final needle = _query.trim().toLowerCase();
    return controller.jobs.where((job) {
      final car = controller.cars
          .where((item) => item.id == job.carId)
          .firstOrNull;
      final customer = car == null ? null : controller.customerForCar(car.id);
      final haystack =
          '${job.status.label} ${car?.carNumber ?? ''} ${car?.model ?? ''} ${customer?.name ?? ''} ${customer?.phone ?? ''}'
              .toLowerCase();
      final statusMatches =
          _statusFilter == null || job.status == _statusFilter;
      return statusMatches && (needle.isEmpty || haystack.contains(needle));
    }).toList()..sort(
      (left, right) => right.pickupTime.compareTo(left.pickupTime),
    );
  }

  void _showPickupMechanicSheet(ServiceJob job) {
    final controller = FlywheelsScope.read(context);
    var mechanicId =
        job.pickupMechanicId ??
        (controller.mechanicProfiles.isEmpty
            ? null
            : controller.mechanicProfiles.first.userId);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.status == JobStatus.deliveryScheduled
                          ? 'Assign delivery'
                          : 'Assign pickup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mechanicId,
                      decoration: const InputDecoration(labelText: 'Mechanic'),
                      items: controller.mechanicProfiles
                          .where((profile) => profile.isActive)
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile.userId,
                              child: Text(
                                '${profile.name} - ${profile.workStatus.label}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => mechanicId = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: mechanicId == null
                            ? null
                            : () {
                                controller.assignPickupMechanic(
                                  job.id,
                                  mechanicId!,
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const ExactIcon(Icons.local_shipping_outlined),
                        label: const Text('Assign'),
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

  void _showMasterMechanicSheet(ServiceJob job) {
    final controller = FlywheelsScope.read(context);
    var masterId =
        job.masterMechanicId ??
        (controller.masterMechanicProfiles.isEmpty
            ? null
            : controller.masterMechanicProfiles.first.userId);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Master Mechanic',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: masterId,
                      decoration: const InputDecoration(
                        labelText: 'Master Mechanic',
                      ),
                      items: controller.masterMechanicProfiles
                          .where((profile) => profile.isActive)
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile.userId,
                              child: Text(
                                '${profile.name} - ${controller.workloadCountForStaff(profile.userId)} active',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => masterId = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: masterId == null
                            ? null
                            : () {
                                controller.assignMasterMechanic(
                                  job.id,
                                  masterId!,
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const ExactIcon(Icons.engineering_outlined),
                        label: const Text('Assign'),
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

  void _showTaskSheet(ServiceJob job) {
    final controller = FlywheelsScope.read(context);
    final titleController = TextEditingController();
    final instructionsController = TextEditingController();
    var mechanicId = controller.mechanicProfiles.isEmpty
        ? null
        : controller.mechanicProfiles.first.userId;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign work',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mechanicId,
                      decoration: const InputDecoration(labelText: 'Mechanic'),
                      items: controller.mechanicProfiles
                          .where((profile) => profile.isActive)
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
                      controller: instructionsController,
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
                                  instructions: instructionsController.text,
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
      instructionsController.dispose();
    });
  }

  void _showTimelineSheet(CarProfile car) {
    final controller = FlywheelsScope.read(context);
    final events = controller.timelineForCar(car.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.carNumber} timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: events.isEmpty
                        ? Center(
                            child: Text(
                              'No timeline events yet.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : ListView.separated(
                            itemCount: events.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const ExactIcon(
                                  Icons.timeline_rounded,
                                ),
                                title: Text(event.title),
                                subtitle: Text(event.message),
                                trailing: Text(
                                  formatShortDate(event.createdAt),
                                ),
                              );
                            },
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
    final jobs = _filteredJobs(controller);

    return ListView(
      key: const PageStorageKey('owner-jobs'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: ExactIcon(Icons.search_rounded),
                  hintText: 'Search jobs',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: 'Wheels',
              onPressed: widget.onOpenWheels,
              icon: const ExactIcon(Icons.motion_photos_auto_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _statusFilter == null,
                  label: const Text('All'),
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
              ),
              ...JobStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _statusFilter == status,
                    label: Text(status.label),
                    onSelected: (_) => setState(() => _statusFilter = status),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _OwnerPendingActionPanel(),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          const _OwnerJobsEmpty(message: 'No jobs match this view.'),
        ...jobs.map((job) {
          final car = controller.cars
              .where((item) => item.id == job.carId)
              .firstOrNull;
          if (car == null) return const SizedBox.shrink();
          final customer = controller.customerForCar(car.id);
          return _OwnerJobCard(
            job: job,
            car: car,
            customer: customer,
            pickupName: controller.staffName(job.pickupMechanicId),
            masterName: controller.staffName(job.masterMechanicId),
            mechanics: job.assignedMechanicIds
                .map(controller.staffName)
                .toList(growable: false),
            documents: controller.documentsForCar(car.id),
            tasks: controller.tasksForJob(job.id),
            approvals: controller.approvalRequestsForJob(job.id),
            updates: controller.progressUpdatesForJob(job.id),
            onAssignPickup: () => _showPickupMechanicSheet(job),
            onMarkPickupDone: () => controller.markPickupDone(job.id),
            onMarkReceived: () => controller.markCarReceived(job.id),
            onAssignMaster: () => _showMasterMechanicSheet(job),
            onAssignTask: () => _showTaskSheet(job),
            onOpenDocuments: () => widget.onOpenDocuments(car.id),
            onOpenChat: () => widget.onOpenChat(car),
            onOpenTimeline: () => _showTimelineSheet(car),
            onScheduleDelivery: () =>
                controller.setJobStatus(job.id, JobStatus.deliveryScheduled),
            onMarkOnRoad: () => controller.markPickupDone(job.id),
          );
        }),
      ],
    );
  }
}

class _OwnerPendingActionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final approvals = controller.pendingApprovalRequests;
    final updates = controller.pendingStaffUpdates;
    if (approvals.isEmpty && updates.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending owner actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...approvals
                .take(3)
                .map((request) => _PendingApprovalRow(request: request)),
            ...updates
                .take(3)
                .map((update) => _PendingUpdateRow(update: update)),
          ],
        ),
      ),
    );
  }
}

class _PendingApprovalRow extends StatelessWidget {
  const _PendingApprovalRow({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(
            '${request.urgency.label} | ${formatCurrency(request.amount)} | ${controller.staffName(request.requesterId)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.decideApprovalRequest(
                  request.id,
                  ApprovalState.approved,
                ),
                icon: const ExactIcon(Icons.check_rounded),
                label: const Text('Approve internal'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.decideApprovalRequest(
                  request.id,
                  ApprovalState.pending,
                  forwardToCustomer: true,
                ),
                icon: const ExactIcon(Icons.person_outline_rounded),
                label: const Text('Forward customer'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.decideApprovalRequest(
                  request.id,
                  ApprovalState.rejected,
                ),
                icon: const ExactIcon(Icons.close_rounded),
                label: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingUpdateRow extends StatelessWidget {
  const _PendingUpdateRow({required this.update});

  final ProgressUpdate update;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(update.message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(
            controller.staffName(update.senderId),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.ownerHandleProgressUpdate(
                  update.id,
                  forward: false,
                ),
                icon: const ExactIcon(Icons.lock_outline_rounded),
                label: const Text('Keep internal'),
              ),
              FilledButton.icon(
                onPressed: () => controller.ownerHandleProgressUpdate(
                  update.id,
                  forward: true,
                ),
                icon: const ExactIcon(Icons.send_rounded),
                label: const Text('Forward customer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerJobCard extends StatelessWidget {
  const _OwnerJobCard({
    required this.job,
    required this.car,
    required this.customer,
    required this.pickupName,
    required this.masterName,
    required this.mechanics,
    required this.documents,
    required this.tasks,
    required this.approvals,
    required this.updates,
    required this.onAssignPickup,
    required this.onMarkPickupDone,
    required this.onMarkReceived,
    required this.onAssignMaster,
    required this.onAssignTask,
    required this.onOpenDocuments,
    required this.onOpenChat,
    required this.onOpenTimeline,
    required this.onScheduleDelivery,
    required this.onMarkOnRoad,
  });

  final ServiceJob job;
  final CarProfile car;
  final GarageUser? customer;
  final String pickupName;
  final String masterName;
  final List<String> mechanics;
  final List<ServiceDocument> documents;
  final List<MechanicWorkTask> tasks;
  final List<ApprovalRequest> approvals;
  final List<ProgressUpdate> updates;
  final VoidCallback onAssignPickup;
  final VoidCallback onMarkPickupDone;
  final VoidCallback onMarkReceived;
  final VoidCallback onAssignMaster;
  final VoidCallback onAssignTask;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenTimeline;
  final VoidCallback onScheduleDelivery;
  final VoidCallback onMarkOnRoad;

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
                  width: 78,
                  height: 58,
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
                      _JobStatusChip(label: job.status.label),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _JobInfoPill(
                  icon: Icons.local_shipping_outlined,
                  text: 'Pickup: $pickupName',
                ),
                _JobInfoPill(
                  icon: Icons.engineering_outlined,
                  text: 'Master: $masterName',
                ),
                _JobInfoPill(
                  icon: Icons.groups_outlined,
                  text: mechanics.isEmpty
                      ? 'Mechanics: Not assigned'
                      : 'Mechanics: ${mechanics.join(', ')}',
                ),
                _JobInfoPill(
                  icon: Icons.receipt_long_outlined,
                  text: '${documents.length} docs',
                ),
                _JobInfoPill(
                  icon: Icons.pending_actions_outlined,
                  text:
                      '${approvals.where((item) => item.status == ApprovalState.pending).length} approvals',
                ),
                _JobInfoPill(
                  icon: Icons.update_rounded,
                  text: '${updates.length} updates',
                ),
              ],
            ),
            if (job.customerConcern.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                job.customerConcern,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...tasks
                  .take(2)
                  .map(
                    (task) => Text(
                      '${task.title}: ${task.status.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.status == JobStatus.pickUpScheduled ||
                    job.status == JobStatus.deliveryScheduled)
                  OutlinedButton.icon(
                    onPressed: onAssignPickup,
                    icon: const ExactIcon(Icons.local_shipping_outlined),
                    label: const Text('Assign'),
                  ),
                if (job.status == JobStatus.pickUpScheduled ||
                    job.status == JobStatus.deliveryScheduled)
                  FilledButton.icon(
                    onPressed: job.pickupMechanicId == null
                        ? null
                        : job.status == JobStatus.deliveryScheduled
                        ? onMarkOnRoad
                        : onMarkPickupDone,
                    icon: const ExactIcon(Icons.task_alt_rounded),
                    label: Text(
                      job.status == JobStatus.deliveryScheduled
                          ? 'On Road'
                          : 'Pick Up Done',
                    ),
                  ),
                if (job.status == JobStatus.pickUpDone)
                  FilledButton.icon(
                    onPressed: onMarkReceived,
                    icon: const ExactIcon(Icons.garage_rounded),
                    label: const Text('Mark Received'),
                  ),
                if (job.status == JobStatus.received ||
                    job.status == JobStatus.underInspection)
                  OutlinedButton.icon(
                    onPressed: onAssignMaster,
                    icon: const ExactIcon(Icons.engineering_outlined),
                    label: const Text('Assign Master'),
                  ),
                if (job.status == JobStatus.workInProgress)
                  FilledButton.icon(
                    onPressed: onAssignTask,
                    icon: const ExactIcon(Icons.assignment_ind_outlined),
                    label: const Text('Assign Work'),
                  ),
                if (job.status == JobStatus.completed)
                  FilledButton.icon(
                    onPressed: onScheduleDelivery,
                    icon: const ExactIcon(Icons.event_available_rounded),
                    label: const Text('Schedule Delivery'),
                  ),
                OutlinedButton.icon(
                  onPressed: onOpenDocuments,
                  icon: const ExactIcon(Icons.receipt_long_outlined),
                  label: const Text('Docs'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: const ExactIcon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenTimeline,
                  icon: const ExactIcon(Icons.timeline_rounded),
                  label: const Text('Timeline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({required this.label});

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

class _JobInfoPill extends StatelessWidget {
  const _JobInfoPill({required this.icon, required this.text});

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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerJobsEmpty extends StatelessWidget {
  const _OwnerJobsEmpty({required this.message});

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

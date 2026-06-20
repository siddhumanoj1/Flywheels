import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/owner/owner_document_tab.dart';
import 'package:flywheels/widgets/exact_icon.dart';
import 'package:flutter/material.dart';

class OwnerDocsHub extends StatefulWidget {
  const OwnerDocsHub({super.key, this.preferredCarId});

  final String? preferredCarId;

  @override
  State<OwnerDocsHub> createState() => _OwnerDocsHubState();
}

class _OwnerDocsHubState extends State<OwnerDocsHub> {
  bool _showStaffRecords = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: ExactIcon(Icons.receipt_long_outlined),
                label: Text('Customer Docs'),
              ),
              ButtonSegment(
                value: true,
                icon: ExactIcon(Icons.badge_outlined),
                label: Text('Staff Records'),
              ),
            ],
            selected: {_showStaffRecords},
            onSelectionChanged: (selection) =>
                setState(() => _showStaffRecords = selection.first),
          ),
        ),
        Expanded(
          child: _showStaffRecords
              ? const _OwnerStaffRecordsView()
              : OwnerDocumentTab(preferredCarId: widget.preferredCarId),
        ),
      ],
    );
  }
}

class _OwnerStaffRecordsView extends StatelessWidget {
  const _OwnerStaffRecordsView();

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StaffRecordHeader(
          title: 'Staff records',
          subtitle:
              'Payslips, salary records, attendance records, leaves, advances, task history, and shared staff documents.',
          icon: Icons.folder_copy_outlined,
        ),
        const SizedBox(height: 12),
        _RecordGroup(
          title: 'Payslips and salary',
          children: controller.salaryRecords
              .map(
                (record) => _RecordTile(
                  icon: Icons.receipt_long_outlined,
                  title:
                      '${controller.staffName(record.staffUserId)} - ${record.monthLabel}',
                  subtitle:
                      '${record.isPaid ? 'Paid' : 'Waiting'} | ${record.presentDays} present | ${record.absentDays} absent',
                  trailing: formatCurrency(record.finalPayable),
                ),
              )
              .toList(),
        ),
        _RecordGroup(
          title: 'Attendance',
          children: controller.attendanceRecords
              .map(
                (record) => _RecordTile(
                  icon: Icons.fact_check_outlined,
                  title:
                      '${controller.staffName(record.staffUserId)} - ${formatShortDate(record.date)}',
                  subtitle:
                      '${record.status.label} | Location ${record.locationVerification.label} | Face ${record.faceVerification.label}',
                ),
              )
              .toList(),
        ),
        _RecordGroup(
          title: 'Leaves',
          children: controller.leaveRequests
              .map(
                (request) => _RecordTile(
                  icon: Icons.event_busy_outlined,
                  title:
                      '${controller.staffName(request.staffUserId)} - ${request.leaveType}',
                  subtitle:
                      '${formatShortDate(request.startDate)} to ${formatShortDate(request.endDate)} | ${request.status.label}',
                ),
              )
              .toList(),
        ),
        _RecordGroup(
          title: 'Advances',
          children: controller.advances
              .map(
                (advance) => _RecordTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title:
                      '${controller.staffName(advance.staffUserId)} - ${formatCurrency(advance.amount)}',
                  subtitle:
                      '${advance.reason} | Remaining ${formatCurrency(advance.remainingAmount)}',
                  trailing: advance.status.label,
                ),
              )
              .toList(),
        ),
        _RecordGroup(
          title: 'Staff documents',
          children: controller.staffDocuments
              .map(
                (document) => _RecordTile(
                  icon: Icons.description_outlined,
                  title: document.title,
                  subtitle:
                      '${controller.staffName(document.staffUserId)} | ${document.category}',
                  trailing: document.amount == null
                      ? formatShortDate(document.createdAt)
                      : formatCurrency(document.amount!),
                ),
              )
              .toList(),
        ),
        _RecordGroup(
          title: 'Task history',
          children: controller.workTasks
              .map(
                (task) => _RecordTile(
                  icon: Icons.task_alt_outlined,
                  title:
                      '${controller.staffName(task.mechanicId)} - ${task.title}',
                  subtitle:
                      '${task.status.label} | ${formatShortDate(task.updatedAt)}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StaffRecordHeader extends StatelessWidget {
  const _StaffRecordHeader({
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
      padding: const EdgeInsets.all(14),
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
        ],
      ),
    );
  }
}

class _RecordGroup extends StatelessWidget {
  const _RecordGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (children.isEmpty)
              Text(
                'No records yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: ExactIcon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing == null ? null : Text(trailing!),
    );
  }
}

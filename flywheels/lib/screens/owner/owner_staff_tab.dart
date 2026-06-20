import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flywheels/widgets/exact_icon.dart';
import 'package:flutter/material.dart';

enum _OwnerStaffSection { team, attendance, payroll, leaves, advances, docs }

extension _OwnerStaffSectionX on _OwnerStaffSection {
  String get label {
    switch (this) {
      case _OwnerStaffSection.team:
        return 'Team';
      case _OwnerStaffSection.attendance:
        return 'Attendance';
      case _OwnerStaffSection.payroll:
        return 'Payroll';
      case _OwnerStaffSection.leaves:
        return 'Leaves';
      case _OwnerStaffSection.advances:
        return 'Advances';
      case _OwnerStaffSection.docs:
        return 'Docs';
    }
  }

  IconData get icon {
    switch (this) {
      case _OwnerStaffSection.team:
        return Icons.groups_rounded;
      case _OwnerStaffSection.attendance:
        return Icons.fact_check_outlined;
      case _OwnerStaffSection.payroll:
        return Icons.payments_outlined;
      case _OwnerStaffSection.leaves:
        return Icons.event_busy_outlined;
      case _OwnerStaffSection.advances:
        return Icons.account_balance_wallet_outlined;
      case _OwnerStaffSection.docs:
        return Icons.folder_copy_outlined;
    }
  }
}

class OwnerStaffTab extends StatefulWidget {
  const OwnerStaffTab({super.key});

  @override
  State<OwnerStaffTab> createState() => _OwnerStaffTabState();
}

class _OwnerStaffTabState extends State<OwnerStaffTab> {
  _OwnerStaffSection _section = _OwnerStaffSection.team;
  UserRole? _roleFilter;
  String _query = '';

  void _showStaffSheet({StaffProfile? profile}) {
    final controller = FlywheelsScope.read(context);
    final nameController = TextEditingController(text: profile?.name ?? '');
    final phoneController = TextEditingController(text: profile?.phone ?? '');
    final salaryController = TextEditingController(
      text: profile == null ? '' : profile.salary.toStringAsFixed(0),
    );
    final emergencyController = TextEditingController(
      text: profile?.emergencyContact ?? '',
    );
    final addressController = TextEditingController(
      text: profile?.address ?? '',
    );
    final skillController = TextEditingController(
      text: profile?.skillNotes ?? '',
    );
    var role = profile?.role ?? UserRole.mechanic;
    var isActive = profile?.isActive ?? true;
    var joiningDate = profile?.joiningDate ?? DateTime.now();
    var masterMechanicId =
        profile?.masterMechanicId ??
        (controller.masterMechanicProfiles.isEmpty
            ? null
            : controller.masterMechanicProfiles.first.userId);

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
                        profile == null
                            ? 'Create staff profile'
                            : 'Edit staff profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<UserRole>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.masterMechanic,
                            child: Text('Master Mechanic'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.mechanic,
                            child: Text('Mechanic'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => role = value);
                        },
                      ),
                      if (role == UserRole.mechanic) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: masterMechanicId,
                          decoration: const InputDecoration(
                            labelText: 'Reports to',
                          ),
                          items: controller.masterMechanicProfiles
                              .map(
                                (master) => DropdownMenuItem(
                                  value: master.userId,
                                  child: Text(master.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setSheetState(() => masterMechanicId = value),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: salaryController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monthly salary',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: joiningDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setSheetState(() => joiningDate = picked);
                                }
                              },
                              icon: const ExactIcon(
                                Icons.calendar_month_rounded,
                              ),
                              label: Text(formatShortDate(joiningDate)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emergencyController,
                        decoration: const InputDecoration(
                          labelText: 'Emergency contact',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: skillController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Skill notes',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        activeThumbColor: AppPalette.red,
                        title: const Text('Active profile'),
                        onChanged: (value) =>
                            setSheetState(() => isActive = value),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final salary =
                                double.tryParse(salaryController.text.trim()) ??
                                0;
                            if (profile == null) {
                              controller.createStaffProfile(
                                name: nameController.text,
                                phone: phoneController.text,
                                role: role,
                                salary: salary,
                                joiningDate: joiningDate,
                                emergencyContact: emergencyController.text,
                                address: addressController.text,
                                skillNotes: skillController.text,
                                masterMechanicId: masterMechanicId,
                              );
                            } else {
                              controller.updateStaffProfile(
                                staffUserId: profile.userId,
                                name: nameController.text,
                                phone: phoneController.text,
                                role: role,
                                salary: salary,
                                joiningDate: joiningDate,
                                emergencyContact: emergencyController.text,
                                address: addressController.text,
                                skillNotes: skillController.text,
                                isActive: isActive,
                                masterMechanicId: masterMechanicId,
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          icon: const ExactIcon(Icons.save_rounded),
                          label: Text(
                            profile == null ? 'Create profile' : 'Save profile',
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
      nameController.dispose();
      phoneController.dispose();
      salaryController.dispose();
      emergencyController.dispose();
      addressController.dispose();
      skillController.dispose();
    });
  }

  void _showAdvanceSheet() {
    final controller = FlywheelsScope.read(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final cutController = TextEditingController(text: 'Deduct from salary');
    var staffUserId = controller.activeStaffProfiles.isEmpty
        ? null
        : controller.activeStaffProfiles.first.userId;
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
                      'Record advance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: staffUserId,
                      decoration: const InputDecoration(labelText: 'Staff'),
                      items: controller.activeStaffProfiles
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile.userId,
                              child: Text(
                                '${profile.name} - ${profile.role.label}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => staffUserId = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cutController,
                      decoration: const InputDecoration(
                        labelText: 'Repayment or cut method',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: staffUserId == null
                            ? null
                            : () {
                                controller.recordAdvance(
                                  staffUserId: staffUserId!,
                                  amount:
                                      double.tryParse(
                                        amountController.text.trim(),
                                      ) ??
                                      0,
                                  reason: reasonController.text,
                                  cutMethod: cutController.text,
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const ExactIcon(Icons.save_rounded),
                        label: const Text('Record advance'),
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
      amountController.dispose();
      reasonController.dispose();
      cutController.dispose();
    });
  }

  void _showSalarySheet() {
    final controller = FlywheelsScope.read(context);
    final monthController = TextEditingController(text: 'June 2026');
    final bonusController = TextEditingController();
    final deductionController = TextEditingController();
    var staffUserId = controller.activeStaffProfiles.isEmpty
        ? null
        : controller.activeStaffProfiles.first.userId;
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
                      'Generate salary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: staffUserId,
                      decoration: const InputDecoration(labelText: 'Staff'),
                      items: controller.activeStaffProfiles
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile.userId,
                              child: Text(
                                '${profile.name} - ${profile.role.label}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => staffUserId = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: monthController,
                      decoration: const InputDecoration(labelText: 'Month'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bonusController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Bonus',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: deductionController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Manual deduction',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: staffUserId == null
                            ? null
                            : () {
                                controller.generateSalaryRecord(
                                  staffUserId: staffUserId!,
                                  monthLabel: monthController.text,
                                  bonus:
                                      double.tryParse(
                                        bonusController.text.trim(),
                                      ) ??
                                      0,
                                  manualDeduction:
                                      double.tryParse(
                                        deductionController.text.trim(),
                                      ) ??
                                      0,
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const ExactIcon(Icons.receipt_long_rounded),
                        label: const Text('Generate payslip'),
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
      monthController.dispose();
      bonusController.dispose();
      deductionController.dispose();
    });
  }

  List<StaffProfile> _filteredStaff(AppController controller) {
    final needle = _query.trim().toLowerCase();
    return controller.staffProfiles.where((profile) {
      final roleMatches = _roleFilter == null || profile.role == _roleFilter;
      final haystack =
          '${profile.name} ${profile.phone} ${profile.role.label} ${profile.skillNotes}'
              .toLowerCase();
      return roleMatches && (needle.isEmpty || haystack.contains(needle));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    return Column(
      children: [
        SizedBox(
          height: 68,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            scrollDirection: Axis.horizontal,
            itemCount: _OwnerStaffSection.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _OwnerStaffSection.values[index];
              final selected = item == _section;
              return ChoiceChip(
                selected: selected,
                avatar: ExactIcon(
                  item.icon,
                  size: 18,
                  color: selected ? AppPalette.red : AppPalette.black,
                ),
                label: Text(item.label),
                onSelected: (_) => setState(() => _section = item),
              );
            },
          ),
        ),
        Expanded(child: _buildSection(controller)),
      ],
    );
  }

  Widget _buildSection(AppController controller) {
    switch (_section) {
      case _OwnerStaffSection.team:
        return _buildTeam(controller);
      case _OwnerStaffSection.attendance:
        return _buildAttendance(controller);
      case _OwnerStaffSection.payroll:
        return _buildPayroll(controller);
      case _OwnerStaffSection.leaves:
        return _buildLeaves(controller);
      case _OwnerStaffSection.advances:
        return _buildAdvances(controller);
      case _OwnerStaffSection.docs:
        return _buildDocs(controller);
    }
  }

  Widget _buildTeam(AppController controller) {
    final staff = _filteredStaff(controller);
    return ListView(
      key: const PageStorageKey('owner-staff-team'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: ExactIcon(Icons.search_rounded),
                  hintText: 'Search staff',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Add staff',
              onPressed: () => _showStaffSheet(),
              icon: const ExactIcon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _roleFilter == null,
              onSelected: (_) => setState(() => _roleFilter = null),
            ),
            ChoiceChip(
              label: const Text('Master Mechanic'),
              selected: _roleFilter == UserRole.masterMechanic,
              onSelected: (_) =>
                  setState(() => _roleFilter = UserRole.masterMechanic),
            ),
            ChoiceChip(
              label: const Text('Mechanic'),
              selected: _roleFilter == UserRole.mechanic,
              onSelected: (_) =>
                  setState(() => _roleFilter = UserRole.mechanic),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (staff.isEmpty)
          const _OwnerStaffEmpty(message: 'No staff profiles match this view.'),
        ...staff.map(
          (profile) => _StaffProfileCard(
            profile: profile,
            reportsTo: profile.masterMechanicId == null
                ? null
                : controller.staffName(profile.masterMechanicId),
            workload: controller.workloadCountForStaff(profile.userId),
            onEdit: () => _showStaffSheet(profile: profile),
            onToggle: () =>
                controller.setStaffActive(profile.userId, !profile.isActive),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendance(AppController controller) {
    final records = controller.attendanceRecords;
    return ListView(
      key: const PageStorageKey('owner-staff-attendance'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _OwnerStaffSummaryBand(
          title: 'Attendance today',
          subtitle:
              '${records.where((record) => record.status == AttendanceStatus.present || record.status == AttendanceStatus.late).length} marked, ${controller.leaveRequests.where((request) => request.status == ApprovalState.approved).length} leave records',
          icon: Icons.fact_check_outlined,
        ),
        const SizedBox(height: 12),
        ...records.map(
          (record) => _AttendanceTile(
            record: record,
            staffName: controller.staffName(record.staffUserId),
            onCorrect: () => _showAttendanceCorrection(record),
          ),
        ),
      ],
    );
  }

  void _showAttendanceCorrection(StaffAttendance record) {
    final reasonController = TextEditingController();
    var status = record.status;
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
                      'Correct attendance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AttendanceStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: AttendanceStatus.values
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
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          FlywheelsScope.read(context).correctAttendance(
                            attendanceId: record.id,
                            status: status,
                            reason: reasonController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const ExactIcon(Icons.save_rounded),
                        label: const Text('Save correction'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  Widget _buildPayroll(AppController controller) {
    return ListView(
      key: const PageStorageKey('owner-staff-payroll'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showSalarySheet,
            icon: const ExactIcon(Icons.add_card_rounded),
            label: const Text('Generate salary'),
          ),
        ),
        const SizedBox(height: 12),
        ...controller.salaryRecords.map(
          (record) => _SalaryTile(
            record: record,
            staffName: controller.staffName(record.staffUserId),
            onMarkPaid: record.isPaid
                ? null
                : () => controller.markSalaryPaid(record.id),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaves(AppController controller) {
    return ListView(
      key: const PageStorageKey('owner-staff-leaves'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        ...controller.leaveRequests.map(
          (request) => _LeaveTile(
            request: request,
            staffName: controller.staffName(request.staffUserId),
            onApprove: request.status == ApprovalState.pending
                ? () => controller.decideLeaveRequest(
                    request.id,
                    ApprovalState.approved,
                  )
                : null,
            onReject: request.status == ApprovalState.pending
                ? () => controller.decideLeaveRequest(
                    request.id,
                    ApprovalState.rejected,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvances(AppController controller) {
    return ListView(
      key: const PageStorageKey('owner-staff-advances'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showAdvanceSheet,
            icon: const ExactIcon(Icons.account_balance_wallet_rounded),
            label: const Text('Record advance'),
          ),
        ),
        const SizedBox(height: 12),
        ...controller.advances.map(
          (advance) => _AdvanceTile(
            advance: advance,
            staffName: controller.staffName(advance.staffUserId),
          ),
        ),
      ],
    );
  }

  Widget _buildDocs(AppController controller) {
    return ListView(
      key: const PageStorageKey('owner-staff-docs'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _OwnerStaffSummaryBand(
          title: 'Staff documents',
          subtitle:
              'Payslips, salary records, attendance records, leave records, advance records, and staff files.',
          icon: Icons.folder_copy_outlined,
        ),
        const SizedBox(height: 12),
        ...controller.staffDocuments.map(
          (document) => _StaffDocumentTile(
            document: document,
            staffName: controller.staffName(document.staffUserId),
          ),
        ),
      ],
    );
  }
}

class _StaffProfileCard extends StatelessWidget {
  const _StaffProfileCard({
    required this.profile,
    required this.reportsTo,
    required this.workload,
    required this.onEdit,
    required this.onToggle,
  });

  final StaffProfile profile;
  final String? reportsTo;
  final int workload;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MessengerAvatar(
                  path: profile.profileImagePath,
                  initials: profile.name.isEmpty ? 'F' : profile.name[0],
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${profile.role.label} | ${profile.phone}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _SmallStatusChip(
                  label: profile.isActive ? 'Active' : 'Inactive',
                  active: profile.isActive,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.payments_outlined,
                  text: formatCurrency(profile.salary),
                ),
                _InfoPill(
                  icon: Icons.work_history_outlined,
                  text: profile.workStatus.label,
                ),
                _InfoPill(
                  icon: Icons.assignment_outlined,
                  text: '$workload active',
                ),
                if (reportsTo != null)
                  _InfoPill(
                    icon: Icons.account_tree_outlined,
                    text: reportsTo!,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              profile.skillNotes.isEmpty
                  ? 'No skill notes added.'
                  : profile.skillNotes,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const ExactIcon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: ExactIcon(
                    profile.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                  ),
                  label: Text(profile.isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.record,
    required this.staffName,
    required this.onCorrect,
  });

  final StaffAttendance record;
  final String staffName;
  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const ExactIcon(Icons.fact_check_outlined),
        title: Text(staffName),
        subtitle: Text(
          '${formatShortDate(record.date)} | ${record.status.label} | Location ${record.locationVerification.label} | Face ${record.faceVerification.label}',
        ),
        trailing: IconButton(
          tooltip: 'Correct',
          onPressed: onCorrect,
          icon: const ExactIcon(Icons.edit_note_rounded),
        ),
      ),
    );
  }
}

class _SalaryTile extends StatelessWidget {
  const _SalaryTile({
    required this.record,
    required this.staffName,
    required this.onMarkPaid,
  });

  final SalaryRecord record;
  final String staffName;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$staffName - ${record.monthLabel}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _SmallStatusChip(
                  label: record.isPaid ? 'Paid' : 'Waiting',
                  active: record.isPaid,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Base ${formatCurrency(record.baseSalary)} | Advance ${formatCurrency(record.advanceDeduction)} | Final ${formatCurrency(record.finalPayable)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${record.presentDays} present, ${record.leaveDays} leave, ${record.absentDays} absent, ${record.halfDays} half day, ${record.lateMarks} late',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onMarkPaid != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onMarkPaid,
                icon: const ExactIcon(Icons.price_check_rounded),
                label: const Text('Mark paid'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({
    required this.request,
    required this.staffName,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveRequest request;
  final String staffName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    staffName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _SmallStatusChip(
                  label: request.status.label,
                  active: request.status == ApprovalState.approved,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${request.leaveType} | ${formatShortDate(request.startDate)} to ${formatShortDate(request.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(request.reason),
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const ExactIcon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const ExactIcon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdvanceTile extends StatelessWidget {
  const _AdvanceTile({required this.advance, required this.staffName});

  final StaffAdvance advance;
  final String staffName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const ExactIcon(Icons.account_balance_wallet_outlined),
        title: Text('$staffName - ${formatCurrency(advance.amount)}'),
        subtitle: Text(
          '${advance.reason} | Remaining ${formatCurrency(advance.remainingAmount)} | ${advance.cutMethod}',
        ),
        trailing: Text(advance.status.label),
      ),
    );
  }
}

class _StaffDocumentTile extends StatelessWidget {
  const _StaffDocumentTile({required this.document, required this.staffName});

  final StaffDocument document;
  final String staffName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const ExactIcon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: Text(
          '$staffName | ${document.category} | ${formatShortDate(document.createdAt)}',
        ),
        trailing: document.amount == null
            ? null
            : Text(formatCurrency(document.amount!)),
      ),
    );
  }
}

class _OwnerStaffSummaryBand extends StatelessWidget {
  const _OwnerStaffSummaryBand({
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

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

class _SmallStatusChip extends StatelessWidget {
  const _SmallStatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppPalette.red.withValues(alpha: 0.1) : AppPalette.soft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: active ? AppPalette.red : AppPalette.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? AppPalette.red : AppPalette.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OwnerStaffEmpty extends StatelessWidget {
  const _OwnerStaffEmpty({required this.message});

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

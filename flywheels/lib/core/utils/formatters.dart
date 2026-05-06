import 'package:flywheels/models/app_models.dart';

String formatCurrency(num value) => 'Rs ${value.toStringAsFixed(0)}';

String formatShortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String formatDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minutes = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${formatShortDate(value)}, $hour:$minutes $suffix';
}

String statusLabel(JobStatus status) {
  switch (status) {
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

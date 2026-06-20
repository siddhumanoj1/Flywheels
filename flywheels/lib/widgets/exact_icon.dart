import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ExactIconKind {
  home,
  docs,
  wheels,
  chat,
  profile,
  team,
  car,
  dashboard,
  left,
  right,
  tick,
  cross;

  Color get glowColor {
    return switch (this) {
      ExactIconKind.home => const Color(0xFF00E5FF),
      ExactIconKind.docs => const Color(0xFFFFEA00),
      ExactIconKind.wheels => const Color(0xFFFF9100),
      ExactIconKind.chat => const Color(0xFFD500F9),
      ExactIconKind.profile => const Color(0xFFFF4081),
      ExactIconKind.team => const Color(0xFF2979FF),
      ExactIconKind.car => const Color(0xFF00E676),
      ExactIconKind.dashboard => const Color(0xFFFF3D00),
      ExactIconKind.left ||
      ExactIconKind.right ||
      ExactIconKind.tick => const Color(0xFF00FF66),
      ExactIconKind.cross => const Color(0xFFFF2B2B),
    };
  }

  static ExactIconKind fromIconData(IconData? icon) {
    if (icon == null) return ExactIconKind.dashboard;
    if (_matches(icon, _leftIcons)) return ExactIconKind.left;
    if (_matches(icon, _rightIcons)) return ExactIconKind.right;
    if (_matches(icon, _crossIcons)) return ExactIconKind.cross;
    if (_matches(icon, _tickIcons)) return ExactIconKind.tick;
    if (_matches(icon, _chatIcons)) return ExactIconKind.chat;
    if (_matches(icon, _profileIcons)) return ExactIconKind.profile;
    if (_matches(icon, _teamIcons)) return ExactIconKind.team;
    if (_matches(icon, _docsIcons)) return ExactIconKind.docs;
    if (_matches(icon, _wheelsIcons)) return ExactIconKind.wheels;
    if (_matches(icon, _carIcons)) return ExactIconKind.car;
    if (_matches(icon, _homeIcons)) return ExactIconKind.home;
    if (_matches(icon, _dashboardIcons)) return ExactIconKind.dashboard;
    return ExactIconKind.dashboard;
  }
}

class ExactIcon extends StatelessWidget {
  const ExactIcon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
  });

  final IconData? icon;
  final double? size;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final bool? applyTextScaling;
  final BlendMode? blendMode;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();

    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final kind = ExactIconKind.fromIconData(icon);
    final matrix = ExactDotMatrixIcon(
      kind,
      size: resolvedSize,
      color: kind.glowColor,
      shadows: shadows,
      blendMode: blendMode,
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: matrix);
    }

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: matrix),
    );
  }
}

class ExactDotMatrixIcon extends StatelessWidget {
  const ExactDotMatrixIcon(
    this.kind, {
    super.key,
    this.size = 24,
    this.color,
    this.shadows,
    this.blendMode,
  });

  final ExactIconKind kind;
  final double size;
  final Color? color;
  final List<Shadow>? shadows;
  final BlendMode? blendMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ExactDotMatrixPainter(
          kind: kind,
          color: color ?? kind.glowColor,
          shadows: shadows,
          blendMode: blendMode,
        ),
      ),
    );
  }
}

class _ExactDotMatrixPainter extends CustomPainter {
  const _ExactDotMatrixPainter({
    required this.kind,
    required this.color,
    this.shadows,
    this.blendMode,
  });

  final ExactIconKind kind;
  final Color color;
  final List<Shadow>? shadows;
  final BlendMode? blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    final scale = side / 215;
    final dot = 8 * scale;
    final step = 9 * scale;
    final radius = dot / 2;
    final offPaint = Paint()
      ..color = const Color(0xFF151515).withValues(alpha: 0.62);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale)
      ..blendMode = blendMode ?? BlendMode.plus;
    final glowPaint2 = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 27 * scale)
      ..blendMode = blendMode ?? BlendMode.plus;
    final onPaint = Paint()
      ..color = color
      ..blendMode = blendMode ?? BlendMode.srcOver;

    for (var y = 0; y < 24; y++) {
      for (var x = 0; x < 24; x++) {
        final center = Offset(
          left + radius + x * step,
          top + radius + y * step,
        );

        if (!_isOn(kind, x, y)) {
          canvas.drawCircle(center, radius, offPaint);
          continue;
        }

        if (shadows != null) {
          for (final shadow in shadows!) {
            canvas.drawCircle(
              center + shadow.offset,
              radius + shadow.blurRadius * 0.08,
              Paint()..color = shadow.color,
            );
          }
        }
        canvas.drawCircle(center, radius * 1.75, glowPaint2);
        canvas.drawCircle(center, radius * 1.22, glowPaint);
        canvas.drawCircle(center, radius, onPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExactDotMatrixPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.shadows != shadows ||
        oldDelegate.blendMode != blendMode;
  }
}

bool _matches(IconData icon, List<IconData> candidates) {
  return candidates.any(
    (candidate) =>
        candidate.codePoint == icon.codePoint &&
        candidate.fontFamily == icon.fontFamily &&
        candidate.fontPackage == icon.fontPackage,
  );
}

bool _isOn(ExactIconKind kind, int x, int y) {
  switch (kind) {
    case ExactIconKind.home:
      final roof = y >= 3 && y <= 11 && (x - 11.5).abs() <= (y - 2);
      final base =
          y >= 12 &&
          y <= 20 &&
          x >= 5 &&
          x <= 18 &&
          !(x >= 10 && x <= 13 && y >= 15);
      return roof || base;
    case ExactIconKind.docs:
      final paper = x >= 5 && x <= 19 && y >= 3 && y <= 21;
      final lines = x >= 8 && x <= 16 && y >= 7 && y <= 17 && y % 3 == 1;
      return paper && !lines;
    case ExactIconKind.wheels:
      final dist = math.sqrt(math.pow(x - 11.5, 2) + math.pow(y - 11.5, 2));
      final ring = dist >= 8 && dist <= 10;
      final hub = dist <= 1;
      final spokes =
          dist <= 10 &&
          ((x - 11.5).abs() <= 1 ||
              (y - 11.5).abs() <= 1 ||
              (x - y).abs() <= 1 ||
              (x + y - 23).abs() <= 1);
      return ring || hub || (spokes && dist > 2);
    case ExactIconKind.chat:
      final bubble = x >= 3 && x <= 20 && y >= 4 && y <= 16;
      final tail = x >= 6 && x <= 10 && y >= 16 && y <= 20 && x - 6 <= 20 - y;
      final cutouts =
          y >= 9 &&
          y <= 11 &&
          ((x >= 6 && x <= 8) || (x >= 10 && x <= 12) || (x >= 14 && x <= 16));
      return (bubble || tail) && !cutouts;
    case ExactIconKind.profile:
      var head = false;
      var body = false;
      if (y == 3 || y == 11) {
        head = x >= 9 && x <= 14;
      } else if (y == 4 || y == 10) {
        head = x >= 8 && x <= 15;
      } else if (y >= 5 && y <= 9) {
        head = x >= 7 && x <= 16;
      }
      if (y == 13) {
        body = x >= 7 && x <= 16;
      } else if (y == 14) {
        body = x >= 6 && x <= 17;
      } else if (y == 15) {
        body = x >= 5 && x <= 18;
      } else if (y >= 16 && y <= 20) {
        body = x >= 4 && x <= 19;
      }
      return head || body;
    case ExactIconKind.team:
      return _isTeamOn(x, y);
    case ExactIconKind.car:
      final roof =
          (y == 6 && x >= 7 && x <= 16) ||
          (y == 7 && x >= 6 && x <= 17) ||
          (y == 8 && x >= 6 && x <= 17) ||
          (y == 9 && x >= 4 && x <= 19) ||
          (y == 10 && x >= 5 && x <= 18);
      final body =
          (y >= 11 && y <= 12 && x >= 4 && x <= 19) ||
          (y >= 12 && y <= 13 && x >= 3 && x <= 20) ||
          (y == 14 && x >= 8 && x <= 15) ||
          (y >= 15 && y <= 16 && x >= 3 && x <= 20) ||
          (y == 17 && x >= 3 && x <= 20);
      final leftBumper = x == 3 && y >= 12 && y <= 17;
      final rightBumper = x == 20 && y >= 12 && y <= 17;
      final leftWheel = x >= 4 && x <= 6 && y >= 15 && y <= 18;
      final rightWheel = x >= 17 && x <= 19 && y >= 15 && y <= 18;
      final window =
          (x >= 8 && x <= 15 && y >= 7 && y <= 10) ||
          (x >= 7 && x <= 16 && y >= 8 && y <= 10);
      return (roof ||
              body ||
              leftBumper ||
              rightBumper ||
              leftWheel ||
              rightWheel) &&
          !window;
    case ExactIconKind.dashboard:
      return _rowHas(_dashboardRows, x, y);
    case ExactIconKind.left:
      return _rowHas(_leftRows, x, y);
    case ExactIconKind.right:
      return _rowHas(_rightRows, x, y);
    case ExactIconKind.tick:
      return _rowHas(_tickRows, x, y);
    case ExactIconKind.cross:
      return _rowHas(_crossRows, x, y);
  }
}

bool _isTeamOn(int x, int y) {
  if (y == 7 && x >= 11 && x <= 13) return true;
  if (y >= 8 && y <= 10 && x >= 10 && x <= 14) return true;
  if (y == 11 && x >= 11 && x <= 13) return true;
  if (y == 13 && x >= 10 && x <= 14) return true;
  if (y == 14 && x >= 9 && x <= 15) return true;
  if (y >= 15 && y <= 17 && x >= 8 && x <= 16) return true;
  if (y == 7 && x >= 5 && x <= 6) return true;
  if (y >= 8 && y <= 9 && x >= 4 && x <= 7) return true;
  if (y == 10 && x >= 5 && x <= 6) return true;
  if (y == 12 && x >= 4 && x <= 7) return true;
  if (y == 13 && x >= 3 && x <= 7) return true;
  if (y >= 14 && y <= 15 && x >= 3 && x <= 6) return true;
  if (y == 7 && x >= 18 && x <= 19) return true;
  if (y >= 8 && y <= 9 && x >= 17 && x <= 20) return true;
  if (y == 10 && x >= 18 && x <= 19) return true;
  if (y == 12 && x >= 17 && x <= 20) return true;
  if (y == 13 && x >= 17 && x <= 21) return true;
  if (y >= 14 && y <= 15 && x >= 18 && x <= 21) return true;
  return false;
}

bool _rowHas(Map<int, List<List<int>>> rows, int x, int y) {
  final ranges = rows[y];
  if (ranges == null) return false;
  return ranges.any((range) => x >= range[0] && x <= range[1]);
}

const _dashboardRows = <int, List<List<int>>>{
  4: [
    [9, 14],
  ],
  5: [
    [7, 16],
  ],
  6: [
    [5, 7],
    [11, 11],
    [16, 18],
  ],
  7: [
    [4, 6],
    [11, 11],
    [17, 19],
  ],
  8: [
    [3, 5],
    [11, 11],
    [18, 20],
  ],
  9: [
    [3, 4],
    [6, 6],
    [17, 17],
    [19, 20],
  ],
  10: [
    [2, 3],
    [7, 7],
    [16, 16],
    [20, 21],
  ],
  11: [
    [2, 3],
    [15, 15],
    [20, 21],
  ],
  12: [
    [2, 2],
    [14, 15],
    [21, 21],
  ],
  13: [
    [1, 2],
    [13, 14],
    [21, 22],
  ],
  14: [
    [1, 2],
    [11, 13],
    [21, 22],
  ],
  15: [
    [1, 5],
    [10, 10],
    [13, 13],
    [18, 22],
  ],
  16: [
    [1, 2],
    [10, 10],
    [13, 13],
    [21, 22],
  ],
  17: [
    [1, 2],
    [11, 12],
    [21, 22],
  ],
  18: [
    [2, 3],
    [20, 21],
  ],
  19: [
    [2, 3],
    [20, 21],
  ],
};

const _leftRows = <int, List<List<int>>>{
  4: [
    [9, 9],
  ],
  5: [
    [8, 9],
  ],
  6: [
    [7, 9],
  ],
  7: [
    [6, 9],
  ],
  8: [
    [5, 9],
  ],
  9: [
    [4, 21],
  ],
  10: [
    [3, 21],
  ],
  11: [
    [2, 21],
  ],
  12: [
    [1, 21],
  ],
  13: [
    [2, 21],
  ],
  14: [
    [3, 21],
  ],
  15: [
    [4, 21],
  ],
  16: [
    [5, 9],
  ],
  17: [
    [6, 9],
  ],
  18: [
    [7, 9],
  ],
  19: [
    [8, 9],
  ],
  20: [
    [9, 9],
  ],
};

const _rightRows = <int, List<List<int>>>{
  4: [
    [14, 14],
  ],
  5: [
    [14, 15],
  ],
  6: [
    [14, 16],
  ],
  7: [
    [14, 17],
  ],
  8: [
    [14, 18],
  ],
  9: [
    [2, 19],
  ],
  10: [
    [2, 20],
  ],
  11: [
    [2, 21],
  ],
  12: [
    [2, 22],
  ],
  13: [
    [2, 21],
  ],
  14: [
    [2, 20],
  ],
  15: [
    [2, 19],
  ],
  16: [
    [14, 18],
  ],
  17: [
    [14, 17],
  ],
  18: [
    [14, 16],
  ],
  19: [
    [14, 15],
  ],
  20: [
    [14, 14],
  ],
};

const _tickRows = <int, List<List<int>>>{
  6: [
    [19, 20],
  ],
  7: [
    [18, 20],
  ],
  8: [
    [17, 19],
  ],
  9: [
    [16, 18],
  ],
  10: [
    [15, 17],
  ],
  11: [
    [14, 16],
  ],
  12: [
    [5, 6],
    [13, 15],
  ],
  13: [
    [5, 7],
    [12, 14],
  ],
  14: [
    [6, 8],
    [11, 13],
  ],
  15: [
    [7, 9],
    [10, 12],
  ],
  16: [
    [8, 11],
  ],
  17: [
    [9, 10],
  ],
};

const _crossRows = <int, List<List<int>>>{
  5: [
    [5, 6],
    [17, 18],
  ],
  6: [
    [5, 7],
    [16, 18],
  ],
  7: [
    [6, 8],
    [15, 17],
  ],
  8: [
    [7, 9],
    [14, 16],
  ],
  9: [
    [8, 10],
    [13, 15],
  ],
  10: [
    [9, 11],
    [12, 14],
  ],
  11: [
    [10, 13],
  ],
  12: [
    [10, 13],
  ],
  13: [
    [9, 11],
    [12, 14],
  ],
  14: [
    [8, 10],
    [13, 15],
  ],
  15: [
    [7, 9],
    [14, 16],
  ],
  16: [
    [6, 8],
    [15, 17],
  ],
  17: [
    [5, 7],
    [16, 18],
  ],
  18: [
    [5, 6],
    [17, 18],
  ],
};

const _homeIcons = <IconData>[
  Icons.home_outlined,
  Icons.home_rounded,
  Icons.today_rounded,
  Icons.calendar_month_outlined,
  Icons.calendar_month_rounded,
  Icons.event_outlined,
  Icons.event_rounded,
  Icons.event_available_outlined,
  Icons.event_available_rounded,
  Icons.schedule_rounded,
  Icons.history_rounded,
];

const _docsIcons = <IconData>[
  Icons.account_balance_wallet_outlined,
  Icons.account_balance_wallet_rounded,
  Icons.account_tree_outlined,
  Icons.assignment_outlined,
  Icons.assignment_rounded,
  Icons.attach_file_rounded,
  Icons.badge_outlined,
  Icons.calculate_rounded,
  Icons.description,
  Icons.description_outlined,
  Icons.description_rounded,
  Icons.download_rounded,
  Icons.edit_document,
  Icons.edit_note_rounded,
  Icons.edit_outlined,
  Icons.edit_rounded,
  Icons.folder_copy_outlined,
  Icons.folder_copy_rounded,
  Icons.ios_share_rounded,
  Icons.library_add_rounded,
  Icons.library_books_outlined,
  Icons.payments_outlined,
  Icons.payments_rounded,
  Icons.picture_as_pdf_rounded,
  Icons.price_check_rounded,
  Icons.receipt_long_outlined,
  Icons.receipt_long_rounded,
  Icons.request_quote_rounded,
  Icons.save_outlined,
  Icons.save_rounded,
  Icons.share_rounded,
  Icons.upload_file_rounded,
  Icons.visibility_rounded,
  Icons.work_history_outlined,
];

const _wheelsIcons = <IconData>[
  Icons.add_card_rounded,
  Icons.local_gas_station,
  Icons.motion_photos_auto_outlined,
  Icons.motion_photos_auto_rounded,
  Icons.palette_outlined,
  Icons.sell_outlined,
  Icons.sell_rounded,
];

const _chatIcons = <IconData>[
  Icons.call_rounded,
  Icons.chat_bubble_outline_rounded,
  Icons.chat_bubble_rounded,
  Icons.notifications_active_outlined,
  Icons.notifications_active_rounded,
  Icons.send_rounded,
];

const _profileIcons = <IconData>[
  Icons.airline_seat_recline_normal_rounded,
  Icons.lock_outline_rounded,
  Icons.logout_rounded,
  Icons.person_outline_rounded,
  Icons.person_rounded,
  Icons.person_search_outlined,
  Icons.person_search_rounded,
];

const _teamIcons = <IconData>[
  Icons.assignment_ind_outlined,
  Icons.engineering_outlined,
  Icons.groups_outlined,
  Icons.groups_rounded,
  Icons.person_add_alt_1_rounded,
];

const _carIcons = <IconData>[
  Icons.add_road_outlined,
  Icons.build_circle_outlined,
  Icons.directions_car_filled_outlined,
  Icons.directions_car_filled_rounded,
  Icons.directions_car_rounded,
  Icons.garage_outlined,
  Icons.garage_rounded,
  Icons.handyman_outlined,
  Icons.home_repair_service_outlined,
  Icons.inventory_2_outlined,
  Icons.local_shipping_outlined,
  Icons.location_on_outlined,
  Icons.location_pin,
  Icons.map_outlined,
  Icons.pin_outlined,
  Icons.route_outlined,
  Icons.route_rounded,
];

const _dashboardIcons = <IconData>[
  Icons.bolt_rounded,
  Icons.dashboard_outlined,
  Icons.dashboard_rounded,
  Icons.dialpad_rounded,
  Icons.hourglass_top_rounded,
  Icons.image_outlined,
  Icons.pending_actions_outlined,
  Icons.pending_actions_rounded,
  Icons.photo_camera_outlined,
  Icons.photo_library_outlined,
  Icons.photo_outlined,
  Icons.play_circle_fill_rounded,
  Icons.play_circle_outline_rounded,
  Icons.publish_rounded,
  Icons.radio_button_off_rounded,
  Icons.refresh_rounded,
  Icons.restart_alt_rounded,
  Icons.search_rounded,
  Icons.settings_outlined,
  Icons.sort_rounded,
  Icons.speed_rounded,
  Icons.timeline_rounded,
  Icons.tune_rounded,
  Icons.update_rounded,
  Icons.videocam_outlined,
];

const _tickIcons = <IconData>[
  Icons.add,
  Icons.add_rounded,
  Icons.approval_outlined,
  Icons.check_circle_outline_rounded,
  Icons.check_circle_rounded,
  Icons.check_rounded,
  Icons.done_all_rounded,
  Icons.done_rounded,
  Icons.fact_check_outlined,
  Icons.fact_check_rounded,
  Icons.radio_button_checked_rounded,
  Icons.task_alt_outlined,
  Icons.task_alt_rounded,
  Icons.verified_outlined,
  Icons.verified_rounded,
];

const _crossIcons = <IconData>[
  Icons.close_rounded,
  Icons.delete_outline_rounded,
  Icons.event_busy_outlined,
  Icons.event_busy_rounded,
  Icons.pause_circle_outline_rounded,
];

const _leftIcons = <IconData>[
  Icons.arrow_back_rounded,
  Icons.chevron_left_rounded,
  Icons.north_rounded,
];

const _rightIcons = <IconData>[
  Icons.arrow_forward_rounded,
  Icons.chevron_right_rounded,
  Icons.keyboard_arrow_up_rounded,
  Icons.south_rounded,
];

import 'dart:async';
import 'dart:math' as math;

import 'package:flywheels/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _firstCheckpointFraction = 0.16;
const _checkpointSpacingFraction = 0.14;
const _finishCheckpointIndex = 5;

double _checkpointFraction(int index) {
  return _firstCheckpointFraction + (_checkpointSpacingFraction * index);
}

double _checkpointFractionForStatus(JobStatus status) {
  return switch (status) {
    JobStatus.pickupDone => _checkpointFraction(0),
    JobStatus.received => _checkpointFraction(1),
    JobStatus.underInspection => _checkpointFraction(2),
    JobStatus.workInProgress => _checkpointFraction(3),
    JobStatus.completed => _checkpointFraction(4),
    JobStatus.deliveryScheduled => _checkpointFraction(_finishCheckpointIndex),
    JobStatus.pickupScheduled || JobStatus.onRoad => _firstCheckpointFraction,
  };
}

class GarageServiceTracker extends StatefulWidget {
  const GarageServiceTracker({
    super.key,
    required this.status,
    this.onStatusChanged,
    this.enableAutoOnRoad = true,
  });

  final JobStatus status;
  final ValueChanged<JobStatus>? onStatusChanged;
  final bool enableAutoOnRoad;

  @override
  State<GarageServiceTracker> createState() => _GarageServiceTrackerState();
}

class _GarageServiceTrackerState extends State<GarageServiceTracker>
    with TickerProviderStateMixin {
  static const _moveDuration = Duration(milliseconds: 1700);
  static const _exitDuration = Duration(milliseconds: 1300);
  static const _enterDuration = Duration(milliseconds: 1600);
  static const _introStepDuration = Duration(milliseconds: 520);
  static const _introStepPause = Duration(milliseconds: 90);

  late final AnimationController _idleController;
  late final AnimationController _roadController;
  late final AnimationController _wheelController;
  late JobStatus _displayStatus;

  Timer? _wheelStopTimer;
  Timer? _exitTimer;
  Timer? _enterTimer;
  Timer? _introTimer;
  _CarMotionPhase _motionPhase = _CarMotionPhase.normal;
  Duration _carDuration = Duration.zero;
  Curve _carCurve = Curves.easeInOut;
  late JobStatus _targetStatus;

  @override
  void initState() {
    super.initState();
    _targetStatus = widget.status;
    _displayStatus = JobStatus.pickupScheduled;
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _syncMotion(animated: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playIntroTo(widget.status);
    });
  }

  @override
  void didUpdateWidget(covariant GarageServiceTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == oldWidget.status || widget.status == _targetStatus) {
      return;
    }
    _playIntroTo(widget.status);
  }

  @override
  void dispose() {
    _cancelTimers();
    _idleController.dispose();
    _roadController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _introTimer?.cancel();
    _cancelMotionTimers();
    _introTimer = null;
  }

  void _cancelMotionTimers() {
    _wheelStopTimer?.cancel();
    _exitTimer?.cancel();
    _enterTimer?.cancel();
    _wheelStopTimer = null;
    _exitTimer = null;
    _enterTimer = null;
  }

  void _applyStatus(
    JobStatus status, {
    required bool notify,
    required Duration moveDuration,
    required bool allowAutoOnRoad,
    bool updateTarget = true,
  }) {
    _cancelMotionTimers();
    if (updateTarget) _targetStatus = status;
    setState(() {
      _displayStatus = status;
      _motionPhase = _CarMotionPhase.normal;
      _carDuration = moveDuration;
      _carCurve = Curves.easeInOut;
    });
    _syncMotion(animated: true);
    if (notify) widget.onStatusChanged?.call(status);
    if (allowAutoOnRoad && status == JobStatus.deliveryScheduled) {
      _scheduleDeliveryToOnRoad(notify: notify);
    }
  }

  void _playIntroTo(JobStatus status) {
    _cancelTimers();
    _targetStatus = status;
    final targetIndex = JobStatus.values.indexOf(status);
    final targetIsOnRoad = status == JobStatus.onRoad;
    final replayTargetIndex = targetIsOnRoad
        ? JobStatus.values.indexOf(JobStatus.deliveryScheduled)
        : targetIndex;
    setState(() {
      _displayStatus = JobStatus.pickupScheduled;
      _motionPhase = _CarMotionPhase.normal;
      _carDuration = Duration.zero;
      _carCurve = Curves.linear;
    });
    _syncMotion(animated: false);

    if (replayTargetIndex <= 0) return;

    var nextIndex = 1;
    void step() {
      if (!mounted || _targetStatus != status) return;
      _applyStatus(
        JobStatus.values[nextIndex],
        notify: false,
        moveDuration: _introStepDuration,
        allowAutoOnRoad: false,
        updateTarget: false,
      );
      if (nextIndex < replayTargetIndex) {
        nextIndex += 1;
        _introTimer = Timer(_introStepDuration + _introStepPause, step);
      } else if (targetIsOnRoad) {
        _scheduleDeliveryToOnRoad(
          notify: false,
          approachDuration: _introStepDuration + _introStepPause,
        );
      }
    }

    _introTimer = Timer(const Duration(milliseconds: 180), step);
  }

  void _syncMotion({required bool animated}) {
    if (_displayStatus == JobStatus.onRoad) {
      _wheelStopTimer?.cancel();
      if (!_roadController.isAnimating) _roadController.repeat();
      if (!_wheelController.isAnimating) _wheelController.repeat();
      return;
    }

    _roadController.stop();
    _roadController.value = 0;
    if (!animated) {
      _wheelController.stop();
      return;
    }

    _wheelController.repeat();
    _wheelStopTimer?.cancel();
    final duration = _displayStatus == JobStatus.deliveryScheduled
        ? _moveDuration + _exitDuration + _enterDuration
        : _moveDuration;
    _wheelStopTimer = Timer(duration, () {
      if (mounted && _displayStatus != JobStatus.onRoad) {
        _wheelController.stop();
      }
    });
  }

  void _scheduleDeliveryToOnRoad({
    required bool notify,
    Duration approachDuration = _moveDuration,
  }) {
    if (!widget.enableAutoOnRoad) return;

    _exitTimer = Timer(approachDuration, () {
      if (!mounted || _displayStatus != JobStatus.deliveryScheduled) return;
      setState(() {
        _motionPhase = _CarMotionPhase.exiting;
        _carDuration = _exitDuration;
        _carCurve = Curves.easeIn;
      });
    });

    _enterTimer = Timer(approachDuration + _exitDuration, () {
      if (!mounted || _displayStatus != JobStatus.deliveryScheduled) return;
      setState(() {
        _targetStatus = JobStatus.onRoad;
        _displayStatus = JobStatus.onRoad;
        _motionPhase = _CarMotionPhase.preEnter;
        _carDuration = Duration.zero;
        _carCurve = Curves.linear;
      });
      _syncMotion(animated: true);
      if (notify) widget.onStatusChanged?.call(JobStatus.onRoad);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _displayStatus != JobStatus.onRoad) return;
        setState(() {
          _motionPhase = _CarMotionPhase.normal;
          _carDuration = _enterDuration;
          _carCurve = Curves.easeOut;
        });
      });
    });
  }

  void _handleStatusChanged(JobStatus? status) {
    if (status == null) return;
    if (status == _displayStatus && _motionPhase == _CarMotionPhase.normal) {
      return;
    }
    _introTimer?.cancel();
    _introTimer = null;
    _applyStatus(
      status,
      notify: true,
      moveDuration: _moveDuration,
      allowAutoOnRoad: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: _StatusSelect(
                  value: _displayStatus,
                  readOnly: widget.onStatusChanged == null,
                  onChanged: _handleStatusChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _TrackerScene(
            status: _displayStatus,
            motionPhase: _motionPhase,
            carDuration: _carDuration,
            carCurve: _carCurve,
            idleAnimation: _idleController,
            roadAnimation: _roadController,
            wheelAnimation: _wheelController,
          ),
        ],
      ),
    );
  }
}

class _StatusSelect extends StatelessWidget {
  const _StatusSelect({
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  final JobStatus value;
  final bool readOnly;
  final ValueChanged<JobStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = _trackerLabel(value);
    const controlRed = Color(0xFFE80000);
    final decoration = BoxDecoration(
      color: controlRed,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: controlRed),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );

    if (readOnly) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: decoration,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: controlRed,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: controlRed),
        boxShadow: decoration.boxShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<JobStatus>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: Colors.white,
          ),
          dropdownColor: controlRed,
          borderRadius: BorderRadius.circular(8),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          selectedItemBuilder: (context) {
            return JobStatus.values
                .map(
                  (status) => Center(
                    child: Text(
                      _trackerLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList();
          },
          items: JobStatus.values
              .map(
                (status) => DropdownMenuItem<JobStatus>(
                  value: status,
                  child: Center(
                    child: Text(
                      _trackerLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TrackerScene extends StatelessWidget {
  const _TrackerScene({
    required this.status,
    required this.motionPhase,
    required this.carDuration,
    required this.carCurve,
    required this.idleAnimation,
    required this.roadAnimation,
    required this.wheelAnimation,
  });

  final JobStatus status;
  final _CarMotionPhase motionPhase;
  final Duration carDuration;
  final Curve carCurve;
  final Animation<double> idleAnimation;
  final Animation<double> roadAnimation;
  final Animation<double> wheelAnimation;

  static const _carWrapperBottom = -8.0;
  static const _exitOffset = 240.0;
  static const _enterOffset = -260.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final carWidth = width < 360
            ? 90.0
            : width < 520
            ? 110.0
            : width < 760
            ? 130.0
            : 148.0;
        final roadHeight = width < 360
            ? 24.0
            : width < 520
            ? 28.0
            : 32.0;
        final scale = carWidth / 220;
        final carHeight = carWidth * 792 / 1080;
        final sceneHeight = width < 360
            ? 78.0
            : width < 520
            ? 92.0
            : 106.0;
        final carLeft = _carLeftFor(width, carWidth, scale);
        final repairMode =
            status == JobStatus.pickupScheduled ||
            status == JobStatus.underInspection ||
            status == JobStatus.workInProgress;
        final onRoad = status == JobStatus.onRoad;

        return ClipRect(
          child: SizedBox(
            height: sceneHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: roadHeight,
                  child: AnimatedBuilder(
                    animation: roadAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RoadPainter(
                          progress: onRoad ? roadAnimation.value : 0,
                          onRoadMode: onRoad,
                        ),
                      );
                    },
                  ),
                ),
                AnimatedPositioned(
                  duration: carDuration,
                  curve: carCurve,
                  left: carLeft,
                  bottom: _carWrapperBottom * scale,
                  width: carWidth,
                  height: carHeight,
                  child: AnimatedBuilder(
                    animation: idleAnimation,
                    child: _CarAssetStack(
                      repairMode: repairMode,
                      carWidth: carWidth,
                      carHeight: carHeight,
                      scale: scale,
                      wheelAnimation: wheelAnimation,
                    ),
                    builder: (context, child) {
                      final dy =
                          -3 * scale * math.sin(idleAnimation.value * math.pi);
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _carLeftFor(double width, double carWidth, double scale) {
    switch (motionPhase) {
      case _CarMotionPhase.exiting:
        return width + (_exitOffset * scale);
      case _CarMotionPhase.preEnter:
        return _enterOffset * scale;
      case _CarMotionPhase.normal:
        return switch (status) {
          JobStatus.pickupScheduled => 40 * scale,
          JobStatus.pickupDone ||
          JobStatus.received ||
          JobStatus.underInspection ||
          JobStatus.workInProgress ||
          JobStatus.completed =>
            width * _checkpointFractionForStatus(status) - carWidth / 2,
          JobStatus.deliveryScheduled =>
            width * _checkpointFractionForStatus(status) - 60 * scale,
          JobStatus.onRoad => (width - carWidth) / 2,
        };
    }
  }
}

class _CarAssetStack extends StatelessWidget {
  const _CarAssetStack({
    required this.repairMode,
    required this.carWidth,
    required this.carHeight,
    required this.scale,
    required this.wheelAnimation,
  });

  final bool repairMode;
  final double carWidth;
  final double carHeight;
  final double scale;
  final Animation<double> wheelAnimation;

  static const _wheelRotationAlignment = Alignment(0, -24 / 196);

  @override
  Widget build(BuildContext context) {
    final wheelSize = 196 * scale;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/car_status/car.svg',
            width: carWidth,
            height: carHeight,
            fit: BoxFit.contain,
            colorFilter: repairMode
                ? const ColorFilter.mode(Colors.transparent, BlendMode.dstIn)
                : null,
          ),
        ),
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/car_status/repair.svg',
            width: carWidth,
            height: carHeight,
            fit: BoxFit.contain,
            colorFilter: repairMode
                ? null
                : const ColorFilter.mode(Colors.transparent, BlendMode.dstIn),
          ),
        ),
        Positioned(
          left: -47 * scale,
          bottom: -63 * scale,
          width: wheelSize,
          height: wheelSize,
          child: RotationTransition(
            alignment: _wheelRotationAlignment,
            turns: wheelAnimation,
            child: SvgPicture.asset(
              'assets/car_status/tire.svg',
              width: wheelSize,
              height: wheelSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          right: -55 * scale,
          bottom: -63 * scale,
          width: wheelSize,
          height: wheelSize,
          child: RotationTransition(
            alignment: _wheelRotationAlignment,
            turns: wheelAnimation,
            child: SvgPicture.asset(
              'assets/car_status/tire.svg',
              width: wheelSize,
              height: wheelSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.progress, required this.onRoadMode});

  static const _red = Color(0xFFE80000);
  static const _white = Color(0xFFFFFFFF);
  static const _roadDark = Color(0xFF2C353D);

  final double progress;
  final bool onRoadMode;

  @override
  void paint(Canvas canvas, Size size) {
    final roadScale = size.height / 64;
    final logicalSize = Size(size.width, 64);
    canvas.save();
    canvas.scale(1, roadScale);
    final shift = onRoadMode ? -progress * size.width : 0.0;
    _paintLayer(
      canvas,
      logicalSize,
      Offset(shift, 0),
      showCheckpoints: !onRoadMode,
    );
    if (onRoadMode) {
      _paintLayer(
        canvas,
        logicalSize,
        Offset(shift + logicalSize.width - 1, 0),
        showCheckpoints: false,
      );
    }
    canvas.restore();
  }

  void _paintLayer(
    Canvas canvas,
    Size size,
    Offset offset, {
    required bool showCheckpoints,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(Offset.zero & size);

    _drawGradientRect(
      canvas,
      const Rect.fromLTWH(0, 0, 1, 2),
      size.width,
      const [Color(0xE0000000), Color(0x593A3A3A)],
    );
    _drawCurb(
      canvas,
      Rect.fromLTWH(0, 2, size.width, 6),
      baseColor: _white,
      stripeColor: _red,
      stripeWidth: 32,
      gapWidth: 30,
      startOffset: 0,
    );
    _drawTopEdge(canvas, size.width);
    _drawRoadSurface(canvas, size.width);

    if (showCheckpoints) {
      for (var index = 0; index < _finishCheckpointIndex; index += 1) {
        _drawCheckpoint(canvas, size.width * _checkpointFraction(index));
      }
      _drawFinalCheckpoint(
        canvas,
        size.width * _checkpointFraction(_finishCheckpointIndex),
      );
    }

    _drawBottomEdge(canvas, size.width);
    _drawCurb(
      canvas,
      Rect.fromLTWH(0, 58, size.width, 6),
      baseColor: _red,
      stripeColor: _white,
      stripeWidth: 36,
      gapWidth: 36,
      startOffset: 0,
    );
    canvas.restore();
  }

  void _drawGradientRect(
    Canvas canvas,
    Rect unitRect,
    double width,
    List<Color> colors,
  ) {
    final rect = Rect.fromLTWH(0, unitRect.top, width, unitRect.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  void _drawTopEdge(Canvas canvas, double width) {
    final colors = const [
      Color(0xFA262E36),
      Color(0xF5BDC4CA),
      Color(0xFAE1E3E5),
      Color(0xFF28323A),
    ];
    for (var index = 0; index < colors.length; index++) {
      canvas.drawRect(
        Rect.fromLTWH(0, 8.0 + index, width, 1),
        Paint()..color = colors[index],
      );
    }
  }

  void _drawRoadSurface(Canvas canvas, double width) {
    final rect = Rect.fromLTWH(0, 12, width, 40);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF28323B),
            Color(0xFF2B343C),
            _roadDark,
            Color(0xFF27313A),
          ],
          stops: [0, 0.30, 0.64, 1],
        ).createShader(rect),
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var x = 31.0; x < width; x += 32) {
      canvas.drawLine(Offset(x, 12), Offset(x, 52), linePaint);
    }
    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var y = 29.0; y < 52; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(width, y), darkPaint);
    }
  }

  void _drawBottomEdge(Canvas canvas, double width) {
    final colors = const [
      Color(0xFA747B84),
      Color(0xFFFDFDFF),
      Color(0xFF232A31),
      Color(0xFF232A31),
      Color(0xE6878A8E),
      Color(0xE6878A8E),
    ];
    for (var index = 0; index < colors.length; index++) {
      canvas.drawRect(
        Rect.fromLTWH(0, 52.0 + index, width, 1),
        Paint()..color = colors[index],
      );
    }
  }

  void _drawCurb(
    Canvas canvas,
    Rect rect, {
    required Color baseColor,
    required Color stripeColor,
    required double stripeWidth,
    required double gapWidth,
    required double startOffset,
  }) {
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = baseColor);
    final step = stripeWidth + gapWidth;
    final slant = rect.height * 1.3;
    for (var x = -step + startOffset; x < rect.width + step; x += step) {
      final path = Path()
        ..moveTo(x, rect.top)
        ..lineTo(x + stripeWidth, rect.top)
        ..lineTo(x + stripeWidth - slant, rect.bottom)
        ..lineTo(x - slant, rect.bottom)
        ..close();
      canvas.drawPath(path, Paint()..color = stripeColor);
    }
    canvas.restore();
  }

  void _drawCheckpoint(Canvas canvas, double left) {
    const top = 20.0;
    const height = 25.0;
    const width = 7.0;
    final skew = math.tan(38 * math.pi / 180) * height;
    final path = Path()
      ..moveTo(left, top)
      ..lineTo(left + width, top)
      ..lineTo(left + width + skew, top + height)
      ..lineTo(left + skew, top + height)
      ..close();
    canvas.drawPath(path, Paint()..color = _red);
  }

  void _drawFinalCheckpoint(Canvas canvas, double left) {
    final path = Path()
      ..moveTo(left, 11)
      ..lineTo(left + 21, 11)
      ..lineTo(left + 76, 68)
      ..lineTo(left + 53, 68)
      ..close();
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, Paint()..color = _white);
    for (var x = left - 60; x < left + 120; x += 8) {
      final stripe = Path()
        ..moveTo(x, 11)
        ..lineTo(x + 4, 11)
        ..lineTo(x + 30, 68)
        ..lineTo(x + 26, 68)
        ..close();
      canvas.drawPath(stripe, Paint()..color = _red);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        onRoadMode != oldDelegate.onRoadMode;
  }
}

enum _CarMotionPhase { normal, exiting, preEnter }

String _trackerLabel(JobStatus status) {
  switch (status) {
    case JobStatus.pickupScheduled:
      return 'Pickup Scheduled';
    case JobStatus.pickupDone:
      return 'Pickup Done';
    case JobStatus.received:
      return 'Received';
    case JobStatus.underInspection:
      return 'Under Inspection';
    case JobStatus.workInProgress:
      return 'Work In Progress';
    case JobStatus.completed:
      return 'Completed - Waiting For Pickup';
    case JobStatus.deliveryScheduled:
      return 'Delivery Scheduled';
    case JobStatus.onRoad:
      return 'On-Road';
  }
}

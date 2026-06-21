import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

enum OdometerOtpStatus { pending, success, error }

class OdometerOtpInput extends StatefulWidget {
  const OdometerOtpInput({
    super.key,
    required this.controller,
    required this.correctOtp,
    this.enabled = true,
    this.autoFocus = false,
    this.showEntryField = true,
    this.status,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String correctOtp;
  final bool enabled;
  final bool autoFocus;
  final bool showEntryField;
  final OdometerOtpStatus? status;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final VoidCallback? onSubmitted;

  @override
  State<OdometerOtpInput> createState() => _OdometerOtpInputState();
}

class _OdometerOtpInputState extends State<OdometerOtpInput> with CodeAutoFill {
  static const _digitCount = 5;

  String _lastValue = '';
  final List<int?> _dialDigits = List<int?>.filled(_digitCount, null);
  Timer? _dialCompletionTimer;
  bool _isApplyingDialUpdate = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _lastValue = _digitsOnly(widget.controller.text);
    widget.controller.addListener(_handleControllerChanged);
    listenForCode(smsCodeRegexPattern: r'\d{5}');
  }

  @override
  void didUpdateWidget(covariant OdometerOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _clearDialDigits();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dialCompletionTimer?.cancel();
    widget.controller.removeListener(_handleControllerChanged);
    unawaited(cancel());
    unawaited(unregisterListener());
    super.dispose();
  }

  void _handleControllerChanged() {
    final value = _digitsOnly(widget.controller.text);
    if (!_isApplyingDialUpdate) {
      _clearDialDigits();
    }
    if (value != _lastValue) {
      _lastValue = value;
      widget.onChanged?.call(value);
      if (_isApplyingDialUpdate) {
        _scheduleDialCompletion();
      } else if (value.length == _digitCount) {
        widget.onCompleted?.call(value);
      }
    }
    if (mounted) setState(() {});
  }

  void _handleDigitStep(int index, int step) {
    if (!widget.enabled || index < 0 || index >= _digitCount) return;

    _seedDialDigitsFromText();
    final currentDigit = _dialDigits[index] ?? 0;
    final steppedDigit = (currentDigit + step) % 10;
    _dialDigits[index] = steppedDigit < 0 ? steppedDigit + 10 : steppedDigit;

    final nextValue = _textFromDialDigits();
    _isApplyingDialUpdate = true;
    try {
      widget.controller.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      );
    } finally {
      _isApplyingDialUpdate = false;
    }
  }

  void _seedDialDigitsFromText() {
    if (_hasDialDigits) return;
    final value = _digitsOnly(widget.controller.text);
    for (var index = 0; index < value.length && index < _digitCount; index++) {
      _dialDigits[index] = int.tryParse(value[index]);
    }
  }

  void _clearDialDigits() {
    _dialCompletionTimer?.cancel();
    for (var index = 0; index < _dialDigits.length; index++) {
      _dialDigits[index] = null;
    }
  }

  bool get _hasDialDigits => _dialDigits.any((digit) => digit != null);
  bool get _hasCompleteDialCode => _dialDigits.every((digit) => digit != null);

  String _textFromDialDigits() {
    return _dialDigits
        .map((digit) => digit?.toString() ?? ' ')
        .join()
        .trimRight();
  }

  String _displayValueFor(String value) {
    if (!_hasDialDigits) return value;
    return _dialDigits.map((digit) => '${digit ?? 0}').join();
  }

  void _scheduleDialCompletion() {
    _dialCompletionTimer?.cancel();
    if (!_hasCompleteDialCode) return;
    _dialCompletionTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || !widget.enabled || !_hasCompleteDialCode) return;
      final currentValue = _digitsOnly(widget.controller.text);
      if (currentValue.length == _digitCount && currentValue == _lastValue) {
        widget.onCompleted?.call(currentValue);
      }
    });
  }

  @override
  void codeUpdated() {
    if (_isDisposed || !mounted) return;
    final detectedCode = _digitsOnly(code ?? '');
    if (detectedCode.length < 5) return;
    final value = detectedCode.substring(0, 5);
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _digitsOnly(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length <= 5 ? digits : digits.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final value = _digitsOnly(widget.controller.text);
    final displayValue = _displayValueFor(value);

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _OdometerDisplay(
                    code: value,
                    displayCode: displayValue,
                    correctOtp: widget.correctOtp,
                    status: widget.status,
                    enabled: widget.enabled,
                    onDigitStep: _handleDigitStep,
                  ),
                );
              },
            ),
          ),
          if (widget.showEntryField) const SizedBox(height: 14),
          if (widget.showEntryField)
            Center(
              child: SizedBox(
                width: 220,
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  autofocus: widget.autoFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  maxLength: 5,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  decoration: const InputDecoration(
                    hintText: 'Enter OTP',
                    counterText: '',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OdometerDisplay extends StatelessWidget {
  const _OdometerDisplay({
    required this.code,
    required this.displayCode,
    required this.correctOtp,
    required this.status,
    required this.enabled,
    required this.onDigitStep,
  });

  final String code;
  final String displayCode;
  final String correctOtp;
  final OdometerOtpStatus? status;
  final bool enabled;
  final void Function(int index, int step) onDigitStep;

  static const double _gap = 25;

  @override
  Widget build(BuildContext context) {
    final value = code.length > 5 ? code.substring(0, 5) : code;
    final displayValue = displayCode.length > 5
        ? displayCode.substring(0, 5)
        : displayCode;
    final padded = displayValue.padRight(5, '0');
    final isComplete = value.length == 5;
    final hasExplicitResult =
        status == OdometerOtpStatus.success ||
        status == OdometerOtpStatus.error;
    final shouldShowStatus =
        isComplete &&
        (hasExplicitResult ||
            status == null ||
            status != OdometerOtpStatus.pending);
    final isCorrect = hasExplicitResult
        ? status == OdometerOtpStatus.success
        : value == correctOtp;

    final children = <Widget>[
      for (var index = 0; index < 2; index++)
        _SwipeableOdometerDigit(
          index: index,
          value: int.tryParse(padded[index]) ?? 0,
          isActive: false,
          enabled: enabled,
          onStep: (step) => onDigitStep(index, step),
        ),
      const _OdometerSeparator(','),
      for (var index = 2; index < 5; index++)
        _SwipeableOdometerDigit(
          index: index,
          value: int.tryParse(padded[index]) ?? 0,
          isActive: index == 4,
          enabled: enabled,
          onStep: (step) => onDigitStep(index, step),
        ),
      shouldShowStatus
          ? _StatusIndicator(isCorrect: isCorrect)
          : const _OdometerSeparator(
              'km',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w700,
              ),
            ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 20),
            blurRadius: 45,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _withGaps(children),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFCFAFAF).withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    stops: const [0, 0.25, 0.75, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> children) {
    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(const SizedBox(width: _gap));
      spaced.add(children[index]);
    }
    return spaced;
  }
}

class _SwipeableOdometerDigit extends StatefulWidget {
  const _SwipeableOdometerDigit({
    required this.index,
    required this.value,
    required this.isActive,
    required this.enabled,
    required this.onStep,
  });

  final int index;
  final int value;
  final bool isActive;
  final bool enabled;
  final ValueChanged<int> onStep;

  @override
  State<_SwipeableOdometerDigit> createState() =>
      _SwipeableOdometerDigitState();
}

class _SwipeableOdometerDigitState extends State<_SwipeableOdometerDigit> {
  static const _stepDistance = 58.0;
  static const _flingVelocity = 760.0;

  double _dragOffset = 0;
  bool _isDragging = false;
  bool _hasSteppedThisDrag = false;

  void _startDrag() {
    _dragOffset = 0;
    _hasSteppedThisDrag = false;
    setState(() => _isDragging = true);
  }

  void _step(int direction) {
    widget.onStep(direction);
    unawaited(HapticFeedback.selectionClick());
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_hasSteppedThisDrag) return;

    _dragOffset += details.delta.dy;
    if (_dragOffset <= -_stepDistance) {
      _step(1);
      _hasSteppedThisDrag = true;
    }
    if (_dragOffset >= _stepDistance) {
      _step(-1);
      _hasSteppedThisDrag = true;
    }
  }

  void _endDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (!_hasSteppedThisDrag &&
        _dragOffset.abs() >= 28 &&
        velocity.abs() >= _flingVelocity) {
      _step(velocity < 0 ? 1 : -1);
    }

    _dragOffset = 0;
    _hasSteppedThisDrag = false;
    if (mounted) setState(() => _isDragging = false);
  }

  void _cancelDrag() {
    _dragOffset = 0;
    _hasSteppedThisDrag = false;
    if (mounted) setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final digit = AnimatedScale(
      scale: _isDragging ? 1.035 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: _OdometerDigit(value: widget.value, isActive: widget.isActive),
    );

    if (!widget.enabled) return digit;

    return Semantics(
      label: 'OTP digit ${widget.index + 1}',
      hint: 'Swipe up or down to adjust',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => _startDrag(),
          onVerticalDragUpdate: _updateDrag,
          onVerticalDragEnd: _endDrag,
          onVerticalDragCancel: _cancelDrag,
          child: digit,
        ),
      ),
    );
  }
}

class _OdometerDigit extends StatelessWidget {
  const _OdometerDigit({required this.value, required this.isActive});

  final int value;
  final bool isActive;

  static const double _width = 78;
  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFBFBFBF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0, 0.32, 0.58, 1],
              )
            : const RadialGradient(
                center: Alignment.topCenter,
                radius: 1,
                colors: [
                  Color(0xFF333333),
                  Color(0xFF111111),
                  Color(0xFF090909),
                ],
                stops: [0, 0.4, 1],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.35),
            blurRadius: isActive ? 16 : 12,
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        curve: Curves.ease,
        tween: Tween<double>(end: -value * _height),
        builder: (context, offset, child) {
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: OverflowBox(
          minWidth: _width,
          maxWidth: _width,
          minHeight: _height * 10,
          maxHeight: _height * 10,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _width,
            height: _height * 10,
            child: Stack(
              children: [
                for (var index = 0; index < 10; index++)
                  Positioned(
                    top: index * _height,
                    left: 0,
                    child: _OdometerNumber(value: index, isActive: isActive),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OdometerNumber extends StatelessWidget {
  const _OdometerNumber({required this.value, required this.isActive});

  final int value;
  final bool isActive;

  static const double _width = 78;
  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontSize: 72,
                height: 1,
                shadows: isActive
                    ? null
                    : [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.22),
                          offset: const Offset(0, 2),
                          blurRadius: 12,
                        ),
                      ],
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OdometerSeparator extends StatelessWidget {
  const _OdometerSeparator(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 72,
        height: 1,
      ).merge(style),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _MatrixStatusPainter(
          type: isCorrect ? _MatrixStatusType.tick : _MatrixStatusType.cross,
        ),
      ),
    );
  }
}

enum _MatrixStatusType { tick, cross }

class _MatrixStatusPainter extends CustomPainter {
  const _MatrixStatusPainter({required this.type});

  final _MatrixStatusType type;

  @override
  void paint(Canvas canvas, Size size) {
    const matrixSize = 24;
    const scale = 0.48;
    const dotSize = 8.0 * scale;
    const gap = 1.0 * scale;
    const padding = 10.0 * scale;
    const cell = dotSize + gap;
    const contentSize = padding * 2 + matrixSize * dotSize + 23 * gap;
    final origin = Offset(
      (size.width - contentSize) / 2,
      (size.height - contentSize) / 2,
    );
    final rect = origin & const Size(contentSize, contentSize);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14 * scale)),
      Paint()..color = const Color(0xFF050505),
    );

    final offPaint = Paint()..color = const Color(0xFF151515);
    final onColor = type == _MatrixStatusType.tick
        ? const Color(0xFF00FF66)
        : const Color(0xFFFF2B2B);
    final glowPaint = Paint()
      ..color = onColor.withValues(alpha: 0.72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25 * scale);
    final onPaint = Paint()..color = onColor;

    for (var y = 0; y < matrixSize; y++) {
      for (var x = 0; x < matrixSize; x++) {
        final center = Offset(
          origin.dx + padding + x * cell + dotSize / 2,
          origin.dy + padding + y * cell + dotSize / 2,
        );
        final isOn = switch (type) {
          _MatrixStatusType.tick => _isTickOn(x, y),
          _MatrixStatusType.cross => _isCrossOn(x, y, matrixSize),
        };

        canvas.drawCircle(center, dotSize / 2, offPaint);
        if (isOn) {
          canvas.drawCircle(center, dotSize / 2, glowPaint);
          canvas.drawCircle(center, dotSize / 2, onPaint);
        }
      }
    }
  }

  bool _isTickOn(int x, int y) {
    final leftArm = x >= 3 && x <= 8 && (y - (x + 11)).abs() <= 2;
    final rightArm = x >= 8 && x <= 22 && (y - (-x + 27)).abs() <= 2;
    return leftArm || rightArm;
  }

  bool _isCrossOn(int x, int y, int size) {
    return (y - x).abs() < 3 || (y - (size - 1 - x)).abs() < 3;
  }

  @override
  bool shouldRepaint(covariant _MatrixStatusPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}

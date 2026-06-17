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
  String _lastValue = '';
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
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.removeListener(_handleControllerChanged);
    unawaited(cancel());
    unawaited(unregisterListener());
    super.dispose();
  }

  void _handleControllerChanged() {
    final value = _digitsOnly(widget.controller.text);
    if (value != _lastValue) {
      _lastValue = value;
      widget.onChanged?.call(value);
      if (value.length == 5) {
        widget.onCompleted?.call(value);
      }
    }
    if (mounted) setState(() {});
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
                    correctOtp: widget.correctOtp,
                    status: widget.status,
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
    required this.correctOtp,
    required this.status,
  });

  final String code;
  final String correctOtp;
  final OdometerOtpStatus? status;

  static const double _gap = 25;

  @override
  Widget build(BuildContext context) {
    final value = code.length > 5 ? code.substring(0, 5) : code;
    final padded = value.padRight(5, '0');
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
        _OdometerDigit(
          value: int.tryParse(padded[index]) ?? 0,
          isActive: false,
        ),
      const _OdometerSeparator(','),
      for (var index = 2; index < 5; index++)
        _OdometerDigit(
          value: int.tryParse(padded[index]) ?? 0,
          isActive: index == 4,
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

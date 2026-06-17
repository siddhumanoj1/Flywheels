import 'dart:async';

import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/odometer_otp_input.dart';
import 'package:flywheels/widgets/speedometer_loader.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '9123456789');
  final _phoneFocusNode = FocusNode();
  bool _otpRequested = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    unawaited(SmsAutoFill().unregisterListener());
    super.dispose();
  }

  String get _otpPhone {
    var digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  bool get _isPhoneValid => _otpPhone.length == 10;
  bool _hasCurrentOtp(AppController controller) {
    return _otpRequested && controller.requestedPhone == _otpPhone;
  }

  Future<void> _requestOtp(AppController controller) async {
    if (controller.isSendingOtp || !_isPhoneValid) return;
    final phone = _otpPhone;
    unawaited(SmsAutoFill().listenForCode(smsCodeRegexPattern: r'\d{5}'));
    unawaited(controller.requestOtp(phone));
    setState(() => _otpRequested = true);
    await _openOtpDialog(controller, phone: phone);
  }

  Future<void> _resendOtp(AppController controller, String phone) async {
    if (controller.isSendingOtp) return;
    unawaited(SmsAutoFill().listenForCode(smsCodeRegexPattern: r'\d{5}'));
    await controller.requestOtp(phone);
    if (!mounted) return;
    setState(() => _otpRequested = true);
  }

  Future<bool> _verifyOtp(AppController controller, String code) async {
    final otp = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (controller.isVerifyingOtp ||
        controller.isLoggingIn ||
        otp.length != 5) {
      return false;
    }
    return controller.verifyOtp(otp);
  }

  Future<void> _openOtpDialog(AppController controller, {String? phone}) async {
    final targetPhone = phone ?? _otpPhone;
    if (targetPhone.length != 10) return;
    if (phone == null && !_hasCurrentOtp(controller)) {
      await _requestOtp(controller);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OtpVerificationDialog(
        controller: controller,
        phone: targetPhone,
        correctOtp: controller.generatedOtp ?? '12345',
        onVerify: (code) => _verifyOtp(controller, code),
        onResend: () => _resendOtp(controller, targetPhone),
        onChangeNumber: () {
          Navigator.of(context).pop();
          setState(() => _otpRequested = false);
          _phoneFocusNode.requestFocus();
        },
      ),
    );
    if (mounted) setState(() {});
  }

  void _handlePhoneChanged(AppController controller) {
    setState(() {
      if (controller.requestedPhone != _otpPhone) {
        _otpRequested = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final hasCurrentOtp = _hasCurrentOtp(controller);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(child: BrandLogo(size: 110)),
                                const SizedBox(height: 18),
                                Text(
                                  'Phone Login',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Verify with OTP and we will open the right dashboard for customer or owner access automatically.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) =>
                                      _handlePhoneChanged(controller),
                                  onSubmitted: (_) => _requestOtp(controller),
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    hintText: 'Enter mobile number',
                                    prefixText: '+91 ',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed:
                                        controller.isSendingOtp ||
                                            !_isPhoneValid
                                        ? null
                                        : hasCurrentOtp
                                        ? () => _openOtpDialog(controller)
                                        : () => _requestOtp(controller),
                                    icon: Icon(
                                      hasCurrentOtp
                                          ? Icons.dialpad_rounded
                                          : Icons.speed_rounded,
                                    ),
                                    label: Text(
                                      hasCurrentOtp ? 'Enter OTP' : 'Send OTP',
                                    ),
                                  ),
                                ),
                                if (controller.generatedOtp != null &&
                                    hasCurrentOtp)
                                  const SizedBox(height: 16),
                                if (controller.generatedOtp != null &&
                                    hasCurrentOtp)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppPalette.soft,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      'Development OTP: ${controller.generatedOtp}\nDemo owner number: 9876543210\nDemo customer number: 9123456789',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpVerificationDialog extends StatefulWidget {
  const _OtpVerificationDialog({
    required this.controller,
    required this.phone,
    required this.correctOtp,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  final AppController controller;
  final String phone;
  final String correctOtp;
  final Future<bool> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onChangeNumber;

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();
  var _status = OdometerOtpStatus.pending;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isLoginAnimating = false;
  String? _errorText;
  String? _submittedCode;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleOtpChanged);
  }

  @override
  void dispose() {
    _otpController.removeListener(_handleOtpChanged);
    _otpController.dispose();
    super.dispose();
  }

  void _handleOtpChanged() {
    final value = _digitsOnly(_otpController.text);
    if (value.length < 5 &&
        (_status != OdometerOtpStatus.pending || _errorText != null)) {
      setState(() {
        _status = OdometerOtpStatus.pending;
        _errorText = null;
        _submittedCode = null;
      });
    }
  }

  Future<void> _handleCompleted(String code) async {
    final otp = _digitsOnly(code);
    if (_isChecking ||
        _isLoginAnimating ||
        widget.controller.isLoggingIn ||
        otp.length != 5 ||
        otp == _submittedCode) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isChecking = true;
      _errorText = null;
      _status = OdometerOtpStatus.pending;
      _submittedCode = otp;
    });

    final success = await widget.onVerify(otp);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isChecking = false;
        _isLoginAnimating = true;
        _status = OdometerOtpStatus.success;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2400));
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isChecking = false;
      _status = OdometerOtpStatus.error;
      _submittedCode = null;
      _errorText =
          widget.controller.errorMessage ?? 'Invalid OTP. Please try again.';
    });
  }

  Future<void> _handleResend() async {
    if (_isResending || _isChecking || _isLoginAnimating) return;
    setState(() {
      _isResending = true;
      _status = OdometerOtpStatus.pending;
      _errorText = null;
      _submittedCode = null;
    });
    _otpController.clear();
    await widget.onResend();
    if (!mounted) return;
    setState(() => _isResending = false);
  }

  void _closeOrCancel() {
    if (_isChecking ||
        _isLoginAnimating ||
        widget.controller.isVerifyingOtp ||
        widget.controller.isLoggingIn) {
      widget.controller.cancelLogin();
    }
    Navigator.of(context).pop();
  }

  String _digitsOnly(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length <= 5 ? digits : digits.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isChecking ||
        _isLoginAnimating ||
        widget.controller.isVerifyingOtp ||
        widget.controller.isLoggingIn;
    final canEdit = !isBusy;
    final mediaQuery = MediaQuery.of(context);
    final maxDialogHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: maxDialogHeight < 360 ? 360 : maxDialogHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'OTP Verification',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: isBusy ? 'Cancel' : 'Close',
                        onPressed: _closeOrCancel,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: canEdit ? widget.onChangeNumber : null,
                behavior: HitTestBehavior.opaque,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 0,
                  runSpacing: 0,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          const TextSpan(text: 'OTP is sent to +91 '),
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(
                              color: AppPalette.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: canEdit
                            ? AppPalette.red
                            : AppPalette.red.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OdometerOtpInput(
                controller: _otpController,
                correctOtp: widget.correctOtp,
                enabled: canEdit,
                autoFocus: true,
                showEntryField: !isBusy,
                status: _status,
                onCompleted: _handleCompleted,
              ),
              if (!isBusy) const SizedBox(height: 8),
              if (!isBusy)
                Center(
                  child: FilledButton.icon(
                    onPressed: canEdit && !_isResending ? _handleResend : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.red,
                      foregroundColor: AppPalette.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 40),
                    ),
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('Resend OTP'),
                  ),
                ),
              if (_isChecking || _isLoginAnimating) const SizedBox(height: 22),
              if (_isChecking || _isLoginAnimating)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpeedometerLogoLoader(size: 190, logoSize: 90),
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Text(
                        _isLoginAnimating ? 'Logging in...' : 'Checking...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              if (_errorText != null) const SizedBox(height: 8),
              if (_errorText != null)
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color.fromRGBO(255, 0, 0, 1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

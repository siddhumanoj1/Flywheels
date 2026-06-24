import 'dart:async';

import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/customer_car_details_fields.dart';
import 'package:flywheels/widgets/odometer_otp_input.dart';
import 'package:flywheels/widgets/speedometer_loader.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sms_autofill/sms_autofill.dart';

enum _AuthMode { welcome, createAccount, phoneLogin }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _picker = ImagePicker();
  final _phoneController = TextEditingController(text: '9123456789');
  final _nameController = TextEditingController();
  final _accountPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carModelController = TextEditingController();
  final _fuelController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  _AuthMode _authMode = _AuthMode.welcome;
  bool _otpRequested = false;
  bool _dataSharingConsent = false;
  bool _accountCarEdited = false;
  String? _accountMessage;
  bool _accountMessageIsError = true;
  String? _phoneLoginNotice;
  String? _accountCarImagePath;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _accountPhoneController.dispose();
    _emailController.dispose();
    _carNumberController.dispose();
    _carModelController.dispose();
    _fuelController.dispose();
    _yearController.dispose();
    _phoneFocusNode.dispose();
    unawaited(SmsAutoFill().unregisterListener());
    super.dispose();
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  String get _otpPhone => _normalizePhone(_phoneController.text);

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
      _phoneLoginNotice = null;
    });
  }

  void _showAccountMessage(String message, {bool isError = true}) {
    setState(() {
      _accountMessage = message;
      _accountMessageIsError = isError;
    });
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool get _hasAnyCarDetails {
    return _carNumberController.text.trim().isNotEmpty ||
        _fuelController.text.trim().isNotEmpty ||
        _accountCarImagePath != null ||
        _accountCarEdited;
  }

  Future<void> _openPhoneLogin({
    required AppController controller,
    String? phone,
    String? notice,
    bool requestOtp = false,
  }) async {
    if (phone != null) {
      _phoneController.text = _normalizePhone(phone);
    }
    setState(() {
      _authMode = _AuthMode.phoneLogin;
      _phoneLoginNotice = notice;
      if (controller.requestedPhone != _otpPhone) {
        _otpRequested = false;
      }
    });
    if (requestOtp) {
      await _requestOtp(controller);
    } else {
      _phoneFocusNode.requestFocus();
    }
  }

  Future<void> _submitCreateAccount(AppController controller) async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final phone = _normalizePhone(_accountPhoneController.text);
    final email = _emailController.text.trim();
    final carNumber = _carNumberController.text.trim();
    final carModel = _carModelController.text.trim();
    final fuelType = _fuelController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    final shouldCreateCar = _hasAnyCarDetails;

    if (name.isEmpty) {
      _showAccountMessage('Name is required.');
      return;
    }
    if (phone.length != 10) {
      _showAccountMessage('Enter a valid 10 digit phone number.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showAccountMessage('Enter a valid email address or leave it blank.');
      return;
    }
    if (!_dataSharingConsent) {
      _showAccountMessage(
        'Please confirm the data sharing option to continue.',
      );
      return;
    }
    if (shouldCreateCar && (carNumber.isEmpty || carModel.isEmpty)) {
      _showAccountMessage(
        'Car number and model are required when adding a car now.',
      );
      return;
    }

    final existingUser = controller.userByPhone(phone);
    if (existingUser != null) {
      await _openPhoneLogin(
        controller: controller,
        phone: phone,
        notice:
            'That phone number already has an account. Verify OTP to continue.',
        requestOtp: true,
      );
      return;
    }

    final user = await controller.createCustomerAccount(
      name: name,
      phone: phone,
      email: email.isEmpty ? null : email,
      dataSharingConsent: _dataSharingConsent,
      carNumber: shouldCreateCar ? carNumber : null,
      model: shouldCreateCar ? carModel : null,
      fuelType: shouldCreateCar ? fuelType : null,
      year: shouldCreateCar ? year : null,
      imagePath: shouldCreateCar ? _accountCarImagePath : null,
    );
    if (user == null) {
      await _openPhoneLogin(
        controller: controller,
        phone: phone,
        notice:
            'This phone number is already registered. Verify OTP to continue.',
        requestOtp: true,
      );
      return;
    }

    await _openPhoneLogin(
      controller: controller,
      phone: user.phone,
      notice: 'Account created. Verify your phone to open customer access.',
      requestOtp: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                MediaQuery.of(context).viewInsets.bottom + 22,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _authMode == _AuthMode.welcome ? 540 : 500,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildAuthPanel(controller),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthPanel(AppController controller) {
    switch (_authMode) {
      case _AuthMode.welcome:
        return _buildWelcomePanel(controller);
      case _AuthMode.createAccount:
        return _buildCreateAccountPanel(controller);
      case _AuthMode.phoneLogin:
        return _buildPhoneLoginPanel(controller);
    }
  }

  Widget _buildWelcomePanel(AppController controller) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('welcome-panel'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1150),
      curve: Curves.linear,
      builder: (context, value, child) {
        final wordmarkProgress = _intervalProgress(
          value,
          0.22,
          0.68,
          Curves.easeOutCubic,
        );
        final copyProgress = _intervalProgress(
          value,
          0.42,
          0.82,
          Curves.easeOutCubic,
        );
        final actionProgress = _intervalProgress(
          value,
          0.58,
          1.0,
          Curves.easeOutCubic,
        );

        return Opacity(
          opacity: 0.96 + (value * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WelcomeOpeningMark(progress: value),
              SizedBox(height: 14 + (8 * (1 - wordmarkProgress))),
              Opacity(
                opacity: wordmarkProgress,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - wordmarkProgress)),
                  child: const BrandWordmark(center: true),
                ),
              ),
              const SizedBox(height: 26),
              Opacity(
                opacity: copyProgress,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - copyProgress)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer account setup and phone-key access for Flywheels Auto.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: actionProgress,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - actionProgress)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _authMode = _AuthMode.createAccount;
                              _accountMessage = null;
                            });
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Create account'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openPhoneLogin(controller: controller),
                          icon: const Icon(Icons.vpn_key_rounded),
                          label: const Text('Phone key'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneLoginPanel(AppController controller) {
    final hasCurrentOtp = _hasCurrentOtp(controller);

    return Card(
      key: const ValueKey('phone-login-panel'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(),
            const SizedBox(height: 8),
            const Center(child: BrandLogo(size: 86)),
            const SizedBox(height: 16),
            Text(
              'Phone key',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Verify with OTP to open customer, owner, or staff access.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_phoneLoginNotice != null) const SizedBox(height: 14),
            if (_phoneLoginNotice != null)
              _noticeBox(_phoneLoginNotice!, isError: false),
            const SizedBox(height: 18),
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _handlePhoneChanged(controller),
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
                onPressed: controller.isSendingOtp || !_isPhoneValid
                    ? null
                    : hasCurrentOtp
                    ? () => _openOtpDialog(controller)
                    : () => _requestOtp(controller),
                icon: Icon(
                  hasCurrentOtp ? Icons.dialpad_rounded : Icons.speed_rounded,
                ),
                label: Text(hasCurrentOtp ? 'Enter OTP' : 'Send OTP'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.border),
              ),
              child: Text(
                'Development OTP: ${controller.generatedOtp ?? '12345'}\n'
                'Demo owner: 9876543210\n'
                'Demo customer: 9123456789\n'
                'Demo master mechanic: 9000011111\n'
                'Demo mechanic: 9000022222\n'
                'Demo mechanic 2: 9000033333',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountPanel(AppController controller) {
    return Card(
      key: const ValueKey('create-account-panel'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(),
            const SizedBox(height: 10),
            Text(
              'Create customer account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Only customer accounts can be created here. Existing phones move to OTP login.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'Required',
                prefixText: '+91 ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 18),
            Text('Car details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            CustomerCarDetailsFields(
              picker: _picker,
              carNumberController: _carNumberController,
              modelController: _carModelController,
              fuelController: _fuelController,
              yearController: _yearController,
              onImagePathChanged: (path) {
                setState(() => _accountCarImagePath = path);
              },
              onEdited: () {
                setState(() {
                  _accountCarEdited = true;
                  _accountMessage = null;
                });
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _dataSharingConsent,
              onChanged: (value) {
                setState(() {
                  _dataSharingConsent = value ?? false;
                  _accountMessage = null;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "I'm OK with sharing my data with Flywheels Auto.",
              ),
            ),
            if (_accountMessage != null) const SizedBox(height: 4),
            if (_accountMessage != null)
              _noticeBox(_accountMessage!, isError: _accountMessageIsError),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _submitCreateAccount(controller),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Create account'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPhoneLogin(controller: controller),
                icon: const Icon(Icons.vpn_key_rounded),
                label: const Text('Use Phone key'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noticeBox(String message, {required bool isError}) {
    final color = isError ? AppPalette.red : AppPalette.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _backButton() {
    return IconButton.outlined(
      tooltip: 'Back',
      onPressed: () {
        setState(() {
          _authMode = _AuthMode.welcome;
          _phoneLoginNotice = null;
          _accountMessage = null;
        });
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

double _intervalProgress(double value, double begin, double end, Curve curve) {
  final normalized = ((value - begin) / (end - begin))
      .clamp(0.0, 1.0)
      .toDouble();
  return curve.transform(normalized);
}

double _lerp(double begin, double end, double progress) {
  return begin + ((end - begin) * progress);
}

class _WelcomeOpeningMark extends StatelessWidget {
  const _WelcomeOpeningMark({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final collapse = _intervalProgress(
      progress,
      0.08,
      0.82,
      Curves.easeInOutCubic,
    );
    final gaugeOpacity =
        1 - _intervalProgress(progress, 0.46, 0.92, Curves.easeOutCubic);
    final logoOpacity = _intervalProgress(
      progress,
      0.58,
      1.0,
      Curves.easeOutCubic,
    );
    final markHeight = _lerp(220, 126, collapse);
    final gaugeSize = _lerp(220, 132, collapse);
    final gaugeLogoSize = _lerp(106, 70, collapse);

    return SizedBox(
      width: 220,
      height: markHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: gaugeOpacity,
            child: SpeedometerLogoLoader(
              size: gaugeSize,
              logoSize: gaugeLogoSize,
            ),
          ),
          Opacity(
            opacity: logoOpacity,
            child: Transform.scale(
              scale: 0.9 + (0.1 * logoOpacity),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppPalette.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const BrandLogo(size: 76),
              ),
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
    final shouldResetStatus =
        (_status != OdometerOtpStatus.pending || _errorText != null) &&
        value != _submittedCode;
    if (value.length < 5 || shouldResetStatus) {
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

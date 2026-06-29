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

const _authLogoSize = SpeedometerLogoLoader.defaultLogoSize * 1.15 * 1.05;
const _authLogoDisplaySize = _authLogoSize * BrandLogo.displayScale;
const _authLogoLift = _authLogoDisplaySize * 0.20;
const _authLogoLayoutHeight = _authLogoDisplaySize - (_authLogoLift * 1.85);
const _formLogoSize = _authLogoSize * 0.90;
const _formLogoDisplaySize = _formLogoSize * BrandLogo.displayScale;
const _formLogoLift = _formLogoDisplaySize * 0.20;
const _formLogoLayoutHeight = _formLogoDisplaySize - (_formLogoLift * 1.85);
const _welcomeContentVisualLift = _authLogoDisplaySize * 0.18;
const _createAccountContentLift = SpeedometerLogoLoader.defaultLogoSize * 0.20;
const _actionButtonHorizontalInset = 5.0;
const _actionButtonWidthFactor = 0.95;
const _actionButtonIconSize = 45.44;
const _authRoundButtonSize = 56.0 * 0.90;
const _authRoundButtonIconSize = 36.0 * 0.90;
const _otpCloseButtonSize = _authRoundButtonSize * 0.80;
const _otpCloseIconSize = _authRoundButtonIconSize * 1.16;
const _otpCloseCornerShift = _otpCloseButtonSize * 0.30;
const _pressedIconGlowIntensity = 1.85;
const _logoContentGap = 21.0;
const _welcomeLogoButtonsGap = _logoContentGap * 2;
const _authFrameHorizontalInset = 10.0;
const _authFrameTopInset = 1.5;
const _authFrameBottomInset = 8.5;
const _authContentTopPadding = 22.0;
const _authContentTopPaddingWithBack = 62.0;

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
  bool _wantsAccountCarDetails = false;
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

  void _showWelcome() {
    setState(() {
      _authMode = _AuthMode.welcome;
      _phoneLoginNotice = null;
      _accountMessage = null;
    });
  }

  void _showCreateAccount() {
    setState(() {
      _authMode = _AuthMode.createAccount;
      _accountMessage = null;
      _phoneLoginNotice = null;
    });
  }

  void _handleSwipeBack(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_authMode != _AuthMode.welcome && velocity > 400) {
      _showWelcome();
    }
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
    final shouldCreateCar = _wantsAccountCarDetails;

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
    const pureRed = Color.fromARGB(255, 255, 0, 0);

    return PopScope(
      canPop: _authMode == _AuthMode.welcome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _authMode != _AuthMode.welcome) {
          _showWelcome();
        }
      },
      child: Scaffold(
        backgroundColor: pureRed,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _authFrameHorizontalInset,
              _authFrameTopInset,
              _authFrameHorizontalInset,
              _authFrameBottomInset,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: _handleSwipeBack,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: pureRed, width: 5),
                  borderRadius: BorderRadius.circular(45),
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            22,
                            _authMode == _AuthMode.welcome
                                ? _authContentTopPadding
                                : _authContentTopPaddingWithBack,
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
                                  maxWidth: _authMode == _AuthMode.welcome
                                      ? 760
                                      : 500,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 360),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final offset = Tween<Offset>(
                                      begin: const Offset(0, 0.04),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    final scale = Tween<double>(
                                      begin: 0.985,
                                      end: 1,
                                    ).animate(animation);

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offset,
                                        child: ScaleTransition(
                                          scale: scale,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildAuthPanel(controller),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_authMode != _AuthMode.welcome)
                      Positioned(left: 12, top: 12, child: _backButton()),
                  ],
                ),
              ),
            ),
          ),
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
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        media.padding.vertical -
        _authFrameTopInset -
        _authFrameBottomInset -
        44;
    final panelHeight = availableHeight < 440.0 ? 440.0 : availableHeight;

    return TweenAnimationBuilder<double>(
      key: const ValueKey('welcome-panel'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1150),
      curve: Curves.linear,
      builder: (context, value, child) {
        final actionProgress = _intervalProgress(
          value,
          0.50,
          1.0,
          Curves.easeOutCubic,
        );

        return Opacity(
          opacity: 0.96 + (value * 0.04),
          child: SizedBox(
            height: panelHeight,
            child: Transform.translate(
              offset: const Offset(0, -_welcomeContentVisualLift),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _WelcomeOpeningMark(progress: value),
                  const SizedBox(height: _welcomeLogoButtonsGap),
                  Opacity(
                    opacity: actionProgress,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - actionProgress)),
                      child: _buildWelcomeActions(controller),
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

  Widget _buildWelcomeActions(AppController controller) {
    final createAccount = _WelcomeActionButton(
      label: 'Create account',
      iconType: _WelcomeIconType.profile,
      onPressed: _showCreateAccount,
    );
    final phoneKey = _WelcomeActionButton(
      label: 'Phone key',
      iconType: _WelcomeIconType.key,
      onPressed: () => _openPhoneLogin(controller: controller),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 460) {
            return Row(
              children: [
                Expanded(child: createAccount),
                const SizedBox(width: _logoContentGap),
                Expanded(child: phoneKey),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              createAccount,
              const SizedBox(height: _logoContentGap),
              phoneKey,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhoneLoginPanel(AppController controller) {
    final hasCurrentOtp = _hasCurrentOtp(controller);

    return KeyedSubtree(
      key: const ValueKey('phone-login-panel'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AuthLogo(),
            const SizedBox(height: _logoContentGap),
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
            _WelcomeActionButton(
              label: hasCurrentOtp ? 'Enter OTP' : 'Send OTP',
              iconType: _WelcomeIconType.key,
              onPressed: controller.isSendingOtp || !_isPhoneValid
                  ? null
                  : hasCurrentOtp
                  ? () => _openOtpDialog(controller)
                  : () => _requestOtp(controller),
            ),
            const SizedBox(height: _logoContentGap),
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
    return KeyedSubtree(
      key: const ValueKey('create-account-panel'),
      child: Transform.translate(
        offset: const Offset(0, -_createAccountContentLift),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuthLogo(),
              const SizedBox(height: _logoContentGap),
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
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _wantsAccountCarDetails,
                onChanged: (value) {
                  setState(() {
                    _wantsAccountCarDetails = value ?? false;
                    _accountMessage = null;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Add car details now'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _wantsAccountCarDetails
                    ? Container(
                        key: const ValueKey('account-car-details'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.soft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppPalette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Car details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
                                  _accountMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-car-details')),
              ),
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
              _WelcomeActionButton(
                label: 'Create account',
                iconType: _WelcomeIconType.profile,
                onPressed: () => _submitCreateAccount(controller),
              ),
              const SizedBox(height: 10),
              _WelcomeActionButton(
                label: 'Use Phone key',
                iconType: _WelcomeIconType.key,
                onPressed: () => _openPhoneLogin(controller: controller),
              ),
            ],
          ),
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
    return _AuthBackButton(onPressed: _showWelcome);
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
    final markHeight = _lerp(
      SpeedometerLogoLoader.defaultSize,
      _authLogoLayoutHeight,
      collapse,
    );
    final gaugeSize = _lerp(
      SpeedometerLogoLoader.defaultSize,
      SpeedometerLogoLoader.defaultSize * 0.6,
      collapse,
    );
    final gaugeLogoSize = _lerp(
      SpeedometerLogoLoader.defaultLogoSize,
      SpeedometerLogoLoader.defaultLogoSize * 0.66,
      collapse,
    );
    final logoTop = _lerp(
      (markHeight - _authLogoDisplaySize) / 2,
      -_authLogoLift,
      collapse,
    );

    return SizedBox(
      width: SpeedometerLogoLoader.defaultSize,
      height: markHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: gaugeOpacity,
            child: SpeedometerLogoLoader(
              size: gaugeSize,
              logoSize: gaugeLogoSize,
            ),
          ),
          Positioned(
            top: logoTop,
            child: Opacity(
              opacity: logoOpacity,
              child: Transform.scale(
                scale: 0.9 + (0.1 * logoOpacity),
                child: const BrandLogo(size: _authLogoSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _formLogoLayoutHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -_formLogoLift,
            child: BrandLogo(size: _formLogoSize),
          ),
        ],
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _AuthRoundIconButton(
      tooltip: 'Back',
      onPressed: onPressed,
      iconType: _WelcomeIconType.leftArrow,
      iconColor: const Color(0xFF31D158),
    );
  }
}

class _AuthRoundIconButton extends StatefulWidget {
  const _AuthRoundIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.iconType,
    required this.iconColor,
    this.size = _authRoundButtonSize,
    this.iconSize = _authRoundButtonIconSize,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final _WelcomeIconType iconType;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  State<_AuthRoundIconButton> createState() => _AuthRoundIconButtonState();
}

class _AuthRoundIconButtonState extends State<_AuthRoundIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final iconGlow = _isPressed ? _pressedIconGlowIntensity : 1.0;
    final borderRadius = BorderRadius.circular(widget.size / 2);

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: const Color.fromARGB(255, 38, 36, 36),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: AppPalette.black),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (isPressed) {
            setState(() => _isPressed = isPressed);
          },
          child: Ink(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.46, 1],
                colors: [
                  Color(0xFF2B2D2E),
                  Color(0xFF242626),
                  Color(0xFF202222),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.black.withValues(alpha: 0.28),
                  offset: const Offset(0, 10),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Center(
              child: _WelcomeMatrixIcon(
                type: widget.iconType,
                color: widget.iconColor,
                size: widget.iconSize,
                glowIntensity: iconGlow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeActionButton extends StatefulWidget {
  const _WelcomeActionButton({
    required this.label,
    required this.iconType,
    required this.onPressed,
  });

  final String label;
  final _WelcomeIconType iconType;
  final VoidCallback? onPressed;

  @override
  State<_WelcomeActionButton> createState() => _WelcomeActionButtonState();
}

class _WelcomeActionButtonState extends State<_WelcomeActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final iconGlow = _isPressed && isEnabled ? _pressedIconGlowIntensity : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth * _actionButtonWidthFactor
            : null;

        return Align(
          alignment: Alignment.center,
          child: Opacity(
            opacity: isEnabled ? 1 : 0.52,
            child: SizedBox(
              width: buttonWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _actionButtonHorizontalInset,
                ),
                child: Material(
                  color: const Color.fromARGB(255, 38, 36, 36),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppPalette.black),
                  ),
                  child: InkWell(
                    onTap: widget.onPressed,
                    onHighlightChanged: isEnabled
                        ? (isPressed) {
                            setState(() => _isPressed = isPressed);
                          }
                        : null,
                    child: Ink(
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.46, 1],
                          colors: [
                            Color(0xFF2B2D2E),
                            Color(0xFF242626),
                            Color(0xFF202222),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: 0.28),
                            offset: const Offset(0, 16),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 1,
                            child: ColoredBox(
                              color: AppPalette.white.withValues(alpha: 0.06),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 1,
                            child: ColoredBox(
                              color: AppPalette.black.withValues(alpha: 0.64),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox.square(
                                    dimension: _actionButtonIconSize,
                                    child: _WelcomeMatrixIcon(
                                      type: widget.iconType,
                                      color: AppPalette.red,
                                      size: _actionButtonIconSize,
                                      glowIntensity: iconGlow,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.label,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppPalette.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _WelcomeMatrixIcon(
                                    type: _WelcomeIconType.rightArrow,
                                    color: Color(0xFF31D158),
                                    size: _actionButtonIconSize,
                                    glowIntensity: iconGlow,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _WelcomeIconType { profile, key, leftArrow, rightArrow, close }

class _WelcomeMatrixIcon extends StatelessWidget {
  const _WelcomeMatrixIcon({
    required this.type,
    required this.color,
    this.size = 24,
    this.glowIntensity = 1.0,
  });

  final _WelcomeIconType type;
  final Color color;
  final double size;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WelcomeMatrixIconPainter(
        type: type,
        color: color,
        glowIntensity: glowIntensity,
      ),
    );
  }
}

class _WelcomeMatrixIconPainter extends CustomPainter {
  const _WelcomeMatrixIconPainter({
    required this.type,
    required this.color,
    required this.glowIntensity,
  });

  static const _matrixSize = 24;
  static const _dotRatio = 0.9;
  static const _litIconScale = 0.9;
  static const _baseGlowBlur = 25.0;

  final _WelcomeIconType type;
  final Color color;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = glowIntensity.clamp(1.0, 2.2).toDouble();
    final cellWidth = size.width / _matrixSize;
    final cellHeight = size.height / _matrixSize;
    final dotSize =
        (cellWidth < cellHeight ? cellWidth : cellHeight) * _dotRatio;
    final dotScale = dotSize / 8;
    final boostedColor =
        Color.lerp(color, AppPalette.white, (glow - 1) * 0.22) ?? color;
    final activePaint = Paint()
      ..color = boostedColor
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = boostedColor.withValues(
        alpha: (0.72 + ((glow - 1) * 0.20)).clamp(0.0, 1.0).toDouble(),
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _baseGlowBlur * dotScale * _litIconScale * glow,
      );

    final iconWidth = size.width * _litIconScale;
    final iconHeight = size.height * _litIconScale;
    final iconLeft = (size.width - iconWidth) / 2;
    final iconTop = (size.height - iconHeight) / 2;
    final iconCellWidth = iconWidth / _matrixSize;
    final iconCellHeight = iconHeight / _matrixSize;
    final iconDotSize =
        (iconCellWidth < iconCellHeight ? iconCellWidth : iconCellHeight) *
        _dotRatio;
    final iconRadius = iconDotSize / 2;

    for (var y = 0; y < _matrixSize; y++) {
      for (var x = 0; x < _matrixSize; x++) {
        if (!_isOn(x, y)) {
          continue;
        }

        final center = Offset(
          iconLeft + (x + 0.5) * iconCellWidth,
          iconTop + (y + 0.5) * iconCellHeight,
        );
        canvas.drawCircle(center, iconRadius, glowPaint);
        canvas.drawCircle(center, iconRadius, activePaint);
      }
    }
  }

  bool _isOn(int x, int y) {
    return switch (type) {
      _WelcomeIconType.profile => _profilePixel(x, y),
      _WelcomeIconType.key => _keyPixel(x, y),
      _WelcomeIconType.leftArrow => _rowPixel(_leftArrowRows[y], x),
      _WelcomeIconType.rightArrow => _rowPixel(_rightArrowRows[y], x),
      _WelcomeIconType.close => _closePixel(x, y),
    };
  }

  bool _profilePixel(int x, int y) {
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
  }

  bool _keyPixel(int x, int y) {
    final dx = x - 6;
    final dy = y - 11;
    final bowOuter = (dx * dx) + (dy * dy) <= 17;
    final bowHole = (dx * dx) + (dy * dy) <= 5;
    final bow = bowOuter && !bowHole;
    final shaft = x >= 10 && x <= 21 && y >= 9 && y <= 11;
    final toothOne = x >= 16 && x <= 17 && y >= 12 && y <= 14;
    final toothTwo = x >= 20 && x <= 21 && y >= 12 && y <= 16;

    return bow || shaft || toothOne || toothTwo;
  }

  bool _closePixel(int x, int y) {
    final inBounds = x >= 6 && x <= 17 && y >= 6 && y <= 17;
    final fallingStroke = (x - y).abs() <= 1;
    final risingStroke = (x + y - 23).abs() <= 1;

    return inBounds && (fallingStroke || risingStroke);
  }

  bool _rowPixel(List<(int, int)>? ranges, int x) {
    if (ranges == null) {
      return false;
    }

    return ranges.any((range) => x >= range.$1 && x <= range.$2);
  }

  static const Map<int, List<(int, int)>> _leftArrowRows = {
    4: [(9, 9)],
    5: [(8, 9)],
    6: [(7, 9)],
    7: [(6, 9)],
    8: [(5, 9)],
    9: [(4, 21)],
    10: [(3, 21)],
    11: [(2, 21)],
    12: [(1, 21)],
    13: [(2, 21)],
    14: [(3, 21)],
    15: [(4, 21)],
    16: [(5, 9)],
    17: [(6, 9)],
    18: [(7, 9)],
    19: [(8, 9)],
    20: [(9, 9)],
  };

  static const Map<int, List<(int, int)>> _rightArrowRows = {
    4: [(14, 14)],
    5: [(14, 15)],
    6: [(14, 16)],
    7: [(14, 17)],
    8: [(14, 18)],
    9: [(2, 19)],
    10: [(2, 20)],
    11: [(2, 21)],
    12: [(2, 22)],
    13: [(2, 21)],
    14: [(2, 20)],
    15: [(2, 19)],
    16: [(14, 18)],
    17: [(14, 17)],
    18: [(14, 16)],
    19: [(14, 15)],
    20: [(14, 14)],
  };

  @override
  bool shouldRepaint(covariant _WelcomeMatrixIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
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
                height: _authRoundButtonSize + 4,
                child: Stack(
                  clipBehavior: Clip.none,
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
                      child: Transform.translate(
                        offset: const Offset(
                          _otpCloseCornerShift,
                          -_otpCloseCornerShift,
                        ),
                        child: _AuthRoundIconButton(
                          tooltip: isBusy ? 'Cancel' : 'Close',
                          onPressed: _closeOrCancel,
                          iconType: _WelcomeIconType.close,
                          iconColor: AppPalette.red,
                          size: _otpCloseButtonSize,
                          iconSize: _otpCloseIconSize,
                        ),
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

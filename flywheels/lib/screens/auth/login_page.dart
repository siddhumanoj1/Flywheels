import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flywheels/widgets/speedometer_loader.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '9123456789');
  final _otpController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
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
  bool get _isOtpValid => _otpController.text.trim().length == 6;

  Future<void> _requestOtp(AppController controller) async {
    if (controller.isSendingOtp || !_isPhoneValid) return;
    await controller.requestOtp(_otpPhone);
    if (!mounted) return;
    setState(() => _otpRequested = true);
  }

  Future<void> _verifyOtp(AppController controller) async {
    if (controller.isVerifyingOtp || !_isOtpValid) return;
    final success = await controller.verifyOtp(_otpController.text.trim());
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(controller.errorMessage ?? 'Verification failed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final isBusy = controller.isSendingOtp || controller.isVerifyingOtp;

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
                                const Center(child: BrandLogo(size: 100)),
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
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _requestOtp(controller),
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    hintText: 'Enter mobile number',
                                    prefixText: '+91 ',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_otpRequested)
                                  TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) => _verifyOtp(controller),
                                    decoration: const InputDecoration(
                                      labelText: 'OTP',
                                      hintText: 'Enter 6-digit code',
                                    ),
                                  ),
                                if (_otpRequested) const SizedBox(height: 16),
                                if (_otpRequested)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed:
                                          controller.isVerifyingOtp ||
                                              !_isOtpValid
                                          ? null
                                          : () => _verifyOtp(controller),
                                      icon: const Icon(Icons.verified_rounded),
                                      label: Text(
                                        controller.isVerifyingOtp
                                            ? 'Verifying...'
                                            : 'Verify OTP',
                                      ),
                                    ),
                                  ),
                                if (_otpRequested) const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: _otpRequested
                                      ? OutlinedButton.icon(
                                          onPressed:
                                              controller.isSendingOtp ||
                                                  !_isPhoneValid
                                              ? null
                                              : () => _requestOtp(controller),
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                          label: Text(
                                            controller.isSendingOtp
                                                ? 'Sending...'
                                                : 'Resend OTP',
                                          ),
                                        )
                                      : FilledButton.icon(
                                          onPressed:
                                              controller.isSendingOtp ||
                                                  !_isPhoneValid
                                              ? null
                                              : () => _requestOtp(controller),
                                          icon: const Icon(Icons.speed_rounded),
                                          label: Text(
                                            controller.isSendingOtp
                                                ? 'Sending...'
                                                : 'Send OTP',
                                          ),
                                        ),
                                ),
                                if (controller.generatedOtp != null)
                                  const SizedBox(height: 16),
                                if (controller.generatedOtp != null)
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
          if (isBusy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppPalette.white.withValues(alpha: 0.9),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpeedometerLogoLoader(size: 190, logoSize: 82),
                      const SizedBox(height: 12),
                      Text(
                        controller.isVerifyingOtp
                            ? 'Verifying number...'
                            : 'Sending OTP...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

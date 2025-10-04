import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpTEController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OTP Code Verification',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter the 6 digit code sent to your email',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 20),
                PinCodeTextField(
                  length: 6,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.grey.shade200,
                    selectedFillColor: Colors.green.shade50,
                    inactiveColor: Colors.grey,
                    selectedColor: Colors.green,
                    activeColor: Colors.green,
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  controller: _otpTEController,
                  appContext: context,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter OTP code";
                    } else if (value.length < 6) {
                      return "Enter 6 digit code";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _onTapVerifyButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Verify'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // TODO: Firebase resend logic
                  },
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapVerifyButton() {
    if (_formKey.currentState!.validate()) {
      // এখানে Firebase OTP verify করলে ভালো হবে
      Navigator.pushNamed(context, '/setNewPassword');
    }
  }

  @override
  void dispose() {
    _otpTEController.dispose();
    super.dispose();
  }
}

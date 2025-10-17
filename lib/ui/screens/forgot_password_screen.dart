import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailTEController = TextEditingController();
  bool _isLoding = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text('Note: Check email in your spam box!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 100),
                Text('Forgot Password',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailTEController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: _isLoding == false,
                  replacement: const CircularProgressIndicator(),
                  child: ElevatedButton(
                    onPressed: _onTapSubmitButton,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapSubmitButton() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoding = true;
        });
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailTEController.text.trim());
        Future.delayed(const Duration(seconds: 1)
            ).then((value) => Navigator.pop(context));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent successfully! Please check your email.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoding = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailTEController.dispose();
    super.dispose();
  }
}

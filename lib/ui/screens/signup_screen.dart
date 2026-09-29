import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailTEController = TextEditingController();
  final _passwordTEController = TextEditingController();
  final _confirmPasswordTEController = TextEditingController();
  final _firstNameTEController = TextEditingController();
  final _lastNameTEController = TextEditingController();
  final _phoneNumberTEController = TextEditingController();
  final _addressTEController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/images/logo-removebg-preview.png',
                  width: 200,
                  height: 200,
                ),
                Text('Sign Up', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),

                // First Name
                TextFormField(
                  controller: _firstNameTEController,
                  decoration: const InputDecoration(
                    hintText: 'First Name',
                    labelText: 'First Name',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter first name' : null,
                ),
                const SizedBox(height: 10),

                // Last Name
                TextFormField(
                  controller: _lastNameTEController,
                  decoration: const InputDecoration(
                    hintText: 'Last Name',
                    labelText: 'Last Name',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter last name' : null,
                ),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailTEController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Phone
                TextFormField(
                  controller: _phoneNumberTEController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    labelText: 'Phone Number',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Enter phone number';
                    if (value.length < 10) {
                      return 'Enter valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Address
                TextFormField(
                  controller: _addressTEController,
                  decoration: const InputDecoration(
                    hintText: 'Address',
                    labelText: 'Address',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Enter address';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Password
                TextFormField(
                  controller: _passwordTEController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    suffixIconColor: Colors.green,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Enter password';
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordTEController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    suffixIconColor: Colors.green,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Confirm your password';
                    if (value != _passwordTEController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Signup Button
                Visibility(
                  visible: _isLoading == false,
                  replacement: const CircularProgressIndicator(),
                  child: ElevatedButton(
                    onPressed: _onTapSignUpButton,
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 20),

                // Already have account
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _onTapLoginText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTapSignUpButton() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailTEController.text.trim(),
              password: _passwordTEController.text.trim(),
            );

        final uid = userCredential.user!.uid;
        final fullName =
            '${_firstNameTEController.text.trim()} ${_lastNameTEController.text.trim()}'
                .trim();

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'first_name': _firstNameTEController.text.trim(),
          'last_name': _lastNameTEController.text.trim(),
          'name': fullName,
          'email': _emailTEController.text.trim(),
          'phone': _phoneNumberTEController.text.trim(),
          'address': _addressTEController.text.trim(),
          'location': _addressTEController.text.trim(),
          'position': 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign Up Successful (User)'),
            backgroundColor: Colors.green,
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Sign Up Failed'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onTapLoginText() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailTEController.dispose();
    _passwordTEController.dispose();
    _confirmPasswordTEController.dispose();
    _firstNameTEController.dispose();
    _lastNameTEController.dispose();
    _phoneNumberTEController.dispose();
    _addressTEController.dispose();
    super.dispose();
  }
}

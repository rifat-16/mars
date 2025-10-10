import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_controller.dart';
import '../../auth/role_controller.dart';
import '../../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailTEController = TextEditingController();
  final _passwordTEController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/images/logo-removebg-preview.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 10),
                  Text('Login', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  // Email Field
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
                  const SizedBox(height: 10),

                  // Password Field
                  TextFormField(
                    controller: _passwordTEController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Visibility(
                    visible: _isLoading == false,
                    child: ElevatedButton(
                      onPressed: _onTapLoginButton,
                      child: const Text('Login'),
                    ),
                    replacement: const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _onForgotPasswordTextButton,
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 10),

                  RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _onTapSingUpText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onForgotPasswordTextButton() {
    Navigator.pushNamed(context, '/forgotPassword');
  }

  void _onTapSingUpText() {
    Navigator.pushNamed(context, '/signup');
  }

  Future<void> _onTapLoginButton() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailTEController.text.trim(),
          password: _passwordTEController.text.trim(),
        );

        final user = userCredential.user;
        final token = await user?.getIdToken();

        if (user != null && token != null) {
          DocumentSnapshot? userDoc;

          // 🔹 Try to fetch from 'users' first
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          // 🔹 If not found in 'users', try 'employees'
          if (!userDoc.exists) {
            userDoc = await FirebaseFirestore.instance
                .collection('employees')
                .doc(user.uid)
                .get();
          }

          if (!userDoc.exists) {
            throw Exception('User data not found in Firestore');
          }

          final userData = userDoc.data() as Map<String, dynamic>;

          // 🔹 Create UserModel
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            first_name: userData['first_name'] ?? userData['name'] ?? '',
            last_name: userData['last_name'] ?? '',
            phone: userData['phone'] ?? '',
            position: userData['position'] ?? '',
            address: userData['address'] ?? userData['location'] ?? '',
          );

          // 🔹 Save locally
          await AuthController.saveUserData(userModel, token);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('first_name', userData['first_name'] ?? userData['name'] ?? '');
          await prefs.setString('last_name', userData['last_name'] ?? '');
          await prefs.setString('address', userData['address'] ?? userData['location'] ?? '');
          await prefs.setString('phone', userData['phone'] ?? '');
          await prefs.setString('position', userData['position'] ?? '');
          await prefs.setString('uid', user.uid);
          await prefs.setString('email', user.email ?? '');



          // 🔹 Navigate home
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 1),
                content: Text('Login Successful'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailTEController.dispose();
    _passwordTEController.dispose();
    super.dispose();
  }
}

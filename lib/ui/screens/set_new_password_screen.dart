import 'package:flutter/material.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordTEController = TextEditingController();
  final _confirmPasswordTEController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
                  'Set New Password',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                // Password Field
                TextFormField(
                  controller: _passwordTEController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    suffixIconColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordTEController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    suffixIconColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_passwordTEController.text !=
                        _confirmPasswordTEController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Passwords do not match!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password set successfully ✅"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

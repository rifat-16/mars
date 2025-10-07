import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_controller.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login
  Future<void> login(BuildContext context, String email, String password) async {
    try {
      UserCredential cred =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = cred.user;

      if (user != null) {
        String? token;
        try {
          token = await user.getIdToken();
        } catch (e) {
          rethrow;
        }

        if (token != null && token.isNotEmpty) {
          await AuthController.saveUserData(
            UserModel(uid: user.uid, email: user.email ?? ''),
            token,
          );

          // Navigate to HomeScreen using named route
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    await AuthController.logout();
    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }
}

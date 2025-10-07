import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthController {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static String? accessToken;
  static UserModel? user;

  // Save user and token
  static Future<void> saveUserData(UserModel u, String token) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, token);
    await sp.setString(_userKey, jsonEncode(u.toJson()));
    accessToken = token;
    user = u;
  }

  // Logout
  static Future<void> logout() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_userKey);
    accessToken = null;
    user = null;
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    accessToken = sp.getString(_tokenKey);
    return accessToken != null && accessToken!.isNotEmpty;
  }
}


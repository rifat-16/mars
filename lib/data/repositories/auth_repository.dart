import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/firestore_keys.dart';
import '../../core/constants/prefs_keys.dart';
import '../../models/domain/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefsKeys.token);
    final userJson = prefs.getString(PrefsKeys.userJson);

    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      return null;
    }

    try {
      return AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Failed to authenticate user.');
    }

    final token = await firebaseUser.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Failed to get auth token.');
    }

    final user = await _loadUserProfile(
      firebaseUser.uid,
      firebaseUser.email ?? email,
    );
    await _persistUser(token: token, user: user);
    return user;
  }

  Future<AppUser> _loadUserProfile(String uid, String fallbackEmail) async {
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (userDoc.exists && userDoc.data() != null) {
      return AppUser.fromMap(uid, userDoc.data()!);
    }

    final employeeDoc = await _firestore
        .collection(FirestoreCollections.employees)
        .doc(uid)
        .get();
    if (employeeDoc.exists && employeeDoc.data() != null) {
      return AppUser.fromMap(uid, employeeDoc.data()!);
    }

    return AppUser(
      uid: uid,
      email: fallbackEmail,
      firstName: '',
      lastName: '',
      phone: '',
      position: '',
      address: '',
    );
  }

  Future<void> _persistUser({
    required String token,
    required AppUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.token, token);
    await prefs.setString(PrefsKeys.userJson, jsonEncode(user.toJson()));
    await prefs.setString(PrefsKeys.uid, user.uid);
    await prefs.setString(PrefsKeys.email, user.email);
    await prefs.setString(PrefsKeys.firstName, user.firstName);
    await prefs.setString(PrefsKeys.lastName, user.lastName);
    await prefs.setString(PrefsKeys.phone, user.phone);
    await prefs.setString(PrefsKeys.position, user.position);
    await prefs.setString(PrefsKeys.address, user.address);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefsKeys.token);
    await prefs.remove(PrefsKeys.userJson);
    await prefs.remove(PrefsKeys.uid);
    await prefs.remove(PrefsKeys.email);
    await prefs.remove(PrefsKeys.firstName);
    await prefs.remove(PrefsKeys.lastName);
    await prefs.remove(PrefsKeys.phone);
    await prefs.remove(PrefsKeys.position);
    await prefs.remove(PrefsKeys.address);
  }
}

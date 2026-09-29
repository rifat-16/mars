import 'package:flutter/foundation.dart';

import '../core/state/async_state.dart';
import '../data/repositories/auth_repository.dart';
import '../models/domain/app_user.dart';

class SessionProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  SessionProvider(this._authRepository);

  AsyncState<AppUser?> _state = const AsyncState.idle();
  AppUser? _currentUser;

  AsyncState<AppUser?> get state => _state;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String get role => _currentUser?.position ?? '';
  String get phone => _currentUser?.phone ?? '';

  Future<void> restoreSession() async {
    _state = const AsyncState.loading();
    notifyListeners();

    try {
      _currentUser = await _authRepository.restoreSession();
      _state = AsyncState.success(_currentUser);
    } catch (e) {
      _currentUser = null;
      _state = AsyncState.error('Failed to restore session: $e');
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _state = const AsyncState.loading();
    notifyListeners();

    try {
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _state = AsyncState.success(_currentUser);
      notifyListeners();
      return true;
    } catch (e) {
      _currentUser = null;
      _state = AsyncState.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _state = const AsyncState.loading();
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _state = const AsyncState.success(null);
    } catch (e) {
      _state = AsyncState.error('Failed to logout: $e');
    }

    notifyListeners();
  }
}

import "package:flutter/foundation.dart";

import "../services/auth_service.dart";

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _isInitialized = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  AuthProvider() {
    _isInitialized = true;
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signIn(email: email, password: password);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signUp(email: email, password: password);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

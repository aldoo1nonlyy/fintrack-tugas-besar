import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentEmail => _authService.currentEmail;
  String? get currentUid => _authService.currentUid;

  AuthProvider() {
    // Pantau perubahan status login secara real-time
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Login dengan email atau username dan password Firebase Auth
  Future<bool> login({required String identifier, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(identifier: identifier, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.translateError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Daftar akun baru dengan nama, username, email dan password Firebase Auth
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(name: name, username: username, email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.translateError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Kirim email reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.translateError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout dari Firebase
  Future<void> logout() async {
    await _authService.signOut();
    // _user akan diupdate otomatis via authStateChanges stream
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

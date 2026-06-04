import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream status login pengguna
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Pengguna yang sedang login (null jika belum login)
  User? get currentUser => _auth.currentUser;

  /// UID pengguna yang sedang login
  String? get currentUid => _auth.currentUser?.uid;

  /// Email pengguna yang sedang login
  String? get currentEmail => _auth.currentUser?.email;

  /// Login dengan email dan password
  /// Mengembalikan [UserCredential] jika sukses, melempar [FirebaseAuthException] jika gagal
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Daftar akun baru dengan email dan password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Logout dari akun Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Kirim email reset password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Terjemahkan kode error Firebase Auth ke pesan bahasa Indonesia
  static String translateError(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException code: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Gunakan email lain atau login.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      default:
        return 'Terjadi kesalahan: ${e.message ?? e.code}';
    }
  }
}

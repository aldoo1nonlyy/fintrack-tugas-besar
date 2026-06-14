import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Nama pengguna yang sedang login
  String? get currentDisplayName => _auth.currentUser?.displayName;

  /// Login dengan email atau username dan password
  /// Mengembalikan [UserCredential] jika sukses, melempar [FirebaseAuthException] jika gagal
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
  }) async {
    String email = identifier.trim();
    if (!email.contains('@')) {
      // It's a username, try to fetch email from Firestore
      try {
        final doc = await FirebaseFirestore.instance.collection('usernames').doc(identifier.trim().toLowerCase()).get();
        if (doc.exists && doc.data() != null) {
          email = doc.data()!['email'];
        } else {
          // Fallback to old fake email method
          email = '${identifier.trim().toLowerCase()}@fintrack.app';
        }
      } catch (e) {
        // Fallback on error (e.g. permission denied)
        email = '${identifier.trim().toLowerCase()}@fintrack.app';
      }
    }

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );
  }

  /// Daftar akun baru dengan nama, username, email dan password
  Future<UserCredential> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    // Check if username already exists
    try {
      final doc = await FirebaseFirestore.instance.collection('usernames').doc(username.trim().toLowerCase()).get();
      if (doc.exists) {
        throw FirebaseAuthException(code: 'username-already-in-use', message: 'Username sudah terpakai.');
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      // Ignore permission errors during read, we will catch it during write if it fails
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    await userCredential.user?.updateDisplayName(name.trim());
    await userCredential.user?.reload();
    
    // Save mapping to Firestore
    try {
      await FirebaseFirestore.instance.collection('usernames').doc(username.trim().toLowerCase()).set({
        'email': email.trim(),
        'uid': userCredential.user?.uid,
      });
    } catch (e) {
      debugPrint('Error saving username mapping: $e');
    }
    
    return userCredential;
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
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-email':
        return 'Format email atau username tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Gunakan email lain atau login.';
      case 'username-already-in-use':
        return 'Username ini sudah terdaftar. Gunakan username lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-credential':
        return 'Email, username, atau password tidak valid.';
      default:
        return 'Terjadi kesalahan: ${e.message ?? e.code}';
    }
  }
}

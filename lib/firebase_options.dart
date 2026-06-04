import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- Web ---
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAsNSHuCwqIPWBZkt-tWr2R61N3DD7DMuU',
    appId: '1:874790336572:web:3e85e68cf7e91fa8b36b39',
    messagingSenderId: '874790336572',
    projectId: 'fintrack-invoice',
    authDomain: 'fintrack-invoice.firebaseapp.com',
    storageBucket: 'fintrack-invoice.firebasestorage.app',
    measurementId: 'G-MRZ74HDSZ0',
  );

  // --- Android ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsNSHuCwqIPWBZkt-tWr2R61N3DD7DMuU',
    appId: '1:874790336572:android:GANTI_DENGAN_APP_ID_ANDROID',
    messagingSenderId: '874790336572',
    projectId: 'fintrack-invoice',
    storageBucket: 'fintrack-invoice.firebasestorage.app',
  );

  // --- iOS ---
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAsNSHuCwqIPWBZkt-tWr2R61N3DD7DMuU',
    appId: '1:874790336572:ios:GANTI_DENGAN_APP_ID_IOS',
    messagingSenderId: '874790336572',
    projectId: 'fintrack-invoice',
    storageBucket: 'fintrack-invoice.firebasestorage.app',
    iosBundleId: 'com.example.catatanInvoiceBonFrontend',
  );

  // --- macOS ---
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAsNSHuCwqIPWBZkt-tWr2R61N3DD7DMuU',
    appId: '1:874790336572:ios:GANTI_DENGAN_APP_ID_IOS',
    messagingSenderId: '874790336572',
    projectId: 'fintrack-invoice',
    storageBucket: 'fintrack-invoice.firebasestorage.app',
    iosBundleId: 'com.example.catatanInvoiceBonFrontend',
  );

  // --- Windows (sama dengan Web) ---
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAsNSHuCwqIPWBZkt-tWr2R61N3DD7DMuU',
    appId: '1:874790336572:web:3e85e68cf7e91fa8b36b39',
    messagingSenderId: '874790336572',
    projectId: 'fintrack-invoice',
    authDomain: 'fintrack-invoice.firebaseapp.com',
    storageBucket: 'fintrack-invoice.firebasestorage.app',
    measurementId: 'G-MRZ74HDSZ0',
  );
}

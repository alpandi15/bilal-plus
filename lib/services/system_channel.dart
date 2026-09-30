import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Kanal ke `MainActivity.kt` ("bilalplus/system"): versi aplikasi, buka
/// tautan di browser, dan halaman info aplikasi di Pengaturan Android.
abstract final class SystemChannel {
  static const _channel = MethodChannel('bilalplus/system');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Versi terpasang ("1.9.1"), null bila tidak tersedia (mis. saat uji).
  static Future<String?> appVersion() async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<String>('appVersion');
    } on Exception {
      return null;
    }
  }

  /// Buka [url] di browser / aplikasi yang sesuai. false bila gagal.
  static Future<bool> openUrl(String url) async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('openUrl', url) ?? false;
    } on Exception {
      return false;
    }
  }

  /// Lepas tampilan di atas layar kunci (sesudah halaman adzan ditutup).
  static Future<void> clearLockScreen() async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<bool>('clearLockScreen');
    } on Exception {
      // abaikan
    }
  }

  /// Android 14+: boleh menampilkan notifikasi layar penuh?
  static Future<bool> canFullScreen() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('canFullScreen') ?? true;
    } on Exception {
      return true;
    }
  }

  /// Halaman izin "Notifikasi layar penuh" (Android 14+).
  static Future<void> openFullScreenSettings() async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<bool>('openFullScreenSettings');
    } on Exception {
      // abaikan
    }
  }

  /// Deklinasi magnetik (derajat, timur positif) di lokasi - selisih utara
  /// kompas dengan utara sejati. 0 bila tidak tersedia.
  static Future<double> declination(double lat, double lon) async {
    if (!_android) return 0;
    try {
      return await _channel.invokeMethod<double>('declination', {
            'lat': lat,
            'lon': lon,
          }) ??
          0;
    } on Exception {
      return 0;
    }
  }

  /// Halaman info aplikasi (izin, "Pintasan layar utama" di MIUI, dll.).
  static Future<bool> openAppSettings() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on Exception {
      return false;
    }
  }
}

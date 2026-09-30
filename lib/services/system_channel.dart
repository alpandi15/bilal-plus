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

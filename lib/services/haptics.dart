import 'package:flutter/services.dart';

/// Pola getar penghitung dzikir & tasbih.
enum HapticKind {
  /// Satu ketukan hitung - pendek & tajam.
  tap,

  /// Hitungan satu dzikir/target tercapai - dua denyut kuat.
  target,

  /// Semua dzikir satu sesi selesai - pola panjang.
  complete,

  /// Atur ulang / nyalakan getar.
  toggle,
}

/// Getar lewat Vibrator Android langsung (kanal `bilalplus/haptics` di
/// MainActivity.kt): `HapticFeedback` bawaan ikut setelan "getaran sentuh"
/// sistem dan tidak terasa di banyak ponsel. Di luar Android (atau bila
/// kanal belum ada, mis. uji) kembali ke `HapticFeedback`.
class Haptics {
  static const _channel = MethodChannel('bilalplus/haptics');

  static Future<void> play(HapticKind kind) async {
    try {
      final ok = await _channel.invokeMethod<bool>('vibrate', kind.name);
      if (ok == true) return;
    } on MissingPluginException {
      // bukan Android / uji
    } catch (_) {}
    await switch (kind) {
      HapticKind.tap => HapticFeedback.lightImpact(),
      HapticKind.target => HapticFeedback.heavyImpact(),
      HapticKind.complete => HapticFeedback.heavyImpact(),
      HapticKind.toggle => HapticFeedback.mediumImpact(),
    };
  }
}

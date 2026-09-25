import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_key.dart';
import 'ramadan_calendar.dart';

/// Awal Ramadan yang berubah sejak terakhir dilihat pengguna.
class RamadanShift {
  const RamadanShift({
    required this.hijriYear,
    required this.from,
    required this.to,
  });
  final int hijriYear;
  final String from;
  final String to;
}

/// Mengingat hal-hal kecil antar-sesi di perangkat: tanggal 1 Ramadan yang
/// terakhir dilihat (untuk memberi tahu bila bergeser) dan kartu isbat yang
/// sudah ditutup.
class RamadanNotices {
  RamadanNotices(this._prefs);
  final SharedPreferences _prefs;

  static Future<RamadanNotices> load() async =>
      RamadanNotices(await SharedPreferences.getInstance());

  static String _seenKey(int hy) => 'ramadan_seen_start_$hy';
  static String _isbatKey(int hy, int month) => 'isbat_dismissed_${hy}_$month';

  /// Pergeseran awal [ramadan] sejak terakhir dilihat, atau null. Kali
  /// pertama melihat sebuah tahun hanya mencatat tanggalnya.
  RamadanShift? shiftOf(RamadanDate ramadan) {
    final now = dateKey(ramadan.start);
    final seen = _prefs.getString(_seenKey(ramadan.hijriYear));
    if (seen == null) {
      _prefs.setString(_seenKey(ramadan.hijriYear), now);
      return null;
    }
    if (seen == now) return null;
    return RamadanShift(hijriYear: ramadan.hijriYear, from: seen, to: now);
  }

  Future<void> acknowledgeShift(RamadanShift shift) =>
      _prefs.setString(_seenKey(shift.hijriYear), shift.to);

  bool isbatDismissed(int hy, int month) =>
      _prefs.getBool(_isbatKey(hy, month)) ?? false;

  Future<void> dismissIsbat(int hy, int month) =>
      _prefs.setBool(_isbatKey(hy, month), true);
}

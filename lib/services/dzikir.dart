import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/dzikir_data.dart';
import '../models/prayer_models.dart';
import 'prayer_calculator.dart' as calc;

/// Kapan sebuah dzikir dibaca.
enum DzikirTime { both, pagi, petang }

/// Sesi baca.
enum DzikirSession {
  pagi('Dzikir Pagi', 'dzikir_pagi'),
  petang('Dzikir Petang', 'dzikir_petang');

  const DzikirSession(this.title, this.itemKey);
  final String title;

  /// Kunci item checklist yang tercentang saat sesi selesai.
  final String itemKey;
}

class Dzikir {
  const Dzikir({
    required this.id,
    required this.title,
    required this.repeat,
    required this.time,
    required this.arabic,
    required this.latin,
    required this.arti,
    required this.source,
    this.arabicPetang,
    this.latinPetang,
    this.artiPetang,
    this.note,
  });

  /// Nomor di Hisnul Muslim.
  final int id;
  final String title;
  final int repeat;
  final DzikirTime time;
  final String arabic, latin, arti, source;
  final String? arabicPetang, latinPetang, artiPetang, note;

  bool readIn(DzikirSession s) =>
      time == DzikirTime.both ||
      (s == DzikirSession.pagi
          ? time == DzikirTime.pagi
          : time == DzikirTime.petang);

  String arabicFor(DzikirSession s) =>
      s == DzikirSession.petang ? arabicPetang ?? arabic : arabic;
  String latinFor(DzikirSession s) =>
      s == DzikirSession.petang ? latinPetang ?? latin : latin;
  String artiFor(DzikirSession s) =>
      s == DzikirSession.petang ? artiPetang ?? arti : arti;
}

List<Dzikir> dzikirFor(DzikirSession s) => [
  for (final d in dzikirList)
    if (d.readIn(s)) d,
];

/// Sesi yang disarankan saat [now]: pagi sejak Subuh sampai sebelum Ashar,
/// petang sejak Ashar (dan malam hari).
DzikirSession suggestedSession(
  DateTime now, {
  required double latitude,
  required double longitude,
}) {
  final t = calc.calculatePrayerTimes(latitude: latitude, longitude: longitude);
  final fajr = t.times[PrayerKey.fajr]!;
  final asr = t.times[PrayerKey.asr]!;
  return !now.isBefore(fajr) && now.isBefore(asr)
      ? DzikirSession.pagi
      : DzikirSession.petang;
}

/// Hitungan tiap dzikir untuk satu sesi di satu tanggal - disimpan di
/// perangkat supaya bisa dilanjutkan setelah aplikasi ditutup.
class DzikirProgressStore {
  static String _key(DzikirSession s, String date) =>
      'dzikir_progress_${s.name}_$date';

  static Future<Map<int, int>> load(DzikirSession s, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(s, date));
      if (raw == null) return {};
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          int.parse(e.key as String): e.value as int,
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(
    DzikirSession s,
    String date,
    Map<int, int> counts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(s, date),
        jsonEncode({for (final e in counts.entries) '${e.key}': e.value}),
      );
    } catch (_) {}
  }
}

/// Sesi untuk kunci item checklist ('dzikir_pagi' / 'dzikir_petang').
DzikirSession? dzikirSession(String itemKey) => switch (itemKey) {
  'dzikir_pagi' => DzikirSession.pagi,
  'dzikir_petang' => DzikirSession.petang,
  _ => null,
};

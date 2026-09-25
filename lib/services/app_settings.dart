import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sholat_guide.dart';
import 'sholat_time.dart';

/// Pengaturan tracker yang disimpan di perangkat. Kuncinya juga dibaca
/// callback widget di isolate latar (lihat `tracker_widget_sync.dart`),
/// jadi jangan diganti sembarangan.
class AppSettings {
  static const sholatTimeKey = 'sholat_time_tracking';
  static const onTimeMinutesKey = 'sholat_on_time_minutes';
  static const lastPlaceKey = 'sholat_last_place';
  static const genderKey = 'user_gender';
  static const adzanKey = 'adzan_enabled';
  static const adzanPrayersKey = 'adzan_prayers';
  static const adzanReminderKey = 'adzan_reminder_minutes';
  static const hapticKey = 'tasbih_haptic';
  static const showLatinKey = 'dzikir_show_latin';
  static const showArtiKey = 'dzikir_show_arti';
  static const madzhabKey = 'sholat_madzhab';
}

/// Jenis kelamin pengguna - menentukan narasi ajakan (laki-laki: sholat
/// berjamaah di masjid, termasuk Sholat Jumat).
enum Gender { male, female }

/// Sholat wajib yang bisa diberi notifikasi adzan.
const adzanPrayerKeys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

class AppSettingsController extends ChangeNotifier {
  bool _sholatTime = true;
  int _onTimeMinutes = defaultOnTimeMinutes;
  String _lastPlace = 'rumah';
  Gender? _gender;
  bool _adzan = false;
  Set<String> _adzanPrayers = adzanPrayerKeys.toSet();
  int _reminderMinutes = 0;
  bool _haptic = true;
  bool _showLatin = true;
  bool _showArti = true;
  Madzhab _madzhab = Madzhab.syafii;

  /// Madzhab untuk versi bacaan sholat bawaan.
  Madzhab get madzhab => _madzhab;

  /// Getar setiap ketukan di penghitung dzikir/tasbih.
  bool get haptic => _haptic;

  /// Tampilkan latin & terjemahan di bacaan dzikir.
  bool get showLatin => _showLatin;
  bool get showArti => _showArti;

  /// null = belum dipilih (narasi umum).
  Gender? get gender => _gender;

  /// Notifikasi adzan aktif.
  bool get adzan => _adzan;

  /// Sholat yang diberi notifikasi.
  Set<String> get adzanPrayers => _adzanPrayers;

  /// Pengingat sekian menit sebelum adzan (siapkan wudhu / berangkat ke
  /// masjid), 0 = mati.
  int get reminderMinutes => _reminderMinutes;

  /// Catat jam & tempat sholat wajib (dan hitung awal waktu/terlambat/qadha).
  bool get sholatTime => _sholatTime;

  /// Batas "awal waktu", menit sesudah adzan.
  int get onTimeMinutes => _onTimeMinutes;

  /// Tempat yang terakhir dipilih - jadi pilihan bawaan berikutnya (juga
  /// untuk centang dari widget).
  String get lastPlace => _lastPlace;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sholatTime = prefs.getBool(AppSettings.sholatTimeKey) ?? true;
      _onTimeMinutes =
          prefs.getInt(AppSettings.onTimeMinutesKey) ?? defaultOnTimeMinutes;
      _lastPlace = prefs.getString(AppSettings.lastPlaceKey) ?? 'rumah';
      _gender = switch (prefs.getString(AppSettings.genderKey)) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => null,
      };
      _adzan = prefs.getBool(AppSettings.adzanKey) ?? false;
      _adzanPrayers =
          prefs.getStringList(AppSettings.adzanPrayersKey)?.toSet() ??
          adzanPrayerKeys.toSet();
      _reminderMinutes = prefs.getInt(AppSettings.adzanReminderKey) ?? 0;
      _haptic = prefs.getBool(AppSettings.hapticKey) ?? true;
      _showLatin = prefs.getBool(AppSettings.showLatinKey) ?? true;
      _showArti = prefs.getBool(AppSettings.showArtiKey) ?? true;
      _madzhab = Madzhab.parse(prefs.getString(AppSettings.madzhabKey));
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('pengaturan gagal dibaca: $e');
    }
  }

  bool _loaded = false;

  /// Sudah dibaca dari penyimpanan (sebelum itu nilainya bawaan).
  bool get loaded => _loaded;

  Future<void> setGender(Gender v) async {
    _gender = v;
    notifyListeners();
    await _save((p) => p.setString(AppSettings.genderKey, v.name));
  }

  Future<void> setAdzan(bool v) async {
    _adzan = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.adzanKey, v));
  }

  Future<void> toggleAdzanPrayer(String key) async {
    _adzanPrayers = {..._adzanPrayers};
    if (!_adzanPrayers.remove(key)) _adzanPrayers.add(key);
    notifyListeners();
    await _save(
      (p) => p.setStringList(AppSettings.adzanPrayersKey, [
        for (final k in adzanPrayerKeys)
          if (_adzanPrayers.contains(k)) k,
      ]),
    );
  }

  Future<void> setReminderMinutes(int v) async {
    _reminderMinutes = v;
    notifyListeners();
    await _save((p) => p.setInt(AppSettings.adzanReminderKey, v));
  }

  Future<void> setHaptic(bool v) async {
    _haptic = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.hapticKey, v));
  }

  Future<void> setShowLatin(bool v) async {
    _showLatin = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.showLatinKey, v));
  }

  Future<void> setShowArti(bool v) async {
    _showArti = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.showArtiKey, v));
  }

  Future<void> setMadzhab(Madzhab v) async {
    _madzhab = v;
    notifyListeners();
    await _save((p) => p.setString(AppSettings.madzhabKey, v.name));
  }

  Future<void> setSholatTime(bool v) async {
    _sholatTime = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.sholatTimeKey, v));
  }

  Future<void> setOnTimeMinutes(int v) async {
    _onTimeMinutes = v;
    notifyListeners();
    await _save((p) => p.setInt(AppSettings.onTimeMinutesKey, v));
  }

  Future<void> setLastPlace(String v) async {
    if (v == _lastPlace) return;
    _lastPlace = v;
    notifyListeners();
    await _save((p) => p.setString(AppSettings.lastPlaceKey, v));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('pengaturan gagal disimpan: $e');
    }
  }
}

/// Membagikan [AppSettingsController] - pola yang sama dengan
/// `UserLocationScope`.
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(
      scope != null,
      'AppSettingsScope tidak ditemukan di atas widget ini',
    );
    return scope!.notifier!;
  }

  /// Seperti [of], tapi null bila tidak ada (mis. dalam uji halaman).
  static AppSettingsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;
}

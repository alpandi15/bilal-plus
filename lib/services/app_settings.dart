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
  static const fastReminderKey = 'fast_reminder';
  static const hapticKey = 'tasbih_haptic';
  static const showLatinKey = 'dzikir_show_latin';
  static const showArtiKey = 'dzikir_show_arti';
  static const madzhabKey = 'sholat_madzhab';
  static const readerSizeKey = 'reader_arabic_size';
  static const soloWeightKey = 'sholat_solo_weight';
  static const lastJamaahKey = 'sholat_last_jamaah';
  static const onboardedKey = 'onboarded';
  static const userNameKey = 'user_name';
  static const quranTajweedKey = 'quran_tajweed';
  static const quranLastReadKey = 'quran_last_read';
  static const quranModeKey = 'quran_mode';
  static const quranLastPageKey = 'quran_last_page';
}

/// Batas ukuran teks Arab di pembaca bilal.
const readerSizeMin = 22.0, readerSizeMax = 40.0, readerSizeDefault = 28.0;

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
  bool _fastReminder = true;
  bool _haptic = true;
  bool _showLatin = true;
  bool _showArti = true;
  Madzhab _madzhab = Madzhab.syafii;

  /// Madzhab untuk versi bacaan sholat bawaan.
  Madzhab get madzhab => _madzhab;

  double _readerSize = readerSizeDefault;
  double _soloWeight = hadithSoloWeight;
  bool _lastJamaah = false;

  /// Nilai sholat wajib sendiri dibanding berjama'ah (bawaan 1/27).
  double get soloWeight => _soloWeight;

  /// Nilai yang benar-benar dipakai menghitung: perempuan tidak dikurangi
  /// (sholat di rumah lebih utama baginya).
  double get effectiveSoloWeight => _gender == Gender.female ? 1 : _soloWeight;

  /// Pilihan jama'ah terakhir - bawaan centang berikutnya (juga dari widget
  /// & notifikasi).
  bool get lastJamaah => _lastJamaah;

  /// Ukuran teks Arab di pembaca bilal tarawih.
  double get readerSize => _readerSize;

  /// Getar setiap ketukan di penghitung dzikir/tasbih.
  bool get haptic => _haptic;

  /// Tampilkan latin & terjemahan di bacaan dzikir.
  bool get showLatin => _showLatin;
  bool get showArti => _showArti;

  /// null = belum dipilih (narasi umum).
  Gender? get gender => _gender;

  bool _quranTajweed = true;
  int? _quranLastRead;

  /// Warna hukum tajwid di pembaca Al-Qur'an.
  bool get quranTajweed => _quranTajweed;

  /// Ayat global terakhir yang dibuka di pembaca (untuk "Lanjutkan").
  int? get quranLastRead => _quranLastRead;

  bool _quranMushaf = false;
  int? _quranLastPage;

  /// Mode baca terakhir: true = Mushaf (per halaman), false = per surah.
  bool get quranMushaf => _quranMushaf;

  /// Halaman mushaf terakhir dibuka (1..604).
  int? get quranLastPage => _quranLastPage;

  bool _onboarded = false;
  String? _userName;

  /// Halaman setup awal sudah dilewati.
  bool get onboarded => _onboarded;

  /// Nama panggilan (untuk sapaan), null = tidak diisi.
  String? get userName => _userName;

  /// Notifikasi adzan aktif.
  bool get adzan => _adzan;

  /// Sholat yang diberi notifikasi.
  Set<String> get adzanPrayers => _adzanPrayers;

  /// Pengingat sekian menit sebelum adzan (siapkan wudhu / berangkat ke
  /// masjid), 0 = mati.
  int get reminderMinutes => _reminderMinutes;

  /// Notifikasi pukul 20.00 malam sebelum Hari Tarwiyah & Arafah (niat &
  /// sahur). Terpisah dari notifikasi adzan; bawaannya aktif.
  bool get fastReminder => _fastReminder;

  /// Catat jam & tempat sholat wajib (dan hitung awal waktu/terlambat/qadha).
  bool get sholatTime => _sholatTime;

  /// Batas "awal waktu", menit sesudah adzan.
  int get onTimeMinutes => _onTimeMinutes;

  /// Tempat yang terakhir dipilih - jadi pilihan bawaan berikutnya (juga
  /// untuk centang dari widget).
  String get lastPlace => _lastPlace;

  Future<void> init() async {
    try {
      // batas waktu: splash tidak boleh tertahan bila penyimpanan macet
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
      );
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
      _fastReminder = prefs.getBool(AppSettings.fastReminderKey) ?? true;
      _haptic = prefs.getBool(AppSettings.hapticKey) ?? true;
      _showLatin = prefs.getBool(AppSettings.showLatinKey) ?? true;
      _showArti = prefs.getBool(AppSettings.showArtiKey) ?? true;
      _madzhab = Madzhab.parse(prefs.getString(AppSettings.madzhabKey));
      _onboarded = prefs.getBool(AppSettings.onboardedKey) ?? false;
      _quranTajweed = prefs.getBool(AppSettings.quranTajweedKey) ?? true;
      _quranLastRead = prefs.getInt(AppSettings.quranLastReadKey);
      _quranMushaf = prefs.getString(AppSettings.quranModeKey) == 'mushaf';
      _quranLastPage = prefs.getInt(AppSettings.quranLastPageKey);
      _userName = prefs.getString(AppSettings.userNameKey);
      _readerSize =
          prefs.getDouble(AppSettings.readerSizeKey) ?? readerSizeDefault;
      _soloWeight =
          prefs.getDouble(AppSettings.soloWeightKey) ?? hadithSoloWeight;
      _lastJamaah = prefs.getBool(AppSettings.lastJamaahKey) ?? false;
      _loaded = true;
    } catch (e) {
      debugPrint('pengaturan gagal dibaca: $e');
    }
    _ready = true;
    notifyListeners();
  }

  bool _loaded = false;
  bool _ready = false;

  /// Pembacaan selesai - berhasil atau tidak (splash menunggu ini).
  bool get ready => _ready;

  /// Sudah dibaca dari penyimpanan (sebelum itu nilainya bawaan).
  bool get loaded => _loaded;

  Future<void> setQuranTajweed(bool v) async {
    _quranTajweed = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.quranTajweedKey, v));
  }

  Future<void> setQuranLastRead(int index) async {
    if (index == _quranLastRead) return;
    _quranLastRead = index;
    notifyListeners();
    await _save((p) => p.setInt(AppSettings.quranLastReadKey, index));
  }

  Future<void> setQuranMode({required bool mushaf}) async {
    if (mushaf == _quranMushaf) return;
    _quranMushaf = mushaf;
    notifyListeners();
    await _save(
      (p) => p.setString(AppSettings.quranModeKey, mushaf ? 'mushaf' : 'surah'),
    );
  }

  Future<void> setQuranLastPage(int page) async {
    if (page == _quranLastPage) return;
    _quranLastPage = page;
    notifyListeners();
    await _save((p) => p.setInt(AppSettings.quranLastPageKey, page));
  }

  Future<void> setUserName(String? v) async {
    final name = v?.trim();
    _userName = name == null || name.isEmpty ? null : name;
    notifyListeners();
    await _save(
      (p) => _userName == null
          ? p.remove(AppSettings.userNameKey)
          : p.setString(AppSettings.userNameKey, _userName!),
    );
  }

  /// Selesai setup awal: simpan nama & jenis kelamin, jangan tampilkan lagi.
  Future<void> completeOnboarding({String? name, Gender? gender}) async {
    await setUserName(name);
    if (gender != null) await setGender(gender);
    _onboarded = true;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.onboardedKey, true));
  }

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

  Future<void> setFastReminder(bool v) async {
    _fastReminder = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.fastReminderKey, v));
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

  Future<void> setSoloWeight(double v) async {
    _soloWeight = v.clamp(0, 1);
    notifyListeners();
    await _save((p) => p.setDouble(AppSettings.soloWeightKey, _soloWeight));
  }

  Future<void> setLastJamaah(bool v) async {
    if (v == _lastJamaah) return;
    _lastJamaah = v;
    notifyListeners();
    await _save((p) => p.setBool(AppSettings.lastJamaahKey, v));
  }

  Future<void> setReaderSize(double v) async {
    _readerSize = v.clamp(readerSizeMin, readerSizeMax);
    notifyListeners();
    await _save((p) => p.setDouble(AppSettings.readerSizeKey, _readerSize));
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

  /// Tanpa berlangganan perubahan - untuk callback (mis. tombol).
  static AppSettingsController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;
}

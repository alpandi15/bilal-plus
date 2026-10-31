import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'app_settings.dart';
import 'hijri_config.dart';
import '../widgets/arabic_font.dart';
import 'hafalan_widget_payload.dart';
import 'prayer_calculator.dart' as calc;
import 'quran_text.dart';
import 'sholat_time.dart';
import 'tracker_widget_payload.dart';
import 'user_location_controller.dart';

/// Nama kelas `AppWidgetProvider` Android - harus sama persis dengan
/// `IbadahWidgetProvider.kt` & `QuranWidgetProvider.kt`.
const ibadahWidgetName = 'IbadahWidgetProvider';
const quranWidgetName = 'QuranWidgetProvider';

/// Widget Semangat Sholat (`SemangatWidgetProvider.kt`) - memakai data
/// `ibadah_json` yang sama dengan widget Ibadah Harian.
const semangatWidgetName = 'SemangatWidgetProvider';

/// Widget Hafalan (`HafalanWidgetProvider.kt`): ayat berikutnya yang belum
/// hafal.
const hafalanWidgetName = 'HafalanWidgetProvider';
const _hafalanKey = 'hafalan_json';

const _ibadahKey = 'ibadah_json';
const _quranKey = 'quran_json';

bool get _supported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Menjaga widget Ibadah & Al-Qur'an tetap sama dengan isi basis data:
/// setiap kali catatan, jangkar hijriah, atau lokasi berubah (dan tiap
/// tengah malam), data widget disusun ulang & widget dimuat ulang. Dijalankan
/// selama aplikasi terbuka; saat tertutup, widget memakai data dua hari yang
/// terakhir dititipkan dan perubahan dari widget sendiri ditangani
/// [trackerWidgetCallback].
class TrackerWidgetSync {
  TrackerWidgetSync({
    required this.db,
    required this.hijri,
    required this.location,
    required this.settings,
  });

  final AppDatabase db;
  final HijriConfigController hijri;
  final UserLocationController location;
  final AppSettingsController settings;

  StreamSubscription<void>? _sub;
  StreamSubscription<void>? _hafalanSub;
  Timer? _debounce;
  Timer? _hafalanDebounce;
  Timer? _midnight;

  void start() {
    if (!_supported) return;
    _sub =
        watchTables(db, {
          db.ibadahItems,
          db.ibadahLogs,
          db.dayStatuses,
          db.ramadanRecaps,
          db.quranCycles,
          db.quranLogs,
        }).listen(
          (_) => schedule(),
          onError: (Object e) {
            debugPrint('tracker widget: $e');
          },
        );
    // widget Hafalan disinkronkan sendiri - cepat & tidak ikut gagal bila
    // widget lain bermasalah
    _hafalanSub = watchTables(db, {db.hafalanAyahs}).listen(
      (_) => scheduleHafalan(),
      onError: (Object e) {
        debugPrint('hafalan widget: $e');
      },
    );
    hijri.addListener(schedule);
    location.addListener(schedule);
    settings.addListener(schedule);
    settings.addListener(scheduleHafalan);
    _armMidnight();
    _warmQuranText();
  }

  /// Muat teks Al-Qur'an lebih awal bila ada hafalan, supaya sinkron widget
  /// Hafalan sesudah menandai hafal tidak menunggu teks dimuat.
  Future<void> _warmQuranText() async {
    try {
      final any = await (db.select(db.hafalanAyahs)..limit(1)).get();
      if (any.isNotEmpty) await QuranText.load();
    } catch (e) {
      debugPrint('hafalan widget: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _hafalanSub?.cancel();
    _debounce?.cancel();
    _hafalanDebounce?.cancel();
    _midnight?.cancel();
    hijri.removeListener(schedule);
    location.removeListener(schedule);
    settings.removeListener(schedule);
    settings.removeListener(scheduleHafalan);
  }

  /// Sinkron sebentar lagi - beberapa perubahan beruntun cukup sekali.
  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), sync);
  }

  void scheduleHafalan() {
    _hafalanDebounce?.cancel();
    _hafalanDebounce = Timer(const Duration(milliseconds: 150), syncHafalan);
  }

  /// Aplikasi ditinggalkan (layar utama / tutup): jalankan sinkron yang masih
  /// menunggu sekarang juga, supaya tidak hilang bila prosesnya dihentikan.
  void flush() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      sync();
    }
    if (_hafalanDebounce?.isActive ?? false) {
      _hafalanDebounce!.cancel();
      syncHafalan();
    }
  }

  Future<void> syncHafalan() async {
    if (!_supported) return;
    try {
      await _syncHafalan(db, settings.quranFont);
    } catch (e) {
      debugPrint('hafalan widget: $e');
    }
  }

  void _armMidnight() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnight = Timer(next.difference(now), () {
      schedule();
      _armMidnight();
    });
  }

  Future<void> sync() async {
    try {
      final loc = location.location;
      final tz = calc.timezoneFromLongitude(loc.long);
      final today = dateKey(calc.todayInZone(tz));
      final ibadah = await ibadahWidgetPayload(
        db,
        anchors: hijri.config.anchors,
        today: today,
        latitude: loc.lat,
        longitude: loc.long,
        sholatTime: settings.sholatTime,
        onTimeMinutes: settings.onTimeMinutes,
        soloWeight: settings.effectiveSoloWeight,
        lastJamaah: settings.lastJamaah,
        male: settings.gender == Gender.male,
      );
      final quran = await quranWidgetPayload(
        db,
        today: today,
        tzId: tzIds[tz]!,
      );
      await HomeWidget.saveWidgetData<String>(_ibadahKey, jsonEncode(ibadah));
      await HomeWidget.saveWidgetData<String>(_quranKey, jsonEncode(quran));
      await HomeWidget.updateWidget(androidName: ibadahWidgetName);
      await HomeWidget.updateWidget(androidName: semangatWidgetName);
      await HomeWidget.updateWidget(androidName: quranWidgetName);
    } catch (e) {
      // widget belum dipasang / plugin tidak tersedia - bukan kegagalan fatal
      debugPrint('tracker widget: $e');
    }
  }
}

/// Susun ulang data widget Hafalan & muat ulang widgetnya.
Future<void> _syncHafalan(AppDatabase db, QuranFont font) async {
  final payload = await hafalanWidgetPayload(db, QuranText.load, font: font);
  await HomeWidget.saveWidgetData<String>(_hafalanKey, jsonEncode(payload));
  await HomeWidget.updateWidget(androidName: hafalanWidgetName);
}

/// "Hafal" dari widget Hafalan: `rinduramadan://hafalan/set?ayah=N` (nomor
/// ayat global). Widget sudah maju ke ayat berikutnya lebih dulu
/// (optimistis); di sini tanda hafal ditulis & antreannya disusun ulang.
Future<void> _hafalanFromWidget(Uri uri) async {
  final ayah = int.tryParse(uri.queryParameters['ayah'] ?? '');
  if (ayah == null) return;
  final db = AppDatabase();
  try {
    await db.quranDao.setHafal(ayah, ayah, true);
    final prefs = await SharedPreferences.getInstance();
    await _syncHafalan(
      db,
      QuranFont.parse(prefs.getString(AppSettings.quranFontKey)),
    );
  } finally {
    await db.close();
  }
}

/// Dipanggil `home_widget` di isolate latar saat pengguna mencentang dari
/// widget: `rinduramadan://ibadah/set?date=YYYY-MM-DD&item=ID&value=N`, atau
/// menandai hafal dari widget Hafalan.
/// Kotlin sudah menampilkan perubahannya lebih dulu (optimistis); di sini
/// catatan ditulis ke basis data dan data widget diperbarui.
@pragma('vm:entry-point')
Future<void> trackerWidgetCallback(Uri? uri) async {
  if (uri?.host == 'hafalan' && uri?.path == '/set') {
    return _hafalanFromWidget(uri!);
  }
  if (uri == null || uri.host != 'ibadah' || uri.path != '/set') return;
  final date = uri.queryParameters['date'];
  final item = int.tryParse(uri.queryParameters['item'] ?? '');
  final value = int.tryParse(uri.queryParameters['value'] ?? '');
  if (date == null || item == null || value == null) return;

  final db = AppDatabase();
  try {
    // sholat wajib dicentang dari widget/notifikasi: berjama'ah atau sendiri
    // = pilihan terakhir; jam = saat diketuk & tempat = yang terakhir dipilih
    // (bila pencatatan waktu aktif)
    DateTime? prayedAt;
    String? place;
    bool? jamaah;
    var qashar = false;
    var jumat = const Value<bool?>.absent();
    if (value > 0) {
      final prefs = await SharedPreferences.getInstance();
      final tracking = prefs.getBool(AppSettings.sholatTimeKey) ?? true;
      final row = await (db.select(
        db.ibadahItems,
      )..where((i) => i.id.equals(item))).getSingleOrNull();
      if (row?.groupKey == sholatWajibGroup) {
        jamaah = prefs.getBool(AppSettings.lastJamaahKey) ?? false;
        // sedang safar (sholat terakhir dicatat safar): diqashar
        final safar = prefs.getBool(AppSettings.lastSafarKey) ?? false;
        qashar = safar && qasharPrayers.contains(row!.key);
        // Dzuhur di hari Jumat (laki-laki): sholat Jumat, kecuali sedang
        // safar (musafir sholat Dzuhur)
        if (row!.key == 'dzuhur' &&
            prefs.getString(AppSettings.genderKey) == Gender.male.name &&
            parseDateKey(date).weekday == DateTime.friday) {
          jumat = Value(!safar);
          if (!safar) jamaah = true;
        }
        if (tracking) {
          prayedAt = DateTime.now();
          place = prefs.getString(AppSettings.lastPlaceKey) ?? 'rumah';
        }
      }
    }
    await db.ibadahDao.setValue(
      date,
      item,
      value,
      prayedAt: prayedAt,
      place: place,
      jamaah: jamaah,
      qashar: qashar ? const Value(true) : const Value.absent(),
      jumat: jumat,
    );
    final raw = await HomeWidget.getWidgetData<String>(_ibadahKey);
    if (raw != null) {
      final payload = await patchIbadahPayload(
        db,
        (jsonDecode(raw) as Map).cast<String, Object?>(),
        date,
      );
      await HomeWidget.saveWidgetData<String>(_ibadahKey, jsonEncode(payload));
      await HomeWidget.updateWidget(androidName: ibadahWidgetName);
      await HomeWidget.updateWidget(androidName: semangatWidgetName);
    }
  } finally {
    await db.close();
  }
}

/// Daftarkan [trackerWidgetCallback] (sekali saat aplikasi mulai).
Future<void> registerTrackerWidgetCallback() async {
  if (!_supported) return;
  try {
    await HomeWidget.registerInteractivityCallback(trackerWidgetCallback);
  } catch (e) {
    debugPrint('tracker widget: $e');
  }
}

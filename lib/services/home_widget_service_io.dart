import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../models/prayer_models.dart';
import '../widgets/prayer_widget_sky_frame.dart';
import '../widgets/sky/seasonal_ornaments.dart';
import 'hijri_calendar.dart';
import 'prayer_calculator.dart';
import 'ramadan_calendar.dart';

/// Nama kelas `AppWidgetProvider` Android, harus sama persis dengan
/// `android/app/src/main/kotlin/.../PrayerWidgetProvider.kt` dan
/// `RamadanWidgetProvider.kt`.
const _androidWidgetName = 'PrayerWidgetProvider';
const _androidRamadanWidgetName = 'RamadanWidgetProvider';

/// Berapa hari jadwal yang dititipkan ke widget, supaya ia tetap benar
/// (termasuk "Menuju Subuh" sesudah Isya dan pergantian hari) walau aplikasi
/// tidak dibuka berhari-hari.
const _scheduleDays = 7;

/// Atlas langit: naikkan angka ini bila rupa langit/ukuran frame berubah,
/// supaya frame lama di perangkat pengguna dirender ulang.
const _atlasVersion = '3';

/// Jumlah frame animasi per fase. Kotlin menyilangkan (crossfade) frame-frame
/// ini lewat `ViewFlipper` dengan jeda [_atlasFrameStepMs] - jadi sampel
/// animasinya juga diambil tiap sekian ms supaya gerak awan & kelip bintang
/// terasa menyambung.
const atlasFrames = 6;
const _atlasFrameStepMs = 1400.0;
const _atlasFrameSize = Size(360, 220);
const _atlasPixelRatio = 2.0;

/// Enam varian langit: lima fase hari + malam larut (lampu kota padam).
const _atlasVariants = <(String, DayPhase, bool)>[
  ('dawn', DayPhase.dawn, false),
  ('morning', DayPhase.morning, false),
  ('noon', DayPhase.noon, false),
  ('dusk', DayPhase.dusk, false),
  ('night', DayPhase.night, false),
  ('nightquiet', DayPhase.night, true),
];

const _tzId = {
  TimezoneCode.wib: 'Asia/Jakarta',
  TimezoneCode.wita: 'Asia/Makassar',
  TimezoneCode.wit: 'Asia/Jayapura',
};

bool _renderingAtlas = false;

/// Versi ornamen musiman (lampion/ketupat/kembang api) - naikkan bila
/// rupanya berubah. Frame-nya hanya dirender bila Ramadan/Idulfitri jatuh
/// dalam [_scheduleDays] hari ke depan, jadi di luar musim tidak ada beban.
const _ornamentVersion = '1';

/// Menuliskan jadwal sholat [_scheduleDays] hari ke depan + lokasi ke
/// penyimpanan yang dibaca widget layar utama Android (`home_widget`), lalu
/// memicu widget itu memuat ulang. Sekali saja (per versi atlas) juga
/// merender frame-frame langit yang dipakai widget sebagai latar animasi.
///
/// Widget layar utama tidak bisa menjalankan Flutter, jadi kartunya disusun
/// ulang secara native di `PrayerWidgetProvider.kt`: latar langit dari atlas
/// PNG ini (disilangkan `ViewFlipper` supaya awan/bintang terasa hidup),
/// busur matahari digambar Canvas native, jam & hitung mundurnya `TextClock`
/// + `Chronometer` yang berdetik sendiri tanpa aplikasi berjalan.
///
/// Dipanggil setiap kali jadwal atau lokasi (kemungkinan) berubah - lihat
/// `PrayerTimesCard` - BUKAN setiap detik.
Future<void> syncPrayerHomeWidget({
  required double latitude,
  required double longitude,
  required String locationName,
  HijriAnchors? hijriAnchors,
}) async {
  final anchors = hijriAnchors ?? HijriAnchors.none;
  try {
    final tz = timezoneFromLongitude(longitude);
    final today = todayInZone(tz);

    final days = <Map<String, Object>>[];
    final seasons = <SkySeason>{};
    for (var i = 0; i < _scheduleDays; i++) {
      final date = today.add(Duration(days: i));
      final s = calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
      );
      days.add({
        'date': _ymd(date),
        for (final key in cardPrayers)
          key.name: s.times[key]!.millisecondsSinceEpoch,
        'labels': {for (final key in cardPrayers) key.name: s.labels[key]!},
        // tanggal hijriah hari ini dan sesudah Maghrib (hari hijriah
        // berganti saat Maghrib - sama dengan kartu di aplikasi)
        'hijri': anchors.fromGregorian(date).format(),
        'hijriAfterMaghrib': anchors
            .fromGregorian(date.add(const Duration(days: 1)))
            .format(),
        // suasana latar (Ramadan/Idulfitri/Iduladha) siang & sesudah
        // Maghrib, dan kembang api malamnya (dini hari & sesudah Maghrib)
        'season': skySeasonOf(anchors.fromGregorian(date)).name,
        'seasonAfterMaghrib': skySeasonOf(
          anchors.fromGregorian(date.add(const Duration(days: 1))),
        ).name,
        'fireworks': skyFireworksOf(anchors.fromGregorian(date)),
        'fireworksAfterMaghrib': skyFireworksOf(
          anchors.fromGregorian(date.add(const Duration(days: 1))),
        ),
      });
      seasons
        ..add(skySeasonOf(anchors.fromGregorian(date)))
        ..add(
          skySeasonOf(anchors.fromGregorian(date.add(const Duration(days: 1)))),
        );
    }

    final payload = jsonEncode({
      'location': locationName,
      'tz': tzLabel[tz],
      'tzId': _tzId[tz],
      'days': days,
    });
    await HomeWidget.saveWidgetData<String>('schedule_json', payload);

    // Widget hitung mundur Ramadan: Ramadan yang baru selesai (bila masih
    // dalam suasana Idulfitri 1-3 Syawal), yang relevan sekarang, dan yang
    // berikutnya - supaya sesudah Idulfitri widget langsung menghitung tahun
    // depan walau aplikasi belum dibuka lagi. `startsAt` = Maghrib malam
    // sebelum tanggal 1 di lokasi ini - saat hari hijriah berganti.
    final ramadans = <Map<String, Object>>[];
    var r = relevantRamadan(
      today.subtract(const Duration(days: eidDays)),
      anchors,
    );
    for (var i = 0; i < 3; i++) {
      final eve = r.start.subtract(const Duration(days: 1));
      final startsAt = calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: DateTime.utc(eve.year, eve.month, eve.day),
      ).times[PrayerKey.maghrib]!;
      ramadans.add({
        'hijriYear': r.hijriYear,
        'start': _ymd(r.start),
        'end': _ymd(r.end),
        'days': r.days,
        'estimated': r.estimated,
        'tentative': r.tentative,
        'overridden': r.overridden,
        'startsAt': startsAt.millisecondsSinceEpoch,
      });
      r = relevantRamadan(r.end, anchors);
    }
    await HomeWidget.saveWidgetData<String>(
      'ramadan_json',
      jsonEncode({'tzId': _tzId[tz], 'items': ramadans}),
    );

    await _ensureSkyAtlas();
    await _ensureOrnaments(seasons..remove(SkySeason.normal));

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
    await HomeWidget.updateWidget(androidName: _androidRamadanWidgetName);
  } catch (_) {
    // widget belum dipasang / platform tidak didukung (mis. saat berjalan
    // di web atau desktop) - abaikan, ini bukan kegagalan yang fatal.
  }
}

/// Merender atlas langit bila belum ada / versinya beda. Render offscreen
/// satu per satu dengan jeda kecil supaya UI tidak tersendat.
Future<void> _ensureSkyAtlas() async {
  if (_renderingAtlas) return;
  final have = await HomeWidget.getWidgetData<String>('sky_atlas_version');
  if (have == _atlasVersion) return;

  _renderingAtlas = true;
  try {
    for (final (name, phase, quiet) in _atlasVariants) {
      for (var f = 0; f < atlasFrames; f++) {
        await HomeWidget.renderFlutterWidget(
          PrayerWidgetSkyFrame(
            phase: phase,
            quiet: quiet,
            // mulai agak jauh dari 0 supaya semua elemen (delay negatif ala
            // CSS) sudah "berjalan" - bukan pose awal yang seragam
            clockMs: 20000 + f * _atlasFrameStepMs,
            size: _atlasFrameSize,
          ),
          key: 'sky_${name}_$f',
          logicalSize: _atlasFrameSize,
          pixelRatio: _atlasPixelRatio,
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
    await HomeWidget.saveWidgetData<String>('sky_atlas_version', _atlasVersion);
  } finally {
    _renderingAtlas = false;
  }
}

/// Merender frame ornamen (latar transparan, kanvas kecil) untuk [seasons]
/// yang belum ada: siang & malam, [atlasFrames] frame per lapisan, kunci
/// `orn_<musim>_<day|night>_<hangers|fireworks>_<frame>` - ditempatkan
/// `PrayerWidgetProvider.kt` di atas frame langit biasa.
Future<void> _ensureOrnaments(Set<SkySeason> seasons) async {
  if (seasons.isEmpty) return;
  final have = await HomeWidget.getWidgetData<String>('orn_version');
  final done = have != null && have.startsWith('$_ornamentVersion:')
      ? have.substring(_ornamentVersion.length + 1).split(',').toSet()
      : <String>{};
  final missing = seasons.where((s) => !done.contains(s.name)).toList();
  if (missing.isEmpty) return;
  for (final season in missing) {
    for (final night in [false, true]) {
      final light = night ? 'night' : 'day';
      final layers = [
        OrnamentLayer.hangers,
        // kembang api: malam Idulfitri & malam takbiran Iduladha - kapan
        // ditampilkan diatur flag `fireworks` per hari di schedule_json
        if (night && (season == SkySeason.eid || season == SkySeason.adha))
          OrnamentLayer.fireworks,
      ];
      for (final layer in layers) {
        for (var f = 0; f < atlasFrames; f++) {
          final frame = PrayerWidgetOrnamentFrame(
            season: season,
            night: night,
            layer: layer,
            clockMs: 20000 + f * _atlasFrameStepMs,
          );
          await HomeWidget.renderFlutterWidget(
            frame,
            key: 'orn_${season.name}_${light}_${layer.name}_$f',
            logicalSize: frame.size,
            pixelRatio: 3,
          );
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
    }
    done.add(season.name);
    await HomeWidget.saveWidgetData<String>(
      'orn_version',
      '$_ornamentVersion:${done.join(',')}',
    );
  }
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

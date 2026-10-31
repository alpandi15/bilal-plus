import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'adzan_messages.dart';
import 'app_settings.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'muhasabah.dart';
import 'prayer_calculator.dart' as calc;
import 'reminder_ids.dart';
import 'sholat_motivation.dart';
import 'sholat_time.dart';
import 'waktu_penting.dart';
import '../models/prayer_models.dart' show PrayerKey;
import 'tracker_widget_payload.dart' show tzIds;
import 'tracker_widget_sync.dart';

/// Berapa hari notifikasi dijadwalkan ke depan. Dijadwalkan ulang setiap
/// aplikasi dibuka / lokasi / pengaturan berubah.
const adzanDays = 14;

const _adzanChannel = AndroidNotificationChannel(
  'adzan',
  'Waktu sholat (adzan)',
  description: 'Pemberitahuan saat waktu sholat wajib masuk',
  importance: Importance.high,
);

const _reminderChannel = AndroidNotificationChannel(
  'adzan_reminder',
  'Pengingat sebelum adzan',
  description: 'Beberapa menit sebelum adzan: siapkan wudhu',
  importance: Importance.defaultImportance,
);

const _fastChannel = AndroidNotificationChannel(
  'fast_reminder',
  'Pengingat puasa & Jumat',
  description:
      'Malam sebelum Tarwiyah & Arafah (niat & sahur) dan Jumat pagi '
      '(Al-Kahfi & sholawat)',
  importance: Importance.defaultImportance,
);

const _muhasabahChannel = AndroidNotificationChannel(
  'muhasabah',
  'Muhasabah & laporan',
  description: 'Ajakan melihat laporan ibadah harian (malam) dan mingguan',
  importance: Importance.defaultImportance,
);

const _ayatChannel = AndroidNotificationChannel(
  'ayat_harian',
  'Ayat harian',
  description: 'Satu ayat Al-Qur\'an setiap hari',
  importance: Importance.defaultImportance,
);

const _waktuChannel = AndroidNotificationChannel(
  'waktu_penting',
  'Waktu penting',
  description: 'Awal sepertiga malam terakhir (waktu tahajud)',
  importance: Importance.defaultImportance,
);

/// Jam pengingat puasa (malam sebelumnya).
const fastReminderHour = 20;

/// Jam pengingat amalan Jumat (pagi).
const fridayReminderHour = 7;

const _doneAction = 'sholat_done';

/// Notifikasi adzan terjadwal (flutter_local_notifications). Ketuk
/// notifikasi = buka tab Ibadah; tombol "Sudah sholat" = catat langsung
/// (jam sekarang, tempat terakhir) lewat jalur yang sama dengan centang dari
/// widget.
class AdzanNotifications {
  AdzanNotifications._();
  static final instance = AdzanNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// [onOpen] dipanggil saat notifikasi diketuk / adzan layar penuh terbuka
  /// (aplikasi dibuka), dengan payload notifikasinya.
  Future<void> init({void Function(String? payload)? onOpen}) async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/widget_ic_crescent'),
      ),
      onDidReceiveNotificationResponse: (r) async {
        if (r.actionId == _doneAction) {
          await _logDone(r.payload);
        } else {
          onOpen?.call(r.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: adzanNotificationBackground,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_adzanChannel);
    await android?.createNotificationChannel(_reminderChannel);
    await android?.createNotificationChannel(_fastChannel);
    await android?.createNotificationChannel(_muhasabahChannel);
    await android?.createNotificationChannel(_ayatChannel);
    await android?.createNotificationChannel(_waktuChannel);
    _ready = true;

    // dibuka dari notifikasi saat aplikasi tertutup
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      onOpen?.call(launch!.notificationResponse?.payload);
    }
  }

  /// Status izin saat ini: notifikasi & alarm tepat waktu (Android 14+
  /// meminta izin terpisah; di versi lama selalu true).
  Future<({bool notifications, bool exactAlarms})> permissionStatus() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return (notifications: false, exactAlarms: false);
    return (
      notifications: await android.areNotificationsEnabled() ?? false,
      exactAlarms: await android.canScheduleExactNotifications() ?? true,
    );
  }

  /// Buka halaman izin "Alarm & pengingat" (Android 14+).
  Future<void> requestExactAlarms() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  /// Minta izin notifikasi (Android 13+) & alarm tepat waktu (Android
  /// 14+). true bila notifikasi diizinkan.
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission() ?? true;
    if (granted && !(await android.canScheduleExactNotifications() ?? true)) {
      await android.requestExactAlarmsPermission();
    }
    return granted;
  }

  /// Ada pengingat yang aktif? (bila tidak, cukup membatalkan semuanya)
  static bool anyActive(AppSettingsController s) =>
      s.adzan ||
      s.fastReminder ||
      s.fridayReminder ||
      s.muhasabah ||
      s.weeklyReport ||
      s.ayatNotif ||
      s.tahajudNotif;

  /// Jadwalkan ulang semua notifikasi [adzanDays] hari ke depan sesuai
  /// pengaturan & lokasi. Setiap jenis punya fungsinya sendiri; yang baru
  /// cukup menambah satu fungsi + satu rentang id di [NotifId].
  ///
  /// [summary] = ringkasan ibadah hari ini untuk teks muhasabah (null =
  /// teks generik); [ayat] = notifikasi ayat harian yang sudah disusun.
  Future<void> reschedule({
    required AppSettingsController settings,
    required double latitude,
    required double longitude,
    required String placeName,
    HijriAnchors? anchors,
    DaySummary? summary,
    List<DayNotice> ayat = const [],
  }) async {
    if (!supported || !_ready) return;
    await _plugin.cancelAll();
    if (!anyActive(settings)) return;

    final zone = calc.timezoneFromLongitude(longitude);
    final location = tz.getLocation(tzIds[zone]!);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = DateTime.now();
    final today = calc.todayInZone(zone);

    if (settings.fastReminder) {
      await _scheduleFastReminders(
        anchors ?? HijriAnchors.none,
        today,
        location,
        now,
        mode,
      );
    }
    if (settings.fridayReminder) {
      await _scheduleFridayReminders(today, location, now, mode);
    }
    if (settings.muhasabah) {
      await _scheduleMuhasabah(
        today,
        location,
        now,
        mode,
        settings.muhasabahMinutes,
        summary,
      );
    }
    if (settings.weeklyReport) {
      await _scheduleWeeklyReport(
        today,
        location,
        now,
        mode,
        settings.weeklyReportMinutes,
      );
    }
    if (settings.ayatNotif) {
      await _scheduleAyat(location, now, mode, settings.ayatMinutes, ayat);
    }
    if (settings.tahajudNotif) {
      await _scheduleTahajud(today, location, now, mode, latitude, longitude);
    }
    if (settings.adzan) {
      await _scheduleAdzan(
        settings,
        latitude,
        longitude,
        placeName,
        zone,
        location,
        now,
        today,
        mode,
      );
    }
  }

  /// Notifikasi adzan & pengingat sebelum adzan.
  Future<void> _scheduleAdzan(
    AppSettingsController settings,
    double latitude,
    double longitude,
    String placeName,
    calc.TimezoneCode zone,
    tz.Location location,
    DateTime now,
    DateTime today,
    AndroidScheduleMode mode,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      final times = calc.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
      );
      for (final (i, key) in adzanPrayerKeys.indexed) {
        if (!settings.adzanPrayers.contains(key)) continue;
        final at = times.times[sholatPrayerKey[key]]!;
        final label =
            '${times.labels[sholatPrayerKey[key]]} ${calc.tzLabel[zone]}';
        // "alarm|" = tampil layar penuh (MainActivity membaca awalan ini)
        final payload =
            '${settings.adzanFullScreen ? adzanAlarmPrefix : ''}'
            '${dateKey(date)}|$key';

        if (at.isAfter(now)) {
          final m = adzanMessage(
            key: key,
            date: date,
            time: label,
            place: placeName,
            gender: settings.gender,
          );
          await _plugin.zonedSchedule(
            id: NotifId.adzan(day, i),
            title: m.title,
            body: m.body,
            scheduledDate: tz.TZDateTime.from(at, location),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _adzanChannel.id,
                _adzanChannel.name,
                channelDescription: _adzanChannel.description,
                importance: Importance.high,
                priority: Priority.high,
                category: settings.adzanFullScreen
                    ? AndroidNotificationCategory.alarm
                    : AndroidNotificationCategory.reminder,
                fullScreenIntent: settings.adzanFullScreen,
                styleInformation: BigTextStyleInformation(m.body),
                color: const Color(0xFFB45309),
                actions: const [
                  AndroidNotificationAction(
                    _doneAction,
                    'Sudah sholat ✓',
                    cancelNotification: true,
                  ),
                ],
              ),
            ),
            androidScheduleMode: mode,
            payload: payload,
          );
        }

        final before = settings.reminderMinutes;
        final remindAt = at.subtract(Duration(minutes: before));
        if (before > 0 && remindAt.isAfter(now)) {
          final m = reminderMessage(
            key: key,
            date: date,
            minutes: before,
            gender: settings.gender,
          );
          await _plugin.zonedSchedule(
            id: NotifId.adzanReminder(day, i),
            title: m.title,
            body: m.body,
            scheduledDate: tz.TZDateTime.from(remindAt, location),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _reminderChannel.id,
                _reminderChannel.name,
                channelDescription: _reminderChannel.description,
                color: const Color(0xFFB45309),
                // teks panjang bisa dibuka penuh (tarik ke bawah / panah)
                styleInformation: BigTextStyleInformation(
                  m.body,
                  contentTitle: m.title,
                ),
                timeoutAfter: before * 60 * 1000,
              ),
            ),
            androidScheduleMode: mode,
          );
        }
      }
    }
  }

  /// Pukul [fastReminderHour] malam sebelum Hari Tarwiyah & Arafah dalam
  /// [adzanDays] hari ke depan.
  Future<void> _scheduleFastReminders(
    HijriAnchors anchors,
    DateTime today,
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      final tomorrow = date.add(const Duration(days: 1));
      final fast = dzulhijjahFastOf(anchors.fromGregorian(tomorrow));
      if (fast == null) continue;
      final at = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        fastReminderHour,
      );
      if (!at.isAfter(now)) continue;
      final arafah = fast == DzulhijjahFast.arafah;
      final body = pickMessage(
        fastEve(arafah: arafah),
        dailySeed(dateKey(date), 9),
      );
      await _plugin.zonedSchedule(
        id: NotifId.fast(day),
        title: 'Besok ${fast.label} 🌙',
        body: body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _fastChannel.id,
            _fastChannel.name,
            channelDescription: _fastChannel.description,
            color: const Color(0xFFB45309),
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        androidScheduleMode: mode,
      );
    }
  }

  /// Pukul [fridayReminderHour] tiap Jumat dalam [adzanDays] hari ke depan:
  /// ajakan membaca Al-Kahfi & memperbanyak sholawat.
  Future<void> _scheduleFridayReminders(
    DateTime today,
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      if (date.weekday != DateTime.friday) continue;
      final at = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        fridayReminderHour,
      );
      if (!at.isAfter(now)) continue;
      final body = pickMessage(fridayDay(), dailySeed(dateKey(date), 5));
      await _plugin.zonedSchedule(
        id: NotifId.friday(day),
        title: 'Hari Jumat · Al-Kahfi & sholawat 🌙',
        body: body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _fastChannel.id,
            _fastChannel.name,
            channelDescription: _fastChannel.description,
            color: const Color(0xFFB45309),
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        androidScheduleMode: mode,
      );
    }
  }

  /// Detail notifikasi senyap berteks panjang (bisa dibuka penuh).
  NotificationDetails _plain(
    AndroidNotificationChannel channel,
    String title,
    String body,
  ) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      color: const Color(0xFFB45309),
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    ),
  );

  tz.TZDateTime _at(tz.Location l, DateTime date, int minutes) => tz.TZDateTime(
    l,
    date.year,
    date.month,
    date.day,
    minutes ~/ 60,
    minutes % 60,
  );

  /// Muhasabah malam tiap hari pada [minutes]: ketuk = laporan harian
  /// tanggal itu. Hanya hari ini yang bisa memuat angka ([summary]); hari
  /// lain bertuliskan generik karena angkanya belum ada.
  Future<void> _scheduleMuhasabah(
    DateTime today,
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
    int minutes,
    DaySummary? summary,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      final at = _at(location, date, minutes);
      if (!at.isAfter(now)) continue;
      final key = dateKey(date);
      final m = muhasabahMessage(summary?.date == key ? summary : null);
      await _plugin.zonedSchedule(
        id: NotifId.muhasabah(date),
        title: m.title,
        body: m.body,
        scheduledDate: at,
        notificationDetails: _plain(_muhasabahChannel, m.title, m.body),
        androidScheduleMode: mode,
        payload: '${NotifPayload.reportDay}$key',
      );
    }
  }

  /// Perbarui HANYA notifikasi muhasabah hari ini (tanpa menyentuh yang
  /// lain) - dipanggil setiap catatan ibadah berubah supaya angkanya benar.
  Future<void> refreshMuhasabah({
    required AppSettingsController settings,
    required double longitude,
    required DaySummary? summary,
  }) async {
    if (!supported || !_ready || !settings.muhasabah) return;
    final zone = calc.timezoneFromLongitude(longitude);
    await _refreshMuhasabahToday(
      _plugin,
      location: tz.getLocation(tzIds[zone]!),
      today: calc.todayInZone(zone),
      minutes: settings.muhasabahMinutes,
      summary: summary,
    );
  }

  /// Laporan mingguan tiap Minggu pada [minutes]: ketuk = laporan pekan itu.
  Future<void> _scheduleWeeklyReport(
    DateTime today,
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
    int minutes,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      if (date.weekday != DateTime.sunday) continue;
      final at = _at(location, date, minutes);
      if (!at.isAfter(now)) continue;
      final m = weeklyReportMessage;
      await _plugin.zonedSchedule(
        id: NotifId.weekly(date),
        title: m.title,
        body: m.body,
        scheduledDate: at,
        notificationDetails: _plain(_muhasabahChannel, m.title, m.body),
        androidScheduleMode: mode,
        payload: '${NotifPayload.reportWeek}${dateKey(date)}',
      );
    }
  }

  /// Ayat harian: isinya tetap per tanggal ([notices] disusun pemanggil dari
  /// teks Al-Qur'an), jadi tidak pernah basi.
  Future<void> _scheduleAyat(
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
    int minutes,
    List<DayNotice> notices,
  ) async {
    for (final n in notices) {
      final at = _at(location, n.date, minutes);
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: NotifId.ayat(n.date),
        title: n.title,
        body: n.body,
        scheduledDate: at,
        notificationDetails: _plain(_ayatChannel, n.title, n.body),
        androidScheduleMode: mode,
        payload: n.payload,
      );
    }
  }

  /// Awal sepertiga malam terakhir (waktu tahajud) tiap malam: malam =
  /// Maghrib hari itu sampai Subuh esok harinya.
  Future<void> _scheduleTahajud(
    DateTime today,
    tz.Location location,
    DateTime now,
    AndroidScheduleMode mode,
    double latitude,
    double longitude,
  ) async {
    for (var day = 0; day < adzanDays; day++) {
      final date = today.add(Duration(days: day));
      final t0 = calc.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
      );
      final t1 = calc.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date.add(const Duration(days: 1)),
      );
      final third = lastThirdOfNight(
        t0.times[PrayerKey.maghrib]!,
        t1.times[PrayerKey.fajr]!,
      );
      if (!third.start.isAfter(now)) continue;
      const title = 'Sepertiga malam terakhir 🌙';
      const body =
          'Waktu yang mustajab untuk berdoa. Tahajud dua rakaat, lalu '
          'perbanyak istighfar sampai Subuh.';
      await _plugin.zonedSchedule(
        id: NotifId.tahajud(date),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(third.start, location),
        notificationDetails: _plain(_waktuChannel, title, body),
        androidScheduleMode: mode,
        payload: NotifPayload.prayerTimes,
      );
    }
  }

  /// "Tunda": adzan layar penuh [payload] muncul lagi [minutes] menit lagi.
  Future<void> snooze(
    String payload, {
    required String title,
    required String body,
    int minutes = 5,
  }) async {
    if (!supported || !_ready) return;
    final at = tz.TZDateTime.now(tz.UTC).add(Duration(minutes: minutes));
    await _plugin.zonedSchedule(
      id: NotifId.snooze,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _adzanChannel.id,
          _adzanChannel.name,
          channelDescription: _adzanChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(body),
          color: const Color(0xFFB45309),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload.startsWith(adzanAlarmPrefix)
          ? payload
          : '$adzanAlarmPrefix$payload',
    );
  }

  /// Izin notifikasi layar penuh (Android 14+ bisa dicabut pengguna).
  Future<void> requestFullScreen() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestFullScreenIntentPermission();
  }

  /// Tampilkan contoh notifikasi sekarang (tombol "Coba" di Pengaturan).
  Future<void> showTest({
    required AppSettingsController settings,
    required String placeName,
  }) async {
    if (!supported || !_ready) return;
    final m = adzanMessage(
      key: 'ashar',
      date: DateTime.now(),
      time: 'contoh',
      place: placeName,
      gender: settings.gender,
    );
    await _plugin.show(
      id: NotifId.test,
      title: m.title,
      body: m.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _adzanChannel.id,
          _adzanChannel.name,
          channelDescription: _adzanChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(m.body),
          color: const Color(0xFFB45309),
        ),
      ),
    );
  }
}

/// Jadwalkan ulang notifikasi muhasabah HARI INI saja (id berbasis tanggal,
/// jadi menimpa yang lama tanpa menggandakan). Dipakai aplikasi & isolate
/// latar.
Future<void> _refreshMuhasabahToday(
  FlutterLocalNotificationsPlugin plugin, {
  required tz.Location location,
  required DateTime today,
  required int minutes,
  required DaySummary? summary,
}) async {
  final at = tz.TZDateTime(
    location,
    today.year,
    today.month,
    today.day,
    minutes ~/ 60,
    minutes % 60,
  );
  final id = NotifId.muhasabah(today);
  if (!at.isAfter(DateTime.now())) {
    await plugin.cancel(id: id);
    return;
  }
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final exact = await android?.canScheduleExactNotifications() ?? false;
  final m = muhasabahMessage(summary);
  await plugin.zonedSchedule(
    id: id,
    title: m.title,
    body: m.body,
    scheduledDate: at,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _muhasabahChannel.id,
        _muhasabahChannel.name,
        channelDescription: _muhasabahChannel.description,
        color: const Color(0xFFB45309),
        styleInformation: BigTextStyleInformation(
          m.body,
          contentTitle: m.title,
        ),
      ),
    ),
    androidScheduleMode: exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    payload: '${NotifPayload.reportDay}${dateKey(today)}',
  );
}

/// Dari isolate latar (centang lewat widget/notifikasi saat aplikasi
/// tertutup): perbarui teks muhasabah hari ini dengan angka terbaru. Zona
/// waktu & hari diambil dari data widget; pengaturan dari SharedPreferences.
Future<void> refreshMuhasabahInBackground(Map<String, Object?> payload) async {
  if (!AdzanNotifications.supported) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppSettings.muhasabahKey) ?? true)) return;
    final zoneId = payload['tzId'] as String?;
    if (zoneId == null) return;
    tzdata.initializeTimeZones();
    final location = tz.getLocation(zoneId);
    final now = tz.TZDateTime.now(location);
    final today = DateTime.utc(now.year, now.month, now.day);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/widget_ic_crescent'),
      ),
    );
    await _refreshMuhasabahToday(
      plugin,
      location: location,
      today: today,
      minutes:
          prefs.getInt(AppSettings.muhasabahMinutesKey) ??
          defaultMuhasabahMinutes,
      summary: DaySummary.fromPayload(payload, dateKey(today)),
    );
  } catch (e) {
    debugPrint('muhasabah latar: $e');
  }
}

/// Awalan payload adzan layar penuh: "alarm|tanggal|kunci".
const adzanAlarmPrefix = 'alarm|';

/// Catat sholat dari halaman adzan layar penuh ([payload] boleh berawalan
/// [adzanAlarmPrefix]).
Future<void> logSholatFromAlarm(String payload) => _logDone(payload);

/// "Sudah sholat" dari notifikasi: catat sholat [payload] (`tanggal|kunci`)
/// lewat callback widget (yang juga mengisi jam & tempat dan memperbarui
/// widget layar utama).
Future<void> _logDone(String? payload) async {
  final parts = payload?.replaceFirst(adzanAlarmPrefix, '').split('|');
  if (parts == null || parts.length != 2) return;
  final db = AppDatabase();
  int? id;
  try {
    final item = await (db.select(
      db.ibadahItems,
    )..where((i) => i.key.equals(parts[1]))).getSingleOrNull();
    id = item?.id;
  } finally {
    await db.close();
  }
  if (id == null) return;
  await trackerWidgetCallback(
    Uri.parse('rinduramadan://ibadah/set?date=${parts[0]}&item=$id&value=1'),
  );
}

/// Tombol notifikasi saat aplikasi tertutup (isolate latar).
@pragma('vm:entry-point')
Future<void> adzanNotificationBackground(NotificationResponse r) async {
  if (r.actionId == _doneAction) await _logDone(r.payload);
}

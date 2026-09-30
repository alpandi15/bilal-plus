import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'adzan_messages.dart';
import 'app_settings.dart';
import 'hijri_calendar.dart';
import 'ibadah_day.dart';
import 'prayer_calculator.dart' as calc;
import 'sholat_motivation.dart';
import 'sholat_time.dart';
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
  'Pengingat puasa sunnah',
  description: 'Malam sebelum Hari Tarwiyah & Arafah: niat & siapkan sahur',
  importance: Importance.defaultImportance,
);

/// Jam pengingat puasa (malam sebelumnya).
const fastReminderHour = 20;

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

  /// Jadwalkan ulang semua notifikasi [adzanDays] hari ke depan sesuai
  /// pengaturan & lokasi: adzan (bila aktif) dan pengingat puasa Tarwiyah /
  /// Arafah (bila aktif; tanggalnya dari [anchors] kalender hijriah).
  Future<void> reschedule({
    required AppSettingsController settings,
    required double latitude,
    required double longitude,
    required String placeName,
    HijriAnchors? anchors,
  }) async {
    if (!supported || !_ready) return;
    await _plugin.cancelAll();
    if (!settings.adzan && !settings.fastReminder) return;

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
    if (!settings.adzan) return;

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
            id: day * 16 + i,
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
            id: day * 16 + 8 + i,
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
        id: 900 + day,
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
      id: 990,
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
      id: 999,
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

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';
import '../utils/date_key.dart';
import 'adzan_messages.dart';
import 'app_settings.dart';
import 'prayer_calculator.dart' as calc;
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

  /// [onOpen] dipanggil saat notifikasi diketuk (aplikasi dibuka).
  Future<void> init({void Function()? onOpen}) async {
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
          onOpen?.call();
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
    _ready = true;

    // dibuka dari notifikasi saat aplikasi tertutup
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) onOpen?.call();
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
  /// pengaturan & lokasi (atau batalkan semua bila dimatikan).
  Future<void> reschedule({
    required AppSettingsController settings,
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    if (!supported || !_ready) return;
    await _plugin.cancelAll();
    if (!settings.adzan) return;

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
        final payload = '${dateKey(date)}|$key';

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
                category: AndroidNotificationCategory.reminder,
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

/// "Sudah sholat" dari notifikasi: catat sholat [payload] (`tanggal|kunci`)
/// lewat callback widget (yang juga mengisi jam & tempat dan memperbarui
/// widget layar utama).
Future<void> _logDone(String? payload) async {
  final parts = payload?.split('|');
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

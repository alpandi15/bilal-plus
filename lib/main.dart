import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'db/app_database.dart';
import 'db/app_database_scope.dart';
import 'services/adzan_notifications.dart';
import 'services/ayat_harian.dart';
import 'services/muhasabah.dart';
import 'services/prayer_calculator.dart' as calc;
import 'services/quran_text.dart';
import 'services/reminder_ids.dart';
import 'services/waktu_penting.dart';
import 'widgets/ibadah/sholat_dalil_sheet.dart';
import 'utils/date_key.dart';
import 'services/app_settings.dart';
import 'services/hijri_config.dart';
import 'services/hijri_config_scope.dart';
import 'services/tracker_widget_sync.dart';
import 'services/user_location_controller.dart';
import 'services/user_location_scope.dart';
import 'pages/adzan_alarm_page.dart';
import 'pages/backup_page.dart';
import 'pages/hijri_calendar_page.dart';
import 'pages/ibadah_daily_report_page.dart';
import 'pages/ibadah_weekly_report_page.dart';
import 'pages/home_shell.dart';
import 'pages/ibadah_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/quran/hafalan_page.dart';
import 'pages/quran/quran_reader_page.dart';
import 'pages/quran_tracker_page.dart';
import 'pages/splash_view.dart';

void main() {
  runApp(const RinduRamadanApp());
}

class RinduRamadanApp extends StatefulWidget {
  const RinduRamadanApp({
    super.key,
    this.database,
    this.homeWidgets = true,
    this.onboarding = true,
  });

  /// Basis data pengganti (mis. in-memory untuk uji); null = berkas SQLite
  /// aplikasi.
  final AppDatabase? database;

  /// Sinkron & tangani ketukan widget layar utama Ibadah/Al-Qur'an. Uji
  /// mematikannya karena plugin `home_widget` tidak tersedia di sana.
  final bool homeWidgets;

  /// Tampilkan setup awal pada pemakaian pertama. Uji mematikannya.
  final bool onboarding;

  @override
  State<RinduRamadanApp> createState() => _RinduRamadanAppState();
}

class _RinduRamadanAppState extends State<RinduRamadanApp> {
  final _location = UserLocationController();
  final _settings = AppSettingsController();
  final _shell = GlobalKey<HomeShellState>();

  // drift membuka berkasnya secara malas (pada kueri pertama), jadi membuat
  // objeknya di sini tidak memperlambat awal aplikasi
  late final AppDatabase _db = widget.database ?? AppDatabase();

  // --dart-define=HIJRI_URL=... untuk mengarahkan unduhan konfigurasi ke
  // server lain (mis. `next dev` lokal saat mengembangkan); kosong = bawaan
  final _hijri = HijriConfigController(
    remoteUrl: const String.fromEnvironment('HIJRI_URL').isEmpty
        ? 'https://bilal-tarawih.vercel.app/api/hijri'
        : const String.fromEnvironment('HIJRI_URL'),
  );

  final _navigator = GlobalKey<NavigatorState>();

  /// Ringkasan ibadah hari ini terbaru (dari sinkron widget) untuk teks
  /// notifikasi muhasabah.
  DaySummary? _summary;

  late final _widgetSync = TrackerWidgetSync(
    db: _db,
    hijri: _hijri,
    location: _location,
    settings: _settings,
    onSummary: (s) {
      _summary = s;
      // hanya notifikasi muhasabah hari ini yang diperbarui - ringan
      AdzanNotifications.instance.refreshMuhasabah(
        settings: _settings,
        longitude: _location.location.long,
        summary: s,
      );
    },
  );
  StreamSubscription<Uri?>? _widgetClicks;
  Timer? _adzanDebounce;

  /// Aplikasi ditinggalkan: data widget yang masih menunggu disimpan
  /// sekarang juga (mis. baru menandai hafal lalu langsung keluar).
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _hijri.init();
    // lokasi menunggu pengaturan: sebelum setup awal selesai, izin GPS
    // diminta di halaman setup (dengan penjelasan), bukan langsung saat buka
    _settings.init().then(
      (_) => _location.init(autoGps: _settings.onboarded || !widget.onboarding),
    );
    if (widget.homeWidgets) {
      _widgetSync
        ..start()
        ..schedule();
      _lifecycle = AppLifecycleListener(
        onHide: _widgetSync.flush,
        onPause: _widgetSync.flush,
      );
      registerTrackerWidgetCallback();
      _listenWidgetLaunch();
      _startAdzan();
    }
  }

  /// Notifikasi adzan: dijadwalkan ulang setiap pengaturan atau lokasi
  /// berubah (dan saat aplikasi dibuka). Ketuk notifikasi = tab Ibadah.
  Future<void> _startAdzan() async {
    await AdzanNotifications.instance.init(
      onOpen: (payload) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openFromNotification(payload),
      ),
    );
    _settings.addListener(_scheduleAdzan);
    _location.addListener(_scheduleAdzan);
    // pengingat puasa Tarwiyah/Arafah mengikuti kalender hijriah
    _hijri.addListener(_scheduleAdzan);
    _scheduleAdzan();
  }

  /// Ketuk notifikasi: adzan layar penuh -> halaman adzan; muhasabah /
  /// laporan mingguan -> laporannya; ayat harian -> pembaca di ayatnya;
  /// selain itu tab Ibadah.
  void _openFromNotification(String? payload) {
    final nav = _navigator.currentState;
    if (nav == null) return;
    Widget? page;
    if (payload == NotifPayload.prayerTimes) {
      // sepertiga malam terakhir: lembar waktu penting
      final ctx = _navigator.currentContext;
      if (ctx != null) {
        final loc = _location.location;
        final now = DateTime.now();
        showWaktuPentingSheet(
          ctx,
          waktu: waktuPenting(now: now, latitude: loc.lat, longitude: loc.long),
          now: now,
        );
        return;
      }
    }
    if (payload != null && payload.startsWith(adzanAlarmPrefix)) {
      page = AdzanAlarmPage(payload: payload);
    } else if (NotifPayload.parseDate(payload, NotifPayload.reportDay)
        case final date?) {
      page = IbadahDailyReportPage(date: date);
    } else if (NotifPayload.parseDate(payload, NotifPayload.reportWeek)
        case final date?) {
      page = IbadahWeeklyReportPage(week: parseDateKey(date));
    } else if (NotifPayload.parseAyat(payload) case (final s, final a)) {
      if (s >= 1 && s <= 114) {
        page = QuranReaderPage(surah: s, ayah: a);
      }
    }
    if (page != null) {
      nav.push(MaterialPageRoute<void>(builder: (_) => page!));
    } else {
      _shell.currentState?.goTo(HomeTab.ibadah);
    }
  }

  void _scheduleAdzan() {
    _adzanDebounce?.cancel();
    _adzanDebounce = Timer(const Duration(seconds: 1), () async {
      if (!_settings.loaded) return;
      final loc = _location.location;
      // ayat harian: isinya tetap per tanggal, disusun dari teks Al-Qur'an
      var ayat = const <DayNotice>[];
      if (_settings.ayatNotif) {
        try {
          ayat = ayatNotices(
            await QuranText.load(),
            calc.todayInZone(calc.timezoneFromLongitude(loc.long)),
            font: _settings.quranFont,
          );
        } catch (_) {}
      }
      await AdzanNotifications.instance.reschedule(
        settings: _settings,
        latitude: loc.lat,
        longitude: loc.long,
        placeName: loc.name,
        anchors: _hijri.config.anchors,
        summary: _summary,
        ayat: ayat,
      );
    });
  }

  /// Ketuk widget Ibadah/Al-Qur'an membuka halamannya
  /// (`rinduramadan://ibadah`, `rinduramadan://quran`).
  void _listenWidgetLaunch() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    HomeWidget.initiallyLaunchedFromHomeWidget()
        .then(_openFromWidget)
        .catchError((Object _) {});
    _widgetClicks = HomeWidget.widgetClicked.listen(
      _openFromWidget,
      onError: (Object _) {},
    );
  }

  void _openFromWidget(Uri? uri) {
    // widget Ayat Harian: langsung ke ayatnya di pembaca
    if (uri?.host == 'ayat') {
      final s = int.tryParse(uri?.queryParameters['s'] ?? '');
      final a = int.tryParse(uri?.queryParameters['a'] ?? '');
      if (s != null && a != null && s >= 1 && s <= 114) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _shell.currentState?.goTo(HomeTab.quran);
          _navigator.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => QuranReaderPage(surah: s, ayah: a),
            ),
          );
        });
      }
      return;
    }
    final tab = switch (uri?.host) {
      'ibadah' => HomeTab.ibadah,
      'quran' || 'hafalan' => HomeTab.quran,
      _ => null,
    };
    if (tab == null) return;
    // widget Hafalan: langsung ke halaman hafalan surahnya
    if (uri?.host == 'hafalan') {
      final surah = int.tryParse(uri?.queryParameters['surah'] ?? '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shell.currentState?.goTo(tab);
        _navigator.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => HafalanOpenPage(surah: surah),
          ),
        );
      });
      return;
    }
    // kerangka belum siap saat aplikasi baru dibuka dari widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shell.currentState?.goTo(tab);
    });
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    _adzanDebounce?.cancel();
    _settings.removeListener(_scheduleAdzan);
    _location.removeListener(_scheduleAdzan);
    _hijri.removeListener(_scheduleAdzan);
    _lifecycle?.dispose();
    _widgetSync.dispose();
    _location.dispose();
    _hijri.dispose();
    _settings.dispose();
    if (widget.database == null) _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDatabaseScope(
      database: _db,
      child: UserLocationScope(
        controller: _location,
        child: HijriConfigScope(
          controller: _hijri,
          child: AppSettingsScope(
            controller: _settings,
            child: MaterialApp(
              navigatorKey: _navigator,
              title: 'Bilal+',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.amber,
              ),
              // --dart-define=INITIAL_PAGE=calendar untuk langsung membuka
              // halaman tertentu saat mengembangkan/uji tangkapan layar
              home: switch (const String.fromEnvironment('INITIAL_PAGE')) {
                'calendar' => const HijriCalendarPage(),
                'quran' => const QuranTrackerPage(),
                'ibadah' => const IbadahPage(),
                'backup' => const BackupPage(),
                'onboarding' => const OnboardingPage(),
                _ => StartGate(
                  onboarding: widget.onboarding,
                  home: HomeShell(key: _shell),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'db/app_database.dart';
import 'db/app_database_scope.dart';
import 'services/adzan_notifications.dart';
import 'services/app_settings.dart';
import 'services/hijri_config.dart';
import 'services/hijri_config_scope.dart';
import 'services/tracker_widget_sync.dart';
import 'services/user_location_controller.dart';
import 'services/user_location_scope.dart';
import 'pages/adzan_alarm_page.dart';
import 'pages/backup_page.dart';
import 'pages/hijri_calendar_page.dart';
import 'pages/home_shell.dart';
import 'pages/ibadah_page.dart';
import 'pages/onboarding_page.dart';
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
  late final _widgetSync = TrackerWidgetSync(
    db: _db,
    hijri: _hijri,
    location: _location,
    settings: _settings,
  );
  StreamSubscription<Uri?>? _widgetClicks;
  Timer? _adzanDebounce;

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
      registerTrackerWidgetCallback();
      _listenWidgetLaunch();
      _startAdzan();
    }
  }

  /// Notifikasi adzan: dijadwalkan ulang setiap pengaturan atau lokasi
  /// berubah (dan saat aplikasi dibuka). Ketuk notifikasi = tab Ibadah.
  Future<void> _startAdzan() async {
    await AdzanNotifications.instance.init(
      onOpen: (payload) => WidgetsBinding.instance.addPostFrameCallback((_) {
        // adzan layar penuh -> halaman adzan; notifikasi biasa -> tab Ibadah
        if (payload != null && payload.startsWith(adzanAlarmPrefix)) {
          _navigator.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => AdzanAlarmPage(payload: payload),
            ),
          );
        } else {
          _shell.currentState?.goTo(HomeTab.ibadah);
        }
      }),
    );
    _settings.addListener(_scheduleAdzan);
    _location.addListener(_scheduleAdzan);
    // pengingat puasa Tarwiyah/Arafah mengikuti kalender hijriah
    _hijri.addListener(_scheduleAdzan);
    _scheduleAdzan();
  }

  void _scheduleAdzan() {
    _adzanDebounce?.cancel();
    _adzanDebounce = Timer(const Duration(seconds: 1), () {
      if (!_settings.loaded) return;
      final loc = _location.location;
      AdzanNotifications.instance.reschedule(
        settings: _settings,
        latitude: loc.lat,
        longitude: loc.long,
        placeName: loc.name,
        anchors: _hijri.config.anchors,
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
    final tab = switch (uri?.host) {
      'ibadah' => HomeTab.ibadah,
      'quran' => HomeTab.quran,
      _ => null,
    };
    if (tab == null) return;
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

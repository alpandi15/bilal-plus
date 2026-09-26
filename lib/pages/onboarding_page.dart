import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/adzan_notifications.dart';
import '../services/app_settings.dart';
import '../services/sholat_time.dart';
import '../services/user_location_controller.dart';
import '../services/user_location_scope.dart';
import '../widgets/location_picker.dart';
import '../widgets/privacy_note.dart';
import 'splash_view.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);
const _gold = Color(0xFFE3BE6A);

/// Setup awal (sekali): salam, nama & jenis kelamin, izin (lokasi,
/// notifikasi adzan, alarm tepat waktu), dan penjelasan bahwa semua data
/// tersimpan di HP. Semua langkah boleh dilewati - bisa diatur lagi di
/// Pengaturan.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with WidgetsBindingObserver {
  static const _steps = 4;
  final _pages = PageController();
  late final _name = TextEditingController(
    text: AppSettingsScope.read(context)?.userName,
  );
  int _page = 0;
  Gender? _gender;

  bool? _locationGranted;
  bool _notifications = false, _exactAlarms = true;
  bool _locating = false, _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gender ??= AppSettingsScope.maybeOf(context)?.gender;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  // kembali dari halaman izin sistem (mis. "Alarm & pengingat")
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    bool? location;
    try {
      final p = await Geolocator.checkPermission();
      location =
          p == LocationPermission.always || p == LocationPermission.whileInUse;
    } catch (_) {}
    var notifications = false, exact = true;
    try {
      final s = await AdzanNotifications.instance.permissionStatus();
      notifications = s.notifications;
      exact = s.exactAlarms;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _locationGranted = location;
      _notifications = notifications;
      _exactAlarms = exact;
    });
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  Future<void> _finish() async {
    await AppSettingsScope.read(
      context,
    )?.completeOnboarding(name: _name.text, gender: _gender);
  }

  Future<void> _askLocation() async {
    final location = UserLocationScope.of(context);
    setState(() => _locating = true);
    final result = await location.requestGps();
    if (!mounted) return;
    setState(() => _locating = false);
    final message = switch (result) {
      GpsResult.ok => null,
      GpsResult.serviceDisabled =>
        'GPS mati - nyalakan lokasi di HP, atau pilih kota manual.',
      GpsResult.permissionDeniedForever =>
        'Izin lokasi ditolak permanen - buka pengaturan aplikasi, atau '
            'pilih kota manual.',
      GpsResult.permissionDenied =>
        'Izin lokasi ditolak - bisa pilih kota manual.',
      GpsResult.failed => 'Lokasi belum terbaca - coba lagi di tempat terbuka.',
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: switch (result) {
            GpsResult.serviceDisabled => SnackBarAction(
              label: 'Buka',
              onPressed: Geolocator.openLocationSettings,
            ),
            GpsResult.permissionDeniedForever => SnackBarAction(
              label: 'Buka',
              onPressed: Geolocator.openAppSettings,
            ),
            _ => null,
          },
        ),
      );
    }
    await _refreshPermissions();
  }

  Future<void> _askNotifications() async {
    final settings = AppSettingsScope.read(context);
    setState(() => _asking = true);
    var granted = false;
    try {
      granted = await AdzanNotifications.instance.requestPermissions();
    } catch (_) {}
    if (granted) await settings?.setAdzan(true);
    if (!mounted) return;
    setState(() => _asking = false);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi ditolak - bisa diaktifkan nanti di Pengaturan.',
          ),
        ),
      );
    }
    await _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _page ? _amber : const Color(0xFFF1E4CF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: _muted),
                      onPressed: () => _go(_steps - 1),
                      child: const Text('Lewati'),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) {
                  FocusScope.of(context).unfocus();
                  setState(() => _page = i);
                },
                children: [
                  const _WelcomeStep(),
                  _AboutStep(
                    name: _name,
                    gender: _gender,
                    onGender: (g) => setState(() => _gender = g),
                  ),
                  _PermissionStep(
                    locationGranted: _locationGranted,
                    notifications: _notifications,
                    exactAlarms: _exactAlarms,
                    locating: _locating,
                    asking: _asking,
                    onLocation: _askLocation,
                    onPickCity: () => showLocationPicker(context),
                    onNotifications: _askNotifications,
                    onExactAlarms: () async {
                      try {
                        await AdzanNotifications.instance.requestExactAlarms();
                      } catch (_) {}
                    },
                  ),
                  const _PrivacyStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: _muted),
                      onPressed: () => _go(_page - 1),
                      child: const Text('Kembali'),
                    ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: last ? _emerald : _amber,
                      minimumSize: const Size(148, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: last ? _finish : () => _go(_page + 1),
                    child: Text(
                      last
                          ? 'Mulai'
                          : _page == 0
                          ? 'Siapkan'
                          : 'Lanjut',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ steps */

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _stone,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 13.5, height: 1.5, color: _muted),
      ),
      const SizedBox(height: 20),
    ],
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  static const _features = [
    (Icons.access_time_rounded, 'Jadwal sholat & notifikasi adzan'),
    (Icons.task_alt_rounded, "Checklist ibadah, berjama'ah & tepat waktu"),
    (Icons.menu_book_rounded, "Tilawah Al-Qur'an sampai khatam"),
    (Icons.auto_stories_rounded, 'Dzikir, bacaan sholat & bilal tarawih'),
  ];

  @override
  Widget build(BuildContext context) => _StepScroll(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: splashBackground,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33064E3B),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: const Column(
          children: [
            BilalLogo(size: 120),
            SizedBox(height: 16),
            Text(
              "Assalamu'alaikum",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Selamat datang di Bilal+',
              style: TextStyle(fontSize: 14, color: _gold),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      for (final (icon, text) in _features)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: _amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _stone,
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 4),
      const Text(
        'Siapkan dalam satu menit - semuanya bisa diubah nanti di Pengaturan.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
    ],
  );
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({
    required this.name,
    required this.gender,
    required this.onGender,
  });

  final TextEditingController name;
  final Gender? gender;
  final ValueChanged<Gender> onGender;

  @override
  Widget build(BuildContext context) {
    final solo = AppSettingsScope.maybeOf(context)?.soloWeight ?? 1;
    return _StepScroll(
      children: [
        const _Heading(
          'Tentang Anda',
          'Untuk sapaan dan ajakan ibadah yang sesuai. Tidak dikirim ke '
              'mana pun.',
        ),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 30,
          decoration: InputDecoration(
            labelText: 'Nama panggilan (opsional)',
            hintText: 'mis. Ahmad',
            prefixIcon: const Icon(Icons.badge_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'JENIS KELAMIN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xCCB45309),
          ),
        ),
        const SizedBox(height: 8),
        _GenderCard(
          icon: Icons.man_rounded,
          title: 'Laki-laki',
          detail:
              "Diajak sholat berjama'ah di masjid & Sholat Jumat. Sholat "
              "sendiri bernilai ${soloWeightLabel(solo)} dari berjama'ah.",
          selected: gender == Gender.male,
          onTap: () => onGender(Gender.male),
        ),
        const SizedBox(height: 10),
        _GenderCard(
          icon: Icons.woman_rounded,
          title: 'Perempuan',
          detail:
              'Ajakan sholat tepat waktu. Sholat di rumah lebih utama - '
              'sholat sendiri tetap bernilai penuh.',
          selected: gender == Gender.female,
          onTap: () => onGender(Gender.female),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title, detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? const Color(0xFFECFDF5) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _emerald : _line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: selected ? _emerald : _amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _emerald),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.locationGranted,
    required this.notifications,
    required this.exactAlarms,
    required this.locating,
    required this.asking,
    required this.onLocation,
    required this.onPickCity,
    required this.onNotifications,
    required this.onExactAlarms,
  });

  final bool? locationGranted;
  final bool notifications, exactAlarms, locating, asking;
  final VoidCallback onLocation, onPickCity, onNotifications, onExactAlarms;

  @override
  Widget build(BuildContext context) {
    final location = UserLocationScope.of(context);
    final place = location.location.name;
    // GPS sedang membaca posisi: kota yang tampil masih yang lama
    final searching = locating || location.status == LocationStatus.locating;
    final adzanOn = AppSettingsScope.maybeOf(context)?.adzan ?? false;
    return _StepScroll(
      children: [
        const _Heading(
          'Izin aplikasi',
          'Semua opsional - tanpa izin, fitur lain tetap berjalan. Bisa '
              'diubah kapan saja di Pengaturan.',
        ),
        _PermissionCard(
          icon: Icons.my_location_rounded,
          title: 'Lokasi',
          detail:
              'Agar jadwal sholat sesuai kota Anda. Dihitung di HP, '
              'tidak dikirim ke mana pun.',
          granted: locationGranted == true && !searching,
          grantedText: 'Diizinkan · $place',
          action: 'Izinkan lokasi',
          busy: searching,
          busyText: 'Mencari lokasi…',
          onTap: onLocation,
          secondary: TextButton(
            style: TextButton.styleFrom(foregroundColor: _amber),
            onPressed: onPickCity,
            child: Text(
              locationGranted == true
                  ? 'Ganti kota'
                  : 'Pilih kota manual · sekarang $place',
            ),
          ),
        ),
        _PermissionCard(
          icon: Icons.notifications_active_rounded,
          title: 'Notifikasi adzan',
          detail:
              'Pengingat saat waktu sholat masuk, dengan tombol "Sudah '
              'sholat" untuk mencentang langsung.',
          granted: notifications && adzanOn,
          grantedText: 'Aktif',
          action: 'Aktifkan',
          busy: asking,
          onTap: onNotifications,
        ),
        if (notifications && !exactAlarms)
          _PermissionCard(
            icon: Icons.alarm_on_rounded,
            title: 'Alarm tepat waktu',
            detail:
                'Android membatasi alarm - izinkan "Alarm & pengingat" agar '
                'adzan tidak terlambat beberapa menit.',
            granted: false,
            grantedText: 'Diizinkan',
            action: 'Buka pengaturan',
            busy: false,
            onTap: onExactAlarms,
          ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.granted,
    required this.grantedText,
    required this.action,
    required this.busy,
    required this.onTap,
    this.secondary,
    this.busyText,
  });

  final IconData icon;
  final String title, detail, grantedText, action;

  /// Teks saat [busy] (mis. "Mencari lokasi…"); null = tombol biasa.
  final String? busyText;
  final bool granted, busy;
  final VoidCallback onTap;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: granted ? const Color(0xFFA7F3D0) : _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: granted
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: granted ? _emerald : _amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: granted
                  ? Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: _emerald,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            grantedText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _emerald,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onTap,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        label: Text(busy ? busyText ?? action : action),
                      ),
                    ),
            ),
          ],
        ),
        ?secondary,
      ],
    ),
  );
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep();

  @override
  Widget build(BuildContext context) => const _StepScroll(
    children: [
      _Heading(
        'Data Anda, milik Anda',
        'Bilal+ tidak punya server untuk menyimpan catatan Anda.',
      ),
      PrivacyNote(),
      SizedBox(height: 12),
      Text(
        'Tip: simpan file cadangan sesekali lewat Lainnya > Cadangan Data, '
        'supaya catatan bisa dipulihkan saat ganti HP.',
        style: TextStyle(fontSize: 12, height: 1.5, color: _muted),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_index.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/feature_menu.dart';
import '../widgets/quran/quran_goto.dart';
import '../widgets/ibadah/sholat_nudge_card.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/quran/progress_ring.dart';
import '../widgets/ramadan_countdown.dart';
import 'home_shell.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Tab Beranda: hitung mundur Ramadan, jadwal sholat, pengingat sholat,
/// dan ringkasan hari ini (ibadah & bacaan Al-Qur'an) yang membawa ke tab
/// masing-masing.
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _scroll = ScrollController();

  /// Kartu jadwal sudah tergulir ke atas: status bar diberi latar supaya
  /// jam & sinyal tidak bertumpuk dengan isi halaman.
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 280;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    final name = AppSettingsScope.maybeOf(context)?.userName;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Stack(
        children: [
          _list(context, shell, name, bottom),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _scrolled ? 1 : 0,
                child: _scrolled
                    ? const AnnotatedRegion<SystemUiOverlayStyle>(
                        value: SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          statusBarIconBrightness: Brightness.dark,
                          statusBarBrightness: Brightness.light,
                        ),
                        child: ColoredBox(color: Color(0xFFFFFAF3)),
                      )
                    : const ColoredBox(color: Color(0xFFFFFAF3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    HomeShellScope? shell,
    String? name,
    double bottom,
  ) {
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.only(bottom: 28 + bottom),
      children: [
        // jadwal sholat selebar layar, tembus ke balik status bar
        PrayerTimesCard(
          hero: true,
          greeting: name == null
              ? "Assalamu'alaikum"
              : "Assalamu'alaikum, $name",
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RamadanCountdown(),
                  const SizedBox(height: 18),
                  _QuranCard(onTracker: () => shell?.goTo(HomeTab.quran)),
                  const SizedBox(height: 16),
                  FeatureGrid(
                    children: [
                      for (final m in homeFeatures) FeatureTile.of(context, m),
                      FeatureTile(
                        title: 'Lainnya',
                        icon: Icons.grid_view_rounded,
                        colors: const [Color(0xFFE7E5E4), Color(0xFFA8A29E)],
                        onTap: () => showAllFeatures(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SholatNudgeCards(onLog: (_) => shell?.goTo(HomeTab.ibadah)),
                  _TodayIbadah(onTap: () => shell?.goTo(HomeTab.ibadah)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.onTap,
    required this.kicker,
    required this.ring,
    required this.value,
    required this.title,
    required this.detail,
  });

  final VoidCallback onTap;
  final String kicker, value, title, detail;
  final double ring;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xCCB45309),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ProgressRing(
                    value: ring,
                    size: 48,
                    stroke: 6,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _stone,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayIbadah extends StatefulWidget {
  const _TodayIbadah({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_TodayIbadah> createState() => _TodayIbadahState();
}

class _TodayIbadahState extends State<_TodayIbadah> {
  Stream<IbadahDayData>? _stream;
  String? _today;

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).ibadahDao;
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    if (_stream == null || _today != today) {
      _today = today;
      _stream = dao.watchDay(
        today,
        summariesFrom: dateKey(
          parseDateKey(today).subtract(const Duration(days: 400)),
        ),
        summariesTo: today,
      );
    }
    return StreamBuilder<IbadahDayData>(
      stream: _stream,
      builder: (context, snap) {
        final data = snap.data;
        var progress = const IbadahProgress(0, 0, 0);
        var streak = 0;
        if (data != null) {
          final items = visibleItems(
            data.items,
            ibadahDay(today, anchors),
            data.values,
            qadhaRemaining: data.qadhaRemaining,
          );
          progress = ibadahProgress(
            items,
            data.values,
            excused: data.excused,
            hasTilawah: data.hasTilawah,
            logs: data.logs,
            soloWeight:
                AppSettingsScope.maybeOf(context)?.effectiveSoloWeight ?? 1,
          );
          streak = ibadahStreak(data.summaries, today);
        }
        return _MiniCard(
          onTap: widget.onTap,
          kicker: 'IBADAH HARI INI',
          ring: progress.fraction,
          value: '${progress.percent}%',
          title: progress.complete
              ? 'Tuntas semua'
              : '${progress.total - progress.done} belum',
          detail: streak > 0 ? '🔥 $streak hari terjaga' : 'Buka checklist',
        );
      },
    );
  }
}

/// Al-Qur'an: lanjutkan membaca, halaman terbaca pekan ini, progress
/// khatam - pintu ke mushaf & tracker tilawah.
class _QuranCard extends StatefulWidget {
  const _QuranCard({required this.onTracker});
  final VoidCallback onTracker;

  @override
  State<_QuranCard> createState() => _QuranCardState();
}

class _QuranCardState extends State<_QuranCard> {
  Stream<(QuranProgress, double)>? _stream;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    _stream ??= db.quranDao.watchProgress().asyncMap((p) async {
      // halaman terbaca Senin-hari ini
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final logs = await db.ibadahDao.quranLogsBetween(
        dateKey(monday),
        dateKey(now),
      );
      final pages = logs
          .where((l) => l.toAyah >= l.fromAyah)
          .fold<double>(0, (a, l) => a + pagesBetween(l.fromAyah, l.toAyah));
      return (p, pages);
    });
    final lastRead = AppSettingsScope.maybeOf(context)?.quranLastRead;

    return StreamBuilder<(QuranProgress, double)>(
      stream: _stream,
      builder: (context, snap) {
        final p = snap.data?.$1;
        final week = snap.data?.$2 ?? 0;
        // gradien & bayangan di luar Material (bukan Ink) supaya sudutnya
        // benar-benar bulat
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33064E3B),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => showQuranModeSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF2D38A), Color(0xFFB45309)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF0C3A33),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AL-QUR'AN",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Color(0xFFF2D38A),
                                ),
                              ),
                              Text(
                                lastRead == null
                                    ? 'Mulai membaca'
                                    : formatAyah(lastRead),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                lastRead == null
                                    ? 'Mushaf bertajwid & catatan ayat'
                                    : 'Terakhir dibuka · Juz ${juzOf(lastRead)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xCCFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Stat(
                          value: week == 0
                              ? '0'
                              : week < 10
                              ? week.toStringAsFixed(1).replaceAll('.', ',')
                              : '${week.round()}',
                          label: 'halaman pekan ini',
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          value: '${(((p?.progress) ?? 0) * 100).floor()}%',
                          label: 'khatam ke-${p?.round ?? 1}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF2D38A),
                              foregroundColor: const Color(0xFF0C3A33),
                            ),
                            onPressed: () => lastRead == null
                                ? showQuranModeSheet(context)
                                : continueQuran(context),
                            icon: const Icon(
                              Icons.auto_stories_rounded,
                              size: 18,
                            ),
                            label: Text(
                              lastRead == null ? 'Buka mushaf' : 'Lanjutkan',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x66FFFFFF)),
                            ),
                            onPressed: widget.onTracker,
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Catat tilawah'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    ),
  );
}

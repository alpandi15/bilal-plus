import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_index.dart';
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/feature_menu.dart';
import '../widgets/quran/quran_goto.dart';
import '../widgets/ibadah/sholat_nudge_card.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/quran/progress_ring.dart';
import '../widgets/ramadan_countdown.dart';
import 'home_shell.dart';

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
      final scrolled = _scroll.offset > 40;
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
                  // ibadah hari ini paling menonjol: di atas Al-Qur'an & menu
                  _TodayIbadah(onTap: () => shell?.goTo(HomeTab.ibadah)),
                  const SizedBox(height: 12),
                  SholatNudgeCards(onLog: (_) => shell?.goTo(HomeTab.ibadah)),
                  const SizedBox(height: 6),
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
                ],
              ),
            ),
          ),
        ),
      ],
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
        final day = ibadahDay(today, anchors);
        final sholat = [
          for (final i in data?.items ?? const <IbadahItem>[])
            if (i.groupKey == sholatWajibGroup) i,
        ];
        return _IbadahCard(
          onTap: widget.onTap,
          progress: progress,
          streak: streak,
          excused: data?.excused ?? false,
          dayLabel: day.isRamadan
              ? 'Ramadan hari ke-${day.ramadanDay}'
              : day.hijri.format(),
          sholat: [
            for (final i in sholat)
              (
                key: i.key,
                name: i.name,
                done: (data?.values[i.id] ?? 0) > 0,
                jamaah: data?.logs[i.id]?.jamaah == true,
              ),
          ],
          current: _currentSholat(location.lat, location.long),
        );
      },
    );
  }

  /// Kunci sholat wajib yang waktunya sedang berjalan.
  String? _currentSholat(double lat, double long) {
    final t = calc.calculatePrayerTimes(latitude: lat, longitude: long);
    final now = DateTime.now();
    String? current;
    for (final e in sholatPrayerKey.entries) {
      final at = t.times[e.value];
      if (at != null && !now.isBefore(at)) current = e.key;
    }
    return current;
  }
}

typedef _SholatDot = ({String key, String name, bool done, bool jamaah});

/// Kartu utama ibadah hari ini: persentase, lima waktu, streak.
class _IbadahCard extends StatelessWidget {
  const _IbadahCard({
    required this.onTap,
    required this.progress,
    required this.streak,
    required this.excused,
    required this.dayLabel,
    required this.sholat,
    required this.current,
  });

  final VoidCallback onTap;
  final IbadahProgress progress;
  final int streak;
  final bool excused;
  final String dayLabel;
  final List<_SholatDot> sholat;
  final String? current;

  static const _gold = Color(0xFFF2D38A);

  @override
  Widget build(BuildContext context) {
    final done = sholat.where((s) => s.done).length;
    final jamaah = sholat.where((s) => s.jamaah).length;
    final left = progress.total - progress.done;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB45309), Color(0xFF7C2D12)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40B45309),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt_rounded, color: _gold, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'IBADAH HARI INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Flexible(
                      flex: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x26FFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          streak > 0 ? '🔥 $streak hari' : dayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ProgressRing(
                      value: progress.fraction,
                      size: 84,
                      stroke: 9,
                      color: _gold,
                      track: const Color(0x33FFFFFF),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${progress.percent}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${progress.done}/${progress.total}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            excused
                                ? 'Sedang berhalangan'
                                : progress.complete
                                ? 'Masyaa Allah, tuntas semua'
                                : '$left ibadah lagi hari ini',
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            excused
                                ? 'Sholat & puasa tidak dihitung hari ini'
                                : "Sholat $done/${sholat.length}"
                                      "${jamaah > 0 ? " · $jamaah berjama'ah" : ''}",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xDDFFFFFF),
                            ),
                          ),
                          if (streak > 0)
                            Text(
                              dayLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0x99FFFFFF),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sholat.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        for (final s in sholat)
                          Expanded(
                            child: _SholatDotView(
                              dot: s,
                              current: s.key == current,
                              excused: excused,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Buka checklist',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _gold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: _gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SholatDotView extends StatelessWidget {
  const _SholatDotView({
    required this.dot,
    required this.current,
    required this.excused,
  });
  final _SholatDot dot;
  final bool current, excused;

  @override
  Widget build(BuildContext context) {
    final done = dot.done;
    return Semantics(
      label:
          '${dot.name}${done ? ', sudah' : ', belum'}'
          '${dot.jamaah ? ", berjama'ah" : ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: excused
                      ? const Color(0x1AFFFFFF)
                      : done
                      ? const Color(0xFF16A34A)
                      : const Color(0x14FFFFFF),
                  border: Border.all(
                    color: current && !done
                        ? const Color(0xFFF2D38A)
                        : done
                        ? const Color(0xFF86EFAC)
                        : const Color(0x55FFFFFF),
                    width: current && !done ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle_outlined,
                  size: done ? 22 : 8,
                  color: done ? Colors.white : const Color(0x88FFFFFF),
                ),
              ),
              if (dot.jamaah)
                Positioned(
                  right: -4,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2D38A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 11,
                      color: Color(0xFF7C2D12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            dot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
              color: current ? const Color(0xFFF2D38A) : Colors.white,
            ),
          ),
        ],
      ),
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

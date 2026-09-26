import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_index.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
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
class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (AppSettingsScope.maybeOf(context)?.userName
                      case final name?) ...[
                    Text(
                      "Assalamu'alaikum, $name",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF44403C),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const RamadanCountdown(),
                  const SizedBox(height: 24),
                  const PrayerTimesCard(),
                  const SizedBox(height: 20),
                  SholatNudgeCards(onLog: (_) => shell?.goTo(HomeTab.ibadah)),
                  Row(
                    children: [
                      Expanded(
                        child: _TodayIbadah(
                          onTap: () => shell?.goTo(HomeTab.ibadah),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuranMini(
                          onTap: () => shell?.goTo(HomeTab.quran),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _QuranMini extends StatefulWidget {
  const _QuranMini({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_QuranMini> createState() => _QuranMiniState();
}

class _QuranMiniState extends State<_QuranMini> {
  Stream<QuranProgress>? _stream;

  @override
  Widget build(BuildContext context) {
    _stream ??= AppDatabaseScope.of(context).quranDao.watchProgress();
    return StreamBuilder<QuranProgress>(
      stream: _stream,
      builder: (context, snap) {
        final p = snap.data;
        final last = p?.lastAyah ?? 0;
        return _MiniCard(
          onTap: widget.onTap,
          kicker: "TILAWAH",
          ring: p?.progress ?? 0,
          value: '${((p?.progress ?? 0) * 100).floor()}%',
          title: last == 0 ? 'Belum mulai' : 'Juz ${juzOf(last)}',
          detail: last == 0 ? 'Mulai catat bacaan' : formatAyah(last),
        );
      },
    );
  }
}

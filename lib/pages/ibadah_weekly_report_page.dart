import 'package:flutter/material.dart';

import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_insight.dart';
import '../services/ibadah_report.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/report_export.dart';
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/report/ibadah_heatmap.dart';
import '../widgets/report/insight_widgets.dart';
import '../widgets/report/reveal.dart';
import '../widgets/sub_header.dart';
import 'ibadah_daily_report_page.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Laporan ibadah satu pekan (Senin-Minggu): skor rata-rata, tujuh hari
/// (ketuk untuk laporan harinya), kualitas sholat, konsistensi per ibadah,
/// lalu wawasan & rekomendasi. Bisa diunduh sebagai gambar atau PDF.
class IbadahWeeklyReportPage extends StatefulWidget {
  const IbadahWeeklyReportPage({super.key, this.week});

  /// Tanggal mana pun dalam pekan yang dilaporkan (bawaan: pekan ini).
  final DateTime? week;

  @override
  State<IbadahWeeklyReportPage> createState() => _IbadahWeeklyReportPageState();
}

class _IbadahWeeklyReportPageState extends State<IbadahWeeklyReportPage> {
  final _boundary = GlobalKey();
  DateTime? _monday;
  Future<WeeklyReport>? _future;
  String _today = '';
  bool _busy = false;
  bool _exporting = false;

  DateTime get _currentMonday => mondayOf(parseDateKey(_today));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) {
      final location = UserLocationScope.of(context).location;
      _today = dateKey(
        calc.todayInZone(calc.timezoneFromLongitude(location.long)),
      );
      _monday = mondayOf(widget.week ?? parseDateKey(_today));
      _future = _load(_monday!);
    }
  }

  Future<WeeklyReport> _load(DateTime monday) async {
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    final (from, to) = weekRange(monday);
    final (pFrom, pTo) = weekRange(monday.subtract(const Duration(days: 7)));
    return buildWeeklyReport(
      await db.ibadahDao.loadRange(from, to),
      monday: monday,
      today: _today,
      anchors: anchors,
      latitude: location.lat,
      longitude: location.long,
      onTimeMinutes: settings?.onTimeMinutes ?? defaultOnTimeMinutes,
      soloWeight: settings?.effectiveSoloWeight ?? 1,
      male: settings?.gender == Gender.male,
      previous: await db.ibadahDao.loadRange(pFrom, pTo),
    );
  }

  void _shift(int weeks) {
    final next = _monday!.add(Duration(days: 7 * weeks));
    if (next.isAfter(_currentMonday)) return;
    setState(() {
      _monday = next;
      _future = _load(next);
    });
  }

  Future<void> _export({required bool pdf}) async {
    final title = 'Laporan Ibadah Mingguan ${weekTitle(_monday!)}';
    setState(() {
      _busy = true;
      _exporting = true;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final image = await captureReport(_boundary);
      if (mounted) setState(() => _exporting = false);
      final bytes = pdf ? await reportToPdf(image, title: title) : image.png;
      if (!mounted) return;
      await shareReport(
        context,
        bytes: bytes,
        fileName:
            'laporan-ibadah-minggu-${dateKey(_monday!)}.${pdf ? 'pdf' : 'png'}',
        mimeType: pdf ? 'application/pdf' : 'image/png',
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat laporan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monday = _monday!;
    final canNext = monday.isBefore(_currentMonday);
    return Scaffold(
      backgroundColor: reportBackground,
      body: Column(
        children: [
          const SubHeader(
            title: 'Laporan Mingguan',
            subtitle: 'Ringkasan ibadah sepekan (Senin-Minggu)',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Pekan sebelumnya',
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    monday == _currentMonday
                        ? 'Pekan ini · ${weekTitle(monday)}'
                        : weekTitle(monday),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pekan berikutnya',
                  onPressed: canNext ? () => _shift(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<WeeklyReport>(
              future: _future,
              builder: (context, snap) {
                final r = snap.data;
                if (r == null) {
                  return snap.hasError
                      ? Center(child: Text('Gagal memuat: ${snap.error}'))
                      : const Center(child: CircularProgressIndicator());
                }
                // kunci per pekan: isi dibangun ulang (animasi main lagi);
                // bukan AnimatedSwitcher - GlobalKey ganda saat cross-fade
                return SingleChildScrollView(
                  key: ValueKey(r.monday),
                  child: RepaintBoundary(
                    key: _boundary,
                    child: ExportMode(
                      exporting: _exporting,
                      child: _WeeklyBody(report: r, today: _today),
                    ),
                  ),
                );
              },
            ),
          ),
          FutureBuilder<WeeklyReport>(
            future: _future,
            builder: (context, snap) => ReportActions(
              enabled: snap.hasData,
              busy: _busy,
              onImage: () => _export(pdf: false),
              onPdf: () => _export(pdf: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBody extends StatelessWidget {
  const _WeeklyBody({required this.report, required this.today});
  final WeeklyReport report;
  final String today;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final rep = r.report;
    final hasData = r.daysWithData > 0;
    final delta = r.delta;
    final exporting = ExportMode.of(context);

    final chips = <HeroChip>[
      if (rep.longestStreak > 0)
        HeroChip(
          Icons.local_fire_department_rounded,
          'Streak ${rep.longestStreak} hari',
          color: const Color(0xFFFFD27A),
        ),
      if (delta != null && delta != 0)
        HeroChip(
          delta > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          '${delta > 0 ? '+' : ''}$delta% vs pekan lalu',
          color: delta > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      if (r.tilawahDays > 0)
        HeroChip(Icons.menu_book_rounded, 'Tilawah ${r.tilawahDays} hari'),
    ];

    final consistency = [
      for (final s in rep.items.where((s) => s.days >= 3).take(6))
        CategoryRow(s.item.name, s.done, s.days, InsightIcon.umum),
    ];

    return Container(
      color: reportBackground,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportBrand(title: 'Laporan Ibadah Mingguan', subtitle: r.title),
              const SizedBox(height: 14),
              ScoreHero(
                fraction: r.average,
                grade: r.grade,
                title: 'Rata-rata tuntas',
                centerLabel: 'sepekan',
                subtitle: hasData
                    ? '${r.daysWithData} hari tercatat · ${r.fullDays} hari '
                          'tuntas penuh'
                    : 'Belum ada catatan pekan ini',
                chips: chips,
                empty: !hasData,
              ),
              const SizedBox(height: 14),
              Entrance(
                delay: 100,
                child: ReportCard(
                  title: 'TUJUH HARI',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WeekStrip(
                        days: rep.days,
                        today: today,
                        monday: r.monday,
                        best: r.bestDay,
                        worst: r.worstDay,
                      ),
                      if (!exporting) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Ketuk sebuah hari untuk laporan harinya.',
                          style: TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasData) ...[
                const SizedBox(height: 14),
                Entrance(
                  delay: 200,
                  child: ReportCard(
                    title: 'KUALITAS SHOLAT WAJIB',
                    child: SholatQuality(
                      onTime: r.onTime,
                      valid: r.valid,
                      late: r.late,
                      qadha: r.qadha,
                      missed: r.missed,
                      jamaahPercent: r.jamaahPercent,
                    ),
                  ),
                ),
                if (consistency.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Entrance(
                    delay: 300,
                    child: ReportCard(
                      title: 'KONSISTENSI PER IBADAH',
                      child: CategoryBars(rows: consistency),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              InsightSection(
                kind: InsightKind.good,
                title: 'Yang sudah baik',
                insights: r.good,
                emptyText: hasData
                    ? 'Belum ada yang menonjol pekan ini - mulai dari satu '
                          'kebiasaan kecil yang konsisten.'
                    : null,
                delay: 400,
              ),
              if (hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.improve,
                title: 'Perlu ditingkatkan',
                insights: r.improve,
                emptyText: hasData
                    ? 'Tidak ada yang perlu diperbaiki pekan ini - '
                          'Alhamdulillah, pertahankan!'
                    : null,
                delay: 500,
              ),
              if (hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.tip,
                title: 'Rekomendasi pekan depan',
                insights: r.tips,
                delay: 600,
              ),
              const SizedBox(height: 18),
              const ReportFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tujuh kolom (Sen-Min): tinggi isian = persen tuntas, pita merah/biru di
/// dasar bila ada qadha, hari terbaik/terendah ditandai. Ketuk = laporan hari.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.today,
    required this.monday,
    required this.best,
    required this.worst,
  });

  final List<DayScore> days;
  final String today;
  final DateTime monday;
  final String? best, worst;

  static const _short = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final byDate = {for (final d in days) d.date: d};
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = dateKey(monday.add(Duration(days: i)));
                  final s = byDate[date];
                  final future = date.compareTo(today) > 0;
                  final has = s != null && s.hasData && !future;
                  final isBest = best == date, isWorst = worst == date;
                  final c = isBest
                      ? const Color(0xFF16A34A)
                      : isWorst
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFF59E0B);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: has
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => IbadahDailyReportPage(date: date),
                            ),
                          )
                        : null,
                    child: Reveal(
                      delay: 200 + i * 80,
                      duration: 800,
                      curve: Curves.easeOutBack,
                      builder: (context, t) => Column(
                        children: [
                          Text(
                            !has
                                ? '–'
                                : s.excused
                                ? 'uzur'
                                : '${(s.fraction * 100 * t.clamp(0.0, 1.0)).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isBest || isWorst ? c : _muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Container(
                              width: 26,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F4),
                                borderRadius: BorderRadius.circular(9),
                                border: date == today
                                    ? Border.all(
                                        color: const Color(0xFFB45309),
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  if (has && !s.excused)
                                    FractionallySizedBox(
                                      heightFactor: (s.fraction * t).clamp(
                                        0.03,
                                        1.0,
                                      ),
                                      widthFactor: 1,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              c,
                                              c.withValues(alpha: 0.55),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ?(has ? qadhaBand(s, maxFill: 0.4) : null),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _short[i],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: date == today
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: date == today
                                  ? const Color(0xFFB45309)
                                  : _muted,
                            ),
                          ),
                          Text(
                            '${monday.add(Duration(days: i)).day}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

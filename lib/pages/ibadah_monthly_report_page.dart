import 'package:flutter/material.dart';

import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_insight.dart';
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
const _line = Color(0xFFF1E4CF);

/// Laporan ibadah satu bulan: skor rata-rata, kalender (ketuk tanggal untuk
/// laporan harinya), kualitas sholat, hari dalam pekan, konsistensi per
/// ibadah, lalu wawasan & rekomendasi. Bisa diunduh sebagai gambar atau PDF.
class IbadahMonthlyReportPage extends StatefulWidget {
  const IbadahMonthlyReportPage({super.key, this.month});

  /// Tanggal mana pun dalam bulan yang dilaporkan (bawaan: bulan ini).
  final DateTime? month;

  @override
  State<IbadahMonthlyReportPage> createState() =>
      _IbadahMonthlyReportPageState();
}

class _IbadahMonthlyReportPageState extends State<IbadahMonthlyReportPage> {
  final _boundary = GlobalKey();
  DateTime? _month;
  Future<MonthlyReport>? _future;
  String _today = '';
  bool _busy = false;
  bool _exporting = false;

  DateTime get _currentMonth {
    final t = parseDateKey(_today);
    return DateTime.utc(t.year, t.month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) {
      final location = UserLocationScope.of(context).location;
      _today = dateKey(
        calc.todayInZone(calc.timezoneFromLongitude(location.long)),
      );
      final base = widget.month ?? parseDateKey(_today);
      _month = DateTime.utc(base.year, base.month, 1);
      _future = _load(_month!);
    }
  }

  Future<MonthlyReport> _load(DateTime month) async {
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    final (from, to) = monthRange(month);
    final (pFrom, pTo) = monthRange(
      DateTime.utc(month.year, month.month - 1, 1),
    );
    return buildMonthlyReport(
      await db.ibadahDao.loadRange(from, to),
      month: month,
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

  void _goto(DateTime month) {
    final m = DateTime.utc(month.year, month.month, 1);
    if (m.isAfter(_currentMonth)) return;
    setState(() {
      _month = m;
      _future = _load(m);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      backgroundColor: reportBackground,
      builder: (_) => _MonthPicker(selected: _month!, last: _currentMonth),
    );
    if (picked != null) _goto(picked);
  }

  Future<void> _export({required bool pdf}) async {
    final title = 'Laporan Ibadah ${monthName(_month!.month)} ${_month!.year}';
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
      final stamp =
          '${_month!.year}-${_month!.month.toString().padLeft(2, '0')}';
      await shareReport(
        context,
        bytes: bytes,
        fileName: 'laporan-ibadah-$stamp.${pdf ? 'pdf' : 'png'}',
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
    final month = _month!;
    final canNext = month.isBefore(_currentMonth);
    return Scaffold(
      backgroundColor: reportBackground,
      body: Column(
        children: [
          const SubHeader(
            title: 'Laporan Bulanan',
            subtitle: 'Ringkasan ibadah sebulan penuh',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Bulan sebelumnya',
                  onPressed: () =>
                      _goto(DateTime.utc(month.year, month.month - 1, 1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickMonth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${monthName(month.month)} ${month.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _stone,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFFB45309),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bulan berikutnya',
                  onPressed: canNext
                      ? () =>
                            _goto(DateTime.utc(month.year, month.month + 1, 1))
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<MonthlyReport>(
              future: _future,
              builder: (context, snap) {
                final r = snap.data;
                if (r == null) {
                  return snap.hasError
                      ? Center(child: Text('Gagal memuat: ${snap.error}'))
                      : const Center(child: CircularProgressIndicator());
                }
                // kunci per tanggal/bulan: isi baru dibangun ulang (animasinya
                // main lagi). Sengaja BUKAN AnimatedSwitcher - saat cross-fade
                // dua RepaintBoundary ber-GlobalKey sama ada bersamaan.
                return SingleChildScrollView(
                  key: ValueKey(r.month),
                  child: RepaintBoundary(
                    key: _boundary,
                    child: ExportMode(
                      exporting: _exporting,
                      child: _MonthlyBody(report: r, today: _today),
                    ),
                  ),
                );
              },
            ),
          ),
          FutureBuilder<MonthlyReport>(
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

/// Pilih bulan: tahun (panah) + 12 bulan; bulan di masa depan nonaktif.
class _MonthPicker extends StatefulWidget {
  const _MonthPicker({required this.selected, required this.last});
  final DateTime selected, last;

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year = widget.selected.year;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
              ),
              IconButton(
                onPressed: _year < widget.last.year
                    ? () => setState(() => _year++)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              for (var m = 1; m <= 12; m++)
                Builder(
                  builder: (context) {
                    final month = DateTime.utc(_year, m, 1);
                    final enabled = !month.isAfter(widget.last);
                    final selected =
                        month.year == widget.selected.year &&
                        month.month == widget.selected.month;
                    return Opacity(
                      opacity: enabled ? 1 : 0.4,
                      child: Material(
                        color: selected
                            ? const Color(0xFFB45309)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: enabled
                              ? () => Navigator.pop(context, month)
                              : null,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? Colors.transparent : _line,
                              ),
                            ),
                            child: Text(
                              monthName(m),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : _stone,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MonthlyBody extends StatelessWidget {
  const _MonthlyBody({required this.report, required this.today});
  final MonthlyReport report;
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
          '${delta > 0 ? '+' : ''}$delta% vs bulan lalu',
          color: delta > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      if (r.tilawahDays > 0)
        HeroChip(Icons.menu_book_rounded, 'Tilawah ${r.tilawahDays} hari'),
    ];

    final byDate = {for (final d in rep.days) d.date: d};
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
              ReportBrand(title: 'Laporan Ibadah Bulanan', subtitle: r.title),
              const SizedBox(height: 14),
              ScoreHero(
                fraction: r.average,
                grade: r.grade,
                title: 'Rata-rata tuntas',
                centerLabel: 'sebulan',
                subtitle: hasData
                    ? '${r.daysWithData} hari tercatat · ${r.fullDays} hari '
                          'tuntas penuh'
                    : 'Belum ada catatan bulan ini',
                chips: chips,
                empty: !hasData,
              ),
              const SizedBox(height: 14),
              Entrance(
                delay: 100,
                child: ReportCard(
                  title: 'KALENDER IBADAH',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MonthHeatmap(
                        month: r.month,
                        today: today,
                        days: byDate,
                        onDayTap: (d) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => IbadahDailyReportPage(date: d.date),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const HeatLegend(),
                      if (!exporting) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk sebuah tanggal untuk laporan hari itu.',
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
                if (rep.weekday.any((w) => w != null)) ...[
                  const SizedBox(height: 14),
                  Entrance(
                    delay: 300,
                    child: ReportCard(
                      title: 'HARI DALAM PEKAN',
                      child: _WeekdayBars(report: r),
                    ),
                  ),
                ],
                if (consistency.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Entrance(
                    delay: 400,
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
                    ? 'Belum ada yang menonjol bulan ini - mulai dari satu '
                          'kebiasaan kecil yang konsisten.'
                    : null,
                delay: 450,
              ),
              if (hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.improve,
                title: 'Perlu ditingkatkan',
                insights: r.improve,
                emptyText: hasData
                    ? 'Tidak ada yang perlu diperbaiki bulan ini - '
                          'Alhamdulillah, pertahankan!'
                    : null,
                delay: 550,
              ),
              if (hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.tip,
                title: 'Rekomendasi bulan depan',
                insights: r.tips,
                delay: 650,
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

class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars({required this.report});
  final MonthlyReport report;

  static const _short = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final r = report;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Reveal(
                delay: 250 + i * 70,
                duration: 800,
                curve: Curves.easeOutBack,
                builder: (context, t) {
                  final v = r.report.weekday[i];
                  final best = r.bestWeekday == i;
                  final worst = r.worstWeekday == i;
                  final c = best
                      ? const Color(0xFF16A34A)
                      : worst
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFF59E0B);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        v == null
                            ? '–'
                            : '${(v * 100 * t.clamp(0.0, 1.0)).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: best || worst ? c : _muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ((v ?? 0) * t).clamp(0.04, 1.0),
                            child: Container(
                              width: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [c, c.withValues(alpha: 0.55)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _short[i],
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/ibadah_insight.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/report_export.dart';
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/report/insight_widgets.dart';
import '../widgets/report/reveal.dart';
import '../widgets/sub_header.dart';

const _stone = Color(0xFF44403C);

/// Laporan ibadah satu hari: skor, sholat lima waktu, rincian, lalu apa yang
/// sudah baik, apa yang perlu ditingkatkan, dan rekomendasinya. Bisa
/// digeser antar-hari, dan diunduh sebagai gambar (PNG) atau PDF.
class IbadahDailyReportPage extends StatefulWidget {
  const IbadahDailyReportPage({super.key, required this.date});

  /// `YYYY-MM-DD`.
  final String date;

  @override
  State<IbadahDailyReportPage> createState() => _IbadahDailyReportPageState();
}

class _IbadahDailyReportPageState extends State<IbadahDailyReportPage> {
  final _boundary = GlobalKey();
  late String _date = widget.date;
  Future<DailyReport>? _future;
  String? _loadedFor;
  String _today = '';
  bool _busy = false;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedFor != _date) {
      _loadedFor = _date;
      _future = _load(_date);
    }
  }

  Future<DailyReport> _load(String date) async {
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    _today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    final from = dateKey(parseDateKey(date).subtract(const Duration(days: 7)));
    final data = await db.ibadahDao.loadRange(from, date);
    return buildDailyReport(
      data,
      date: date,
      today: _today,
      anchors: anchors,
      latitude: location.lat,
      longitude: location.long,
      onTimeMinutes: settings?.onTimeMinutes ?? defaultOnTimeMinutes,
      soloWeight: settings?.effectiveSoloWeight ?? 1,
      male: settings?.gender == Gender.male,
    );
  }

  void _shift(int days) {
    final next = dateKey(parseDateKey(_date).add(Duration(days: days)));
    if (_today.isNotEmpty && next.compareTo(_today) > 0) return;
    setState(() {
      _date = next;
      _loadedFor = next;
      _future = _load(next);
    });
  }

  Future<void> _export({required bool pdf}) async {
    setState(() {
      _busy = true;
      _exporting = true;
    });
    try {
      // satu frame lagi supaya semua animasi sudah di keadaan akhir
      await WidgetsBinding.instance.endOfFrame;
      final image = await captureReport(_boundary);
      if (mounted) setState(() => _exporting = false);
      final bytes = pdf
          ? await reportToPdf(
              image,
              title: 'Laporan Ibadah Harian ${longDate(_date)}',
            )
          : image.png;
      if (!mounted) return;
      await shareReport(
        context,
        bytes: bytes,
        fileName: 'laporan-ibadah-$_date.${pdf ? 'pdf' : 'png'}',
        mimeType: pdf ? 'application/pdf' : 'image/png',
        subject: 'Laporan Ibadah Harian ${longDate(_date)}',
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
    final canNext = _today.isNotEmpty && _date.compareTo(_today) < 0;
    return Scaffold(
      backgroundColor: reportBackground,
      body: Column(
        children: [
          SubHeader(
            title: 'Laporan Harian',
            subtitle: _date == _today ? 'Hari ini' : longDate(_date),
          ),
          _DayNav(
            label: longDate(_date),
            onPrev: () => _shift(-1),
            onNext: canNext ? () => _shift(1) : null,
          ),
          Expanded(
            child: FutureBuilder<DailyReport>(
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
                  key: ValueKey(r.date),
                  padding: EdgeInsets.zero,
                  child: RepaintBoundary(
                    key: _boundary,
                    child: ExportMode(
                      exporting: _exporting,
                      child: _DailyBody(report: r),
                    ),
                  ),
                );
              },
            ),
          ),
          FutureBuilder<DailyReport>(
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

class _DayNav extends StatelessWidget {
  const _DayNav({required this.label, required this.onPrev, this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Hari sebelumnya',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _stone,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Hari berikutnya',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

/// Isi laporan - inilah yang ditangkap menjadi gambar/PDF.
class _DailyBody extends StatelessWidget {
  const _DailyBody({required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final anchors = HijriConfigScope.of(context).config.anchors;
    final hijri = ibadahDay(r.date, anchors).hijri.format();
    final s = r.score;
    final hasData = s.hasData && !r.excused;
    final delta = r.delta;

    final chips = <HeroChip>[
      if (s.total > 0 && !r.excused)
        HeroChip(Icons.task_alt_rounded, '${s.done}/${s.total} ibadah'),
      if (r.streak > 0)
        HeroChip(
          Icons.local_fire_department_rounded,
          '${r.streak} hari terjaga',
          color: const Color(0xFFFFD27A),
        ),
      if (delta != null && delta != 0)
        HeroChip(
          delta > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          '${delta > 0 ? '+' : ''}$delta% vs pekan lalu',
          color: delta > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
    ];

    final sholatDone = r.prayers.where((p) => p.done).length;
    return Container(
      color: reportBackground,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        20 + MediaQuery.paddingOf(context).bottom * 0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportBrand(
                title: 'Laporan Ibadah Harian',
                subtitle: longDate(r.date),
              ),
              const SizedBox(height: 14),
              ScoreHero(
                fraction: r.fraction,
                grade: r.grade,
                title: r.isToday ? 'Hari ini' : 'Laporan hari',
                subtitle: r.excused
                    ? 'Hari berhalangan - sholat & puasa tidak dihitung'
                    : hasData
                    ? '$sholatDone dari ${r.prayers.length} sholat wajib · '
                          '$hijri'
                    : hijri,
                chips: chips,
                empty: !hasData,
              ),
              const SizedBox(height: 14),
              Entrance(
                delay: 100,
                child: ReportCard(
                  title: 'SHOLAT LIMA WAKTU',
                  child: PrayerStrip(prayers: r.prayers),
                ),
              ),
              if (r.categories.any((c) => c.total > 0)) ...[
                const SizedBox(height: 14),
                Entrance(
                  delay: 250,
                  child: ReportCard(
                    title: 'RINCIAN IBADAH',
                    child: CategoryBars(rows: r.categories),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              InsightSection(
                kind: InsightKind.good,
                title: 'Yang sudah baik',
                insights: r.good,
                emptyText: hasData
                    ? 'Belum ada yang menonjol hari ini. Mulai dari satu '
                          'langkah kecil - sholat berikutnya di awal waktu.'
                    : null,
                delay: 350,
              ),
              if (r.good.isNotEmpty || hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.improve,
                title: 'Perlu ditingkatkan',
                insights: r.improve,
                emptyText: hasData
                    ? 'Tidak ada yang perlu diperbaiki dari catatan hari ini. '
                          'Alhamdulillah - pertahankan!'
                    : null,
                delay: 450,
              ),
              if (r.improve.isNotEmpty || hasData) const SizedBox(height: 14),
              InsightSection(
                kind: InsightKind.tip,
                title: 'Rekomendasi untukmu',
                insights: r.tips,
                delay: 550,
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

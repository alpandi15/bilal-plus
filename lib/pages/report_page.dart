import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_report.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/ibadah/jamaah_info.dart';
import '../widgets/ibadah/sholat_log_sheet.dart';
import '../widgets/report/ibadah_heatmap.dart';
import '../widgets/sub_header.dart';
import 'ramadan_recap_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _cream = Color(0xFFFFF1D6);

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

enum _Range {
  month(30, '30 hari'),
  quarter(91, '3 bulan'),
  year(364, '1 tahun');

  const _Range(this.days, this.label);
  final int days;
  final String label;
}

/// Dashboard laporan ibadah: kalender kontribusi semua ibadah harian yang
/// aktif, hari paling rajin, kualitas sholat wajib (awal waktu/terlambat/
/// qadha, masjid/rumah), dan konsistensi per ibadah.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, this.showBack = true});

  /// false saat menjadi tab di navigasi bawah.
  final bool showBack;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  _Range _range = _Range.quarter;
  Stream<IbadahRangeData>? _stream;
  String? _key;

  Stream<IbadahRangeData> _data(AppDatabase db, String from, String to) {
    final key = '$from|$to';
    if (_stream == null || key != _key) {
      _key = key;
      _stream = db
          .customSelect(
            'SELECT 1',
            readsFrom: {
              db.ibadahItems,
              db.ibadahLogs,
              db.dayStatuses,
              db.quranLogs,
            },
          )
          .watch()
          .asyncMap((_) => db.ibadahDao.loadRange(from, to));
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    // mulai hari Senin supaya kolom kalender kontribusi rapi
    final start = parseDateKey(today).subtract(Duration(days: _range.days - 1));
    final from = dateKey(start.subtract(Duration(days: start.weekday - 1)));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Laporan Ibadah',
            subtitle: 'Semua ibadah harian yang aktif',
            showBack: widget.showBack,
          ),
          Expanded(
            child: StreamBuilder<IbadahRangeData>(
              stream: _data(db, from, today),
              builder: (context, snap) {
                final data = snap.data;
                if (data == null || data.from != from) {
                  return const Center(child: CircularProgressIndicator());
                }
                final report = buildIbadahReport(
                  data,
                  anchors: anchors,
                  today: today,
                  latitude: location.lat,
                  longitude: location.long,
                  onTimeMinutes:
                      settings?.onTimeMinutes ?? defaultOnTimeMinutes,
                  soloWeight: settings?.effectiveSoloWeight ?? 1,
                );
                return _ReportBody(
                  report: report,
                  range: _range,
                  onRange: (r) => setState(() => _range = r),
                  showSholat:
                      (settings?.sholatTime ?? false) ||
                      report.sholatTotals != (0, 0, 0) ||
                      report.jamaahTotals != (0, 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.range,
    required this.onRange,
    required this.showSholat,
  });

  final IbadahReport report;
  final _Range range;
  final ValueChanged<_Range> onRange;
  final bool showSholat;

  @override
  Widget build(BuildContext context) {
    final noData = report.counted.isEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_Range>(
                segments: [
                  for (final r in _Range.values)
                    ButtonSegment(value: r, label: Text(r.label)),
                ],
                selected: {range},
                showSelectedIcon: false,
                onSelectionChanged: (v) => onRange(v.first),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Tile(
                    value: '${(report.average * 100).round()}%',
                    label: 'rata-rata tuntas',
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    value: '${report.currentStreak}',
                    unit: ' hari',
                    label: 'streak · terlama ${report.longestStreak}',
                  ),
                  const SizedBox(width: 8),
                  _Tile(value: '${report.fullDays}', label: 'hari tuntas'),
                ],
              ),
              const SizedBox(height: 14),
              _Card(
                title: 'KALENDER IBADAH',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContributionCalendar(days: report.days),
                    const SizedBox(height: 10),
                    const HeatLegend(),
                    if (noData)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Belum ada catatan. Centang ibadah di tab Ibadah - '
                          'kalender ini akan terisi.',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ),
                  ],
                ),
              ),
              if (!noData) ...[
                const SizedBox(height: 14),
                _WeekdayCard(weekday: report.weekday),
              ],
              if (showSholat && !noData) ...[
                const SizedBox(height: 14),
                _SholatQualityCard(stats: report.sholat),
              ],
              if (report.items.isNotEmpty && !noData) ...[
                const SizedBox(height: 14),
                _ItemsCard(items: report.items),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _amber,
                  side: const BorderSide(color: _line),
                  backgroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RamadanRecapPage(),
                  ),
                ),
                icon: const Icon(Icons.nightlight_round),
                label: const Text(
                  'Rekap Ramadan & hutang puasa',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14785624),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xCCB45309),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, this.unit = ''});
  final String value, label, unit;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    ),
  );
}

/// Rata-rata tuntas per hari dalam pekan + kesimpulan paling rajin/bolong.
class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.weekday});
  final List<double?> weekday;

  @override
  Widget build(BuildContext context) {
    final known = [
      for (var i = 0; i < 7; i++)
        if (weekday[i] != null) (i, weekday[i]!),
    ];
    final best = known.isEmpty
        ? null
        : known.reduce((a, b) => b.$2 > a.$2 ? b : a);
    final worst = known.isEmpty
        ? null
        : known.reduce((a, b) => b.$2 < a.$2 ? b : a);
    return _Card(
      title: 'HARI PALING RAJIN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (best != null && worst != null && best.$1 != worst.$1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: _stone),
                  children: [
                    const TextSpan(text: 'Paling rajin hari '),
                    TextSpan(
                      text: _hari[best.$1],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: ', paling sering bolong hari '),
                    TextSpan(
                      text: _hari[worst.$1],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _Bar(
                      value: weekday[i],
                      label: _hari[i].substring(0, 3),
                      highlight: best?.$1 == i,
                      low: worst?.$1 == i && best?.$1 != i,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.label,
    required this.highlight,
    required this.low,
  });
  final double? value;
  final String label;
  final bool highlight, low;

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value == null ? '–' : '${(v * 100).round()}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: highlight ? _amber : _muted,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: v.clamp(0.04, 1),
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: low
                        ? const [Color(0xFFFCA5A5), Color(0xFFFECACA)]
                        : highlight
                        ? const [Color(0xFFD97706), Color(0xFFFBBF24)]
                        : const [Color(0xFFFCD34D), Color(0xFFFDE68A)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    );
  }
}

class _SholatQualityCard extends StatelessWidget {
  const _SholatQualityCard({required this.stats});
  final List<SholatStat> stats;

  @override
  Widget build(BuildContext context) {
    final on = stats.fold<int>(0, (a, s) => a + s.onTime);
    final late = stats.fold<int>(0, (a, s) => a + s.late);
    final qadha = stats.fold<int>(0, (a, s) => a + s.qadha);
    final timed = on + late + qadha;
    final worst = stats
        .where((s) => s.timed > 0)
        .fold<SholatStat?>(
          null,
          (a, s) =>
              a == null ||
                  (s.late + s.qadha) / s.timed > (a.late + a.qadha) / a.timed
              ? s
              : a,
        );
    final masjid = stats.fold<int>(0, (a, s) => a + (s.places['masjid'] ?? 0));
    final placed = stats.fold<int>(
      0,
      (a, s) => a + s.places.values.fold<int>(0, (x, y) => x + y),
    );
    final jamaah = stats.fold<int>(0, (a, s) => a + s.jamaah);
    final withJamaah = stats.fold<int>(0, (a, s) => a + s.jamaah + s.sendiri);

    return _Card(
      title: 'KUALITAS SHOLAT WAJIB',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (timed == 0)
            const Text(
              'Aktifkan "Catat jam & tempat sholat" di Pengaturan, lalu '
              'catat jam sholatmu - di sini akan terlihat berapa yang di '
              'awal waktu.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(on * 100 / timed).round()}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'sholat di awal waktu',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Stacked(onTime: on, late: late, qadha: qadha, height: 12),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                for (final (st, n) in [
                  (SholatStatus.onTime, on),
                  (SholatStatus.late, late),
                  (SholatStatus.qadha, qadha),
                ])
                  Text(
                    '${sholatStatusLabel[st]} $n',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sholatStatusColor[st],
                    ),
                  ),
              ],
            ),
            if (worst != null && worst.late + worst.qadha > 0)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${worst.item.name} paling sering lewat awal waktu '
                  '(${worst.late + worst.qadha} dari ${worst.timed}, rata-rata '
                  '${worst.avgDelay.round()} menit setelah adzan). Yuk, '
                  'siapkan diri sebelum adzan ${worst.item.name}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            for (final s in stats)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        s.item.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Stacked(
                        onTime: s.onTime,
                        late: s.late,
                        qadha: s.qadha,
                        untimed: s.untimed,
                        missed: s.missed,
                        height: 8,
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        s.timed == 0 ? '–' : '±${s.avgDelay.round()} mnt',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Kuning muda: tercentang tanpa jam. Abu-abu: tidak tercatat. '
              'Menit = rata-rata setelah adzan.',
              style: TextStyle(fontSize: 10, color: _muted),
            ),
          ],
          if (placed > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(sholatPlaceIcon['masjid'], size: 16, color: _amber),
                const SizedBox(width: 6),
                Text(
                  '${(masjid * 100 / placed).round()}% di masjid '
                  '($masjid dari $placed sholat)',
                  style: const TextStyle(fontSize: 12, color: _stone),
                ),
              ],
            ),
          ],
          if (withJamaah > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(jamaahIcon(true), size: 16, color: _amber),
                const SizedBox(width: 6),
                Text(
                  "${(jamaah * 100 / withJamaah).round()}% berjama'ah "
                  '($jamaah dari $withJamaah sholat)',
                  style: const TextStyle(fontSize: 12, color: _stone),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stacked extends StatelessWidget {
  const _Stacked({
    required this.onTime,
    required this.late,
    required this.qadha,
    required this.height,
    this.untimed = 0,
    this.missed = 0,
  });
  final int onTime, late, qadha, untimed, missed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final parts = [
      (onTime, sholatStatusColor[SholatStatus.onTime]!),
      (late, sholatStatusColor[SholatStatus.late]!),
      (qadha, sholatStatusColor[SholatStatus.qadha]!),
      (untimed, const Color(0xFFFDE68A)),
      (missed, const Color(0xFFE7E5E4)),
    ].where((p) => p.$1 > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: parts.isEmpty
            ? const ColoredBox(color: Color(0xFFF5F5F4))
            : Row(
                // tanpa stretch, ColoredBox tanpa anak setinggi 0
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (n, c) in parts)
                    Expanded(
                      flex: n,
                      child: ColoredBox(color: c),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});
  final List<ItemStat> items;

  @override
  Widget build(BuildContext context) => _Card(
    title: 'KONSISTENSI PER IBADAH',
    child: Column(
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                    ),
                    Text(
                      '${(s.rate * 100).round()}% · ${s.done}/${s.days} hari',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: s.rate,
                    minHeight: 7,
                    backgroundColor: _cream,
                    valueColor: AlwaysStoppedAnimation(
                      s.rate >= 0.8
                          ? const Color(0xFF16A34A)
                          : s.rate >= 0.4
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

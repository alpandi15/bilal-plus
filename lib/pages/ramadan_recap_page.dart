import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/hijri_calendar.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_report.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_target.dart';
import '../services/ramadan_calendar.dart';
import '../services/ramadan_recap.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/report/ibadah_heatmap.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _cream = Color(0xFFFFF1D6);
const _red = Color(0xFFDC2626);

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class _RecapData {
  const _RecapData({
    required this.summary,
    required this.recap,
    required this.qadha,
    required this.recaps,
    required this.month,
  });

  final RamadanSummary summary;

  /// Rekap terkunci untuk tahun yang dibuka, bila ada.
  final RamadanRecap? recap;
  final QadhaStatus qadha;
  final List<RamadanRecap> recaps;

  /// Skor semua ibadah aktif per tanggal untuk bulan heatmap.
  final Map<String, DayScore> month;
}

/// Rekap Ramadan per tahun hijriah (grid hari puasa, tarawih, tilawah,
/// khatam), hutang puasa qadha, dan heatmap lima waktu per bulan.
class RamadanRecapPage extends StatefulWidget {
  const RamadanRecapPage({super.key, this.hijriYear, this.showBack = true});

  /// false saat menjadi tab "Ramadan" di navigasi bawah.
  final bool showBack;

  /// Tahun yang dibuka pertama kali; null = Ramadan yang sedang/terakhir
  /// berjalan.
  final int? hijriYear;

  @override
  State<RamadanRecapPage> createState() => _RamadanRecapPageState();
}

class _RamadanRecapPageState extends State<RamadanRecapPage> {
  int? _year;
  DateTime? _month; // tanggal 1 bulan heatmap
  Stream<_RecapData>? _stream;
  String? _streamKey;
  bool _lockChecked = false;

  String _today() {
    final location = UserLocationScope.of(context).location;
    return dateKey(calc.todayInZone(calc.timezoneFromLongitude(location.long)));
  }

  /// Ramadan yang sedang berjalan, atau yang terakhir bila belum masuk.
  int _defaultYear(String today, HijriAnchors anchors) {
    final r = relevantRamadan(parseDateKey(today), anchors);
    return dateKey(r.start).compareTo(today) <= 0
        ? r.hijriYear
        : r.hijriYear - 1;
  }

  Stream<_RecapData> _data(
    AppDatabase db,
    HijriAnchors anchors,
    int year,
    DateTime month,
    String today,
  ) {
    final key = '$year|${dateKey(month)}|$today|${anchors.fingerprint}';
    if (_stream == null || key != _streamKey) {
      _streamKey = key;
      final ramadan = ramadanOfYear(year, anchors);
      final monthEnd = DateTime.utc(month.year, month.month + 1, 0);
      _stream = db
          .customSelect(
            'SELECT 1',
            readsFrom: {
              db.ibadahLogs,
              db.dayStatuses,
              db.quranLogs,
              db.quranCycles,
              db.ramadanRecaps,
            },
          )
          .watch()
          .asyncMap(
            (_) async => _RecapData(
              summary: await loadRamadanSummary(db, ramadan, today),
              recap: await db.ibadahDao.recapOf(year),
              qadha: await db.ibadahDao.qadhaStatus(),
              recaps: await db.ibadahDao.watchRecaps().first,
              month: {
                for (final d in buildIbadahReport(
                  await db.ibadahDao.loadRange(
                    dateKey(month),
                    dateKey(monthEnd),
                  ),
                  anchors: anchors,
                  today: today,
                ).days)
                  d.date: d,
              },
            ),
          );
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final today = _today();
    final maxYear = _defaultYear(today, anchors);
    final year = _year ?? widget.hijriYear ?? maxYear;
    final t = parseDateKey(today);
    final month = _month ?? DateTime.utc(t.year, t.month, 1);

    if (!_lockChecked) {
      _lockChecked = true;
      lockFinishedRamadans(db, anchors, today);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Rekap Ramadan',
            showBack: widget.showBack,
            subtitle: 'Puasa, tarawih, tilawah & hutang qadha',
          ),
          Expanded(
            child: StreamBuilder<_RecapData>(
              stream: _data(db, anchors, year, month, today),
              builder: (context, snap) {
                final data = snap.data;
                if (data == null || data.summary.ramadan.hijriYear != year) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _YearHeader(
                            summary: data.summary,
                            onPrev: () => setState(() => _year = year - 1),
                            onNext: year < maxYear
                                ? () => setState(() => _year = year + 1)
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _Stats(summary: data.summary),
                          const SizedBox(height: 14),
                          _RamadanGrid(summary: data.summary),
                          const SizedBox(height: 14),
                          _LockCard(
                            summary: data.summary,
                            recap: data.recap,
                            onLock: () => saveRecapFrom(db, data.summary),
                          ),
                          const SizedBox(height: 22),
                          _QadhaSection(
                            qadha: data.qadha,
                            recaps: data.recaps,
                            dao: db.ibadahDao,
                            currentYear: maxYear,
                          ),
                          const SizedBox(height: 22),
                          _MonthHeatmap(
                            month: month,
                            today: today,
                            days: data.month,
                            onPrev: () => setState(
                              () => _month = DateTime.utc(
                                month.year,
                                month.month - 1,
                                1,
                              ),
                            ),
                            onNext:
                                month.year < t.year ||
                                    (month.year == t.year &&
                                        month.month < t.month)
                                ? () => setState(
                                    () => _month = DateTime.utc(
                                      month.year,
                                      month.month + 1,
                                      1,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
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

/* -------------------------------------------------------------------------- */

BoxDecoration _card({Color color = Colors.white}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: _line),
  boxShadow: const [
    BoxShadow(color: Color(0x14785624), blurRadius: 24, offset: Offset(0, 10)),
  ],
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xCCB45309),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

String _shortDate(DateTime d) =>
    '${d.day} ${_bulan[d.month - 1].substring(0, 3)} ${d.year}';

class _YearHeader extends StatelessWidget {
  const _YearHeader({
    required this.summary,
    required this.onPrev,
    required this.onNext,
  });
  final RamadanSummary summary;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final r = summary.ramadan;
    final last = r.end.subtract(const Duration(days: 1));
    return Row(
      children: [
        IconButton(
          tooltip: 'Tahun sebelumnya',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded, color: _amber),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Ramadan ${r.hijriYear} H',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              Text(
                '${_shortDate(r.start)} – ${_shortDate(last)} · ${r.days} hari'
                '${r.statusLabel.isNotEmpty ? ' · ${r.statusLabel}' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tahun berikutnya',
          onPressed: onNext,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: onNext == null ? _line : _amber,
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});
  final RamadanSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Row(
      children: [
        _Stat(
          label: 'Puasa',
          value: '${s.fastedCount}',
          unit: '/${s.ramadan.days}',
        ),
        const SizedBox(width: 8),
        _Stat(label: 'Tarawih', value: '${s.tarawihCount}', unit: ' malam'),
        const SizedBox(width: 8),
        _Stat(label: 'Tilawah', value: formatPages(s.quranPages), unit: ' hlm'),
        const SizedBox(width: 8),
        _Stat(label: 'Khatam', value: '${s.khatam}', unit: 'x'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});
  final String label, value, unit;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: _card(),
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
                      fontSize: 22,
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
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xCCB45309),
            ),
          ),
        ],
      ),
    ),
  );
}

const _stateColor = {
  RamadanDayState.fasted: _amber,
  RamadanDayState.excused: Color(0xFFD6D3D1),
  RamadanDayState.missed: Colors.white,
  RamadanDayState.today: Colors.white,
  RamadanDayState.upcoming: Color(0xFFFFFAF3),
};

class _RamadanGrid extends StatelessWidget {
  const _RamadanGrid({required this.summary});
  final RamadanSummary summary;

  @override
  Widget build(BuildContext context) {
    final dates = summary.dates;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < dates.length; i++)
                _DayCell(n: i + 1, state: summary.stateOf(dates[i])),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              _Legend(color: _amber, label: 'Puasa'),
              _Legend(color: Color(0xFFD6D3D1), label: 'Berhalangan'),
              _Legend(color: Colors.white, border: _red, label: 'Terlewat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.n, required this.state});
  final int n;
  final RamadanDayState state;

  @override
  Widget build(BuildContext context) {
    final fasted = state == RamadanDayState.fasted;
    return Container(
      decoration: BoxDecoration(
        color: _stateColor[state],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: switch (state) {
            RamadanDayState.missed => _red,
            RamadanDayState.today => _amber,
            RamadanDayState.fasted => _amber,
            _ => _line,
          },
          width: state == RamadanDayState.today ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: fasted
              ? Colors.white
              : state == RamadanDayState.upcoming
              ? const Color(0xFFD6D3D1)
              : _stone,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.border});
  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border ?? color),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
    ],
  );
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.summary,
    required this.recap,
    required this.onLock,
  });
  final RamadanSummary summary;
  final RamadanRecap? recap;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final r = recap;
    final String title;
    final String detail;
    String? action;
    if (r != null && r.manual) {
      title = 'Hutang dicatat manual: ${r.days - r.fasted} hari';
      detail = 'Ubah di bagian Hutang Puasa di bawah.';
    } else if (r != null) {
      title = 'Rekap terkunci · hutang ${r.days - r.fasted} hari';
      detail =
          'Dibekukan supaya perubahan kalender tidak mengubah hutang. '
          'Hitung ulang bila catatannya diperbaiki.';
      action = 'Hitung ulang';
    } else if (!summary.started) {
      title = 'Ramadan belum dimulai';
      detail = 'Catatan puasa & tarawih akan terkumpul di sini.';
    } else if (!summary.finished) {
      title = 'Sedang berjalan';
      detail = summary.owed == 0
          ? 'Belum ada hari yang terlewat. Semoga istiqamah.'
          : '${summary.owed} hari tidak berpuasa sejauh ini '
                '(terhitung hutang).';
    } else if (!summary.hasData) {
      title = 'Tidak ada catatan untuk Ramadan ini';
      detail =
          'Hutang dari tahun sebelum memakai aplikasi bisa dicatat di '
          'bagian Hutang Puasa.';
    } else {
      title = 'Hutang ${summary.owed} hari';
      detail =
          'Dikunci otomatis sesudah suasana Idulfitri, atau kunci '
          'sekarang.';
      action = 'Kunci rekap';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: _card(color: _cream),
      child: Row(
        children: [
          Icon(
            r != null ? Icons.lock_rounded : Icons.hourglass_top_rounded,
            color: _amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _amber),
              onPressed: onLock,
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

class _QadhaSection extends StatelessWidget {
  const _QadhaSection({
    required this.qadha,
    required this.recaps,
    required this.dao,
    required this.currentYear,
  });
  final QadhaStatus qadha;
  final List<RamadanRecap> recaps;
  final IbadahDao dao;
  final int currentYear;

  Future<int?> _askDays(BuildContext context, String title, int initial) {
    final controller = TextEditingController(text: '$initial');
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'hari'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _addManual(BuildContext context) async {
    final used = {for (final r in recaps) r.hijriYear};
    final years = [
      for (var y = currentYear; y > currentYear - 15; y--)
        if (!used.contains(y)) y,
    ];
    final year = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Hutang Ramadan tahun berapa?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
            ),
            for (final y in years)
              ListTile(
                title: Text('Ramadan $y H'),
                onTap: () => Navigator.pop(context, y),
              ),
          ],
        ),
      ),
    );
    if (year == null || !context.mounted) return;
    final days = await _askDays(context, 'Hutang Ramadan $year H', 1);
    if (days == null || days <= 0) return;
    await dao.saveRecap(
      RamadanRecapsCompanion.insert(
        hijriYear: Value(year),
        days: days.clamp(1, 30),
        fasted: 0,
        excused: 0,
        manual: const Value(true),
        lockedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _edit(BuildContext context, RamadanRecap r) async {
    final owed = r.days - r.fasted;
    final days = await _askDays(
      context,
      'Hutang Ramadan ${r.hijriYear} H',
      owed,
    );
    if (days == null) return;
    final value = days.clamp(0, r.manual ? 30 : r.days);
    await dao.saveRecap(
      r.manual
          ? r.toCompanion(true).copyWith(days: Value(value.clamp(1, 30)))
          : r.toCompanion(true).copyWith(fasted: Value(r.days - value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          'HUTANG PUASA',
          trailing: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _amber,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _addManual(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Tahun lalu'),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${qadha.remaining}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: qadha.remaining == 0
                          ? const Color(0xFF16A34A)
                          : _stone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qadha.remaining == 0
                          ? 'hari · tidak ada hutang puasa'
                          : 'hari lagi · ${qadha.paid} dari ${qadha.owed} '
                                'sudah diganti',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
                ],
              ),
              if (qadha.owed > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: qadha.paid / qadha.owed,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF6E7CC),
                    valueColor: const AlwaysStoppedAnimation(_amber),
                  ),
                ),
              ],
              if (recaps.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final r in recaps)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Ramadan ${r.hijriYear} H',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _stone,
                      ),
                    ),
                    subtitle: Text(
                      r.manual
                          ? 'dicatat manual'
                          : 'puasa ${r.fasted}/${r.days} hari',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${r.days - r.fasted} hari',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _stone,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ubah hutang',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _edit(context, r),
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: _muted,
                          ),
                        ),
                        if (r.manual)
                          IconButton(
                            tooltip: 'Hapus',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => dao.deleteRecap(r.hijriYear),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: _muted,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              const Text(
                'Centang "Puasa qadha" di Ibadah Harian setiap kali '
                'mengganti puasa; muncul otomatis selama masih ada hutang.',
                style: TextStyle(fontSize: 11, color: _muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kalender satu bulan untuk SEMUA ibadah harian yang aktif: warna tiap
/// tanggal = persen ibadah yang tuntas (lihat `ibadah_heatmap.dart`).
class _MonthHeatmap extends StatelessWidget {
  const _MonthHeatmap({
    required this.month,
    required this.today,
    required this.days,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final String today;
  final Map<String, DayScore> days;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('IBADAH HARIAN PER BULAN'),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: onPrev,
                    icon: const Icon(Icons.chevron_left_rounded, color: _amber),
                  ),
                  Expanded(
                    child: Text(
                      '${_bulan[month.month - 1]} ${month.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: onNext,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: onNext == null ? _line : _amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              MonthHeatmap(month: month, today: today, days: days),
              const SizedBox(height: 10),
              const HeatLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

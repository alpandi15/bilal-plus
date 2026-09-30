import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../models/prayer_models.dart';
import '../services/hijri_calendar.dart';
import '../services/hijri_config_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/ramadan_calendar.dart';
import '../services/user_location_scope.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', //
  'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _hijriPendek = [
  'Muh', 'Saf', 'R.Awl', 'R.Akh', 'J.Awl', 'J.Akh', //
  'Raj', "Sya'b", 'Ram', 'Syw', "Dzq", 'Dzh',
];

/// Kolom jadwal di tabel imsakiyah, urut.
const _cols = [
  PrayerKey.imsak,
  PrayerKey.fajr,
  PrayerKey.sunrise,
  PrayerKey.dhuhr,
  PrayerKey.asr,
  PrayerKey.maghrib,
  PrayerKey.isha,
];

/// Satu baris tabel: tanggal Masehi, hijriah, dan jadwalnya.
class ImsakiyahRow {
  const ImsakiyahRow(this.date, this.hijri, this.times);
  final DateTime date;
  final HijriDate hijri;
  final calc.DailyPrayerTimes times;
}

/// Jadwal [days] hari mulai [start] di lokasi ([latitude], [longitude]).
List<ImsakiyahRow> imsakiyahRows({
  required DateTime start,
  required int days,
  required double latitude,
  required double longitude,
  required HijriAnchors anchors,
}) => [
  for (var i = 0; i < days; i++)
    () {
      final d = DateTime.utc(start.year, start.month, start.day + i);
      return ImsakiyahRow(
        d,
        anchors.fromGregorian(d),
        calc.calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: d,
        ),
      );
    }(),
];

enum _Mode { ramadan, month }

/// Jadwal imsakiyah: sebulan penuh Ramadan (bawaan) atau per bulan Masehi,
/// imsak sampai isya di lokasi terpilih. Hari ini disorot & langsung
/// digulir ke tengah; tabelnya bisa dibagikan sebagai teks.
class ImsakiyahPage extends StatefulWidget {
  const ImsakiyahPage({super.key});

  @override
  State<ImsakiyahPage> createState() => _ImsakiyahPageState();
}

class _ImsakiyahPageState extends State<ImsakiyahPage> {
  _Mode _mode = _Mode.ramadan;

  /// Bulan Masehi yang dibuka pada mode per bulan.
  DateTime? _month;
  final _scroll = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final location = UserLocationScope.of(context).location;
    final anchors = HijriConfigScope.of(context).config.anchors;
    final tz = calc.timezoneFromLongitude(location.long);
    final today = calc.todayInZone(tz);
    final ramadan = relevantRamadan(today, anchors);
    final month = _month ?? DateTime.utc(today.year, today.month);

    final rows = _mode == _Mode.ramadan
        ? imsakiyahRows(
            start: ramadan.start,
            days: ramadan.days,
            latitude: location.lat,
            longitude: location.long,
            anchors: anchors,
          )
        : imsakiyahRows(
            start: month,
            days: DateTime.utc(month.year, month.month + 1, 0).day,
            latitude: location.lat,
            longitude: location.long,
            anchors: anchors,
          );
    final todayIndex = rows.indexWhere(
      (r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day,
    );
    final title = _mode == _Mode.ramadan
        ? 'Ramadan ${ramadan.hijriYear} H'
        : '${_bulan[month.month - 1]} ${month.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Imsakiyah',
            subtitle: '${location.name} · ${calc.tzLabel[tz]}',
            trailing: IconButton(
              tooltip: 'Bagikan jadwal',
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: _shareText(title, location.name, tz, rows)),
              ),
              icon: const Icon(Icons.share_rounded, color: Color(0xFF92400E)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<_Mode>(
              segments: [
                ButtonSegment(
                  value: _Mode.ramadan,
                  icon: const Icon(Icons.nightlight_round, size: 16),
                  label: Text('Ramadan ${ramadan.hijriYear} H'),
                ),
                const ButtonSegment(
                  value: _Mode.month,
                  icon: Icon(Icons.calendar_month_rounded, size: 16),
                  label: Text('Per bulan'),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
          ),
          _Summary(
            mode: _mode,
            title: title,
            ramadan: ramadan,
            onPrev: () => setState(
              () => _month = DateTime.utc(month.year, month.month - 1),
            ),
            onNext: () => setState(
              () => _month = DateTime.utc(month.year, month.month + 1),
            ),
          ),
          const _HeaderRow(),
          Expanded(
            child: ScrollablePositionedList.builder(
              key: ValueKey('$_mode|$title'),
              itemScrollController: _scroll,
              // hari ini langsung terlihat, sedikit di bawah tepi atas
              initialScrollIndex: todayIndex < 3 ? 0 : todayIndex - 2,
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: rows.length + 1,
              itemBuilder: (context, i) => i == rows.length
                  ? const _Footnote()
                  : _Row(
                      row: rows[i],
                      index: i,
                      ramadan: _mode == _Mode.ramadan,
                      today: i == todayIndex,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _shareText(
    String title,
    String place,
    calc.TimezoneCode tz,
    List<ImsakiyahRow> rows,
  ) {
    final b = StringBuffer()
      ..writeln('Jadwal Imsakiyah $title')
      ..writeln('$place (${calc.tzLabel[tz]}) · Metode Kemenag RI')
      ..writeln()
      ..writeln('Tgl | Imsak Subuh Terbit Dzuhur Ashar Maghrib Isya');
    for (final r in rows) {
      final d = '${r.date.day} ${_bulan[r.date.month - 1].substring(0, 3)}';
      b.writeln('$d | ${[for (final k in _cols) r.times.labels[k]].join(' ')}');
    }
    b
      ..writeln()
      ..writeln('Dibagikan dari Bilal+');
    return b.toString();
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.mode,
    required this.title,
    required this.ramadan,
    required this.onPrev,
    required this.onNext,
  });

  final _Mode mode;
  final String title;
  final RamadanDate ramadan;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final ramadanMode = mode == _Mode.ramadan;
    final start = ramadan.start;
    final last = ramadan.end.subtract(const Duration(days: 1));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ramadanMode
                      ? '${start.day} ${_bulan[start.month - 1]} - '
                            '${last.day} ${_bulan[last.month - 1]} '
                            '${last.year} · ${ramadan.days} hari'
                            '${ramadan.statusLabel.isEmpty ? '' : ' · ${ramadan.statusLabel}'}'
                      : 'Imsak = 10 menit sebelum Subuh',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          if (!ramadanMode) ...[
            IconButton(
              tooltip: 'Bulan sebelumnya',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              onPressed: onNext,
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.nightlight_round,
                color: Color(0xFFF2D38A),
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}

/// Lebar kolom tanggal; sisanya dibagi rata untuk tujuh waktu.
const _dateWidth = 68.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
    child: Row(
      children: [
        const SizedBox(
          width: _dateWidth,
          child: Text('TANGGAL', style: _headStyle),
        ),
        for (final k in _cols)
          Expanded(
            child: Text(
              prayerLabels[k]!.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: _headStyle.copyWith(
                color: k == PrayerKey.imsak || k == PrayerKey.maghrib
                    ? _amber
                    : _muted,
              ),
            ),
          ),
      ],
    ),
  );
}

const _headStyle = TextStyle(
  fontSize: 8,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.3,
  color: _muted,
);

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.index,
    required this.ramadan,
    required this.today,
  });

  final ImsakiyahRow row;
  final int index;
  final bool ramadan;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final d = row.date;
    final friday = d.weekday == DateTime.friday;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: today
            ? const Color(0xFFFFF1D6)
            : index.isEven
            ? Colors.white
            : const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: today ? const Color(0xFFF59E0B) : _line,
          width: today ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _dateWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ramadan
                      ? '${row.hijri.day} Ramadan'
                      : '${d.day} ${_bulan[d.month - 1].substring(0, 3)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: today ? _amber : _stone,
                  ),
                ),
                Text(
                  ramadan
                      ? '${_hari[d.weekday - 1]}, ${d.day} '
                            '${_bulan[d.month - 1].substring(0, 3)}'
                      : '${_hari[d.weekday - 1]} · ${row.hijri.day} '
                            '${_hijriPendek[row.hijri.month - 1]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: friday ? _emerald : _muted,
                    fontWeight: friday ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          for (final k in _cols)
            Expanded(
              child: Text(
                row.times.labels[k]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: k == PrayerKey.imsak || k == PrayerKey.maghrib
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: k == PrayerKey.imsak || k == PrayerKey.maghrib
                      ? _amber
                      : _stone,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
    child: Text(
      'Metode Kemenag RI (Subuh 20°, Isya 18°) dengan ihtiyath 2 menit. '
      'Imsak 10 menit sebelum Subuh; Maghrib = waktu berbuka. Tanggal '
      'Ramadan mengikuti pilihan kalender hijriah di Pengaturan.',
      style: TextStyle(fontSize: 11, height: 1.5, color: _muted),
    ),
  );
}

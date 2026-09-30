import 'package:flutter/material.dart';

import '../models/prayer_models.dart';
import '../services/hijri_calendar.dart';
import '../services/hijri_config.dart';
import '../services/hijri_config_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../widgets/hijri_settings_sheet.dart';
import '../widgets/sub_header.dart';

const _bulanMasehi = [
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

// Minggu di kolom pertama, seperti kalender dinding Indonesia pada umumnya
const _namaHari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
const _namaHariPanjang = [
  'Minggu',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _merah = Color(0xFFDC2626);

/// Kalender hijriah bulanan, Muharram sampai Dzulhijjah: grid per bulan
/// hijriah dengan tanggal Masehi sebagai angka kecil di tiap sel, deretan 12
/// bulan untuk melompat, dan pengatur tahun. Mode kedua ("Masehi")
/// membaliknya: grid per bulan Masehi dengan hijriah sebagai angka kecil.
/// Tanggalnya mengikuti konfigurasi jangkar (`hijri_config.json`) - bulan
/// yang belum punya jangkar ditandai sebagai perkiraan.
class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key});

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

enum _ViewMode { hijri, masehi }

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  _ViewMode _mode = _ViewMode.hijri;

  // kursor mode Masehi: tanggal 1 bulan yang ditampilkan
  late DateTime _cursor;

  // kursor mode hijriah: (tahun, bulan); diisi saat build pertama karena
  // butuh jangkar untuk tahu bulan hijriah hari ini
  int? _hy, _hm;

  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cursor = DateTime.utc(now.year, now.month, 1);
  }

  void _shift(int months) {
    setState(() {
      _cursor = DateTime.utc(_cursor.year, _cursor.month + months, 1);
    });
  }

  void _shiftHijri(int months) {
    setState(() {
      var y = _hy!, m = _hm! + months;
      while (m > 12) {
        m -= 12;
        y++;
      }
      while (m < 1) {
        m += 12;
        y--;
      }
      _hy = y;
      _hm = m;
    });
  }

  void _jumpHijri(int year, int month) => setState(() {
    _hy = year;
    _hm = month;
  });

  Future<void> _refresh(HijriConfigController controller) async {
    setState(() => _refreshing = true);
    final ok = await controller.refreshFromRemote();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Konfigurasi kalender diperbarui dari server'
              : 'Tidak bisa mengunduh - memakai konfigurasi tersimpan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = HijriConfigScope.of(context);
    final config = controller.config;
    final anchors = config.anchors;
    final location = UserLocationScope.of(context).location;

    final now = DateTime.now();
    final schedule = calc.calculatePrayerTimes(
      latitude: location.lat,
      longitude: location.long,
    );
    final maghrib = schedule.times[PrayerKey.maghrib]!;
    final todayJdn = gregorianToJdn(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
    );
    final hijriNow = anchors.current(
      now: now,
      todayInZone: schedule.date,
      maghribToday: maghrib,
    );
    final afterMaghrib = !now.isBefore(maghrib);

    // bulan hijriah hari ini (siang - grid memakai pemetaan siang hari)
    final hijriToday = anchors.fromJdn(todayJdn);
    _hy ??= hijriToday.year;
    _hm ??= hijriToday.month;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Kalender Hijriah',
            subtitle: hijriNow.format(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Metode & penyesuaian tanggal',
                  onPressed: () => showHijriSettingsSheet(context),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF92400E),
                  ),
                ),
                IconButton(
                  tooltip: 'Perbarui dari server',
                  onPressed: _refreshing ? null : () => _refresh(controller),
                  icon: _refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFF92400E),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
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
                      _TodayCard(
                        hijri: hijriNow,
                        gregorian: schedule.date,
                        maghribLabel:
                            '${schedule.labels[PrayerKey.maghrib]} ${calc.tzLabel[schedule.timezone]}',
                        afterMaghrib: afterMaghrib,
                        locationName: location.name,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SegmentedButton<_ViewMode>(
                          segments: const [
                            ButtonSegment(
                              value: _ViewMode.hijri,
                              label: Text('Hijriah'),
                              icon: Icon(Icons.nightlight_round, size: 14),
                            ),
                            ButtonSegment(
                              value: _ViewMode.masehi,
                              label: Text('Masehi'),
                              icon: Icon(Icons.wb_sunny_rounded, size: 14),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (v) =>
                              setState(() => _mode = v.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStateProperty.all(
                              const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_mode == _ViewMode.hijri) ...[
                        _HijriMonthGrid(
                          year: _hy!,
                          month: _hm!,
                          anchors: anchors,
                          todayJdn: todayJdn,
                          onPrev: () => _shiftHijri(-1),
                          onNext: () => _shiftHijri(1),
                          onPick: () async {
                            final picked = await _pickHijriMonth(
                              context,
                              year: _hy!,
                              month: _hm!,
                              current: (hijriToday.year, hijriToday.month),
                            );
                            if (picked != null) {
                              _jumpHijri(picked.$1, picked.$2);
                            }
                          },
                          onToday:
                              _hy == hijriToday.year && _hm == hijriToday.month
                              ? null
                              : () => _jumpHijri(
                                  hijriToday.year,
                                  hijriToday.month,
                                ),
                        ),
                        const SizedBox(height: 16),
                        _HijriEventList(
                          year: _hy!,
                          month: _hm!,
                          anchors: anchors,
                        ),
                      ] else ...[
                        _MonthGrid(
                          cursor: _cursor,
                          anchors: anchors,
                          todayJdn: todayJdn,
                          onPrev: () => _shift(-1),
                          onNext: () => _shift(1),
                          onToday:
                              _cursor.year == now.year &&
                                  _cursor.month == now.month
                              ? null
                              : () => setState(
                                  () => _cursor = DateTime.utc(
                                    now.year,
                                    now.month,
                                    1,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        _EventList(cursor: _cursor, anchors: anchors),
                      ],
                      const SizedBox(height: 16),
                      _ConfigInfo(config: config),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.hijri,
    required this.gregorian,
    required this.maghribLabel,
    required this.afterMaghrib,
    required this.locationName,
  });

  final HijriDate hijri;
  final DateTime gregorian;
  final String maghribLabel;
  final bool afterMaghrib;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final events = eventsOn(hijri);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5EB), Color(0xFFFFE8CF), Color(0xFFFFDCBB)],
        ),
        border: Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F785624),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARI INI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: _amber,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hijri.format(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _stone,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_namaHariPanjang[gregorian.weekday % 7]}, ${gregorian.day} '
            '${_bulanMasehi[gregorian.month - 1]} ${gregorian.year}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          if (afterMaghrib) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0x1A92400E),
              ),
              child: Text(
                'Sudah Maghrib · masuk malam ${hijri.day} ${hijri.monthName}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
          if (events.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final e in events) _EventChip(e.name)],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x2692400E)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.nightlight_round, size: 13, color: _muted),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tanggal hijriah berganti saat Maghrib ($maghribLabel, '
                  '$locationName).'
                  '${hijri.estimated ? ' Bulan ini belum ada ketetapan resmi, tanggalnya hasil perhitungan.' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

/* -------------------------------------------------------------------------- */

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cursor,
    required this.anchors,
    required this.todayJdn,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime cursor;
  final HijriAnchors anchors;
  final int todayJdn;
  final VoidCallback onPrev, onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final y = cursor.year, m = cursor.month;
    final daysInMonth = DateTime.utc(y, m + 1, 0).day;
    final firstJdn = gregorianToJdn(y, m, 1);
    final leading = DateTime.utc(y, m, 1).weekday % 7; // Minggu = 0

    // bulan hijriah yang terlewati dalam bulan Masehi ini, untuk judul
    final hFirst = anchors.fromJdn(firstJdn);
    final hLast = anchors.fromJdn(firstJdn + daysInMonth - 1);
    final hijriTitle = hFirst.month == hLast.month
        ? '${hFirst.monthName} ${hFirst.year} H'
        : hFirst.year == hLast.year
        ? '${hFirst.monthName} – ${hLast.monthName} ${hFirst.year} H'
        : '${hFirst.monthName} ${hFirst.year} – ${hLast.monthName} ${hLast.year} H';

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          hijri: anchors.fromJdn(firstJdn + d - 1),
          isToday: firstJdn + d - 1 == todayJdn,
          isSunday: (leading + d - 1) % 7 == 0,
          isFriday: (leading + d - 1) % 7 == 5,
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCFDE9C8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14785624),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_bulanMasehi[m - 1]} $y',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _stone,
                      ),
                    ),
                    Text(
                      hijriTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _amber,
                      ),
                    ),
                  ],
                ),
              ),
              _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          _MonthBadges(estimated: false, onToday: onToday),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _namaHari[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: i == 0 ? _merah : _muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            // tanpa padding eksplisit GridView menambahkan inset status bar
            // (MediaQuery) di atasnya - tampak seperti baris kosong
            padding: EdgeInsets.zero,
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
          const SizedBox(height: 10),
          const _Legend(),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF7E8),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: const Color(0xFF92400E)),
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hijri,
    required this.isToday,
    required this.isSunday,
    required this.isFriday,
  });

  final int day;
  final HijriDate hijri;
  final bool isToday, isSunday, isFriday;

  @override
  Widget build(BuildContext context) {
    final events = eventsOn(hijri);
    final firstOfHijriMonth = hijri.day == 1;
    final hasEvent = events.isNotEmpty;

    final dayColor = isToday
        ? Colors.white
        : isSunday
        ? _merah
        : _stone;
    final hijriColor = isToday
        ? Colors.white.withOpacity(0.9)
        : hijri.estimated
        ? const Color(0xFFA8A29E)
        : _amber;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isToday
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              )
            : null,
        color: isToday
            ? null
            : hasEvent
            ? const Color(0xFFFFF1DB)
            : isFriday
            ? const Color(0xFFF0FDF4)
            : null,
        border: firstOfHijriMonth && !isToday
            ? Border.all(color: const Color(0xFFFCD34D))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1,
              color: dayColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            firstOfHijriMonth
                ? '1 ${_singkat(hijri.monthName)}'
                : '${hijri.estimated ? '≈' : ''}${hijri.day}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: firstOfHijriMonth ? FontWeight.bold : FontWeight.w600,
              height: 1,
              color: hijriColor,
            ),
          ),
          if (hasEvent) ...[
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? Colors.white : const Color(0xFFEA580C),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _singkat(String bulan) {
    // "Rabiul Akhir" -> "Rab. Akhir", "Ramadan" -> "Ramadan"
    final parts = bulan.split(' ');
    if (parts.length == 1)
      return bulan.length > 7 ? '${bulan.substring(0, 6)}.' : bulan;
    return '${parts.first.substring(0, 3)}. ${parts.last}';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({this.showFirstOfMonth = true});

  /// Penanda "awal bulan hijriah" hanya bermakna di mode Masehi - di mode
  /// hijriah tanggal 1 selalu sel pertama.
  final bool showFirstOfMonth;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        if (showFirstOfMonth)
          item(
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
            ),
            'awal bulan hijriah',
          ),
        item(
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEA580C),
            ),
          ),
          'hari penting',
        ),
        item(
          const Text(
            '≈',
            style: TextStyle(fontSize: 11, color: Color(0xFFA8A29E)),
          ),
          'perkiraan (belum ada ketetapan)',
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  Mode hijriah: grid per bulan Muharram .. Dzulhijjah                        */
/* -------------------------------------------------------------------------- */

const _bulanMasehiSingkat = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

class _HijriMonthGrid extends StatelessWidget {
  const _HijriMonthGrid({
    required this.year,
    required this.month,
    required this.anchors,
    required this.todayJdn,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.onToday,
  });

  final int year, month;
  final HijriAnchors anchors;
  final int todayJdn;
  final VoidCallback onPrev, onNext, onPick;

  /// Kembali ke bulan ini; null bila sudah di bulan ini.
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final firstJdn = anchors.firstDayJdn(year, month);
    final days = anchors.daysInMonth(year, month);
    final estimated = !anchors.has(year, month);
    // JDN 0 jatuh pada Senin, jadi (jdn + 1) % 7 -> 0 = Minggu
    final leading = (firstJdn + 1) % 7;

    final (gy1, gm1, gd1) = jdnToGregorian(firstJdn);
    final (gy2, gm2, gd2) = jdnToGregorian(firstJdn + days - 1);
    final rentang = gy1 == gy2 && gm1 == gm2
        ? '$gd1 – $gd2 ${_bulanMasehi[gm1 - 1]} $gy1'
        : gy1 == gy2
        ? '$gd1 ${_bulanMasehiSingkat[gm1 - 1]} – $gd2 ${_bulanMasehiSingkat[gm2 - 1]} $gy1'
        : '$gd1 ${_bulanMasehiSingkat[gm1 - 1]} $gy1 – $gd2 ${_bulanMasehiSingkat[gm2 - 1]} $gy2';

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        Builder(
          builder: (context) {
            final jdn = firstJdn + d - 1;
            final (gy, gm, gd) = jdnToGregorian(jdn);
            // tanggal Masehi ditulis lengkap ("14 Sep") di hari pertama dan
            // tiap ganti bulan Masehi; selebihnya cukup angka harinya
            final gantiBulan = d == 1 || gd == 1;
            return _HijriDayCell(
              day: d,
              hijri: HijriDate(year, month, d, estimated: estimated),
              gregorian: gantiBulan
                  ? '$gd ${_bulanMasehiSingkat[gm - 1]}'
                  : '$gd',
              isToday: jdn == todayJdn,
              isSunday: (leading + d - 1) % 7 == 0,
              isFriday: (leading + d - 1) % 7 == 5,
            );
          },
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCFDE9C8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14785624),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPick,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                '${hijriMonthNames[month - 1]} $year H',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _stone,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: _amber,
                            ),
                          ],
                        ),
                        Text(
                          '$days hari · $rentang',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          _MonthBadges(estimated: estimated, onToday: onToday),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _namaHari[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: i == 0 ? _merah : _muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            // tanpa padding eksplisit GridView menambahkan inset status bar
            // (MediaQuery) di atasnya - tampak seperti baris kosong
            padding: EdgeInsets.zero,
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
          const SizedBox(height: 10),
          const _Legend(showFirstOfMonth: false),
        ],
      ),
    );
  }
}

/// Baris kecil di bawah judul bulan: penanda "perkiraan" & tombol kembali
/// ke bulan ini. Kosong bila keduanya tidak perlu.
class _MonthBadges extends StatelessWidget {
  const _MonthBadges({required this.estimated, required this.onToday});
  final bool estimated;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    if (!estimated && onToday == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (estimated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFF5F5F4),
              ),
              child: const Text(
                '≈ perkiraan, belum ada ketetapan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
          if (onToday != null)
            Material(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onToday,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today_rounded, size: 13, color: _amber),
                      SizedBox(width: 4),
                      Text(
                        'Bulan ini',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lembar pemilih bulan hijriah: tahun (panah kiri/kanan) + 12 bulan.
Future<(int, int)?> _pickHijriMonth(
  BuildContext context, {
  required int year,
  required int month,
  required (int, int) current,
}) => showModalBottomSheet<(int, int)>(
  context: context,
  backgroundColor: const Color(0xFFFFFAF3),
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    var y = year;
    return StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => setSheet(() => y--),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '$y H',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                  ),
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => setSheet(() => y++),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                        final selected = y == year && m == month;
                        final isNow = (y, m) == current;
                        return Material(
                          color: selected
                              ? const Color(0xFFEA580C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, (y, m)),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : isNow
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xCCFDE9C8),
                                  width: isNow && !selected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$m',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white70
                                          : const Color(0xFFA8A29E),
                                    ),
                                  ),
                                  Text(
                                    hijriMonthNames[m - 1],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : _stone,
                                    ),
                                  ),
                                ],
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
      ),
    );
  },
);

/// Sel mode hijriah: tanggal hijriah besar, tanggal Masehi kecil.
class _HijriDayCell extends StatelessWidget {
  const _HijriDayCell({
    required this.day,
    required this.hijri,
    required this.gregorian,
    required this.isToday,
    required this.isSunday,
    required this.isFriday,
  });

  final int day;
  final HijriDate hijri;
  final String gregorian;
  final bool isToday, isSunday, isFriday;

  @override
  Widget build(BuildContext context) {
    final hasEvent = eventsOn(hijri).isNotEmpty;
    final dayColor = isToday
        ? Colors.white
        : isSunday
        ? _merah
        : _stone;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isToday
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              )
            : null,
        color: isToday
            ? null
            : hasEvent
            ? const Color(0xFFFFF1DB)
            : isFriday
            ? const Color(0xFFF0FDF4)
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1,
              color: dayColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            gregorian,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1,
              color: isToday
                  ? Colors.white.withOpacity(0.9)
                  : const Color(0xFFA8A29E),
            ),
          ),
          if (hasEvent) ...[
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? Colors.white : const Color(0xFFEA580C),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HijriEventList extends StatelessWidget {
  const _HijriEventList({
    required this.year,
    required this.month,
    required this.anchors,
  });
  final int year, month;
  final HijriAnchors anchors;

  @override
  Widget build(BuildContext context) {
    final firstJdn = anchors.firstDayJdn(year, month);
    final estimated = !anchors.has(year, month);
    final rows = <(HijriDate, String, HijriEvent)>[];
    for (final e in hijriEvents) {
      if (e.month != month) continue;
      final h = HijriDate(year, month, e.day, estimated: estimated);
      final (gy, gm, gd) = jdnToGregorian(firstJdn + e.day - 1);
      rows.add((h, '$gd ${_bulanMasehi[gm - 1]} $gy', e));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xCCFDE9C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARI PENTING BULAN INI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: _amber,
            ),
          ),
          const SizedBox(height: 6),
          for (final (h, masehi, e) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFF1DB),
                    ),
                    child: Text(
                      '${h.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _stone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _stone,
                          ),
                        ),
                        Text(
                          '$masehi${estimated ? ' · perkiraan' : ''}',
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
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

/* -------------------------------------------------------------------------- */

class _EventList extends StatelessWidget {
  const _EventList({required this.cursor, required this.anchors});
  final DateTime cursor;
  final HijriAnchors anchors;

  @override
  Widget build(BuildContext context) {
    final y = cursor.year, m = cursor.month;
    final daysInMonth = DateTime.utc(y, m + 1, 0).day;
    final firstJdn = gregorianToJdn(y, m, 1);

    final rows = <(int, HijriDate, HijriEvent)>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final h = anchors.fromJdn(firstJdn + d - 1);
      for (final e in eventsOn(h)) {
        rows.add((d, h, e));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xCCFDE9C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARI PENTING BULAN INI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: _amber,
            ),
          ),
          const SizedBox(height: 6),
          for (final (d, h, e) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFF1DB),
                    ),
                    child: Text(
                      '$d',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _stone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _stone,
                          ),
                        ),
                        Text(
                          '${h.format()}${h.estimated ? ' · perkiraan' : ''}',
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
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

/* -------------------------------------------------------------------------- */

class _ConfigInfo extends StatelessWidget {
  const _ConfigInfo({required this.config});
  final HijriConfig config;

  @override
  Widget build(BuildContext context) {
    final asal = switch (config.origin) {
      'remote' => 'dari server',
      'cache' => 'data tersimpan',
      'bundle' => 'data bawaan',
      _ => 'belum dimuat',
    };
    final u = DateTime.tryParse(config.updatedAt);
    final updated = u == null
        ? (config.updatedAt.isEmpty ? null : config.updatedAt)
        : '${u.day} ${_bulanMasehiSingkat[u.month - 1]} ${u.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xCCFDE9C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: _amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mengikuti ${config.currentMethod?.label ?? 'Pemerintah'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _stone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${config.anchors.length} bulan sudah ditetapkan · $asal'
            '${updated != null ? ' · diperbarui $updated' : ''}',
            style: const TextStyle(fontSize: 11, color: _muted, height: 1.4),
          ),
          if (config.source.isNotEmpty || config.warnings.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                visualDensity: VisualDensity.compact,
                dense: true,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: const Text(
                  'Detail teknis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amber,
                  ),
                ),
                children: [
                  if (config.source.isNotEmpty)
                    Text(
                      'Sumber: ${config.source}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                  for (final w in config.warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $w',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _muted,
                          height: 1.4,
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
}

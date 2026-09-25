import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../models/prayer_models.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../services/ramadan_recap.dart';
import '../widgets/ibadah/ibadah_manage_sheet.dart';
import '../widgets/ibadah/ramadan_notice_cards.dart';
import '../widgets/quran/progress_ring.dart';
import '../widgets/sub_header.dart';
import 'quran_tracker_page.dart';
import 'ramadan_recap_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _cream = Color(0xFFFFF1D6);
const _green = Color(0xFF16A34A);

/// Rentang ringkasan untuk streak: cukup panjang untuk streak setahun.
const _summaryDays = 400;

/// Waktu sholat untuk tiap item lima waktu.
const _prayerOfItem = {
  'subuh': PrayerKey.fajr,
  'dzuhur': PrayerKey.dhuhr,
  'ashar': PrayerKey.asr,
  'maghrib': PrayerKey.maghrib,
  'isya': PrayerKey.isha,
};

const _hariPanjang = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Checklist ibadah harian. Item yang tampil mengikuti hari itu - lima
/// waktu setiap hari, puasa/sahur/tarawih hanya di Ramadan (tarawih pada
/// MALAM-nya), puasa sunnah pada hari yang disarankan - dan semuanya
/// diturunkan dari kalender hijriah yang berlaku, jadi otomatis ikut bila
/// awal Ramadan bergeser.
class IbadahPage extends StatefulWidget {
  const IbadahPage({super.key});

  @override
  State<IbadahPage> createState() => _IbadahPageState();
}

class _IbadahPageState extends State<IbadahPage> {
  String? _date; // tanggal yang dibuka; null = hari ini
  Stream<IbadahDayData>? _stream;
  String? _streamKey;
  bool _lockChecked = false;

  String _today() {
    final location = UserLocationScope.of(context).location;
    return dateKey(calc.todayInZone(calc.timezoneFromLongitude(location.long)));
  }

  Stream<IbadahDayData> _dayStream(IbadahDao dao, String date, String today) {
    final key = '$date|$today';
    if (_stream == null || key != _streamKey) {
      _streamKey = key;
      _stream = dao.watchDay(
        date,
        summariesFrom: dateKey(
          parseDateKey(today).subtract(const Duration(days: _summaryDays)),
        ),
        summariesTo: today,
      );
    }
    return _stream!;
  }

  void _go(String date) => setState(() => _date = date);

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).ibadahDao;
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final today = _today();
    final date = _date ?? today;
    final day = ibadahDay(date, anchors);

    // Ramadan yang suasana Idulfitrinya sudah lewat dikunci rekapnya, supaya
    // hutang qadha (dan item "Puasa qadha") langsung tersedia
    if (!_lockChecked) {
      _lockChecked = true;
      lockFinishedRamadans(AppDatabaseScope.of(context), anchors, today);
    }

    final schedule = calc.calculatePrayerTimes(
      latitude: location.lat,
      longitude: location.long,
      date: parseDateKey(date),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Ibadah Harian',
            subtitle: day.isRamadan
                ? 'Ramadan hari ke-${day.ramadanDay} · ${day.hijri.format()}'
                : day.hijri.format(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Rekap Ramadan',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RamadanRecapPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF92400E),
                  ),
                ),
                IconButton(
                  tooltip: 'Atur daftar ibadah',
                  onPressed: () => showIbadahManageSheet(context),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<IbadahDayData>(
              stream: _dayStream(dao, date, today),
              builder: (context, snap) {
                final data = snap.data;
                if (data == null || data.date != date) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _DayView(
                  data: data,
                  day: day,
                  today: today,
                  schedule: schedule,
                  onGo: _go,
                  dao: dao,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.data,
    required this.day,
    required this.today,
    required this.schedule,
    required this.onGo,
    required this.dao,
  });

  final IbadahDayData data;
  final IbadahDay day;
  final String today;
  final calc.DailyPrayerTimes schedule;
  final ValueChanged<String> onGo;
  final IbadahDao dao;

  @override
  Widget build(BuildContext context) {
    final items = visibleItems(
      data.items,
      day,
      data.values,
      qadhaRemaining: data.qadhaRemaining,
    );
    final sholat = [
      for (final i in items)
        if (i.groupKey == sholatWajibGroup) i,
    ];
    final others = [
      for (final i in items)
        if (i.groupKey != sholatWajibGroup) i,
    ];

    // yang gugur saat berhalangan tidak dihitung
    final counted = [
      for (final i in items)
        if (!(data.excused && excusable(i))) i,
    ];
    final done = counted
        .where(
          (i) =>
              itemDone(i, data.values[i.id] ?? 0, hasTilawah: data.hasTilawah),
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RamadanNoticeCards(today: today),
              _WeekStrip(
                date: data.date,
                today: today,
                summaries: data.summaries,
                onTap: onGo,
              ),
              const SizedBox(height: 14),
              _SummaryCard(
                date: data.date,
                today: today,
                day: day,
                done: done,
                total: counted.length,
                streak: ibadahStreak(data.summaries, today),
                excused: data.excused,
                onExcused: (v) => dao.setExcused(data.date, v),
              ),
              const SizedBox(height: 14),
              if (sholat.isNotEmpty) ...[
                _SholatCard(
                  items: sholat,
                  values: data.values,
                  excused: data.excused,
                  schedule: schedule,
                  isToday: data.date == today,
                  onToggle: (item, v) => dao.setValue(data.date, item.id, v),
                ),
                const SizedBox(height: 20),
              ],
              if (others.isNotEmpty) ...[
                const _SectionTitle('IBADAH LAINNYA'),
                for (final item in others)
                  _ItemTile(
                    item: item,
                    value: data.values[item.id] ?? 0,
                    subtitle: _subtitle(item, data),
                    hasTilawah: data.hasTilawah,
                    excused: data.excused && excusable(item),
                    onChanged: (v) => dao.setValue(data.date, item.id, v),
                  ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: _amber),
                onPressed: () => showIbadahManageSheet(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Atur daftar ibadah'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _subtitle(IbadahItem item, IbadahDayData data) {
    if (data.excused && excusable(item)) return 'Gugur karena berhalangan';
    return switch (item.key) {
      'puasa' when day.ramadanDay != null => 'Hari ke-${day.ramadanDay}',
      'tarawih' when day.ramadanNight != null => 'Malam ke-${day.ramadanNight}',
      'puasa_sunnah' => day.sunnahFastReasons.join(' · '),
      qadhaKey => 'Sisa hutang ${data.qadhaRemaining} hari',
      tilawahKey =>
        data.hasTilawah
            ? "Tercatat dari bacaan Al-Qur'an"
            : 'Tercentang otomatis saat mencatat bacaan',
      _ => null,
    };
  }
}

/* -------------------------------------------------------------------------- */

BoxDecoration _cardDecoration({Color color = Colors.white}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: _line),
  boxShadow: const [
    BoxShadow(color: Color(0x14785624), blurRadius: 24, offset: Offset(0, 10)),
  ],
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Color(0xCCB45309),
      ),
    ),
  );
}

/// Tujuh hari (Senin-Minggu) pekan tanggal yang dibuka; tiap hari
/// menunjukkan berapa dari lima waktu yang tercentang. Hari mendatang
/// tidak bisa dibuka.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.date,
    required this.today,
    required this.summaries,
    required this.onTap,
  });

  final String date;
  final String today;
  final Map<String, IbadahDaySummary> summaries;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final d = parseDateKey(date);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final prevWeek = dateKey(d.subtract(const Duration(days: 7)));
    final nextWeek = dateKey(d.add(const Duration(days: 7)));
    final canNext =
        dateKey(monday.add(const Duration(days: 7))).compareTo(today) <= 0;

    return Row(
      children: [
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          onTap: () => onTap(prevWeek),
        ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              dateKey: dateKey(monday.add(Duration(days: i))),
              weekday: i,
              selected: dateKey(monday.add(Duration(days: i))) == date,
              isToday: dateKey(monday.add(Duration(days: i))) == today,
              future:
                  dateKey(monday.add(Duration(days: i))).compareTo(today) > 0,
              summary: summaries[dateKey(monday.add(Duration(days: i)))],
              onTap: onTap,
            ),
          ),
        _NavArrow(
          icon: Icons.chevron_right_rounded,
          onTap: canNext
              ? () => onTap(nextWeek.compareTo(today) > 0 ? today : nextWeek)
              : null,
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    child: IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, color: onTap == null ? _line : _amber),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dateKey,
    required this.weekday,
    required this.selected,
    required this.isToday,
    required this.future,
    required this.summary,
    required this.onTap,
  });

  final String dateKey;
  final int weekday;
  final bool selected, isToday, future;
  final IbadahDaySummary? summary;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final fraction = s == null ? 0.0 : (s.excused ? 1.0 : s.sholat / 5);
    final dayNum = parseDateKey(dateKey).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? _amber : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: future ? null : () => onTap(dateKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  _hariPendek[weekday],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xE6FFFFFF)
                        : future
                        ? _line
                        : _muted,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox.square(
                  dimension: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!future)
                        ProgressRing(value: fraction, size: 30, stroke: 3),
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday || selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : future
                              ? _line
                              : _stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s?.excused == true ? 'uzur' : (isToday ? 'hari ini' : ''),
                  style: TextStyle(
                    fontSize: 8,
                    color: selected ? const Color(0xE6FFFFFF) : _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.date,
    required this.today,
    required this.day,
    required this.done,
    required this.total,
    required this.streak,
    required this.excused,
    required this.onExcused,
  });

  final String date, today;
  final IbadahDay day;
  final int done, total, streak;
  final bool excused;
  final ValueChanged<bool> onExcused;

  @override
  Widget build(BuildContext context) {
    final d = parseDateKey(date);
    final all = total > 0 && done >= total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                value: total == 0 ? 0 : done / total,
                size: 88,
                stroke: 9,
                child: Text(
                  '$done/$total',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date == today
                          ? 'Hari ini'
                          : '${_hariPanjang[d.weekday - 1]}, '
                                '${formatDateKeyShort(date).split(', ').last}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    Text(
                      all
                          ? 'Masyaa Allah, semua tuntas'
                          : '${total - done} ibadah belum tercentang',
                      style: TextStyle(
                        fontSize: 12,
                        color: all ? _green : _muted,
                        fontWeight: all ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        streak > 0
                            ? '🔥 $streak hari terjaga'
                            : 'Mulai streak: lengkapi lima waktu',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _line),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeTrackColor: _amber,
            value: excused,
            onChanged: onExcused,
            title: const Text(
              'Sedang berhalangan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _stone,
              ),
            ),
            subtitle: const Text(
              'Sholat & puasa tidak dihitung, streak tetap terjaga',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lima waktu dalam satu kartu: lingkaran yang bisa diketuk, lengkap dengan
/// jamnya. Pada hari ini, waktu yang sedang berjalan disorot.
class _SholatCard extends StatelessWidget {
  const _SholatCard({
    required this.items,
    required this.values,
    required this.excused,
    required this.schedule,
    required this.isToday,
    required this.onToggle,
  });

  final List<IbadahItem> items;
  final Map<int, int> values;
  final bool excused;
  final calc.DailyPrayerTimes schedule;
  final bool isToday;
  final void Function(IbadahItem, int) onToggle;

  @override
  Widget build(BuildContext context) {
    // waktu sholat yang sedang berjalan: yang terakhir sudah masuk
    String? currentKey;
    if (isToday) {
      final now = DateTime.now();
      for (final i in items) {
        final t = schedule.times[_prayerOfItem[i.key]];
        if (t != null && !now.isBefore(t)) currentKey = i.key;
      }
    }
    final doneCount = items.where((i) => (values[i.id] ?? 0) > 0).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SHOLAT LIMA WAKTU',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xCCB45309),
                ),
              ),
              const Spacer(),
              Text(
                excused ? 'berhalangan' : '$doneCount/${items.length}',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _PrayerDot(
                    name: item.name,
                    time: schedule.labels[_prayerOfItem[item.key]] ?? '',
                    done: (values[item.id] ?? 0) > 0,
                    current: item.key == currentKey,
                    disabled: excused,
                    onTap: () =>
                        onToggle(item, (values[item.id] ?? 0) > 0 ? 0 : 1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerDot extends StatelessWidget {
  const _PrayerDot({
    required this.name,
    required this.time,
    required this.done,
    required this.current,
    required this.disabled,
    required this.onTap,
  });

  final String name, time;
  final bool done, current, disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = disabled
        ? const Color(0xFFF5F5F4)
        : done
        ? _amber
        : Colors.white;
    return Semantics(
      button: true,
      checked: done,
      label: '$name $time',
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: current && !done
                      ? const Color(0xFFF59E0B)
                      : done
                      ? _amber
                      : _line,
                  width: current && !done ? 2.5 : 1.5,
                ),
                boxShadow: done
                    ? const [
                        BoxShadow(
                          color: Color(0x40B45309),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.circle_outlined,
                size: done ? 26 : 10,
                color: done ? Colors.white : const Color(0xFFE7D8BD),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: disabled ? _muted : _stone,
              ),
            ),
            Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.value,
    required this.subtitle,
    required this.hasTilawah,
    required this.excused,
    required this.onChanged,
  });

  final IbadahItem item;
  final int value;
  final String? subtitle;
  final bool hasTilawah, excused;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final done = itemDone(item, value, hasTilawah: hasTilawah);
    final counter = item.kind == IbadahKind.counter;
    final auto = item.key == tilawahKey && hasTilawah;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: excused ? const Color(0xFFFAFAF9) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: done ? const Color(0xFFFCD34D) : _line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: excused || auto
              ? null
              : () => onChanged(counter ? value + 1 : (value > 0 ? 0 : 1)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: excused ? _muted : _stone,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                    ],
                  ),
                ),
                if (item.key == tilawahKey)
                  IconButton(
                    tooltip: "Buka catatan Al-Qur'an",
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QuranTrackerPage(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: _amber,
                    ),
                  ),
                if (counter)
                  _Counter(
                    value: value,
                    target: item.target,
                    enabled: !excused,
                    onChanged: onChanged,
                  )
                else
                  _CheckMark(done: done, disabled: excused),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.done, required this.disabled});
  final bool done, disabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? _amber : Colors.transparent,
        border: Border.all(
          color: disabled ? _line : (done ? _amber : const Color(0xFFE7D8BD)),
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.target,
    required this.enabled,
    required this.onChanged,
  });

  final int value, target;
  final bool enabled;
  final ValueChanged<int> onChanged;

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jumlah'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: '/ $target'),
          onSubmitted: (t) => Navigator.pop(context, int.tryParse(t)),
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
    );
    controller.dispose();
    if (result != null) onChanged(result.clamp(0, 99999));
  }

  @override
  Widget build(BuildContext context) {
    final reached = value >= target;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Kurangi',
          onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => _edit(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '$value/$target',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: reached ? _green : _stone,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Tambah',
          onPressed: enabled ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 18, color: _amber),
        ),
      ],
    );
  }
}

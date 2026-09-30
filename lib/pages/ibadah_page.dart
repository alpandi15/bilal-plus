import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../models/prayer_models.dart';
import '../services/hijri_config_scope.dart';
import '../services/ibadah_day.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../services/app_settings.dart';
import '../services/ramadan_recap.dart';
import '../services/sholat_time.dart';
import '../widgets/ibadah/ibadah_manage_sheet.dart';
import '../widgets/ibadah/ramadan_notice_cards.dart';
import '../widgets/ibadah/jamaah_info.dart';
import '../widgets/ibadah/sholat_log_sheet.dart';
import '../widgets/ibadah/sholat_nudge_card.dart';
import '../widgets/quran/progress_ring.dart';
import '../widgets/sub_header.dart';
import '../services/dzikir.dart';
import 'bilal_tarawih_page.dart';
import 'dzikir_page.dart';
import 'quran_tracker_page.dart';
import 'tasbih_page.dart';
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
  const IbadahPage({super.key, this.showBack = true});

  /// false saat menjadi tab di navigasi bawah.
  final bool showBack;

  @override
  State<IbadahPage> createState() => _IbadahPageState();
}

class _IbadahPageState extends State<IbadahPage> {
  String? _date; // tanggal yang dibuka; null = hari ini
  Stream<IbadahDayData>? _stream;

  /// Data hari terakhir yang tampil - tetap ditampilkan selama data tanggal
  /// baru dimuat (tidak berkedip ke indikator muat), lalu disilangkan.
  IbadahDayData? _shown;

  /// Arah geser saat berganti tanggal: 1 = ke tanggal sesudahnya.
  int _dir = 1;
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

  void _go(String date) => setState(() {
    final current = _date ?? _today();
    if (date == current) return;
    _dir = date.compareTo(current) > 0 ? 1 : -1;
    _date = date;
  });

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
            showBack: widget.showBack,
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
                final fresh = snap.data;
                if (fresh != null && fresh.date == date) _shown = fresh;
                final data = _shown;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    // filter tanggal selalu di atas (tidak ikut tergulir),
                    // langsung menandai tanggal baru walau datanya masih dimuat
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _WeekStrip(
                            date: date,
                            today: today,
                            summaries: data.summaries,
                            onTap: _go,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, animation) {
                          // yang masuk dari arah tujuan, yang keluar ke sisi
                          // sebaliknya
                          final incoming = child.key == ValueKey(data.date);
                          final dx = (incoming ? 1 : -1) * _dir * 0.08;
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: Offset(dx, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _DayView(
                          key: ValueKey(data.date),
                          data: data,
                          day: ibadahDay(data.date, anchors),
                          today: today,
                          schedule: data.date == date
                              ? schedule
                              : calc.calculatePrayerTimes(
                                  latitude: location.lat,
                                  longitude: location.long,
                                  date: parseDateKey(data.date),
                                ),
                          latitude: location.lat,
                          longitude: location.long,
                          onGo: _go,
                          dao: dao,
                        ),
                      ),
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

class _DayView extends StatelessWidget {
  const _DayView({
    super.key,
    required this.data,
    required this.day,
    required this.today,
    required this.schedule,
    required this.latitude,
    required this.longitude,
    required this.onGo,
    required this.dao,
  });

  final IbadahDayData data;
  final IbadahDay day;
  final String today;
  final calc.DailyPrayerTimes schedule;
  final double latitude, longitude;
  final ValueChanged<String> onGo;
  final IbadahDao dao;

  /// Ketuk sholat wajib: bila pencatatan waktu aktif, tanya jam, jama'ah &
  /// tempat; kalau tidak, centang/batalkan langsung (berjama'ah atau sendiri
  /// = pilihan terakhir, bisa diganti lewat pil di bawahnya).
  Future<void> _tapSholat(BuildContext context, IbadahItem item) async {
    final settings = AppSettingsScope.maybeOf(context);
    final value = data.values[item.id] ?? 0;
    final window = sholatWindow(
      item.key,
      parseDateKey(data.date),
      latitude: latitude,
      longitude: longitude,
    );
    if (settings == null || !settings.sholatTime || window == null) {
      await dao.setValue(
        data.date,
        item.id,
        value > 0 ? 0 : 1,
        jamaah: value > 0 ? null : settings?.lastJamaah ?? false,
      );
      return;
    }
    final log = data.logs[item.id];
    final place = log?.place ?? settings.lastPlace;
    final result = await showSholatLogSheet(
      context,
      name: item.name,
      itemKey: item.key,
      date: parseDateKey(data.date),
      window: window,
      tz: calc.timezoneFromLongitude(longitude),
      onTimeMinutes: settings.onTimeMinutes,
      place: place,
      // di masjid hampir selalu berjama'ah
      jamaah: log?.jamaah ?? (place == 'masjid' || settings.lastJamaah),
      soloWeight: settings.effectiveSoloWeight,
      prayedAt: log?.prayedAt,
      done: value > 0,
    );
    switch (result) {
      case SholatLogSave(prayedAt: final at, place: final where, :final jamaah):
        await dao.setValue(
          data.date,
          item.id,
          1,
          prayedAt: at,
          place: where,
          jamaah: jamaah,
        );
        await settings.setLastPlace(where);
        await settings.setLastJamaah(jamaah);
      case SholatLogRemove():
        await dao.setValue(data.date, item.id, 0);
      case null:
        break;
    }
  }

  /// Ganti berjama'ah <-> sendiri pada sholat yang sudah dicentang.
  Future<void> _toggleJamaah(BuildContext context, IbadahItem item) async {
    final settings = AppSettingsScope.maybeOf(context);
    final next = !(data.logs[item.id]?.jamaah ?? false);
    await dao.setValue(data.date, item.id, 1, jamaah: next);
    await settings?.setLastJamaah(next);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
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
    final rawatib = [
      for (final i in items)
        if (i.groupKey == rawatibGroup) i,
    ];
    final others = [
      for (final i in items)
        if (i.groupKey != sholatWajibGroup && i.groupKey != rawatibGroup) i,
    ];

    final progress = ibadahProgress(
      items,
      data.values,
      excused: data.excused,
      hasTilawah: data.hasTilawah,
      logs: data.logs,
      soloWeight: settings?.effectiveSoloWeight ?? 1,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // pesan pengingat di bawah filter tanggal - muncul dengan
              // tinggi yang tumbuh halus, bukan melompat
              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RamadanNoticeCards(today: today),
                    if (data.date == today)
                      SholatNudgeCards(
                        // sholat: lembar catat jam/tempat; puasa: langsung
                        // tercentang
                        onLog: (item) => item.groupKey == sholatWajibGroup
                            ? _tapSholat(context, item)
                            : dao.setValue(data.date, item.id, 1),
                      ),
                  ],
                ),
              ),
              _SummaryCard(
                date: data.date,
                today: today,
                day: day,
                progress: progress,
                streak: ibadahStreak(data.summaries, today),
                excused: data.excused,
                onExcused: (v) => dao.setExcused(data.date, v),
              ),
              const SizedBox(height: 14),
              if (sholat.isNotEmpty) ...[
                _SholatCard(
                  items: sholat,
                  values: data.values,
                  logs: data.logs,
                  excused: data.excused,
                  schedule: schedule,
                  date: parseDateKey(data.date),
                  latitude: latitude,
                  longitude: longitude,
                  isToday: data.date == today,
                  onTap: (item) => _tapSholat(context, item),
                  onToggleJamaah: (item) => _toggleJamaah(context, item),
                  rawatib: rawatib,
                  onToggleRawatib: (item) => dao.setValue(
                    data.date,
                    item.id,
                    (data.values[item.id] ?? 0) > 0 ? 0 : 1,
                  ),
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
      'dzikir_pagi' || 'dzikir_petang' =>
        'Ketuk ikon kitab untuk membaca - tercentang saat selesai',
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
/// Filter tanggal sepekan. Sorotan hari terpilih berupa pil yang bergeser
/// halus ke hari baru; berganti pekan, deretan harinya bersilang pudar.
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

  static const _motion = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final d = parseDateKey(date);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final prevWeek = dateKey(d.subtract(const Duration(days: 7)));
    final nextWeek = dateKey(d.add(const Duration(days: 7)));
    final canNext =
        dateKey(monday.add(const Duration(days: 7))).compareTo(today) <= 0;
    final days = [
      for (var i = 0; i < 7; i++) dateKey(monday.add(Duration(days: i))),
    ];

    return Row(
      children: [
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          onTap: () => onTap(prevWeek),
        ),
        Expanded(
          child: Stack(
            children: [
              // pil hari terpilih - bergeser, bukan berganti seketika
              Positioned.fill(
                child: AnimatedAlign(
                  duration: _motion,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(-1 + 2 * (d.weekday - 1) / 6, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / 7,
                    heightFactor: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _amber,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33B45309),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _motion,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Row(
                  key: ValueKey(days.first),
                  children: [
                    for (final (i, key) in days.indexed)
                      Expanded(
                        child: _DayCell(
                          dateKey: key,
                          weekday: i,
                          selected: key == date,
                          isToday: key == today,
                          future: key.compareTo(today) > 0,
                          summary: summaries[key],
                          onTap: onTap,
                        ),
                      ),
                  ],
                ),
              ),
            ],
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

/// Durasi perpindahan warna teks hari - seirama dengan pil yang bergeser.
const _cellMotion = Duration(milliseconds: 320);

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
        // latar terpilih = pil bergeser di _WeekStrip
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: future ? null : () => onTap(dateKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                AnimatedDefaultTextStyle(
                  duration: _cellMotion,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xE6FFFFFF)
                        : future
                        ? _line
                        : _muted,
                  ),
                  child: Text(_hariPendek[weekday]),
                ),
                const SizedBox(height: 4),
                SizedBox.square(
                  dimension: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!future)
                        ProgressRing(value: fraction, size: 30, stroke: 3),
                      AnimatedDefaultTextStyle(
                        duration: _cellMotion,
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
                        child: Text('$dayNum'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: _cellMotion,
                  style: TextStyle(
                    fontSize: 8,
                    color: selected ? const Color(0xE6FFFFFF) : _muted,
                  ),
                  child: Text(
                    s?.excused == true ? 'uzur' : (isToday ? 'hari ini' : ''),
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
    required this.progress,
    required this.streak,
    required this.excused,
    required this.onExcused,
  });

  final String date, today;
  final IbadahDay day;
  final IbadahProgress progress;
  final int streak;
  final bool excused;
  final ValueChanged<bool> onExcused;

  @override
  Widget build(BuildContext context) {
    final d = parseDateKey(date);
    final done = progress.done, total = progress.total;
    final all = progress.complete;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                value: progress.fraction,
                size: 88,
                stroke: 9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${progress.percent}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    Text(
                      '$done/$total',
                      style: const TextStyle(fontSize: 10, color: _muted),
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
    required this.logs,
    required this.excused,
    required this.schedule,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.isToday,
    required this.onTap,
    this.onToggleJamaah,
    this.rawatib = const [],
    this.onToggleRawatib,
  });

  final List<IbadahItem> items;

  /// Ganti berjama'ah/sendiri pada sholat yang sudah dicentang.
  final void Function(IbadahItem)? onToggleJamaah;

  /// Sholat sunnah rawatib yang aktif - ditampilkan di bawah kolom sholat
  /// wajibnya masing-masing.
  final List<IbadahItem> rawatib;
  final void Function(IbadahItem)? onToggleRawatib;
  final Map<int, int> values;
  final Map<int, IbadahLog> logs;
  final bool excused;
  final calc.DailyPrayerTimes schedule;
  final DateTime date;
  final double latitude, longitude;
  final bool isToday;
  final void Function(IbadahItem) onTap;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final tracking = settings?.sholatTime ?? false;
    final tz = calc.timezoneFromLongitude(longitude);
    SholatStatus? statusOf(IbadahItem i) {
      final at = logs[i.id]?.prayedAt;
      if (!tracking || at == null || (values[i.id] ?? 0) == 0) return null;
      final w = sholatWindow(
        i.key,
        date,
        latitude: latitude,
        longitude: longitude,
      );
      return w == null
          ? null
          : sholatStatus(at, w, onTimeMinutes: settings!.onTimeMinutes);
    }

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
              const Expanded(
                child: Text(
                  'SHOLAT LIMA WAKTU',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xCCB45309),
                  ),
                ),
              ),
              Text(
                excused ? 'berhalangan' : '$doneCount/${items.length}',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: "Berjama'ah atau sendiri?",
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                onPressed: () => showJamaahInfo(
                  context,
                  soloWeight: settings?.effectiveSoloWeight ?? 1,
                  female: settings?.gender == Gender.female,
                ),
                icon: const Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: _amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            // pil jama'ah menambah tinggi kolom - lingkaran tetap sejajar
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Expanded(
                  child: _PrayerDot(
                    name: item.name,
                    time: schedule.labels[_prayerOfItem[item.key]] ?? '',
                    done: (values[item.id] ?? 0) > 0,
                    current: item.key == currentKey,
                    disabled: excused,
                    status: statusOf(item),
                    prayedTime: tracking && logs[item.id]?.prayedAt != null
                        ? calc.formatInZone(
                            logs[item.id]!.prayedAt!.toUtc(),
                            tz,
                          )
                        : null,
                    place: tracking ? logs[item.id]?.place : null,
                    jamaah: logs[item.id]?.jamaah,
                    onTap: () => onTap(item),
                    onToggleJamaah: onToggleJamaah == null
                        ? null
                        : () => onToggleJamaah!(item),
                  ),
                ),
            ],
          ),
          if (rawatib.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: _line),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'SUNNAH RAWATIB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xCCB45309),
                  ),
                ),
                const Spacer(),
                Text(
                  '${rawatib.where((r) => (values[r.id] ?? 0) > 0).length}'
                  '/${rawatib.length}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Expanded(
                    child: Column(
                      children: [
                        // urutan item sudah qabliyah sebelum ba'diyah
                        for (final r in rawatib.where(
                          (r) => rawatibOf(r.key)?.$1 == item.key,
                        ))
                          _RawatibPill(
                            qabliyah: rawatibOf(r.key)!.$2,
                            done: (values[r.id] ?? 0) > 0,
                            disabled: excused,
                            tooltip: r.name,
                            onTap: () => onToggleRawatib?.call(r),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (tracking) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final st in SholatStatus.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sholatStatusColor[st],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sholatStatusLabel[st]!,
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu sholat rawatib di bawah kolom sholat wajibnya: pil kecil
/// "Qabliyah"/"Ba'diyah" yang tercentang dengan sekali ketuk.
class _RawatibPill extends StatelessWidget {
  const _RawatibPill({
    required this.qabliyah,
    required this.done,
    required this.disabled,
    required this.tooltip,
    required this.onTap,
  });

  final bool qabliyah, done, disabled;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        checked: done,
        label: tooltip,
        child: GestureDetector(
          onTap: disabled ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 50, maxWidth: 60),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            decoration: BoxDecoration(
              color: disabled
                  ? const Color(0xFFF5F5F4)
                  : done
                  ? const Color(0xFFFEF3C7)
                  : Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: done ? const Color(0xFFF59E0B) : _line,
                width: done ? 1.5 : 1,
              ),
            ),
            // menyusut (bukan terpotong) pada font besar
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (done)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.check_rounded, size: 11, color: _amber),
                    ),
                  Text(
                    qabliyah ? 'Qabl' : "Ba'd",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? _muted
                          : done
                          ? _amber
                          : _stone,
                    ),
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

class _PrayerDot extends StatelessWidget {
  const _PrayerDot({
    required this.name,
    required this.time,
    required this.done,
    required this.current,
    required this.disabled,
    required this.onTap,
    this.status,
    this.prayedTime,
    this.place,
    this.jamaah,
    this.onToggleJamaah,
  });

  final String name, time;

  /// Berjama'ah / sendiri (null = belum dicatat).
  final bool? jamaah;
  final VoidCallback? onToggleJamaah;
  final bool done, current, disabled;
  final VoidCallback onTap;

  /// Ketepatan waktu (bila pencatatan waktu aktif & jamnya tercatat).
  final SholatStatus? status;
  final String? prayedTime;
  final String? place;

  @override
  Widget build(BuildContext context) {
    final doneColor = status == null ? _amber : sholatStatusColor[status]!;
    final fill = disabled
        ? const Color(0xFFF5F5F4)
        : done
        ? doneColor
        : Colors.white;
    return Semantics(
      button: true,
      checked: done,
      label: [
        '$name $time',
        if (status != null) sholatStatusLabel[status]!,
        if (sholatPlaceLabel[place] case final p?) p,
      ].join(', '),
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
                      ? doneColor
                      : _line,
                  width: current && !done ? 2.5 : 1.5,
                ),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: doneColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
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
            if (done && prayedTime != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sholatPlaceIcon[place] case final icon?)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(icon, size: 10, color: doneColor),
                    ),
                  Text(
                    prayedTime!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: doneColor,
                    ),
                  ),
                ],
              )
            else
              Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
            if (done && !disabled && onToggleJamaah != null)
              JamaahPill(jamaah: jamaah, onTap: onToggleJamaah!),
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
                if (item.key == 'tarawih')
                  IconButton(
                    tooltip: 'Buka bacaan bilal tarawih',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BilalTarawihPage(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.record_voice_over_rounded,
                      size: 20,
                      color: _amber,
                    ),
                  ),
                if (dzikirSession(item.key) case final session?)
                  IconButton(
                    tooltip: 'Buka bacaan ${session.title.toLowerCase()}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DzikirPage(session: session),
                      ),
                    ),
                    icon: const Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: _amber,
                    ),
                  ),
                if (counter && !excused)
                  IconButton(
                    tooltip: 'Hitung layar penuh',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => openTasbih(
                      context,
                      title: item.name,
                      target: item.target,
                      initial: value,
                      onChanged: onChanged,
                    ),
                    icon: const Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
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

import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/app_database_scope.dart';
import '../../models/prayer_models.dart';
import '../../services/app_settings.dart';
import '../../services/hijri_calendar.dart';
import '../../services/hijri_config_scope.dart';
import '../../services/ibadah_day.dart';
import '../../services/ibadah_report.dart';
import '../../services/prayer_calculator.dart' as calc;
import '../../services/sholat_motivation.dart';
import '../../services/sholat_time.dart';
import '../../services/user_location_scope.dart';
import '../../utils/date_key.dart';
import '../entrance_fade.dart';

/// Pesan penyemangat sholat di awal waktu.
class SholatNudge {
  const SholatNudge({
    required this.title,
    required this.message,
    required this.tone,
    this.item,
    this.icon,
  });

  final String title;
  final String message;

  /// Warna kartu (hijau = pujian, amber = pengingat, merah = evaluasi).
  final SholatStatus tone;

  /// Sholat / puasa yang bisa langsung dicatat dari kartu (pengingat).
  final IbadahItem? item;

  /// Ikon kartu (null = sesuai jenisnya).
  final IconData? icon;
}

/// Pengingat puasa Tarwiyah (8 Dzulhijjah) & Arafah (9 Dzulhijjah): pada
/// harinya sampai Maghrib bila puasa sunnah belum dicatat (tombol Catat),
/// atau sore/malam sebelumnya (mulai 15.00) untuk niat & sahur. Null bila
/// bukan waktunya.
SholatNudge? fastNudge({
  required String today,
  required HijriAnchors anchors,
  required DateTime now,
  required DateTime maghribToday,
  required IbadahItem? fastItem,
  required bool fastDone,
  required bool excusedToday,
}) {
  final date = parseDateKey(today);
  final todayFast = dzulhijjahFastOf(anchors.fromGregorian(date));
  if (todayFast != null &&
      fastItem != null &&
      !fastDone &&
      !excusedToday &&
      now.isBefore(maghribToday)) {
    final arafah = todayFast == DzulhijjahFast.arafah;
    return SholatNudge(
      title: 'Hari ini ${todayFast.label} 🌙',
      message: pickMessage(
        fastToday(arafah: arafah),
        dailySeed(today, fastItem.id),
      ),
      tone: SholatStatus.onTime,
      item: fastItem,
      icon: Icons.nightlight_round,
    );
  }
  final tomorrow = dzulhijjahFastOf(
    anchors.fromGregorian(date.add(const Duration(days: 1))),
  );
  if (tomorrow != null && now.hour >= 15) {
    final arafah = tomorrow == DzulhijjahFast.arafah;
    return SholatNudge(
      title: 'Besok ${tomorrow.label} 🌙',
      message: pickMessage(fastEve(arafah: arafah), dailySeed(today, 9)),
      tone: SholatStatus.onTime,
      icon: Icons.nightlight_round,
    );
  }
  return null;
}

/// Pengingat sholat yang sedang berjalan tapi belum dicatat (>= 10 menit
/// sesudah adzan) - atau, bila tidak ada, penyemangat sesudah sholat terakhir
/// hari ini tercatat terlambat/qadha - lalu evaluasi 7 hari terakhir. Pesan
/// bervariasi per hari (lihat sholat_motivation.dart). Kosong bila tidak ada
/// yang perlu disampaikan.
List<SholatNudge> sholatNudges({
  required List<IbadahItem> sholatItems,
  required Map<int, int> todayValues,
  Map<int, DateTime> todayPrayedAt = const {},
  required bool excusedToday,
  required IbadahReport week,
  required DateTime now,
  required String today,
  required double latitude,
  required double longitude,
  required int onTimeMinutes,
  required bool tracking,
}) {
  final tz = calc.timezoneFromLongitude(longitude);
  String hm(DateTime d) => calc.formatInZone(d.toUtc(), tz);
  final nudges = <SholatNudge>[];

  if (!excusedToday) {
    for (final i in sholatItems.reversed) {
      final w = sholatWindow(
        i.key,
        parseDateKey(today),
        latitude: latitude,
        longitude: longitude,
      );
      if (w == null || now.isBefore(w.start) || !now.isBefore(w.end)) {
        continue;
      }
      if ((todayValues[i.id] ?? 0) > 0) break;
      final since = now.difference(w.start).inMinutes;
      if (since < 10) break;
      final onTimeUntil = w.start.add(Duration(minutes: onTimeMinutes));
      nudges.add(
        SholatNudge(
          title: '${i.name} sudah masuk $since menit lalu',
          message: pickMessage(
            now.isBefore(onTimeUntil)
                ? onTimeReminders(i.name, hm(onTimeUntil))
                : lateReminders(i.name, hm(w.end)),
            dailySeed(today, i.id),
          ),
          tone: now.isBefore(onTimeUntil)
              ? SholatStatus.onTime
              : SholatStatus.late,
          item: i,
        ),
      );
      break;
    }

    // tanpa pengingat: sholat terakhir yang dicatat hari ini terlambat/qadha?
    if (tracking && nudges.isEmpty) {
      final done = [
        for (final i in sholatItems)
          if ((todayValues[i.id] ?? 0) > 0 && todayPrayedAt[i.id] != null) i,
      ];
      final last = done.isEmpty ? null : done.last;
      final w = last == null
          ? null
          : sholatWindow(
              last.key,
              parseDateKey(today),
              latitude: latitude,
              longitude: longitude,
            );
      if (last != null && w != null) {
        final at = todayPrayedAt[last.id]!;
        final status = sholatStatus(at, w, onTimeMinutes: onTimeMinutes);
        if (status != SholatStatus.onTime) {
          final after = sholatItems.skip(sholatItems.indexOf(last) + 1);
          final next = after
              .where((i) => (todayValues[i.id] ?? 0) == 0)
              .firstOrNull
              ?.name;
          final late = minutesAfterAdzan(at, w);
          nudges.add(
            SholatNudge(
              title: status == SholatStatus.qadha
                  ? '${last.name} hari ini diqadha'
                  : '${last.name} terlambat $late menit dari adzan',
              message: pickMessage(
                status == SholatStatus.qadha
                    ? qadhaToday(last.name, next)
                    : lateToday(last.name, next),
                dailySeed(today, last.id),
              ),
              tone: status,
            ),
          );
        }
      }
    }
  }

  if (tracking) {
    final timed = week.sholat.where((s) => s.timed > 0).toList();
    final total = timed.fold<int>(0, (a, s) => a + s.timed);
    final onTime = timed.fold<int>(0, (a, s) => a + s.onTime);
    final worst = timed.fold<SholatStat?>(
      null,
      (a, s) => a == null || s.late + s.qadha > a.late + a.qadha ? s : a,
    );
    if (worst != null && worst.late + worst.qadha >= 2) {
      nudges.add(
        SholatNudge(
          title:
              '${worst.item.name} lewat awal waktu '
              '${worst.late + worst.qadha}x dalam 7 hari',
          message: pickMessage(
            worst.qadha > 0
                ? weeklyQadha(worst.item.name, worst.qadha)
                : weeklyLate(worst.item.name, worst.avgDelay.round()),
            dailySeed(today, worst.item.id),
          ),
          tone: worst.qadha > 0 ? SholatStatus.qadha : SholatStatus.late,
        ),
      );
    } else if (total >= 10 && onTime / total >= 0.8) {
      nudges.add(
        SholatNudge(
          title:
              'Masyaa Allah, ${(onTime * 100 / total).round()}% di awal '
              'waktu',
          message: pickMessage(weeklyPraise(onTime, total), dailySeed(today)),
          tone: SholatStatus.onTime,
        ),
      );
    }
  }
  return nudges;
}

/// Kartu-kartu [sholatNudges] untuk hari ini, diperbarui mengikuti basis
/// data. [onLog] dipanggil saat tombol "Catat" pada pengingat diketuk.
class SholatNudgeCards extends StatefulWidget {
  const SholatNudgeCards({super.key, this.onLog});

  final void Function(IbadahItem item)? onLog;

  @override
  State<SholatNudgeCards> createState() => _SholatNudgeCardsState();
}

class _SholatNudgeCardsState extends State<SholatNudgeCards> {
  Stream<IbadahRangeData>? _stream;
  String? _key;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "N menit lalu" & batas awal waktu bergerak mengikuti jam
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Stream<IbadahRangeData> _data(AppDatabase db, String from, String today) {
    final key = '$from|$today';
    if (_stream == null || key != _key) {
      _key = key;
      _stream = db
          .customSelect(
            'SELECT 1',
            readsFrom: {db.ibadahItems, db.ibadahLogs, db.dayStatuses},
          )
          .watch()
          .asyncMap((_) => db.ibadahDao.loadRange(from, today));
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final onLog = widget.onLog;
    final db = AppDatabaseScope.of(context);
    final anchors = HijriConfigScope.of(context).config.anchors;
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    final from = dateKey(parseDateKey(today).subtract(const Duration(days: 6)));

    return StreamBuilder<IbadahRangeData>(
      stream: _data(db, from, today),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final week = buildIbadahReport(
          data,
          anchors: anchors,
          today: today,
          latitude: location.lat,
          longitude: location.long,
          onTimeMinutes: settings?.onTimeMinutes ?? defaultOnTimeMinutes,
        );
        final todayLogs = data.logs[today] ?? const {};
        final nudges = sholatNudges(
          sholatItems: [
            for (final i in data.items)
              if (i.groupKey == sholatWajibGroup) i,
          ],
          todayValues: {
            for (final e in todayLogs.entries) e.key: e.value.value,
          },
          todayPrayedAt: {
            for (final e in todayLogs.entries)
              if (e.value.prayedAt case final at?) e.key: at,
          },
          excusedToday: data.excused.contains(today),
          week: week,
          now: DateTime.now(),
          today: today,
          latitude: location.lat,
          longitude: location.long,
          onTimeMinutes: settings?.onTimeMinutes ?? defaultOnTimeMinutes,
          tracking: settings?.sholatTime ?? false,
        );
        // puasa Tarwiyah/Arafah: sesudah pengingat sholat yang berjalan
        final fastItem = data.items
            .where((i) => i.key == 'puasa_sunnah' && i.active)
            .firstOrNull;
        final fast = fastNudge(
          today: today,
          anchors: anchors,
          now: DateTime.now(),
          maghribToday: calc
              .calculatePrayerTimes(
                latitude: location.lat,
                longitude: location.long,
              )
              .times[PrayerKey.maghrib]!,
          fastItem: fastItem,
          fastDone:
              fastItem != null && (todayLogs[fastItem.id]?.value ?? 0) > 0,
          excusedToday: data.excused.contains(today),
        );
        if (fast != null) {
          nudges.insert(
            nudges.isNotEmpty && nudges.first.item != null ? 1 : 0,
            fast,
          );
        }
        if (nudges.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, n) in nudges.indexed)
              EntranceFade(
                // kunci stabil (judul berubah tiap menit: "… menit lalu")
                key: ValueKey('$i|${n.tone.name}|${n.item?.id}|${n.icon}'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NudgeCard(nudge: n, onLog: onLog),
                ),
              ),
          ],
        );
      },
    );
  }
}

const _tone = {
  SholatStatus.onTime: (
    Color(0xFFF0FDF4),
    Color(0xFF16A34A),
    Color(0xFF14532D),
  ),
  SholatStatus.late: (Color(0xFFFFFBEB), Color(0xFFD97706), Color(0xFF78350F)),
  SholatStatus.qadha: (Color(0xFFFEF2F2), Color(0xFFDC2626), Color(0xFF7F1D1D)),
};

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.nudge, required this.onLog});
  final SholatNudge nudge;
  final void Function(IbadahItem item)? onLog;

  @override
  Widget build(BuildContext context) {
    final (bg, accent, text) = _tone[nudge.tone]!;
    final item = nudge.item;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            nudge.icon ??
                (item != null
                    ? Icons.alarm_rounded
                    : nudge.tone == SholatStatus.onTime
                    ? Icons.emoji_events_rounded
                    : Icons.trending_up_rounded),
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nudge.message,
                  style: TextStyle(fontSize: 12, color: text, height: 1.35),
                ),
              ],
            ),
          ),
          if (item != null && onLog != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: accent),
              onPressed: () => onLog!(item),
              child: const Text('Catat'),
            ),
        ],
      ),
    );
  }
}

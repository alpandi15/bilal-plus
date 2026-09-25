import 'package:flutter/material.dart';

import '../services/hijri_calendar.dart';
import '../services/hijri_config.dart';
import '../services/hijri_config_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Bulan-bulan yang awalnya kerap berbeda antar-metode/daerah, jadi boleh
/// disesuaikan pengguna.
const _adjustableMonths = [9, 10, 12];

const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanPendek = [
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

String _tanggalPendek(DateTime d) =>
    '${_namaHari[d.weekday - 1]}, ${d.day} ${_bulanPendek[d.month - 1]}';

/// Lembar pengaturan kalender hijriah: metode penetapan (Pemerintah /
/// Muhammadiyah / varian lain dari berkas konfigurasi) dan penyesuaian ±1
/// hari untuk tanggal 1 Ramadan, Syawal, dan Dzulhijjah terdekat.
Future<void> showHijriSettingsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => const HijriSettingsSheet(),
    );

class HijriSettingsSheet extends StatelessWidget {
  const HijriSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HijriConfigScope.of(context);
    final anchors = controller.config.anchors;
    final location = UserLocationScope.of(context).location;
    final today = calc.todayInZone(
      calc.timezoneFromLongitude(location.long),
      DateTime.now(),
    );
    final todayJdn = gregorianToJdn(today.year, today.month, today.day);

    // kemunculan terdekat tiap bulan yang belum berakhir
    final upcoming = <(int, int)>[];
    final hy = anchors.fromJdn(todayJdn).year;
    for (final m in _adjustableMonths) {
      final (ny, nm) = nextHijriMonth(hy, m);
      upcoming.add(
        anchors.firstDayJdn(ny, nm) > todayJdn ? (hy, m) : (hy + 1, m),
      );
    }
    upcoming.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Penetapan Tanggal Hijriah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('IKUTI KETETAPAN'),
            for (final m in controller.methods)
              _MethodTile(
                method: m,
                selected: controller.config.method == m.key,
                onTap: () => controller.setMethod(m.key),
              ),
            const SizedBox(height: 20),
            const _SectionLabel('SESUAIKAN TANGGAL 1'),
            const Text(
              'Bila masjid atau daerahmu memulai di hari yang berbeda. '
              'Pilihanmu tetap dipakai walau data diperbarui, kecuali '
              'ketetapan resmi ternyata sama.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final (y, m) in upcoming)
              _AdjustRow(
                year: y,
                month: m,
                controller: controller,
                anchors: anchors,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
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

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final HijriMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = method.anchors.isEmpty
        ? 'Data belum tersedia · memakai perhitungan'
        : method.source;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFFFF1D6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFF1E4CF),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected ? _amber : _muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                    ],
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

class _AdjustRow extends StatelessWidget {
  const _AdjustRow({
    required this.year,
    required this.month,
    required this.controller,
    required this.anchors,
  });
  final int year;
  final int month;
  final HijriConfigController controller;
  final HijriAnchors anchors;

  @override
  Widget build(BuildContext context) {
    final base = controller.baseFirstDay(year, month);
    final current = anchors.toGregorian(year, month, 1);
    final overridden = anchors.isOverridden(year, month);
    // status ketetapan metodenya sendiri, sebelum penyesuaian pengguna
    final method = controller.config.currentMethod?.anchors ?? anchors;
    final baseLabel = !method.has(year, month)
        ? 'perkiraan'
        : method.isTentative(year, month)
        ? 'menunggu isbat'
        : 'resmi';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '1 ${hijriMonthNames[month - 1]} $year H',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _stone,
                  ),
                ),
              ),
              if (overridden)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _amber,
                  ),
                  onPressed: () => controller.setOverride(year, month, null),
                  child: const Text('Ikuti ketetapan'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final shift in const [-1, 0, 1]) ...[
                if (shift != -1) const SizedBox(width: 8),
                Expanded(
                  child: _DateChoice(
                    date: base.add(Duration(days: shift)),
                    caption: shift == 0
                        ? baseLabel
                        : shift < 0
                        ? 'sehari lebih awal'
                        : 'sehari lebih lambat',
                    selected: current == base.add(Duration(days: shift)),
                    onTap: () => controller.setOverride(
                      year,
                      month,
                      base.add(Duration(days: shift)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChoice extends StatelessWidget {
  const _DateChoice({
    required this.date,
    required this.caption,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _amber : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _amber : const Color(0xFFF1E4CF),
            ),
          ),
          child: Column(
            children: [
              Text(
                _tanggalPendek(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _stone,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? const Color(0xE6FFFFFF) : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

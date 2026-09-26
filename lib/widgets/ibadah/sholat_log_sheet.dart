import 'package:flutter/material.dart';

import '../../services/prayer_calculator.dart' as calc;
import '../../services/sholat_time.dart';
import 'jamaah_info.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

const sholatStatusColor = {
  SholatStatus.onTime: Color(0xFF16A34A),
  SholatStatus.late: Color(0xFFD97706),
  SholatStatus.qadha: Color(0xFFDC2626),
};

const sholatPlaceIcon = {
  'masjid': Icons.mosque_rounded,
  'rumah': Icons.home_rounded,
  'lainnya': Icons.place_rounded,
};

/// Hasil lembar catat sholat: simpan jam & tempat, atau batalkan centang.
sealed class SholatLogResult {
  const SholatLogResult();
}

class SholatLogSave extends SholatLogResult {
  const SholatLogSave(this.prayedAt, this.place, this.jamaah);
  final DateTime prayedAt;
  final String place;
  final bool jamaah;
}

class SholatLogRemove extends SholatLogResult {
  const SholatLogRemove();
}

/// "Sholat Subuh jam berapa, berjama'ah, & di mana?" - jam bawaannya
/// sekarang (atau adzan untuk hari yang sudah lewat), statusnya langsung
/// ikut berubah saat jam diganti.
Future<SholatLogResult?> showSholatLogSheet(
  BuildContext context, {
  required String name,
  required String itemKey,
  required DateTime date,
  required SholatWindow window,
  required calc.TimezoneCode tz,
  required int onTimeMinutes,
  required String place,
  required bool jamaah,
  double soloWeight = 1,
  DateTime? prayedAt,
  required bool done,
}) => showModalBottomSheet<SholatLogResult>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (_) => _SholatLogSheet(
    name: name,
    itemKey: itemKey,
    date: date,
    window: window,
    tz: tz,
    onTimeMinutes: onTimeMinutes,
    place: place,
    jamaah: jamaah,
    soloWeight: soloWeight,
    prayedAt: prayedAt,
    done: done,
  ),
);

class _SholatLogSheet extends StatefulWidget {
  const _SholatLogSheet({
    required this.name,
    required this.itemKey,
    required this.date,
    required this.window,
    required this.tz,
    required this.onTimeMinutes,
    required this.place,
    required this.jamaah,
    required this.soloWeight,
    required this.prayedAt,
    required this.done,
  });

  final String name, itemKey, place;
  final bool jamaah;
  final double soloWeight;
  final DateTime date;
  final SholatWindow window;
  final calc.TimezoneCode tz;
  final int onTimeMinutes;
  final DateTime? prayedAt;
  final bool done;

  @override
  State<_SholatLogSheet> createState() => _SholatLogSheetState();
}

class _SholatLogSheetState extends State<_SholatLogSheet> {
  late DateTime _at;
  late String _place;
  late bool _jamaah;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _jamaah = widget.jamaah;
    final now = DateTime.now();
    _at =
        widget.prayedAt ??
        (now.isAfter(widget.window.start) && now.isBefore(widget.window.end)
            ? now
            : widget.window.start);
  }

  String _hm(DateTime d) => calc.formatInZone(d.toUtc(), widget.tz);

  Future<void> _pickTime() async {
    final (h, m) = calc.hourMinuteInZone(_at, widget.tz);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      helpText: 'Sholat ${widget.name} jam',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    var at = calc.atTimeInZone(
      widget.tz,
      widget.date,
      picked.hour,
      picked.minute,
    );
    // Isya lewat tengah malam: jam kecil berarti keesokan harinya
    if (widget.itemKey == 'isya' &&
        at.isBefore(widget.window.start.subtract(const Duration(hours: 1)))) {
      at = at.add(const Duration(days: 1));
    }
    setState(() => _at = at);
  }

  @override
  Widget build(BuildContext context) {
    final status = sholatStatus(
      _at,
      widget.window,
      onTimeMinutes: widget.onTimeMinutes,
    );
    final color = sholatStatusColor[status]!;
    final late = minutesAfterAdzan(_at, widget.window);
    final detail = switch (status) {
      SholatStatus.onTime =>
        late == 0
            ? 'Tepat saat adzan. Masyaa Allah!'
            : '$late menit setelah adzan. Masyaa Allah!',
      SholatStatus.late =>
        '$late menit setelah adzan - masih dalam waktu ${widget.name}.',
      SholatStatus.qadha =>
        'Waktu ${widget.name} berakhir ${_hm(widget.window.end)}. '
            'Dicatat sebagai qadha.',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sholat ${widget.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            Text(
              'Adzan ${_hm(widget.window.start)} · waktu berakhir '
              '${_hm(widget.window.end)}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _hm(_at),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: _stone,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        calc.tzLabel[widget.tz]!,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          sholatStatusLabel[status]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 18, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(detail, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 16),
            JamaahChoice(
              jamaah: _jamaah,
              soloWeight: widget.soloWeight,
              onChanged: (v) => setState(() => _jamaah = v),
            ),
            const SizedBox(height: 16),
            const Text(
              'DI MANA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xCCB45309),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final p in sholatPlaces) ...[
                  if (p != sholatPlaces.first) const SizedBox(width: 8),
                  Expanded(
                    child: _PlaceChoice(
                      label: sholatPlaceLabel[p]!,
                      icon: sholatPlaceIcon[p]!,
                      selected: _place == p,
                      onTap: () => setState(() {
                        _place = p;
                        // di masjid hampir selalu berjama'ah - tetap bisa
                        // diganti bila sholat sendiri
                        if (p == 'masjid') _jamaah = true;
                      }),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _amber,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () =>
                  Navigator.pop(context, SholatLogSave(_at, _place, _jamaah)),
              child: const Text(
                'Simpan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.done)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _muted),
                onPressed: () =>
                    Navigator.pop(context, const SholatLogRemove()),
                child: const Text('Batalkan centang'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceChoice extends StatelessWidget {
  const _PlaceChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _amber : Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _amber : _line),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : _amber),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _stone,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

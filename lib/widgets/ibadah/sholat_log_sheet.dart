import 'package:flutter/material.dart';

import '../../services/prayer_calculator.dart' as calc;
import '../../services/sholat_time.dart';
import 'jamaah_info.dart';
import 'sholat_dalil_sheet.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

const sholatStatusColor = {
  SholatStatus.onTime: Color(0xFF16A34A),
  SholatStatus.late: Color(0xFFD97706),
  SholatStatus.qadha: Color(0xFFDC2626),
  SholatStatus.jamak: Color(0xFF0D9488),
  SholatStatus.uzur: Color(0xFF2563EB),
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
  const SholatLogSave(
    this.prayedAt,
    this.place,
    this.jamaah, {
    this.qadhaReason,
    this.safar = false,
    this.qashar = false,
    this.jamak = false,
  });
  final DateTime prayedAt;
  final String place;
  final bool jamaah;

  /// Alasan qadha (hanya bila dikerjakan sesudah waktunya & tidak dijamak).
  final String? qadhaReason;

  /// Sedang safar - [qashar]/[jamak] hanya bermakna bila true.
  final bool safar, qashar, jamak;
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
  String? qadhaReason,
  bool safar = false,
  bool qashar = false,
  bool jamak = false,
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
    qadhaReason: qadhaReason,
    safar: safar,
    qashar: qashar,
    jamak: jamak,
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
    required this.qadhaReason,
    required this.safar,
    required this.qashar,
    required this.jamak,
  });

  final String? qadhaReason;
  final bool safar, qashar, jamak;
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
  late String? _reason = widget.qadhaReason;
  late bool _safar = widget.safar && _canSafar;
  late bool _qashar = widget.qashar;
  late bool _jamak = widget.jamak;

  bool get _canQashar => qasharPrayers.contains(widget.itemKey);
  bool get _canJamak => jamakPair.containsKey(widget.itemKey);

  /// Subuh tidak bisa diqashar maupun dijamak.
  bool get _canSafar => _canQashar || _canJamak;

  /// Dikerjakan di luar waktunya sendiri (sebelum adzan / sesudah habis).
  bool get _outside =>
      _at.isBefore(widget.window.start) || !_at.isBefore(widget.window.end);

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
    setState(() {
      _at = at;
      // safar & di luar waktunya: kemungkinan besar dijamak
      if (_safar && _canJamak && _outside) _jamak = true;
    });
  }

  void _setSafar(bool on) => setState(() {
    _safar = on;
    if (on) {
      _qashar = _canQashar;
      _jamak = _canJamak && _outside;
    }
  });

  @override
  Widget build(BuildContext context) {
    final jamak = _safar && _canJamak && _jamak;
    final status = sholatStatus(
      _at,
      widget.window,
      onTimeMinutes: widget.onTimeMinutes,
      jamak: jamak,
      qadhaReason: _reason,
    );
    // perlu alasan: dikerjakan sesudah waktunya & tidak dijamak
    final needsReason =
        status == SholatStatus.qadha || status == SholatStatus.uzur;
    final pair = switch (jamakPair[widget.itemKey]) {
      'ashar' => 'Ashar',
      'dzuhur' => 'Dzuhur',
      'isya' => 'Isya',
      'maghrib' => 'Maghrib',
      _ => '',
    };
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
            'Dicatat sebagai qadha - pilih alasannya di bawah.',
      SholatStatus.uzur => 'Diqadha karena uzur - tidak berdosa, nilai penuh.',
      SholatStatus.jamak =>
        'Dijamak dengan $pair saat safar - sah, bukan qadha.',
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
            if (_canSafar) ...[
              const SizedBox(height: 14),
              _SafarCard(
                on: _safar,
                onChanged: _setSafar,
                canQashar: _canQashar,
                canJamak: _canJamak,
                qashar: _qashar,
                jamak: _jamak,
                pair: pair,
                onQashar: (v) => setState(() => _qashar = v),
                onJamak: (v) => setState(() => _jamak = v),
              ),
            ],
            if (needsReason) ...[
              const SizedBox(height: 14),
              _QadhaReason(
                reason: _reason,
                itemKey: widget.itemKey,
                canJamak: _canJamak,
                onChanged: (r) => setState(() => _reason = r),
              ),
            ],
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
              onPressed: needsReason && _reason == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      SholatLogSave(
                        _at,
                        _place,
                        _jamaah,
                        qadhaReason: needsReason ? _reason : null,
                        safar: _safar,
                        qashar: _safar && _canQashar && _qashar,
                        jamak: jamak,
                      ),
                    ),
              child: Text(
                needsReason && _reason == null
                    ? 'Pilih alasan qadha dulu'
                    : 'Simpan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
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

/// "Sedang safar?" - bila ya: qashar (Dzuhur/Ashar/Isya) & jamak
/// (pasangan Dzuhur-Ashar, Maghrib-Isya).
class _SafarCard extends StatelessWidget {
  const _SafarCard({
    required this.on,
    required this.onChanged,
    required this.canQashar,
    required this.canJamak,
    required this.qashar,
    required this.jamak,
    required this.pair,
    required this.onQashar,
    required this.onJamak,
  });

  final bool on, canQashar, canJamak, qashar, jamak;
  final String pair;
  final ValueChanged<bool> onChanged, onQashar, onJamak;

  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
    decoration: BoxDecoration(
      color: on ? const Color(0xFFF0FDFA) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: on ? const Color(0xFF99F6E4) : _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.luggage_rounded, size: 20, color: on ? _teal : _muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sedang safar (musafir)',
                style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
              ),
            ),
            Switch.adaptive(
              value: on,
              activeTrackColor: _teal,
              onChanged: onChanged,
            ),
          ],
        ),
        if (on) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (canQashar)
                FilterChip(
                  label: const Text('Qashar · 2 rakaat'),
                  selected: qashar,
                  onSelected: onQashar,
                  selectedColor: const Color(0xFFCCFBF1),
                  checkmarkColor: _teal,
                ),
              if (canJamak)
                FilterChip(
                  label: Text('Jamak dengan $pair'),
                  selected: jamak,
                  onSelected: onJamak,
                  selectedColor: const Color(0xFFCCFBF1),
                  checkmarkColor: _teal,
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _teal,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => showQasharGuideSheet(context),
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: const Text(
              'Cara qashar & jamak',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Alasan qadha: uzur syar'i (nilai penuh, tidak berdosa) atau tanpa uzur
/// (peringatan + nilai berkurang).
class _QadhaReason extends StatelessWidget {
  const _QadhaReason({
    required this.reason,
    required this.itemKey,
    required this.canJamak,
    required this.onChanged,
  });

  final String? reason;
  final String itemKey;
  final bool canJamak;
  final ValueChanged<String> onChanged;

  static const _red = Color(0xFFDC2626);
  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final noUzur = reason == 'tanpa';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ALASAN QADHA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xCCB45309),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final e in qadhaReasons.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: reason == e.key,
                onSelected: (_) => onChanged(e.key),
                showCheckmark: false,
                selectedColor: e.key == 'tanpa'
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: reason == e.key
                      ? (e.key == 'tanpa' ? _red : _blue)
                      : _stone,
                ),
              ),
          ],
        ),
        if (reason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            decoration: BoxDecoration(
              color: noUzur ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  noUzur
                      ? 'Menunda sholat sampai habis waktunya tanpa uzur '
                            'termasuk dosa besar. Segera bertaubat & jangan '
                            'diulangi. Dicatat dengan nilai '
                            '${(qadhaNoUzurWeight * 100).round()}%.'
                      : reason == 'perjalanan' && canJamak
                      ? 'Uzur perjalanan: tidak berdosa bila benar-benar tidak '
                            'memungkinkan. Bila sholat ini dijamak, aktifkan '
                            '"Sedang safar" lalu pilih Jamak.'
                      : 'Uzur syar\'i - tidak berdosa. Kaffaratnya menunaikan '
                            'sholat itu ketika ingat (HR. Muslim no. 1103). '
                            'Nilai penuh.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: noUzur
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF1E3A8A),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: noUzur ? _red : _blue,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        showSholatWarningSheet(context, prayerKey: itemKey),
                    icon: Icon(
                      noUzur
                          ? Icons.warning_amber_rounded
                          : Icons.menu_book_rounded,
                      size: 16,
                    ),
                    label: Text(
                      noUzur
                          ? 'Baca peringatan & dalil'
                          : 'Dalil & pintu taubat',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Tertidur, lupa & uzur lain tidak berdosa (nilai penuh). Qadha '
              'tanpa uzur tetap dicatat dengan peringatan.',
              style: TextStyle(fontSize: 11.5, color: _muted),
            ),
          ),
      ],
    );
  }
}

/// Arti setiap status sholat + pintu ke peringatan & panduan qashar.
Future<void> showSholatStatusInfo(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Status sholat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              const SizedBox(height: 12),
              for (final (st, meaning) in const [
                (SholatStatus.onTime, 'Dikerjakan di awal waktu.'),
                (SholatStatus.late, 'Lewat awal waktu, masih dalam waktunya.'),
                (
                  SholatStatus.jamak,
                  'Dijamak saat safar di waktu pasangannya - sah, nilai '
                      'penuh.',
                ),
                (
                  SholatStatus.uzur,
                  'Diqadha karena uzur (tertidur, lupa, ...) - tidak '
                      'berdosa, nilai penuh.',
                ),
                (
                  SholatStatus.qadha,
                  'Diqadha tanpa uzur - termasuk lalai, nilai berkurang.',
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: sholatStatusColor[st],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${sholatStatusLabel[st]}  ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: meaning),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: _stone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                ),
                onPressed: () => showSholatWarningSheet(context),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Peringatan meninggalkan sholat'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                ),
                onPressed: () => showQasharGuideSheet(context),
                icon: const Icon(Icons.luggage_rounded, size: 18),
                label: const Text('Cara qashar & jamak saat safar'),
              ),
            ],
          ),
        ),
      ),
    );

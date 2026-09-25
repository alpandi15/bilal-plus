import 'package:flutter/material.dart';

import '../../db/app_database_scope.dart';
import '../../models/prayer_models.dart';
import '../../pages/ramadan_recap_page.dart';
import '../../services/hijri_config_scope.dart';
import '../../services/prayer_calculator.dart' as calc;
import '../../services/ramadan_calendar.dart';
import '../../services/ramadan_notices.dart';
import '../../services/ramadan_recap.dart';
import '../../services/user_location_scope.dart';
import '../../utils/date_key.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
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

String _tanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';

/// Kartu-kartu seputar awal/akhir Ramadan di atas checklist hari ini:
/// - awal Ramadan bergeser sejak terakhir dilihat (catatan tetap aman),
/// - menjelang 1 Ramadan/Syawal yang belum resmi: "mulai kapan?",
/// - suasana Idulfitri: rekap Ramadan yang baru selesai.
class RamadanNoticeCards extends StatefulWidget {
  const RamadanNoticeCards({super.key, required this.today});
  final String today;

  @override
  State<RamadanNoticeCards> createState() => _RamadanNoticeCardsState();
}

class _RamadanNoticeCardsState extends State<RamadanNoticeCards> {
  RamadanNotices? _notices;

  @override
  void initState() {
    super.initState();
    RamadanNotices.load()
        .then((n) {
          if (mounted) setState(() => _notices = n);
        })
        // tanpa penyimpanan (mis. plugin tak tersedia): kartu tidak tampil
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final notices = _notices;
    if (notices == null) return const SizedBox.shrink();

    final controller = HijriConfigScope.of(context);
    final anchors = controller.config.anchors;
    final location = UserLocationScope.of(context).location;
    final today = parseDateKey(widget.today);
    final afterMaghrib = !DateTime.now().isBefore(
      calc
          .calculatePrayerTimes(
            latitude: location.lat,
            longitude: location.long,
            date: today,
          )
          .times[PrayerKey.maghrib]!,
    );
    final status = ramadanStatus(
      today: today,
      afterMaghrib: afterMaghrib,
      anchors: anchors,
    );

    final shift = notices.shiftOf(status.ramadan);
    final isbat = isbatPrompt(widget.today, anchors);
    final showIsbat =
        isbat != null && !notices.isbatDismissed(isbat.hijriYear, isbat.month);

    final cards = <Widget>[
      if (shift != null)
        _ShiftCard(
          shift: shift,
          onOk: () async {
            await notices.acknowledgeShift(shift);
            if (mounted) setState(() {});
          },
        ),
      if (showIsbat)
        _IsbatCard(
          prompt: isbat,
          today: widget.today,
          base: controller.baseFirstDay(isbat.hijriYear, isbat.month),
          onPick: (date) =>
              controller.setOverride(isbat.hijriYear, isbat.month, date),
          onLater: () async {
            await notices.dismissIsbat(isbat.hijriYear, isbat.month);
            if (mounted) setState(() {});
          },
        ),
      if (status.phase == RamadanPhase.eid)
        _EidRecapCard(ramadan: status.ramadan, today: widget.today),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in cards) ...[c, const SizedBox(height: 12)],
      ],
    );
  }
}

BoxDecoration _noticeDecoration(Color a, Color b) => BoxDecoration(
  borderRadius: BorderRadius.circular(22),
  gradient: LinearGradient(colors: [a, b]),
  border: Border.all(color: const Color(0xFFFDE68A)),
);

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.onOk});
  final RamadanShift shift;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: _noticeDecoration(
        const Color(0xFFFFFBEB),
        const Color(0xFFFFF1D6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_repeat_rounded, color: _amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Awal Ramadan ${shift.hijriYear} H disesuaikan menjadi '
                  '${_tanggal(parseDateKey(shift.to))} '
                  '(sebelumnya ${_tanggal(parseDateKey(shift.from))}). '
                  'Catatanmu tetap aman - tanggal Ramadan di checklist '
                  'ikut menyesuaikan.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _stone,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: _amber),
              onPressed: onOk,
              child: const Text('Mengerti'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IsbatCard extends StatelessWidget {
  const _IsbatCard({
    required this.prompt,
    required this.today,
    required this.base,
    required this.onPick,
    required this.onLater,
  });

  final IsbatPrompt prompt;
  final String today;

  /// Tanggal 1 menurut ketetapan/perkiraan metodenya (tanpa penyesuaian).
  final DateTime base;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final ramadan = prompt.month == 9;
    final options = [
      for (final shift in const [-1, 0, 1])
        if (dateKey(base.add(Duration(days: shift))).compareTo(today) > 0)
          base.add(Duration(days: shift)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _noticeDecoration(
        const Color(0xFF1E1B4B),
        const Color(0xFF312E81),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ramadan
                      ? 'Kapan mulai puasa Ramadan ${prompt.hijriYear} H?'
                      : 'Kapan Idulfitri ${prompt.hijriYear} H?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tanggalnya belum ditetapkan resmi - perkiraan saat ini '
            '${_tanggal(prompt.expected)}. Pilih sesuai hasil sidang isbat '
            'atau ketetapan yang kamu ikuti.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xE6E0E7FF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in options)
                ActionChip(
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  label: Text(
                    _tanggal(d),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  onPressed: () => onPick(d),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC7D2FE),
                ),
                onPressed: onLater,
                child: const Text('Ikuti ketetapan nanti'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EidRecapCard extends StatelessWidget {
  const _EidRecapCard({required this.ramadan, required this.today});
  final RamadanDate ramadan;
  final String today;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return FutureBuilder<RamadanSummary>(
      future: loadRamadanSummary(db, ramadan, today),
      builder: (context, snap) {
        final s = snap.data;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RamadanRecapPage(hijriYear: ramadan.hijriYear),
              ),
            ),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: _noticeDecoration(
                const Color(0xFFFBBF24),
                const Color(0xFFEA580C),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekap Ramadan ${ramadan.hijriYear} H',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          s == null
                              ? 'Taqabbalallahu minna wa minkum'
                              : 'Puasa ${s.fastedCount}/${ramadan.days} · '
                                    'tarawih ${s.tarawihCount} malam · '
                                    'khatam ${s.khatam}x',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xF2FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

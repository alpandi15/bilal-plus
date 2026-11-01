import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/app_database_scope.dart';
import '../../services/app_settings.dart';
import '../../services/murajaah.dart';
import '../../services/prayer_calculator.dart' as calc;
import '../../services/quran_text.dart';
import '../../services/user_location_scope.dart';
import '../../utils/date_key.dart';
import '../../widgets/arabic_font.dart';
import '../../widgets/quran/quran_ayah_text.dart';
import '../../widgets/sub_header.dart';
import 'murajaah_quiz_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);
const _red = Color(0xFFB91C1C);

/// Kunci tanggal hari ini di zona lokasi pengguna.
String murajaahToday(BuildContext context) {
  final location = UserLocationScope.of(context).location;
  return dateKey(calc.todayInZone(calc.timezoneFromLongitude(location.long)));
}

/// Muraja'ah hari ini: unit hafalan yang jatuh tempo diulang dari ingatan
/// lalu dinilai Lancar / Ragu / Lupa; jadwal berikutnya mengikuti nilainya.
class MurajaahPage extends StatefulWidget {
  const MurajaahPage({super.key});

  @override
  State<MurajaahPage> createState() => _MurajaahPageState();
}

class _MurajaahPageState extends State<MurajaahPage> {
  Future<void>? _sync;
  QuranText? _text;

  @override
  void initState() {
    super.initState();
    QuranText.load().then((t) {
      if (mounted) setState(() => _text = t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).quranDao;
    final today = murajaahToday(context);
    _sync ??= dao.syncReviews(today);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: "Muraja'ah",
            subtitle: 'Ulangi hafalan agar tidak hilang',
            trailing: IconButton(
              tooltip: 'Kuis sambung ayat',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MurajaahQuizPage(),
                ),
              ),
              icon: const Icon(Icons.quiz_rounded, color: _amber),
            ),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _sync,
              builder: (context, ready) => StreamBuilder<List<HafalanReview>>(
                stream: dao.watchReviews(),
                builder: (context, snap) {
                  final all = snap.data;
                  if (all == null ||
                      ready.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final due =
                      [
                        for (final r in all)
                          if (r.dueDate.compareTo(today) <= 0) r,
                      ]..sort((a, b) {
                        final c = a.dueDate.compareTo(b.dueDate);
                        return c != 0 ? c : a.startAyah.compareTo(b.startAyah);
                      });
                  final later = [
                    for (final r in all)
                      if (r.dueDate.compareTo(today) > 0) r,
                  ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      28 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (all.isEmpty)
                                const _Empty()
                              else ...[
                                _DueCard(
                                  due: due.length,
                                  total: all.length,
                                  onStart: due.isEmpty || _text == null
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => MurajaahSessionPage(
                                              units: due,
                                              text: _text!,
                                              today: today,
                                            ),
                                          ),
                                        ),
                                ),
                                if (later.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  const _Heading('AKAN DATANG'),
                                  _UpcomingList(
                                    units: later.take(12).toList(),
                                    today: today,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _line),
    ),
    child: const Column(
      children: [
        Icon(Icons.psychology_rounded, size: 40, color: _amber),
        SizedBox(height: 10),
        Text(
          'Belum ada hafalan untuk diulang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _stone,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tandai ayat yang sudah kamu hafal di menu Hafalan. Ayat yang '
          'berurutan dikelompokkan otomatis menjadi unit, lalu dijadwalkan '
          'diulang: 1, 3, 7, 14, lalu 30 hari sekali.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.45, color: _muted),
        ),
      ],
    ),
  );
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.due, required this.total, this.onStart});
  final int due, total;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: due == 0
            ? const [Color(0xFF0F766E), Color(0xFF064E3B)]
            : const [Color(0xFF00503C), Color(0xFF0C3A33)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          due == 0 ? 'ALHAMDULILLAH' : 'HARI INI',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: Color(0xFFF2D38A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          due == 0 ? 'Semua sudah diulang' : '$due unit jatuh tempo',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$total unit hafalan terjadwal',
          style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
        ),
        if (due > 0) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2D38A),
                foregroundColor: const Color(0xFF3B2A06),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Mulai muraja'ah"),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: _muted,
      ),
    ),
  );
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.units, required this.today});
  final List<HafalanReview> units;
  final String today;

  String _when(String due) {
    final d = parseDateKey(due).difference(parseDateKey(today)).inDays;
    return d == 1 ? 'besok' : 'dalam $d hari';
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        for (final (i, r) in units.indexed) ...[
          if (i > 0) const Divider(height: 1, color: _line),
          ListTile(
            dense: true,
            title: Text(
              murajaahLabel(r.startAyah, r.endAyah),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _stone,
              ),
            ),
            subtitle: Text(
              _when(r.dueDate),
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
            trailing: _StageDots(stage: r.stage),
          ),
        ],
      ],
    ),
  );
}

class _StageDots extends StatelessWidget {
  const _StageDots({required this.stage});
  final int stage;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < murajaahIntervals.length; i++)
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i <= stage ? _emerald : _line,
          ),
        ),
    ],
  );
}

/// Sesi mengulang unit-unit yang jatuh tempo, satu per satu.
class MurajaahSessionPage extends StatefulWidget {
  const MurajaahSessionPage({
    super.key,
    required this.units,
    required this.text,
    required this.today,
  });

  final List<HafalanReview> units;
  final QuranText text;
  final String today;

  @override
  State<MurajaahSessionPage> createState() => _MurajaahSessionPageState();
}

class _MurajaahSessionPageState extends State<MurajaahSessionPage> {
  int _at = 0;
  bool _revealed = false;
  bool _showArti = true;
  final _tally = {for (final g in MurajaahGrade.values) g: 0};

  Future<void> _grade(MurajaahGrade g) async {
    final dao = AppDatabaseScope.of(context).quranDao;
    final unit = widget.units[_at];
    await dao.gradeReview(unit.id, g, widget.today);
    if (!mounted) return;
    setState(() {
      _tally[g] = _tally[g]! + 1;
      _at++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _at >= widget.units.length;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: "Muraja'ah",
            subtitle: done
                ? 'Selesai'
                : 'Unit ${_at + 1} dari ${widget.units.length}',
          ),
          Expanded(child: done ? _finished() : _unit(context)),
        ],
      ),
    );
  }

  Widget _finished() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt_rounded, size: 56, color: _emerald),
          const SizedBox(height: 12),
          const Text(
            'Muraja\'ah hari ini selesai',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_tally[MurajaahGrade.lancar]} lancar · '
            '${_tally[MurajaahGrade.ragu]} ragu · '
            '${_tally[MurajaahGrade.lupa]} lupa',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Yang ragu atau lupa akan muncul lebih cepat.',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _emerald),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Selesai'),
          ),
        ],
      ),
    ),
  );

  Widget _unit(BuildContext context) {
    final u = widget.units[_at];
    final font = AppSettingsScope.maybeOf(context)?.quranFont ?? QuranFont.lpmq;
    final size = AppSettingsScope.maybeOf(context)?.readerSize ?? 28;
    final ayahs = [
      for (var i = u.startAyah; i <= u.endAyah; i++) widget.text.ayah(i),
    ];
    final style = TextStyle(
      fontSize: size,
      height: 2,
      color: const Color(0xFF1C1917),
    );
    final late = parseDateKey(
      widget.today,
    ).difference(parseDateKey(u.dueDate)).inDays;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: _at / widget.units.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: _line,
                  valueColor: const AlwaysStoppedAnimation(_emerald),
                ),
                const SizedBox(height: 16),
                Text(
                  murajaahLabel(u.startAyah, u.endAyah),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
                if (late > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'terlambat $late hari',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: _red),
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line),
                  ),
                  child: _revealed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final a in ayahs) ...[
                              QuranAyahText(
                                quranTextFor(a, font),
                                font: font,
                                style: style,
                              ),
                              if (_showArti)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${a.number}. ${a.translation}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // petunjuk: kata pertama saja, sisanya diburamkan
                            QuranAyahText(
                              quranTextFor(ayahs.first, font).split(' ').first,
                              font: font,
                              style: style.copyWith(color: _amber),
                            ),
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 8,
                                sigmaY: 8,
                              ),
                              child: QuranAyahText(
                                quranTextFor(
                                  ayahs.first,
                                  font,
                                ).split(' ').skip(1).join(' '),
                                font: font,
                                style: style.copyWith(
                                  color: const Color(0x991C1917),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ucapkan dari ingatan, lalu tampilkan ayat '
                              'untuk memeriksa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                if (!_revealed)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _amber),
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Tampilkan ayat'),
                  )
                else ...[
                  Row(
                    children: [
                      for (final (g, c) in const [
                        (MurajaahGrade.lancar, _emerald),
                        (MurajaahGrade.ragu, _amber),
                        (MurajaahGrade.lupa, _red),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: c,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => _grade(g),
                              child: Text(g.label),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: _amber,
                    value: _showArti,
                    onChanged: (v) => setState(() => _showArti = v),
                    title: const Text(
                      'Terjemahan',
                      style: TextStyle(fontSize: 13, color: _stone),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu masuk ke Muraja'ah di halaman Hafalan: jumlah unit yang jatuh
/// tempo hari ini. Menyelaraskan unit setiap hafalan berubah.
class MurajaahEntryCard extends StatefulWidget {
  const MurajaahEntryCard({super.key});

  @override
  State<MurajaahEntryCard> createState() => _MurajaahEntryCardState();
}

class _MurajaahEntryCardState extends State<MurajaahEntryCard> {
  Stream<List<HafalanReview>>? _stream;
  String _today = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dao = AppDatabaseScope.of(context).quranDao;
    _today = murajaahToday(context);
    // sinkron lebih dulu, baru memantau jadwal; perubahan hafalan memicu
    // sinkron lagi lewat aliran jadwal yang sama
    _stream ??= () async* {
      await dao.syncReviews(_today);
      yield* dao.watchHafalan().asyncMap((_) async {
        await dao.syncReviews(_today);
        return dao.reviewsAll();
      });
    }();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<HafalanReview>>(
    stream: _stream,
    builder: (context, snap) {
      final all = snap.data;
      if (all == null || all.isEmpty) {
        return all == null ? const SizedBox.shrink() : _card(context, 0, 0);
      }
      final due = all.where((r) => r.dueDate.compareTo(_today) <= 0).length;
      return _card(context, due, all.length);
    },
  );

  Widget _card(BuildContext context, int due, int total) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MurajaahPage())),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: due > 0 ? const Color(0xFFFEF3C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: due > 0 ? const Color(0xFFFCD34D) : _line),
        ),
        child: Row(
          children: [
            Icon(
              due > 0
                  ? Icons.replay_circle_filled_rounded
                  : Icons.task_alt_rounded,
              color: due > 0 ? _amber : _emerald,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Muraja'ah hari ini",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                  Text(
                    total == 0
                        ? 'Ulangi hafalan berjarak agar tidak hilang'
                        : due == 0
                        ? 'Semua sudah diulang'
                        : '$due unit perlu diulang',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

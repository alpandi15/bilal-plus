import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_index.dart';
import '../services/quran_target.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/quran/progress_ring.dart';
import '../widgets/quran/quran_log_sheet.dart';
import '../widgets/sub_header.dart';
import 'quran/quran_home_page.dart';
import 'quran/quran_notes_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _cream = Color(0xFFFFF1D6);

/// Pilihan cepat target khatam (hari).
const _targetChoices = [7, 15, 20, 30, 60];

class _PageData {
  const _PageData(this.progress, this.logs, this.cycles);
  final QuranProgress progress;

  /// Sesi putaran aktif, terbaru dulu.
  final List<QuranLog> logs;

  /// Semua putaran, terbaru dulu.
  final List<QuranCycle> cycles;

  /// Putaran khatam terakhir bila putaran aktif belum diisi - untuk ucapan
  /// "Alhamdulillah, khatam".
  QuranCycle? get justCompleted {
    if (logs.isNotEmpty) return null;
    for (final c in cycles) {
      if (c.id == progress.cycle.id) continue;
      return c.completed ? c : null;
    }
    return null;
  }
}

/// Catatan bacaan Al-Qur'an: posisi terakhir (juz/surah/ayat/halaman),
/// progress khatam berbobot halaman, target harian, peta 30 juz, dan
/// riwayat sesi baca. Semua dari basis data lokal ([AppDatabaseScope]).
class QuranTrackerPage extends StatefulWidget {
  const QuranTrackerPage({super.key, this.showBack = true});

  /// false saat menjadi tab di navigasi bawah.
  final bool showBack;

  @override
  State<QuranTrackerPage> createState() => _QuranTrackerPageState();
}

class _QuranTrackerPageState extends State<QuranTrackerPage> {
  Stream<_PageData>? _data;
  late QuranDao _dao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dao = AppDatabaseScope.of(context).quranDao;
    if (_data == null || !identical(dao, _dao)) {
      _dao = dao;
      _data = dao.watchProgress().asyncMap(
        (p) async =>
            _PageData(p, await dao.logsOf(p.cycle.id), await dao.cycles()),
      );
    }
  }

  String _today() {
    final location = UserLocationScope.of(context).location;
    return dateKey(calc.todayInZone(calc.timezoneFromLongitude(location.long)));
  }

  Future<void> _log(_PageData data, {int? juz}) async {
    final result = await showQuranLogSheet(
      context,
      lastAyah: data.progress.lastAyah,
      today: _today(),
      initialJuz: juz,
    );
    if (result == null) return;
    await _dao.logReading(date: result.date, toAyah: result.toAyah);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.toAyah == totalAyahs
              ? 'Alhamdulillah, khatam!'
              : 'Tersimpan: ${formatAyah(result.toAyah)}',
        ),
      ),
    );
  }

  Future<void> _pickTarget(QuranCycle cycle) async {
    final today = _today();
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (context) =>
          _TargetSheet(today: today, hasTarget: cycle.targetDate != null),
    );
    if (choice == null) return;
    await _dao.setTargetDate(choice == 0 ? null : targetDateFor(today, choice));
  }

  Future<void> _restart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ulangi dari awal?'),
        content: const Text(
          'Putaran ini ditutup dan bacaan dimulai lagi dari Al-Fatihah. '
          'Riwayatnya tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ulangi'),
          ),
        ],
      ),
    );
    if (ok == true) await _dao.startNewCycle();
  }

  Future<void> _deleteLog(QuranLog log) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        content: Text(
          '${formatAyah(log.fromAyah)} - ${formatAyah(log.toAyah)} '
          '(${formatDateKeyShort(log.date)})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) await _dao.deleteLog(log.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_PageData>(
      stream: _data,
      builder: (context, snap) {
        final data = snap.data;
        return Scaffold(
          backgroundColor: const Color(0xFFFFFAF3),
          body: Column(
            children: [
              SubHeader(
                title: "Tilawah Al-Qur'an",
                showBack: widget.showBack,
                subtitle: data == null
                    ? null
                    : 'Putaran khatam ke-${data.progress.round}',
                trailing: data == null
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF92400E),
                        ),
                        onSelected: (v) => switch (v) {
                          'target' => _pickTarget(data.progress.cycle),
                          _ => _restart(),
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'target',
                            child: Text('Atur target khatam'),
                          ),
                          PopupMenuItem(
                            value: 'restart',
                            child: Text('Ulangi dari awal'),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: data == null
                    ? const Center(child: CircularProgressIndicator())
                    : _Body(
                        data: data,
                        today: _today(),
                        onLog: ({int? juz}) => _log(data, juz: juz),
                        onPickTarget: () => _pickTarget(data.progress.cycle),
                        onDeleteLog: _deleteLog,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.today,
    required this.onLog,
    required this.onPickTarget,
    required this.onDeleteLog,
  });

  final _PageData data;
  final String today;
  final void Function({int? juz}) onLog;
  final VoidCallback onPickTarget;
  final void Function(QuranLog) onDeleteLog;

  @override
  Widget build(BuildContext context) {
    final target = dailyTarget(
      cycle: data.progress.cycle,
      logs: data.logs,
      today: today,
    );
    final completed = data.justCompleted;

    return SingleChildScrollView(
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
              if (completed != null) ...[
                _KhatamBanner(
                  round: data.progress.completedCycles,
                  finishedAt: completed.finishedAt,
                ),
                const SizedBox(height: 14),
              ],
              const _ReadCard(),
              const SizedBox(height: 14),
              _HeroCard(progress: data.progress, onLog: () => onLog()),
              const SizedBox(height: 14),
              target == null
                  ? _NoTargetCard(onTap: onPickTarget)
                  : _TargetCard(target: target, onTap: onPickTarget),
              const SizedBox(height: 20),
              const _SectionTitle('PETA 30 JUZ'),
              _JuzGrid(
                lastAyah: data.progress.lastAyah,
                onTap: (j) => onLog(juz: j),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('RIWAYAT PUTARAN INI'),
              if (data.logs.isEmpty)
                const _EmptyHistory()
              else
                for (final log in data.logs)
                  _LogTile(log: log, onDelete: () => onDeleteLog(log)),
            ],
          ),
        ),
      ),
    );
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.progress, required this.onLog});
  final QuranProgress progress;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final last = progress.lastAyah;
    final percent = (progress.progress * 100).floor();
    final pagesDone = progress.progress * totalPages;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          ProgressRing(
            value: progress.progress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                    height: 1.05,
                  ),
                ),
                Text(
                  '${formatPages(pagesDone)} / $totalPages hlm',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (last == 0)
            const Text(
              'Belum ada bacaan di putaran ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _stone,
              ),
            )
          else ...[
            const Text(
              'TERAKHIR DIBACA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xCCB45309),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatAyah(last),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Juz ${juzOf(last)} · Halaman ${pageOf(last)}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _amber,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onLog,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(
              last == 0 ? 'Mulai catat bacaan' : 'Catat bacaan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (progress.nextAyah case final next? when last > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Lanjut dari ${formatAyah(next)}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _KhatamBanner extends StatelessWidget {
  const _KhatamBanner({required this.round, required this.finishedAt});
  final int round;
  final DateTime? finishedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
        ),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alhamdulillah, khatam ke-$round',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (finishedAt != null)
                  Text(
                    'Selesai ${formatDateKeyShort(dateKey(finishedAt!))}. '
                    'Semoga menjadi syafaat. Putaran baru siap dimulai.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xF2FFFFFF),
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

class _NoTargetCard extends StatelessWidget {
  const _NoTargetCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(color: _cream),
          child: const Row(
            children: [
              Icon(Icons.flag_rounded, color: _amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Atur target khatam untuk mendapat target baca harian',
                  style: TextStyle(fontSize: 13, color: _stone),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target, required this.onTap});
  final QuranDailyTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = target.reached;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'TARGET HARI INI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xCCB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.overdue
                          ? 'Batas ${formatDateKeyShort(target.targetDate)} terlewat'
                          : 'Khatam ${formatDateKeyShort(target.targetDate)} · '
                                'sisa ${target.daysLeft} hari',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: target.overdue
                            ? const Color(0xFFDC2626)
                            : _muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                done
                    ? 'Masyaa Allah, target hari ini tercapai'
                    : 'Sampai ${formatAyah(target.targetAyah)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              Text(
                done
                    ? 'Tambahan bacaan meringankan hari-hari berikutnya'
                    : 'Akhir halaman ${target.targetPage} · '
                          '${formatPages(target.pagesPerDay)} halaman hari ini',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: target.fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF6E7CC),
                    valueColor: AlwaysStoppedAnimation(
                      done ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatPages(target.pagesToday)} dari '
                '${formatPages(target.pagesPerDay)} halaman',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetSheet extends StatelessWidget {
  const _TargetSheet({required this.today, required this.hasTarget});
  final String today;
  final bool hasTarget;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Target khatam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dihitung dari hari ini. Sisa bacaan dibagi rata ke hari yang '
              'tersisa, jadi bila tertinggal target harian menyesuaikan.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in _targetChoices)
                  ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _line),
                    label: Text(
                      '$days hari · ${formatDateKeyShort(targetDateFor(today, days))}',
                    ),
                    onPressed: () => Navigator.pop(context, days),
                  ),
              ],
            ),
            if (hasTarget) ...[
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _amber),
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Hapus target'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

/// 30 kotak juz: penuh = selesai, terisi sebagian = sedang dibaca. Ketuk
/// untuk mencatat bacaan di juz itu.
class _JuzGrid extends StatelessWidget {
  const _JuzGrid({required this.lastAyah, required this.onTap});
  final int lastAyah;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final currentJuz = lastAyah == 0 ? 1 : juzOf(lastAyah);
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var j = 1; j <= totalJuz; j++)
          _JuzCell(
            juz: j,
            fraction: juzProgressAfter(j, lastAyah),
            current: j == currentJuz && lastAyah < totalAyahs,
            onTap: () => onTap(j),
          ),
      ],
    );
  }
}

class _JuzCell extends StatelessWidget {
  const _JuzCell({
    required this.juz,
    required this.fraction,
    required this.current,
    required this.onTap,
  });
  final int juz;
  final double fraction;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = fraction >= 1;
    return Semantics(
      button: true,
      label: 'Juz $juz, ${(fraction * 100).round()} persen',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.white),
              // isian dari bawah sesuai progress juz
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fraction,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: done
                            ? const [Color(0xFFEA580C), Color(0xFFFBBF24)]
                            : const [Color(0xFFFCD34D), Color(0xFFFDE68A)],
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: current ? _amber : _line,
                    width: current ? 2 : 1,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$juz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: done ? Colors.white : _stone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.onDelete});
  final QuranLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pages = log.toAyah >= log.fromAyah
        ? pagesBetween(log.fromAyah, log.toAyah)
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              formatDateKeyShort(log.date),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _amber,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.fromAyah == log.toAyah
                      ? formatAyah(log.toAyah)
                      : '${formatAyah(log.fromAyah)} – ${formatAyah(log.toAyah)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _stone,
                  ),
                ),
                Text(
                  'Juz ${juzOf(log.toAyah)} · hlm ${pageOf(log.toAyah)}'
                  '${pages > 0 ? ' · ${formatPages(pages)} halaman' : ''}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus catatan',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: const Text(
      'Catatan bacaan akan muncul di sini. Setiap sesi tersimpan, jadi '
      'kalau salah input cukup dihapus.',
      style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
    ),
  );
}

/// Pintu ke mushaf (baca + tajwid) & catatan pribadi.
class _ReadCard extends StatelessWidget {
  const _ReadCard();

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33064E3B),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFFF2D38A)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Baca Al-Qur'an",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mushaf Standar Indonesia dengan warna tajwid, terjemahan, dan '
            'catatan pribadi per ayat.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xCCFFFFFF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF2D38A),
                    foregroundColor: const Color(0xFF0C3A33),
                  ),
                  onPressed: () => _push(context, const QuranHomePage()),
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: const Text('Buka mushaf'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                  ),
                  onPressed: () => _push(context, const QuranNotesPage()),
                  icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                  label: const Text('Catatan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

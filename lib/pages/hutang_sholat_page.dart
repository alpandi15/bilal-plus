import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/app_database_scope.dart';
import '../services/hutang_sholat.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/ibadah/sholat_dalil_sheet.dart';
import '../widgets/report/insight_widgets.dart' show longDate;
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _teal = Color(0xFF0F766E);

/// Hutang sholat (qadha) yang dicicil: sisa per waktu, tombol "Bayar 1",
/// penambahan manual atau dari catatan yang dipilih sendiri, dan riwayat.
class HutangSholatPage extends StatelessWidget {
  const HutangSholatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final location = UserLocationScope.of(context).location;
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Hutang Sholat',
            subtitle: 'Cicil qadha sedikit demi sedikit',
            trailing: IconButton(
              tooltip: 'Tentang hutang sholat',
              onPressed: () => showHutangSholatSheet(context),
              icon: const Icon(Icons.info_outline_rounded, color: _amber),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SholatQadhaEntry>>(
              stream: db.ibadahDao.watchSholatQadha(),
              builder: (context, snap) {
                final entries = snap.data ?? const <SholatQadhaEntry>[];
                final debt = sholatDebt(entries, today: today);
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
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
                            _Summary(debt: debt, today: today),
                            const SizedBox(height: 14),
                            _PrayerRows(debt: debt, today: today),
                            const SizedBox(height: 14),
                            _Actions(today: today),
                            if (entries.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _History(entries: entries),
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
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.debt, required this.today});
  final SholatDebt debt;
  final String today;

  @override
  Widget build(BuildContext context) {
    final eta = debt.daysToSettle;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: debt.settled
              ? const [Color(0xFF0F766E), Color(0xFF064E3B)]
              : const [Color(0xFFB45309), Color(0xFF7C2D12)],
        ),
      ),
      child: debt.isEmpty
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada hutang tercatat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bila ada sholat yang ingin kamu qadha, tambahkan di bawah '
                  'lalu cicil - alhamdulillah, pintu taubat selalu terbuka.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFFFDE7C4),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.settled ? 'LUNAS, ALHAMDULILLAH' : 'SISA HUTANG',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: Color(0xFFFDE7C4),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${debt.left}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'sholat',
                      style: TextStyle(fontSize: 15, color: Color(0xFFFDE7C4)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: debt.fraction,
                    minHeight: 8,
                    backgroundColor: const Color(0x33FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${debt.paid} dari ${debt.added} sudah dibayar '
                  '(${(debt.fraction * 100).floor()}%)'
                  '${eta == null ? '' : ' · perkiraan lunas $eta hari lagi '
                            'bila kecepatanmu bertahan'}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFFFDE7C4),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PrayerRows extends StatelessWidget {
  const _PrayerRows({required this.debt, required this.today});
  final SholatDebt debt;
  final String today;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          for (final (i, p) in hutangPrayers.indexed) ...[
            if (i > 0) const Divider(height: 1, color: _line),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hutangPrayerNames[p]!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _stone,
                      ),
                    ),
                  ),
                  Text(
                    '${debt.remaining[p]}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: (debt.remaining[p] ?? 0) > 0 ? _amber : _muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _teal),
                    onPressed: (debt.remaining[p] ?? 0) == 0
                        ? null
                        : () async {
                            await db.ibadahDao.paySholatQadha(
                              p,
                              1,
                              date: today,
                            );
                          },
                    child: const Text('Bayar 1'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.today});
  final String today;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _amber),
          onPressed: () => _addSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah hutang'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: _amber),
          onPressed: () => _fromRecords(context),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Dari catatan'),
        ),
      ),
    ],
  );

  Future<void> _addSheet(BuildContext context) async {
    final db = AppDatabaseScope.of(context);
    final result = await showModalBottomSheet<(String?, int)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => const _AddSheet(),
    );
    if (result == null || result.$2 <= 0) return;
    final (prayer, n) = result;
    for (final p in prayer == null ? hutangPrayers : [prayer]) {
      await db.ibadahDao.addSholatQadha(p, n);
    }
  }

  Future<void> _fromRecords(BuildContext context) async {
    final db = AppDatabaseScope.of(context);
    final to = dateKey(parseDateKey(today).subtract(const Duration(days: 1)));
    final from = dateKey(
      parseDateKey(today).subtract(const Duration(days: 60)),
    );
    final data = await db.ibadahDao.loadRange(from, to);
    final entries = await db.ibadahDao.sholatQadhaEntriesAll();
    final already = {
      for (final e in entries)
        if (e.source == 'catatan' && e.date != null) '${e.date}|${e.prayer}',
    };
    final missed = missedFromRecords(data, today: today, already: already);
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<List<MissedPrayer>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => _MissedSheet(missed: missed),
    );
    if (picked == null) return;
    for (final m in picked) {
      await db.ibadahDao.addSholatQadha(
        m.prayer,
        1,
        source: 'catatan',
        date: m.date,
      );
    }
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  String? _prayer; // null = semua waktu
  int _count = 1;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tambah hutang',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _stone,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Boleh perkiraan kasar; bisa dikoreksi lewat riwayat.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Semua waktu'),
              selected: _prayer == null,
              onSelected: (_) => setState(() => _prayer = null),
            ),
            for (final p in hutangPrayers)
              ChoiceChip(
                label: Text(hutangPrayerNames[p]!),
                selected: _prayer == p,
                onSelected: (_) => setState(() => _prayer = p),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: _count > 1 ? () => setState(() => _count--) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$_count',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _stone,
                    ),
                  ),
                  Text(
                    _prayer == null ? 'hari (tiap waktu)' : 'kali sholat',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => setState(() => _count++),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final n in const [5, 10, 30, 100])
              ActionChip(
                label: Text('+$n'),
                onPressed: () => setState(() => _count += n),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () => Navigator.of(context).pop((_prayer, _count)),
            child: Text(
              _prayer == null
                  ? 'Tambah $_count hari (${_count * 5} sholat)'
                  : 'Tambah $_count ${hutangPrayerNames[_prayer]}',
            ),
          ),
        ),
      ],
    ),
  );
}

class _MissedSheet extends StatefulWidget {
  const _MissedSheet({required this.missed});
  final List<MissedPrayer> missed;

  @override
  State<_MissedSheet> createState() => _MissedSheetState();
}

class _MissedSheetState extends State<_MissedSheet> {
  final _picked = <MissedPrayer>{};

  @override
  Widget build(BuildContext context) {
    final m = widget.missed;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dari catatan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.isEmpty
                      ? 'Tidak ada sholat yang belum tercatat dalam 60 hari '
                            'terakhir (hari berhalangan dilewati).'
                      : 'Sholat yang belum tercatat dalam 60 hari terakhir. '
                            'Belum tercatat belum tentu terlewat - centang '
                            'hanya yang memang ingin kamu qadha.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              children: [
                for (final x in m.reversed)
                  CheckboxListTile(
                    dense: true,
                    activeColor: _amber,
                    value: _picked.contains(x),
                    onChanged: (v) => setState(
                      () => v == true ? _picked.add(x) : _picked.remove(x),
                    ),
                    title: Text(
                      '${hutangPrayerNames[x.prayer]} · ${longDate(x.date)}',
                    ),
                  ),
              ],
            ),
          ),
          if (m.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _picked.length == m.length
                            ? _picked.clear()
                            : _picked.addAll(m);
                      }),
                      child: Text(
                        _picked.length == m.length
                            ? 'Kosongkan'
                            : 'Pilih semua',
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _amber),
                      onPressed: _picked.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_picked.toList()),
                      child: Text('Tambahkan ${_picked.length}'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.entries});
  final List<SholatQadhaEntry> entries;

  String _label(SholatQadhaEntry e) {
    final name = hutangPrayerNames[e.prayer] ?? e.prayer;
    final n = e.count.abs();
    return switch (e.source) {
      'bayar' => 'Bayar $n $name',
      'catatan' => '+$n $name (dari catatan ${longDate(e.date ?? '')})',
      _ => '+$n $name',
    };
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final shown = entries.take(30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'RIWAYAT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: _muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              for (final (i, e) in shown.indexed) ...[
                if (i > 0) const Divider(height: 1, color: _line),
                ListTile(
                  dense: true,
                  title: Text(
                    _label(e),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: e.count < 0 ? _teal : _stone,
                    ),
                  ),
                  subtitle: Text(
                    longDate(dateKey(e.createdAt)),
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  trailing: IconButton(
                    tooltip: 'Batalkan',
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    onPressed: () => db.ibadahDao.deleteSholatQadha(e.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

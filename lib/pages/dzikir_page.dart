import 'package:flutter/material.dart';

import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/dzikir.dart';
import '../services/haptics.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';
import '../widgets/hadith_ref_text.dart';
import 'tasbih_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _green = Color(0xFF16A34A);

/// Bacaan dzikir pagi & petang (Hisnul Muslim) dengan penghitung per
/// dzikir. Selesai semua = item "Dzikir pagi/petang" di checklist hari ini
/// tercentang otomatis. Hitungan tersimpan per tanggal & sesi.
const _prayerNames = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

class DzikirPage extends StatefulWidget {
  const DzikirPage({super.key, this.session});

  /// null = sesuai jam (pagi sejak Subuh sampai sebelum Ashar).
  final DzikirSession? session;

  @override
  State<DzikirPage> createState() => _DzikirPageState();
}

class _DzikirPageState extends State<DzikirPage> {
  DzikirSession? _session;

  /// Sholat yang dzikirnya sedang dibaca (sesi setelah sholat).
  String _prayer = 'subuh';
  Map<int, int> _counts = {};
  bool _loaded = false;
  String? _today;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null) return;
    final loc = UserLocationScope.of(context).location;
    _today = dateKey(calc.todayInZone(calc.timezoneFromLongitude(loc.long)));
    _session =
        widget.session ??
        suggestedSession(
          DateTime.now(),
          latitude: loc.lat,
          longitude: loc.long,
        );
    _prayer = lastSholat(
      DateTime.now(),
      latitude: loc.lat,
      longitude: loc.long,
    );
    _load();
  }

  /// Kunci simpan progres: per tanggal, dan per sholat untuk sesi setelah
  /// sholat (dibaca lima kali sehari).
  String get _slot =>
      _session == DzikirSession.sholat ? '${_today!}_$_prayer' : _today!;

  void _switchPrayer(String p) {
    if (p == _prayer) return;
    setState(() {
      _prayer = p;
      _loaded = false;
    });
    _load();
  }

  Future<void> _load() async {
    final counts = await DzikirProgressStore.load(_session!, _slot);
    if (mounted) {
      setState(() {
        _counts = counts;
        _loaded = true;
      });
    }
  }

  void _switch(DzikirSession s) {
    if (s == _session) return;
    setState(() {
      _session = s;
      _loaded = false;
    });
    _load();
  }

  bool get _haptic => AppSettingsScope.maybeOf(context)?.haptic ?? true;

  Future<void> _setCount(Dzikir d, int value) async {
    final before = _allDone;
    setState(() => _counts[d.id] = value.clamp(0, 99999));
    await DzikirProgressStore.save(_session!, _slot, _counts);
    if (!before && _allDone) await _markChecklist();
  }

  void _tap(Dzikir d) {
    final c = _counts[d.id] ?? 0;
    if (c >= d.repeat) return;
    final reached = c + 1 >= d.repeat;
    // dzikir terakhir yang tuntas: pola "selesai semua" (di _markChecklist)
    final last =
        reached &&
        _list.every((x) => x.id == d.id || (_counts[x.id] ?? 0) >= x.repeat);
    if (_haptic && !last) {
      Haptics.play(reached ? HapticKind.target : HapticKind.tap);
    }
    _setCount(d, c + 1);
  }

  Future<void> _fullscreen(Dzikir d) async {
    await openTasbih(
      context,
      title: d.title,
      arabic: d.repeat <= 10 && d.arabicFor(_session!).length < 90
          ? d.arabicFor(_session!)
          : null,
      latin: d.latinFor(_session!).length < 80 ? d.latinFor(_session!) : null,
      target: d.repeat,
      initial: _counts[d.id] ?? 0,
      onChanged: (v) => _setCount(d, v),
    );
  }

  List<Dzikir> get _list => dzikirFor(_session!, prayer: _prayer);

  bool get _allDone => _list.every((d) => (_counts[d.id] ?? 0) >= d.repeat);

  Future<void> _markChecklist() async {
    final db = AppDatabaseScope.of(context);
    final items = await db.ibadahDao.watchItems(includeInactive: true).first;
    final item = items.where((i) => i.key == _session!.itemKey).firstOrNull;
    if (item != null) await db.ibadahDao.setValue(_today!, item.id, 1);
    if (!mounted) return;
    if (_haptic) Haptics.play(HapticKind.complete);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item != null
              ? 'Masyaa Allah, ${_session!.title.toLowerCase()} selesai - '
                    'tercatat di checklist hari ini.'
              : 'Masyaa Allah, dzikir setelah sholat '
                    '${_prayerNames[_prayer]} selesai.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session!;
    final settings = AppSettingsScope.maybeOf(context);
    final list = _list;
    final done = list.where((d) => (_counts[d.id] ?? 0) >= d.repeat).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: session.title,
            subtitle: "Hisnul Muslim · $done/${list.length} selesai",
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF92400E)),
              onSelected: (v) {
                if (v == 'latin') settings?.setShowLatin(!settings.showLatin);
                if (v == 'arti') settings?.setShowArti(!settings.showArti);
                if (v == 'reset') {
                  setState(() => _counts = {});
                  DzikirProgressStore.save(session, _slot, _counts);
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'latin',
                  checked: settings?.showLatin ?? true,
                  child: const Text('Tampilkan latin'),
                ),
                CheckedPopupMenuItem(
                  value: 'arti',
                  checked: settings?.showArti ?? true,
                  child: const Text('Tampilkan terjemahan'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Ulangi dari awal'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<DzikirSession>(
                  segments: const [
                    ButtonSegment(
                      value: DzikirSession.pagi,
                      icon: Icon(Icons.wb_sunny_rounded, size: 16),
                      label: Text('Pagi'),
                    ),
                    ButtonSegment(
                      value: DzikirSession.petang,
                      icon: Icon(Icons.nights_stay_rounded, size: 16),
                      label: Text('Petang'),
                    ),
                    ButtonSegment(
                      value: DzikirSession.sholat,
                      icon: Icon(Icons.mosque_rounded, size: 16),
                      label: Text('Usai Sholat'),
                    ),
                  ],
                  selected: {session},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => _switch(v.first),
                ),
                if (session == DzikirSession.sholat) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final p in _prayerNames.keys)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(_prayerNames[p]!),
                              selected: _prayer == p,
                              selectedColor: const Color(0xFFFDE68A),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => _switchPrayer(p),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: list.isEmpty ? 0 : done / list.length),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF6E7CC),
                      valueColor: AlwaysStoppedAnimation(
                        done == list.length ? _green : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: list.length + 1,
                    itemBuilder: (context, i) {
                      if (i == list.length) {
                        return _FinishCard(
                          done: _allDone,
                          onFinish: _markChecklist,
                        );
                      }
                      final d = list[i];
                      return _DzikirCard(
                        number: i + 1,
                        dzikir: d,
                        session: session,
                        count: _counts[d.id] ?? 0,
                        showLatin: settings?.showLatin ?? true,
                        showArti: settings?.showArti ?? true,
                        onTap: () => _tap(d),
                        onFullscreen: () => _fullscreen(d),
                        onUndo: (_counts[d.id] ?? 0) > 0
                            ? () => _setCount(d, (_counts[d.id] ?? 0) - 1)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DzikirCard extends StatelessWidget {
  const _DzikirCard({
    required this.number,
    required this.dzikir,
    required this.session,
    required this.count,
    required this.showLatin,
    required this.showArti,
    required this.onTap,
    required this.onFullscreen,
    required this.onUndo,
  });

  final int number;
  final Dzikir dzikir;
  final DzikirSession session;
  final int count;
  final bool showLatin, showArti;
  final VoidCallback onTap, onFullscreen;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final done = count >= dzikir.repeat;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: done ? const Color(0xFF86EFAC) : _line),
        boxShadow: done
            ? null
            : const [
                BoxShadow(
                  color: Color(0x10785624),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? _green : const Color(0xFFFFF1D6),
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '$number',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _amber,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dzikir.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${dzikir.repeat}×',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ArabicText(
            dzikir.arabicFor(session),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 24,
              height: 2.0,
              color: Color(0xFF1C1917),
            ),
          ),
          if (showLatin) ...[
            const SizedBox(height: 10),
            Text(
              dzikir.latinFor(session),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF92400E),
              ),
            ),
          ],
          if (showArti) ...[
            const SizedBox(height: 8),
            Text(
              dzikir.artiFor(session),
              style: const TextStyle(fontSize: 13, height: 1.5, color: _stone),
            ),
          ],
          if (dzikir.note != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: _amber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dzikir.note!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HadithRefText(
                  dzikir.source,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              if (onUndo != null)
                IconButton(
                  tooltip: 'Kurangi',
                  visualDensity: VisualDensity.compact,
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18, color: _muted),
                ),
              if (dzikir.repeat >= 7)
                IconButton(
                  tooltip: 'Hitung layar penuh',
                  visualDensity: VisualDensity.compact,
                  onPressed: onFullscreen,
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    size: 18,
                    color: _amber,
                  ),
                ),
              const SizedBox(width: 4),
              _CountButton(count: count, target: dzikir.repeat, onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol hitung bulat dengan cincin progres: "2/3" -> centang.
class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.count,
    required this.target,
    required this.onTap,
  });
  final int count, target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = count >= target;
    return Semantics(
      button: true,
      label: done ? 'Selesai' : 'Hitung, $count dari $target',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: (count / target).clamp(0, 1)),
                duration: const Duration(milliseconds: 220),
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFF6E7CC),
                  valueColor: AlwaysStoppedAnimation(
                    done ? _green : const Color(0xFFF59E0B),
                  ),
                  constraints: const BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _green : _amber,
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            target == 1 ? 'Baca' : '$count/$target',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
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

class _FinishCard extends StatelessWidget {
  const _FinishCard({required this.done, required this.onFinish});
  final bool done;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: done ? _green : _amber,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onFinish,
        icon: Icon(done ? Icons.check_circle_rounded : Icons.done_all_rounded),
        label: Text(
          done ? 'Selesai - tercatat di checklist' : 'Tandai selesai',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

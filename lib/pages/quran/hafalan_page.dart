import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../db/app_database_scope.dart';
import '../../services/app_settings.dart';
import '../../services/quran_index.dart';
import '../../services/quran_text.dart';
import '../../widgets/arabic_font.dart';
import '../../widgets/quran/quran_ornaments.dart';
import '../../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

/// Surah Juz 30 (An-Naba' .. An-Nas) - lazim dihafal lebih dulu.
bool _isJuz30(int surah) => surah >= 78;

enum _Filter { juz30, progress, done, all }

const _filterLabel = {
  _Filter.juz30: 'Juz 30',
  _Filter.progress: 'Sedang dihafal',
  _Filter.done: 'Sudah hafal',
  _Filter.all: 'Semua surah',
};

/// Mode hafalan: progres hafalan per surah; ketuk surah untuk menghafal
/// ayat demi ayat (ayat bisa disembunyikan, ulangi berkali-kali, tandai
/// hafal). Tersimpan di HP & ikut cadangan data.
class HafalanPage extends StatefulWidget {
  const HafalanPage({super.key});

  @override
  State<HafalanPage> createState() => _HafalanPageState();
}

class _HafalanPageState extends State<HafalanPage> {
  QuranText? _text;
  _Filter _filter = _Filter.juz30;

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
    final text = _text;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(title: 'Hafalan', subtitle: "Menghafal Al-Qur'an"),
          Expanded(
            child: text == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<Set<int>>(
                    stream: dao.watchHafalan(),
                    builder: (context, snap) {
                      final hafal = snap.data ?? const <int>{};
                      int doneOf(QuranSurah s) => [
                        for (var i = 0; i < s.ayahCount; i++)
                          if (hafal.contains(s.firstIndex + i)) 1,
                      ].length;
                      final surahs = [
                        for (final s in text.surahs)
                          if (switch (_filter) {
                            _Filter.juz30 => _isJuz30(s.number),
                            _Filter.progress =>
                              doneOf(s) > 0 && doneOf(s) < s.ayahCount,
                            _Filter.done => doneOf(s) == s.ayahCount,
                            _Filter.all => true,
                          })
                            s,
                      ];
                      // Juz 30 dihafal dari surah pendek (An-Nas) ke atas
                      if (_filter == _Filter.juz30) {
                        surahs.sort((a, b) => b.number.compareTo(a.number));
                      }
                      final fullSurah = text.surahs
                          .where((s) => doneOf(s) == s.ayahCount)
                          .length;
                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          32 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          _Summary(ayat: hafal.length, surah: fullSurah),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final f in _Filter.values)
                                ChoiceChip(
                                  label: Text(_filterLabel[f]!),
                                  selected: _filter == f,
                                  selectedColor: const Color(0xFFFDE68A),
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setState(() => _filter = f),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (surahs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _filter == _Filter.done
                                    ? 'Belum ada surah yang hafal penuh. '
                                          'Semangat, mulai dari yang pendek!'
                                    : 'Belum ada surah yang sedang dihafal.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _muted),
                              ),
                            ),
                          for (final s in surahs)
                            _SurahTile(
                              surah: s,
                              done: doneOf(s),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      HafalanSurahPage(text: text, surah: s),
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
  const _Summary({required this.ayat, required this.surah});
  final int ayat, surah;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HAFALANMU',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Color(0xFFF2D38A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$ayat ayat',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '$surah surah hafal penuh · '
                '${(ayat * 100 / totalAyahs).toStringAsFixed(1)}% Al-Qur\'an',
                style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.psychology_rounded,
          color: Color(0xFFF2D38A),
          size: 44,
        ),
      ],
    ),
  );
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.done,
    required this.onTap,
  });

  final QuranSurah surah;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final full = done == surah.ayahCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: full ? const Color(0xFFA7F3D0) : _line),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${surah.number}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _amber,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _stone,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: done / surah.ayahCount,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFF6E7CC),
                          valueColor: const AlwaysStoppedAnimation(_emerald),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        full
                            ? 'Hafal · ${surah.ayahCount} ayat'
                            : '$done / ${surah.ayahCount} ayat',
                        style: TextStyle(
                          fontSize: 11,
                          color: full ? _emerald : _muted,
                          fontWeight: full ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (full)
                  const Icon(Icons.verified_rounded, color: _emerald)
                else
                  ArabicText(
                    surah.arabic,
                    style: const TextStyle(fontSize: 20, color: _emerald),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menghafal satu surah: ayat bisa disembunyikan (ketuk untuk mengintip),
/// hitungan ulang per ayat, dan tanda hafal.
class HafalanSurahPage extends StatefulWidget {
  const HafalanSurahPage({super.key, required this.text, required this.surah});
  final QuranText text;
  final QuranSurah surah;

  @override
  State<HafalanSurahPage> createState() => _HafalanSurahPageState();
}

class _HafalanSurahPageState extends State<HafalanSurahPage> {
  /// Sembunyikan teks ayat (kecuali kata pertama sebagai petunjuk).
  bool _hide = false;
  bool _showArti = true;

  /// Ayat yang sedang diintip saat mode sembunyi.
  final _peek = <int>{};

  /// Hitungan ulang per ayat di sesi ini.
  final _reps = <int, int>{};

  /// Target ulang per ayat.
  static const _target = 5;

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).quranDao;
    final size = (AppSettingsScope.maybeOf(context)?.readerSize ?? 28);
    final ayahs = widget.text.ayahsOf(widget.surah.number);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: widget.surah.name,
            subtitle: 'Hafalan · ${widget.surah.ayahCount} ayat',
          ),
          StreamBuilder<Set<int>>(
            stream: dao.watchHafalan(),
            builder: (context, snap) {
              final hafal = snap.data ?? const <int>{};
              final done = ayahs.where((a) => hafal.contains(a.index)).length;
              return Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: ayahs.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _Toolbar(
                        done: done,
                        total: ayahs.length,
                        hide: _hide,
                        showArti: _showArti,
                        onHide: (v) => setState(() {
                          _hide = v;
                          _peek.clear();
                        }),
                        onArti: (v) => setState(() => _showArti = v),
                        onAll: (v) => dao.setHafal(
                          ayahs.first.index,
                          ayahs.last.index,
                          v,
                        ),
                      );
                    }
                    final a = ayahs[i - 1];
                    return _AyahCard(
                      ayah: a,
                      size: size,
                      hidden: _hide && !_peek.contains(a.index),
                      showArti: _showArti,
                      hafal: hafal.contains(a.index),
                      reps: _reps[a.index] ?? 0,
                      target: _target,
                      onPeek: _hide
                          ? () => setState(() {
                              if (!_peek.remove(a.index)) _peek.add(a.index);
                            })
                          : null,
                      onRepeat: () => setState(
                        () => _reps[a.index] = (_reps[a.index] ?? 0) + 1,
                      ),
                      onHafal: (v) => dao.setHafal(a.index, a.index, v),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.done,
    required this.total,
    required this.hide,
    required this.showArti,
    required this.onHide,
    required this.onArti,
    required this.onAll,
  });

  final int done, total;
  final bool hide, showArti;
  final ValueChanged<bool> onHide, onArti, onAll;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$done / $total ayat hafal',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _emerald),
              onPressed: () => onAll(done < total),
              child: Text(done < total ? 'Tandai semua' : 'Hapus semua'),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 6,
            backgroundColor: const Color(0xFFF6E7CC),
            valueColor: const AlwaysStoppedAnimation(_emerald),
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeTrackColor: _amber,
          value: hide,
          onChanged: onHide,
          title: const Text(
            'Sembunyikan ayat',
            style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
          ),
          subtitle: const Text(
            'Hanya kata pertama sebagai petunjuk - ketuk ayat untuk mengintip.',
            style: TextStyle(fontSize: 11.5, color: _muted),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeTrackColor: _amber,
          value: showArti,
          onChanged: onArti,
          title: const Text(
            'Tampilkan terjemahan',
            style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
          ),
        ),
      ],
    ),
  );
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.size,
    required this.hidden,
    required this.showArti,
    required this.hafal,
    required this.reps,
    required this.target,
    required this.onPeek,
    required this.onRepeat,
    required this.onHafal,
  });

  final QuranAyah ayah;
  final double size;
  final bool hidden, showArti, hafal;
  final int reps, target;
  final VoidCallback? onPeek;
  final VoidCallback onRepeat;
  final ValueChanged<bool> onHafal;

  @override
  Widget build(BuildContext context) {
    final words = ayah.arabic.split(' ');
    final style = TextStyle(
      fontSize: size,
      height: 2,
      color: const Color(0xFF1C1917),
    );
    Widget arabic = ArabicText(ayah.arabic, style: style);
    if (hidden) {
      // kata pertama tetap terlihat, sisanya diburamkan
      arabic = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArabicText(words.first, style: style.copyWith(color: _amber)),
          if (words.length > 1)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: ArabicText(
                words.skip(1).join(' '),
                style: style.copyWith(color: const Color(0x991C1917)),
              ),
            ),
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: hafal ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hafal ? const Color(0xFFA7F3D0) : _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AyahMedallion(number: ayah.number, size: 32, arabicDigits: false),
              const Spacer(),
              // hitungan ulang: ketuk tiap selesai mengulang sekali
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: reps >= target ? _emerald : _amber,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onRepeat,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text('Ulang $reps/$target'),
              ),
              FilterChip(
                label: const Text('Hafal'),
                selected: hafal,
                showCheckmark: true,
                checkmarkColor: Colors.white,
                selectedColor: _emerald,
                labelStyle: TextStyle(
                  color: hafal ? Colors.white : _stone,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: onHafal,
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPeek,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: arabic,
            ),
          ),
          if (showArti) ...[
            const SizedBox(height: 6),
            Text(
              ayah.translation,
              style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
            ),
          ],
        ],
      ),
    );
  }
}

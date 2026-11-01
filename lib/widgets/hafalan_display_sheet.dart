import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/hafalan_cue.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Lembar "Tampilan hafalan": ayat penuh atau hanya kata awal tiap ayat
/// (petunjuk) di halaman hafalan, dan satu ayat penuh atau beberapa ayat di
/// widget layar utama.
Future<void> showHafalanDisplaySheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => const _DisplaySheet(),
    );

class _DisplaySheet extends StatelessWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context) {
    final s = AppSettingsScope.maybeOf(context);
    if (s == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tampilan hafalan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mode petunjuk: tiap ayat hanya menampilkan kata-kata awalnya - '
                'sisanya kamu ingat sendiri, lalu periksa.',
                style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
              ),
              const _Heading('DI HALAMAN HAFALAN'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Ayat penuh')),
                  ButtonSegment(value: true, label: Text('Petunjuk awal')),
                ],
                selected: {s.hafalanCue},
                onSelectionChanged: (v) => s.setHafalanCue(v.first),
              ),
              const _Heading('KATA AWAL PER AYAT'),
              Wrap(
                spacing: 8,
                children: [
                  for (var n = cueWordsMin; n <= cueWordsMax; n++)
                    ChoiceChip(
                      label: Text('$n kata'),
                      selected: s.cueWords == n,
                      selectedColor: const Color(0xFFFDE68A),
                      onSelected: (_) => s.setCueWords(n),
                    ),
                ],
              ),
              const _Heading('DI WIDGET LAYAR UTAMA'),
              SegmentedButton<HafalanWidgetMode>(
                segments: const [
                  ButtonSegment(
                    value: HafalanWidgetMode.full,
                    label: Text('1 ayat penuh'),
                  ),
                  ButtonSegment(
                    value: HafalanWidgetMode.cue,
                    label: Text('Beberapa ayat'),
                  ),
                ],
                selected: {s.hafalanWidgetMode},
                onSelectionChanged: (v) => s.setHafalanWidgetMode(v.first),
              ),
              if (s.hafalanWidgetMode == HafalanWidgetMode.cue) ...[
                const _Heading('JUMLAH AYAT DI WIDGET'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var n = cueCountMin; n <= cueCountMax; n++)
                      ChoiceChip(
                        label: Text('$n ayat'),
                        selected: s.hafalanWidgetCount == n,
                        selectedColor: const Color(0xFFFDE68A),
                        onSelected: (_) => s.setHafalanWidgetCount(n),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Widget menampilkan ayat-ayat berikutnya yang belum hafal, '
                    'hanya kata awalnya. '
                    '"Intip" memperlihatkan ayat pertamanya utuh; "Hafal" '
                    'menandainya dan daftar bergeser.',
                    style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Satu ayat berikutnya yang belum hafal, dengan tombol '
                    '"Tutup" untuk menyamarkannya.',
                    style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: _amber,
      ),
    ),
  );
}

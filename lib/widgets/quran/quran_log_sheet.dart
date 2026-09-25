import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/quran_meta.dart';
import '../../services/quran_index.dart';
import '../../services/quran_target.dart';
import '../../utils/date_key.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Hasil lembar catat bacaan: sudah membaca sampai (dan termasuk) ayat
/// global [toAyah] pada tanggal [date] (kunci tanggal).
typedef QuranLogResult = ({int toAyah, String date});

/// Lembar "Sudah baca sampai mana?": pilih Juz -> Surah (hanya yang ada di
/// juz itu) -> Ayat (hanya rentang di juz itu), plus pintasan akhir
/// halaman/surah/juz. [lastAyah] = posisi terakhir (0 = belum mulai),
/// [today] = kunci tanggal hari ini di zona lokasi. [initialJuz] membuka
/// langsung ke juz tertentu (mis. dari grid juz).
Future<QuranLogResult?> showQuranLogSheet(
  BuildContext context, {
  required int lastAyah,
  required String today,
  int? initialJuz,
}) => showModalBottomSheet<QuranLogResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (_) =>
      QuranLogSheet(lastAyah: lastAyah, today: today, initialJuz: initialJuz),
);

class QuranLogSheet extends StatefulWidget {
  const QuranLogSheet({
    super.key,
    required this.lastAyah,
    required this.today,
    this.initialJuz,
  });

  final int lastAyah;
  final String today;
  final int? initialJuz;

  @override
  State<QuranLogSheet> createState() => _QuranLogSheetState();
}

class _QuranLogSheetState extends State<QuranLogSheet> {
  late int _ayah; // ayat global terpilih
  late int _juz; // juz yang sedang dijelajahi
  late String _date;
  final _juzScroll = ScrollController();

  /// Naik setiap kali ayat diubah dari luar roda (tombol pintas, pilih
  /// surah/juz) supaya roda dibuat ulang di posisi barunya; menggulir roda
  /// sendiri tidak menaikkannya.
  int _pickerVersion = 0;

  @override
  void initState() {
    super.initState();
    _date = widget.today;
    if (widget.initialJuz != null) {
      _juz = widget.initialJuz!;
      final (start, end) = juzRange(_juz);
      // di juz yang sedang dibaca: lanjut dari posisi terakhir
      _ayah = widget.lastAyah >= start && widget.lastAyah < end
          ? _endOfPage(widget.lastAyah + 1)
          : end;
    } else {
      // tebakan awal: menyelesaikan halaman berikutnya
      _ayah = _endOfPage(
        widget.lastAyah >= totalAyahs ? totalAyahs : widget.lastAyah + 1,
      );
      _juz = juzOf(_ayah);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToJuz());
  }

  @override
  void dispose() {
    _juzScroll.dispose();
    super.dispose();
  }

  static int _endOfPage(int ayah) => pageRange(pageOf(ayah)).$2;

  void _scrollToJuz() {
    if (!_juzScroll.hasClients) return;
    const chipExtent = 52.0;
    final target = (_juz - 3) * chipExtent;
    _juzScroll.animateTo(
      target.clamp(0, _juzScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectJuz(int juz) {
    setState(() {
      _juz = juz;
      // pindah juz: pilih ayat terakhir juz itu kecuali posisi ada di dalamnya
      final (start, end) = juzRange(juz);
      if (_ayah < start || _ayah > end) _ayah = end;
      _pickerVersion++;
    });
    _scrollToJuz();
  }

  void _selectSurah(SurahInJuz s) {
    setState(() {
      _ayah = ayahIndex(s.surah, s.lastAyah);
      _pickerVersion++;
    });
  }

  void _setAyah(int ayah, {bool fromWheel = false}) {
    setState(() {
      _ayah = ayah.clamp(1, totalAyahs);
      _juz = juzOf(_ayah);
      if (!fromWheel) _pickerVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final (surah, ayahInSurah) = surahAyahOf(_ayah);
    final inJuz = surahsInJuz(_juz);
    final current = inJuz.firstWhere(
      (s) => s.surah == surah,
      orElse: () => inJuz.last,
    );
    final page = pageOf(_ayah);
    final delta = _ayah > widget.lastAyah
        ? pagesBetween(widget.lastAyah + 1, _ayah)
        : 0.0;
    final yesterday = dateKey(
      parseDateKey(widget.today).subtract(const Duration(days: 1)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sudah baca sampai mana?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _Label('JUZ'),
            SizedBox(
              height: 44,
              child: ListView.separated(
                controller: _juzScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: totalJuz,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _JuzChip(
                  juz: i + 1,
                  selected: _juz == i + 1,
                  done: juzRange(i + 1).$2 <= widget.lastAyah,
                  onTap: () => _selectJuz(i + 1),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _Label('SURAH'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in inJuz)
                    _SurahChip(
                      range: s,
                      selected: s.surah == surah,
                      onTap: () => _selectSurah(s),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _Label('AYAT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 132,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _line),
                      ),
                      child: CupertinoPicker(
                        key: ValueKey(
                          '${_juz}_${current.surah}_$_pickerVersion',
                        ),
                        scrollController: FixedExtentScrollController(
                          initialItem: (ayahInSurah - current.firstAyah).clamp(
                            0,
                            current.lastAyah - current.firstAyah,
                          ),
                        ),
                        itemExtent: 36,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x1FF59E0B),
                            ),
                        onSelectedItemChanged: (i) => _setAyah(
                          ayahIndex(current.surah, current.firstAyah + i),
                          fromWheel: true,
                        ),
                        children: [
                          for (
                            var a = current.firstAyah;
                            a <= current.lastAyah;
                            a++
                          )
                            Center(
                              child: Text(
                                'Ayat $a',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _stone,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 132,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuickButton(
                          label: 'Akhir halaman',
                          onTap: () => _setAyah(_endOfPage(_ayah)),
                        ),
                        const SizedBox(height: 6),
                        _QuickButton(
                          label: 'Akhir surah',
                          onTap: () => _setAyah(
                            ayahIndex(current.surah, current.lastAyah),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _QuickButton(
                          label: 'Akhir juz',
                          onTap: () => _setAyah(juzRange(_juz).$2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${surahName(surah)} ayat $ayahInSurah',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Juz $_juz · Halaman $page'
                      '${delta > 0 ? ' · +${formatPages(delta)} halaman' : ''}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                    if (_ayah <= widget.lastAyah)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Sebelum posisi terakhirmu - posisi akan dimundurkan '
                          'ke sini.',
                          style: TextStyle(fontSize: 11, color: _amber),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: widget.today,
                    label: const Text('Hari ini'),
                  ),
                  ButtonSegment(value: yesterday, label: const Text('Kemarin')),
                ],
                selected: {_date},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _date = v.first),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).pop((toAyah: _ayah, date: _date)),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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

class _JuzChip extends StatelessWidget {
  const _JuzChip({
    required this.juz,
    required this.selected,
    required this.done,
    required this.onTap,
  });
  final int juz;
  final bool selected, done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _amber
          : done
          ? const Color(0xFFFFF1D6)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _amber : _line),
          ),
          child: Text(
            '$juz',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _stone,
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahChip extends StatelessWidget {
  const _SurahChip({
    required this.range,
    required this.selected,
    required this.onTap,
  });
  final SurahInJuz range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final whole =
        range.firstAyah == 1 && range.lastAyah == ayahCount(range.surah);
    return Material(
      color: selected ? _amber : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _amber : _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${range.surah}. ${range.name}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _stone,
                ),
              ),
              Text(
                whole
                    ? '${surahArabicNames[range.surah - 1]} · ${range.lastAyah} ayat'
                    : 'ayat ${range.firstAyah}-${range.lastAyah}',
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

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: _amber,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _line),
      minimumSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onTap,
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

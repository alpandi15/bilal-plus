import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/silsilah_data.dart';
import '../widgets/arabic_font.dart';

const _gold = Color(0xFFF2D38A);
const _goldDeep = Color(0xFFC9A24A);
const _green = Color(0xFF00503C);
const _greenDark = Color(0xFF0C3A33);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Silsilah (nasab) Nabi Muhammad ﷺ sampai 'Adnan dalam bentuk garis waktu,
/// bisa dibaca dari Nabi ke atas atau dari 'Adnan ke bawah, plus nasab
/// ibunda & catatan sumber.
class SilsilahPage extends StatefulWidget {
  const SilsilahPage({super.key});

  @override
  State<SilsilahPage> createState() => _SilsilahPageState();
}

class _SilsilahPageState extends State<SilsilahPage> {
  /// Hero hijau sudah tergulir lewat: ikon status bar jadi gelap supaya
  /// tetap terlihat di latar krem.
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    final scrolled = n.metrics.axis == Axis.vertical && n.metrics.pixels > 260;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  /// true = dari 'Adnan turun ke Nabi ﷺ.
  bool _fromAdnan = false;

  @override
  Widget build(BuildContext context) {
    final order = [
      for (var i = 0; i < silsilahNabi.length; i++) (i, silsilahNabi[i]),
    ];
    final list = _fromAdnan ? order.reversed.toList() : order;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _scrolled ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFAF3),
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Hero()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '21 generasi sampai \'Adnan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _stone,
                          ),
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.north_rounded, size: 14),
                            label: Text('Nabi ﷺ'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.south_rounded, size: 14),
                            label: Text("'Adnan"),
                          ),
                        ],
                        selected: {_fromAdnan},
                        showSelectedIcon: false,
                        onSelectionChanged: (v) =>
                            setState(() => _fromAdnan = v.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                sliver: SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final (gen, person) = list[i];
                    return _TimelineRow(
                      generation: gen,
                      person: person,
                      first: i == 0,
                      last: i == list.length - 1,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MotherCard(),
                      SizedBox(height: 14),
                      _NoteCard(),
                    ],
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3D35), _green, _greenDark],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, top + 4, 8, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.account_tree_rounded, color: _gold, size: 30),
              const SizedBox(height: 8),
              const Text(
                'SILSILAH NABI ﷺ',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Nasab Rasulullah ﷺ yang shahih sampai 'Adnan",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xCCFFFFFF)),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x33F2D38A)),
                ),
                child: const Column(
                  children: [
                    ArabicText(
                      nasabBukhari,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Shahih al-Bukhari, Kitab Manaqib al-Anshar, Bab Mab'ats "
                      'an-Nabi ﷺ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.generation,
    required this.person,
    required this.first,
    required this.last,
  });

  final int generation;
  final Leluhur person;
  final bool first, last;

  @override
  Widget build(BuildContext context) {
    final nabi = generation == 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // garis & nomor generasi
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: first ? Colors.transparent : const Color(0xFFE9D8B4),
                  ),
                ),
                Container(
                  width: nabi ? 34 : 28,
                  height: nabi ? 34 : 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nabi ? _green : const Color(0xFFFFF5DA),
                    border: Border.all(
                      color: nabi ? _gold : _goldDeep,
                      width: 1.5,
                    ),
                  ),
                  child: nabi
                      ? const Icon(Icons.star_rounded, size: 18, color: _gold)
                      : Text(
                          '$generation',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C5A17),
                          ),
                        ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : const Color(0xFFE9D8B4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: nabi ? _NabiCard(person: person) : _PersonCard(person),
            ),
          ),
        ],
      ),
    );
  }
}

class _NabiCard extends StatelessWidget {
  const _NabiCard({required this.person});
  final Leluhur person;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_green, _greenDark],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2600503C),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                person.latin,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            ArabicText(
              person.arabic,
              style: const TextStyle(fontSize: 26, height: 1.6, color: _gold),
            ),
          ],
        ),
        if (person.note != null)
          Text(
            person.note!,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xD9FFFFFF),
            ),
          ),
      ],
    ),
  );
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(this.person);
  final Leluhur person;

  @override
  Widget build(BuildContext context) {
    final highlight = person.tag != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF7E6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? const Color(0xFFFDE68A) : const Color(0xFFF1E4CF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.latin,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFFB45309),
                        ),
                        child: Text(
                          person.tag!,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ArabicText(
                person.arabic,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.6,
                  color: _green,
                ),
              ),
            ],
          ),
          if (person.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                person.note!,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MotherCard extends StatelessWidget {
  const _MotherCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1E4CF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFDB2777)),
            SizedBox(width: 6),
            Text(
              'Nasab ibunda',
              style: TextStyle(fontWeight: FontWeight.w800, color: _stone),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
          children: [
            for (var i = 0; i < nasabIbu.length; i++) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i == nasabIbu.length - 1
                      ? const Color(0xFFFFF7E6)
                      : const Color(0xFFFDF2F8),
                  border: Border.all(
                    color: i == nasabIbu.length - 1
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFFBCFE8),
                  ),
                ),
                child: Text(
                  nasabIbu[i].latin,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _stone,
                  ),
                ),
              ),
              if (i < nasabIbu.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'bin',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Aminah binti Wahb berasal dari Bani Zuhrah; nasabnya bertemu '
          'dengan nasab ayahanda Nabi ﷺ pada Kilab bin Murrah.',
          style: TextStyle(fontSize: 11.5, height: 1.45, color: _muted),
        ),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFDE68A)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 18, color: _goldDeep),
            SizedBox(width: 6),
            Text(
              'Tentang keshahihan',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF7C5A17),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          "Nasab sampai 'Adnan disepakati para ulama nasab dan disebut Imam "
          "Al-Bukhari dalam Shahih-nya. Nasab di atas 'Adnan sampai Nabi "
          "Isma'il bin Ibrahim tidak memiliki riwayat yang shahih - nama dan "
          'jumlah generasinya diperselisihkan - sehingga dicukupkan sampai '
          "'Adnan (lihat Ibnul Qayyim, Zadul Ma'ad).",
          style: TextStyle(fontSize: 12.5, height: 1.55, color: _stone),
        ),
        SizedBox(height: 10),
        ArabicText(
          'إِنَّ اللّٰهَ اصْطَفَى كِنَانَةَ مِنْ وَلَدِ إِسْمَاعِيلَ، '
          'وَاصْطَفَى قُرَيْشًا مِنْ كِنَانَةَ، وَاصْطَفَى مِنْ قُرَيْشٍ بَنِي '
          'هَاشِمٍ، وَاصْطَفَانِي مِنْ بَنِي هَاشِمٍ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 2, color: _green),
        ),
        SizedBox(height: 4),
        Text(
          '"Sesungguhnya Allah memilih Kinanah dari keturunan Isma\'il, '
          'memilih Quraisy dari Kinanah, memilih Bani Hasyim dari Quraisy, '
          'dan memilihku dari Bani Hasyim." (HR. Muslim no. 2276)',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            fontStyle: FontStyle.italic,
            color: _muted,
          ),
        ),
      ],
    ),
  );
}

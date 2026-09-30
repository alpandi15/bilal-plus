import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/asmaul_husna_data.dart';
import '../widgets/arabic_font.dart';

const _gold = Color(0xFFF2D38A);
const _goldDeep = Color(0xFFC9A24A);
const _green = Color(0xFF00503C);
const _greenDark = Color(0xFF0C3A33);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// 99 Asmaul Husna: hero kaligrafi, kisi kartu bermotif bintang delapan,
/// pencarian, mode hafalan (arti disembunyikan), dan tampilan penuh yang
/// bisa digeser antar-nama.
class AsmaulHusnaPage extends StatefulWidget {
  const AsmaulHusnaPage({super.key});

  @override
  State<AsmaulHusnaPage> createState() => _AsmaulHusnaPageState();
}

class _AsmaulHusnaPageState extends State<AsmaulHusnaPage> {
  /// Hero hijau sudah tergulir lewat: ikon status bar jadi gelap supaya
  /// tetap terlihat di latar krem.
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    final scrolled = n.metrics.axis == Axis.vertical && n.metrics.pixels > 260;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  final _query = TextEditingController();
  bool _hafalan = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<AsmaulHusna> get _filtered {
    final q = _query.text.trim().toLowerCase().replaceAll("'", '');
    if (q.isEmpty) return asmaulHusna;
    return [
      for (final a in asmaulHusna)
        if (a.latin.toLowerCase().replaceAll("'", '').contains(q) ||
            a.arti.toLowerCase().contains(q) ||
            '${a.number}' == q)
          a,
    ];
  }

  void _open(AsmaulHusna a) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) =>
          AsmaulHusnaDetailPage(initial: a.number - 1, hideArti: _hafalan),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(
            begin: 0.96,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 700 ? 4 : (width > 520 ? 3 : 2);
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _query,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau arti',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Hapus',
                                    onPressed: () {
                                      _query.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFF1E4CF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFF1E4CF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'Mode hafalan: sembunyikan arti',
                        child: FilterChip(
                          avatar: Icon(
                            _hafalan
                                ? Icons.visibility_off_rounded
                                : Icons.psychology_rounded,
                            size: 18,
                            color: _hafalan ? Colors.white : _green,
                          ),
                          label: const Text('Hafalan'),
                          selected: _hafalan,
                          showCheckmark: false,
                          selectedColor: _green,
                          labelStyle: TextStyle(
                            color: _hafalan ? Colors.white : _stone,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (v) => setState(() => _hafalan = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'Tidak ditemukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _NameCard(
                    name: list[i],
                    hideArti: _hafalan,
                    onTap: () => _open(list[i]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: const _HadithCard(),
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
        child: Stack(
          children: [
            // pola bintang samar di latar
            const Positioned.fill(
              child: CustomPaint(painter: _PatternPainter()),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 8, 26),
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
                      const Spacer(),
                    ],
                  ),
                  const ArabicText(
                    'اَلْأَسْمَاءُ الْحُسْنٰى',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 44, height: 1.7, color: _gold),
                  ),
                  const Text(
                    'ASMAUL HUSNA',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '99 nama Allah yang terindah',
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
                          'وَلِلّٰهِ الْاَسْمَاۤءُ الْحُسْنٰى فَادْعُوْهُ بِهَا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.8,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '"Dan Allah memiliki Asmaul Husna, maka bermohonlah '
                          'kepada-Nya dengan menyebutnya." (QS. Al-A\'raf: 180)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                            color: Color(0xD9FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({
    required this.name,
    required this.hideArti,
    required this.onTap,
  });

  final AsmaulHusna name;
  final bool hideArti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final long = name.arabic.length > 14;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF1E4CF)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFFBF0)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F785624),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // bintang delapan samar di belakang kaligrafi
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 26, 14, 50),
                  child: CustomPaint(
                    painter: _StarPainter(
                      color: Color(0x1FC9A24A),
                      fill: Color(0x0AF2D38A),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: _NumberBadge(number: name.number),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ArabicText(
                            name.arabic,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: long ? 26 : 34,
                              height: 1.6,
                              color: _green,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      name.latin,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: hideArti
                          ? const Text(
                              '• • •',
                              key: ValueKey('hidden'),
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: _goldDeep,
                              ),
                            )
                          : Text(
                              name.arti,
                              key: const ValueKey('arti'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                color: _muted,
                              ),
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

/// Nomor dalam bintang delapan emas.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;
  static const size = 28.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: const _StarPainter(color: _goldDeep, fill: Color(0xFFFFF5DA)),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: size * (number > 9 ? 0.34 : 0.4),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF7C5A17),
          ),
        ),
      ),
    ),
  );
}

/// Bintang delapan (dua persegi bertumpuk 45°) - motif rub el hizb.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color, required this.fill});
  final Color color, fill;

  Path _star(Offset c, double r) {
    final path = Path();
    for (var k = 0; k < 16; k++) {
      final a = -math.pi / 2 + k * math.pi / 8;
      final rr = k.isEven ? r : r * 0.8;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final star = _star(c, r);
    canvas.drawPath(star, Paint()..color = fill);
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.06).clamp(1, 2.5)
        ..color = color,
    );
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.025).clamp(0.6, 1.5)
        ..color = color.withValues(alpha: color.a * 0.7),
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.fill != fill;
}

/// Pola bintang tersebar samar untuk latar hero & tampilan penuh.
class _PatternPainter extends CustomPainter {
  const _PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 64.0;
    const star = _StarPainter(
      color: Color(0x14F2D38A),
      fill: Color(0x00000000),
    );
    for (var y = -step / 2; y < size.height + step; y += step) {
      final row = (y / step).round();
      for (
        var x = row.isEven ? 0.0 : step / 2;
        x < size.width + step;
        x += step
      ) {
        canvas.save();
        canvas.translate(x - 16, y - 16);
        star.paint(canvas, const Size(32, 32));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => false;
}

class _HadithCard extends StatelessWidget {
  const _HadithCard();

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
            Icon(Icons.format_quote_rounded, color: _goldDeep),
            SizedBox(width: 6),
            Text(
              'Keutamaan',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF7C5A17),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          '"Sesungguhnya Allah memiliki sembilan puluh sembilan nama, seratus '
          'kurang satu. Barangsiapa menjaganya (menghafal, memahami, dan '
          'mengamalkannya), ia masuk surga."',
          style: TextStyle(fontSize: 13, height: 1.55, color: _stone),
        ),
        SizedBox(height: 6),
        Text(
          'HR. Bukhari no. 2736 & Muslim no. 2677. Urutan nama mengikuti '
          'riwayat At-Tirmidzi no. 3507.',
          style: TextStyle(fontSize: 11.5, color: _muted),
        ),
      ],
    ),
  );
}

/// Tampilan penuh satu nama; geser kiri/kanan untuk nama berikutnya.
class AsmaulHusnaDetailPage extends StatefulWidget {
  const AsmaulHusnaDetailPage({
    super.key,
    required this.initial,
    this.hideArti = false,
  });

  /// Indeks awal (0..98).
  final int initial;
  final bool hideArti;

  @override
  State<AsmaulHusnaDetailPage> createState() => _AsmaulHusnaDetailPageState();
}

class _AsmaulHusnaDetailPageState extends State<AsmaulHusnaDetailPage> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  /// Arti yang sudah diintip saat mode hafalan.
  final _revealed = <int>{};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) => _pages.animateToPage(
    (_index + delta).clamp(0, asmaulHusna.length - 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final name = asmaulHusna[_index];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F3D35), _green, _greenDark],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _PatternPainter()),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${name.number} / 99',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _gold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Salin',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${name.arabic}\n${name.latin} - ${name.arti}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${name.latin} disalin')),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: asmaulHusna.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, i) {
                          final a = asmaulHusna[i];
                          final hidden =
                              widget.hideArti && !_revealed.contains(i);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: hidden
                                ? () => setState(() => _revealed.add(i))
                                : null,
                            child: _DetailBody(name: a, hideArti: hidden),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          _RoundButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _index > 0 ? () => _go(-1) : null,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: (_index + 1) / 99),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (_, v, _) => LinearProgressIndicator(
                                    value: v,
                                    minHeight: 4,
                                    backgroundColor: const Color(0x26FFFFFF),
                                    valueColor: const AlwaysStoppedAnimation(
                                      _gold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _RoundButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: _index < asmaulHusna.length - 1
                                ? () => _go(1)
                                : null,
                          ),
                        ],
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.name, required this.hideArti});
  final AsmaulHusna name;
  final bool hideArti;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final medallion = math.min(c.maxWidth * 0.82, c.maxHeight * 0.58);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: medallion,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // cahaya lembut di belakang bintang
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33F2D38A), Color(0x00F2D38A)],
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _StarPainter(
                        color: Color(0x99F2D38A),
                        fill: Color(0x14F2D38A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(medallion * 0.2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ArabicText(
                        name.arabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 64,
                          height: 1.6,
                          color: _gold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              name.latin,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: hideArti
                    ? Container(
                        key: const ValueKey('hidden'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0x66F2D38A)),
                        ),
                        child: const Text(
                          'Ketuk untuk melihat arti',
                          style: TextStyle(color: _gold),
                        ),
                      )
                    : Text(
                        name.arti,
                        key: const ValueKey('arti'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.4,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: onTap == null ? const Color(0x14FFFFFF) : const Color(0x26FFFFFF),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: onTap == null ? Colors.white24 : Colors.white,
          size: 28,
        ),
      ),
    ),
  );
}

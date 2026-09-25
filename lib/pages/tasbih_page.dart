import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings.dart';
import '../widgets/arabic_font.dart';

const _gold = Color(0xFFE3BE6A);
const _goldLight = Color(0xFFF2D38A);
const _cream = Color(0xFFF7F1E1);
const _mint = Color(0xFFB9D3CB);

/// Satu pilihan bacaan di tasbih bebas.
class TasbihPreset {
  const TasbihPreset(this.title, this.target, {this.arabic, this.latin});
  final String title;
  final int? target;
  final String? arabic, latin;
}

/// Bacaan tasbih yang umum (sesudah sholat: 33/33/34).
const tasbihPresets = [
  TasbihPreset(
    'Subhanallah',
    33,
    arabic: 'سُبْحَانَ اللَّهِ',
    latin: 'Subhaanallaah',
  ),
  TasbihPreset(
    'Alhamdulillah',
    33,
    arabic: 'الْحَمْدُ لِلَّهِ',
    latin: 'Alhamdulillaah',
  ),
  TasbihPreset(
    'Allahu Akbar',
    34,
    arabic: 'اللَّهُ أَكْبَرُ',
    latin: 'Allaahu akbar',
  ),
  TasbihPreset(
    'Istighfar',
    100,
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    latin: 'Astaghfirullaah',
  ),
  TasbihPreset(
    'Tahlil',
    100,
    arabic: 'لَا إِلَهَ إِلَّا اللَّهُ',
    latin: 'Laa ilaaha illallaah',
  ),
  TasbihPreset('Bebas', null),
];

/// Buka penghitung layar penuh. [onChanged] dipanggil setiap hitungan
/// berubah (untuk langsung disimpan); hasil akhirnya juga dikembalikan.
Future<int?> openTasbih(
  BuildContext context, {
  required String title,
  String? arabic,
  String? latin,
  int? target,
  int initial = 0,
  ValueChanged<int>? onChanged,
  List<TasbihPreset> presets = const [],
}) => Navigator.of(context).push<int>(
  PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => TasbihPage(
      title: title,
      arabic: arabic,
      latin: latin,
      target: target,
      initial: initial,
      onChanged: onChanged,
      presets: presets,
    ),
    transitionsBuilder: (_, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ),
);

/// Penghitung dzikir/tasbih layar penuh: ketuk di mana saja untuk
/// menambah, getar di setiap ketukan (bisa dimatikan), getar panjang saat
/// target tercapai. Tanpa target, cincin berputar tiap 33.
class TasbihPage extends StatefulWidget {
  const TasbihPage({
    super.key,
    required this.title,
    this.arabic,
    this.latin,
    this.target,
    this.initial = 0,
    this.onChanged,
    this.presets = const [],
  });

  final String title;
  final String? arabic, latin;
  final int? target;
  final int initial;
  final ValueChanged<int>? onChanged;

  /// Bila diisi (tasbih bebas), pilihan bacaan tampil di atas.
  final List<TasbihPreset> presets;

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage>
    with SingleTickerProviderStateMixin {
  late int _count = widget.initial;
  late String _title = widget.title;
  // dibuka dari menu dengan pilihan bacaan: teks Arab/latin dari pilihan
  // yang sesuai judul bila tidak diberikan
  late final TasbihPreset? _initialPreset = widget.presets
      .where((p) => p.title == widget.title)
      .firstOrNull;
  late String? _arabic = widget.arabic ?? _initialPreset?.arabic;
  late String? _latin = widget.latin ?? _initialPreset?.latin;
  late int? _target = widget.target;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _haptic => AppSettingsScope.maybeOf(context)?.haptic ?? true;

  /// Panjang satu putaran cincin.
  int get _cycle => _target ?? 33;
  bool get _done => _target != null && _count >= _target!;

  void _set(int v) {
    setState(() => _count = v.clamp(0, 99999));
    widget.onChanged?.call(_count);
  }

  void _increment() {
    final next = _count + 1;
    final reached =
        (_target != null && next == _target) ||
        (_target == null && next % _cycle == 0);
    if (_haptic) {
      if (reached) {
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 140),
          HapticFeedback.heavyImpact,
        );
      } else {
        HapticFeedback.lightImpact();
      }
    }
    _pulse.forward(from: 0);
    _set(next);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai dari nol?'),
        content: Text('Hitungan $_count akan diatur ulang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Atur ulang'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (_haptic) HapticFeedback.mediumImpact();
      _set(0);
    }
  }

  void _choose(TasbihPreset p) {
    setState(() {
      _title = p.title;
      _arabic = p.arabic;
      _latin = p.latin;
      _target = p.target;
      _count = 0;
    });
    widget.onChanged?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final haptic = settings?.haptic ?? true;
    final inCycle = _done ? _cycle : _count % _cycle;
    final progress = _done
        ? 1.0
        : (_count > 0 && inCycle == 0 ? 1.0 : inCycle / _cycle);
    final rounds = _target == null ? _count ~/ _cycle : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_count);
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F4A40), Color(0xFF0C3A33), Color(0xFF071F1A)],
            ),
          ),
          child: Stack(
            children: [
              // seluruh layar = tombol hitung
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _increment(),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.of(context).pop(_count),
                            icon: const Icon(Icons.close_rounded, color: _mint),
                          ),
                          Expanded(
                            child: Text(
                              _title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _cream,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: haptic
                                ? 'Matikan getar'
                                : 'Nyalakan getar',
                            onPressed: settings == null
                                ? null
                                : () {
                                    settings.setHaptic(!haptic);
                                    if (!haptic) HapticFeedback.mediumImpact();
                                  },
                            icon: Icon(
                              haptic
                                  ? Icons.vibration_rounded
                                  : Icons.smartphone_rounded,
                              color: haptic ? _gold : _mint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.presets.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final p in widget.presets)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _PresetPill(
                                  label: p.target == null
                                      ? p.title
                                      : '${p.title} ${p.target}×',
                                  selected: p.title == _title,
                                  onTap: () => _choose(p),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (_arabic != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ArabicText(
                          _arabic!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.7,
                            color: _goldLight,
                          ),
                        ),
                      ),
                    if (_latin != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                        child: Text(
                          _latin!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: _mint,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    IgnorePointer(
                      child: _Ring(
                        progress: progress,
                        pulse: _pulse,
                        done: _done,
                        count: _count,
                        caption: _target != null
                            ? (_done
                                  ? 'Masyaa Allah, selesai'
                                  : 'dari $_target')
                            : (rounds > 0 ? '$rounds × 33' : 'ketuk layar'),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundButton(
                            icon: Icons.remove_rounded,
                            label: 'Kurangi',
                            onTap: _count == 0 ? null : () => _set(_count - 1),
                          ),
                          const Text(
                            'Ketuk di mana saja',
                            style: TextStyle(fontSize: 12, color: _mint),
                          ),
                          _RoundButton(
                            icon: Icons.restart_alt_rounded,
                            label: 'Ulang',
                            onTap: _count == 0 ? null : _reset,
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

class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.pulse,
    required this.done,
    required this.count,
    required this.caption,
  });

  final double progress;
  final Animation<double> pulse;
  final bool done;
  final int count;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = Curves.easeOut.transform(pulse.value);
        final bump = pulse.isAnimating ? math.sin(t * math.pi) * 0.06 : 0.0;
        return SizedBox.square(
          dimension: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // gelombang tiap ketukan
              if (pulse.isAnimating)
                Container(
                  width: 240 + 60 * t,
                  height: 240 + 60 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.35 * (1 - t)),
                      width: 2,
                    ),
                  ),
                ),
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => CustomPaint(
                  size: const Size.square(240),
                  painter: _RingPainter(v, done),
                ),
              ),
              Transform.scale(
                scale: 1 + bump,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (done)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _goldLight,
                        size: 28,
                      ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: _cream,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done ? _goldLight : _mint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.done);
  final double value;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x26E3BE6A),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: done
              ? const [_goldLight, Color(0xFFD9A441), _goldLight]
              : const [Color(0xFFD9A441), _goldLight, Color(0xFFD9A441)],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.done != done;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0x1AFFFFFF),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                icon,
                color: enabled ? _cream : const Color(0x55F7F1E1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: enabled ? _mint : const Color(0x55B9D3CB),
          ),
        ),
      ],
    );
  }
}

/// Pilihan bacaan di tasbih bebas - pil emas saat terpilih, kaca gelap saat
/// tidak (chip Material mengikuti tema terang & tak terbaca di latar gelap).
class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _gold : const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _gold : const Color(0x40E3BE6A),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF0C3A33) : _cream,
            ),
          ),
        ),
      ),
    );
  }
}

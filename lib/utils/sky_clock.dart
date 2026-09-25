import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Satu jam bersama untuk seluruh lapisan langit (awan, bintang, layang-layang,
/// burung, jendela kota). Alih-alih satu `AnimationController` per elemen -
/// bisa puluhan sekaligus untuk 26 bintang + 6 awan + 7 burung + belasan
/// jendela - semuanya membaca satu "waktu berjalan" yang sama lalu menghitung
/// fasenya sendiri lewat modulo periode masing-masing. Ini padanan langsung
/// dari `animation-delay` negatif di CSS: elemen dengan delay -14s pada durasi
/// 104s dihitung seolah sudah berjalan 14 detik sejak jam ini mulai.
class SkyClock extends ChangeNotifier {
  SkyClock(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  /// Jam beku pada [ms] tertentu - dipakai untuk merender satu frame langit
  /// secara offscreen (mis. atlas gambar widget layar utama), tanpa ticker.
  SkyClock.fixed(double ms) : _ms = ms;

  Ticker? _ticker;
  double _ms = 0;

  double get ms => _ms;

  /// Posisi 0..1 di dalam satu putaran periode `periodMs`. `delayMs` memakai
  /// makna `animation-delay` CSS apa adanya: positif berarti menunggu dulu
  /// sebelum mulai, negatif berarti dianggap sudah berjalan sekian lama sejak
  /// jam ini mulai (start-nya "dicuri maju"). Operator `%` Dart selalu
  /// mengembalikan hasil tak-negatif untuk pembagi positif, jadi aman dipakai
  /// langsung tanpa perlu membalik tanda `delayMs` di pemanggil.
  double phase(double periodMs, {double delayMs = 0}) {
    if (periodMs <= 0) return 0;
    final t = (_ms - delayMs) % periodMs;
    return t / periodMs;
  }

  void _onTick(Duration elapsed) {
    _ms = elapsed.inMicroseconds / 1000.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

/// Membungkus [child] dengan satu [SkyClock] dan mengalirkannya lewat
/// [AnimatedBuilder] - seluruh subtree di bawahnya dibangun ulang tiap frame,
/// tapi karena isinya cuma Container/CustomPaint ringan, ini jauh lebih murah
/// daripada mengelola puluhan controller terpisah.
class SkyClockProvider extends StatefulWidget {
  const SkyClockProvider({super.key, required this.builder, this.clockMs});

  final Widget Function(BuildContext context, SkyClock clock) builder;

  /// Bila diisi, jamnya dibekukan di milidetik ini (tanpa ticker) - untuk
  /// render satu frame statis.
  final double? clockMs;

  @override
  State<SkyClockProvider> createState() => _SkyClockProviderState();
}

class _SkyClockProviderState extends State<SkyClockProvider>
    with SingleTickerProviderStateMixin {
  late final SkyClock _clock = widget.clockMs != null
      ? SkyClock.fixed(widget.clockMs!)
      : SkyClock(this);

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => widget.builder(context, _clock),
    );
  }
}

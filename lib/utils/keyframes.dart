import 'package:flutter/animation.dart';

/// Satu titik keyframe CSS: posisi 0..1 pada satu putaran animasi, nilai di
/// titik itu, dan kurva easing yang dipakai dari titik ini menuju titik
/// berikutnya (persis semantik `animation-timing-function` yang dipasang di
/// satu keyframe pada CSS - berlaku untuk segmen setelahnya, bukan sebelumnya).
class KeyStop<T> {
  final double t;
  final T value;
  final Curve curve;

  const KeyStop(this.t, this.value, {this.curve = Curves.linear});
}

/// Menerjemahkan satu putaran `@keyframes` CSS: `stops` terurut menaik dari
/// t=0 sampai t=1, `progress` adalah posisi 0..1 di dalam satu putaran
/// (biasanya `(elapsed % period) / period`), dan `lerp` adalah cara
/// menginterpolasi nilai `T` (mis. `Offset.lerp`, `lerpDouble`).
T sampleKeyframes<T>(
  List<KeyStop<T>> stops,
  double progress,
  T Function(T a, T b, double t) lerp,
) {
  final p = progress.clamp(0.0, 1.0);
  for (var i = 0; i < stops.length - 1; i++) {
    final a = stops[i];
    final b = stops[i + 1];
    if (p >= a.t && p <= b.t) {
      final span = b.t - a.t;
      final localT = span == 0 ? 0.0 : (p - a.t) / span;
      final eased = a.curve.transform(localT.clamp(0.0, 1.0));
      return lerp(a.value, b.value, eased);
    }
  }
  return stops.last.value;
}

double lerpDoubleV(double a, double b, double t) => a + (b - a) * t;

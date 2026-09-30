import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ka'bah, Masjidil Haram.
const kaabaLat = 21.422487, kaabaLon = 39.826206;

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// Arah kiblat dari ([lat], [lon]): sudut lingkaran besar dari utara sejati,
/// searah jarum jam (0..360). Indonesia sekitar 292-295°.
double qiblaBearing(double lat, double lon) {
  final p1 = _rad(lat), p2 = _rad(kaabaLat);
  final dl = _rad(kaabaLon - lon);
  final y = math.sin(dl) * math.cos(p2);
  final x =
      math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// Jarak ke Ka'bah dalam km (haversine).
double kaabaDistanceKm(double lat, double lon) {
  const r = 6371.0;
  final dp = _rad(kaabaLat - lat), dl = _rad(kaabaLon - lon);
  final a =
      math.pow(math.sin(dp / 2), 2) +
      math.cos(_rad(lat)) *
          math.cos(_rad(kaabaLat)) *
          math.pow(math.sin(dl / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Selisih sudut terpendek b - a (-180..180).
double angleDelta(double a, double b) => ((b - a + 540) % 360) - 180;

/// "292° (barat laut)".
String compassPoint(double deg) {
  const names = [
    'utara', 'timur laut', 'timur', 'tenggara', //
    'selatan', 'barat daya', 'barat', 'barat laut',
  ];
  return names[((deg + 22.5) % 360 ~/ 45)];
}

/// Satu bacaan kompas: arah (derajat dari utara MAGNETIK) & akurasi sensor
/// (0 = tidak andal .. 3 = tinggi).
typedef Heading = ({double heading, int accuracy});

/// Aliran arah kompas dari sensor HP (`bilalplus/heading` di MainActivity).
/// Error `no_sensor` bila HP tidak punya kompas.
Stream<Heading> headingStream() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return Stream.error(PlatformException(code: 'no_sensor'));
  }
  return const EventChannel('bilalplus/heading').receiveBroadcastStream().map((
    e,
  ) {
    final m = (e as Map).cast<String, Object?>();
    return (
      heading: (m['heading'] as num).toDouble(),
      accuracy: (m['accuracy'] as num?)?.toInt() ?? 3,
    );
  });
}

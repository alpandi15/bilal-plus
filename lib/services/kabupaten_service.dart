import 'dart:math' as math;

import '../data/kabupaten_data.dart';

export '../data/kabupaten_data.dart' show Kabupaten;

/// Cari kabupaten/kota berdasarkan kata kunci nama. Padanan
/// `searchKabupaten` (web) - di sana query SQL `LIKE`, di sini cukup filter
/// substring karena seluruh datanya (516 baris) sudah di memori.
List<Kabupaten> searchKabupaten(String keyword, {int limit = 30}) {
  final q = keyword.trim().toLowerCase();
  final list = q.isEmpty
      ? kabupatenData
      : kabupatenData.where((k) => k.name.toLowerCase().contains(q)).toList();
  final sorted = [...list]..sort((a, b) => a.name.compareTo(b.name));
  return sorted.take(limit).toList();
}

/// Batas kewajaran hasil pencocokan terdekat, dalam kilometer - sama seperti
/// `RADIUS_WAJAR_KM` di web. Di atas ini koordinatnya dianggap di luar
/// Indonesia (mis. sedang di Mekkah), lebih jujur dijawab "tidak ketemu"
/// daripada menamainya dengan kota Indonesia yang ribuan km jauhnya.
const double radiusWajarKm = 250;

double _jarakKm(double lat1, double long1, double lat2, double long2) {
  const rad = math.pi / 180;
  final dx = (long2 - long1) * math.cos(((lat1 + lat2) / 2) * rad);
  final dy = lat2 - lat1;
  return math.sqrt(dx * dx + dy * dy) * 111.32;
}

class KabupatenTerdekat {
  final Kabupaten kabupaten;
  final double distanceKm;
  const KabupatenTerdekat(this.kabupaten, this.distanceKm);
}

/// Kabupaten/kota yang titik pusatnya paling dekat dengan koordinat yang
/// diberikan. Padanan `findNearestKabupaten` (web) - dipakai untuk menamai
/// lokasi GPS, BUKAN untuk menggeser koordinatnya (jadwal sholat tetap
/// dihitung dari koordinat GPS asli yang lebih presisi).
KabupatenTerdekat? findNearestKabupaten(double lat, double long) {
  KabupatenTerdekat? terdekat;
  for (final k in kabupatenData) {
    final d = _jarakKm(lat, long, k.lat, k.long);
    if (terdekat == null || d < terdekat.distanceKm) {
      terdekat = KabupatenTerdekat(k, d);
    }
  }
  if (terdekat == null || terdekat.distanceKm > radiusWajarKm) return null;
  return terdekat;
}

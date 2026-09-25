import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'hijri_calendar.dart';

/// Berkas konfigurasi kalender hijriah. Bentuknya:
///
/// ```json
/// {
///   "updatedAt": "2027-02-07",
///   "source": "Sidang Isbat Kemenag RI",
///   "anchors": { "1448-09": "2027-02-08", "1448-10": "2027-03-09" }
/// }
/// ```
///
/// `anchors`: kunci `tahun-bulan` hijriah, nilai tanggal Masehi (YYYY-MM-DD)
/// tanggal 1 bulan itu. Bulan yang ada di sini dipakai apa adanya; yang
/// tidak ada jatuh ke algoritma tabular. Kasus "1 Ramadan mundur/maju
/// sehari" = ubah satu baris.
///
/// Berkas yang sama dipakai tiga hal sekaligus - kalender, baris tanggal di
/// kartu jadwal, dan hitung mundur Ramadan (jangkar bulan 9) - supaya tidak
/// pernah saling bertentangan.
class HijriConfig {
  const HijriConfig({
    required this.anchors,
    required this.updatedAt,
    required this.source,
    required this.origin,
    this.warnings = const [],
  });

  final HijriAnchors anchors;
  final String updatedAt;
  final String source;

  /// Dari mana berkas ini: 'bundle', 'cache', atau 'remote'.
  final String origin;

  /// Jangkar yang DIBUANG saat validasi beserta alasannya - ditampilkan di
  /// halaman kalender supaya salah ketik di berkas tidak lewat begitu saja.
  final List<String> warnings;

  static final HijriConfig empty = HijriConfig(
    anchors: HijriAnchors.none,
    updatedAt: '',
    source: '',
    origin: 'none',
  );

  /// Parse + validasi. Jangkar yang membuat panjang sebuah bulan bukan 29
  /// atau 30 hari dibuang (yang LEBIH AWAL dipertahankan - biasanya itu
  /// tanggal 1 Ramadan yang diumumkan dan paling penting), bukan seluruh
  /// berkas ditolak: satu salah ketik tidak boleh mematikan kalendernya.
  static HijriConfig parse(String jsonText, {required String origin}) {
    final raw = jsonDecode(jsonText) as Map<String, dynamic>;
    final anchorsRaw = (raw['anchors'] as Map?)?.cast<String, dynamic>() ?? {};
    final warnings = <String>[];

    // 1. baca & validasi bentuk tiap entri
    final parsed = <(int, int), int>{};
    for (final entry in anchorsRaw.entries) {
      final keyMatch = RegExp(r'^(\d{3,4})-(\d{1,2})$').firstMatch(entry.key);
      final value = entry.value;
      if (keyMatch == null || value is! String) {
        warnings.add(
          '"${entry.key}": bentuk kunci/nilai tidak dikenal, dilewati',
        );
        continue;
      }
      final hy = int.parse(keyMatch.group(1)!);
      final hm = int.parse(keyMatch.group(2)!);
      if (hm < 1 || hm > 12) {
        warnings.add('"${entry.key}": bulan harus 1-12, dilewati');
        continue;
      }
      final date = DateTime.tryParse(value);
      if (date == null) {
        warnings.add('"${entry.key}": tanggal "$value" tidak valid, dilewati');
        continue;
      }
      final jdn = gregorianToJdn(date.year, date.month, date.day);

      // jangkar yang melenceng >3 hari dari algoritma hampir pasti salah
      // tahun/bulan - lebih baik ditolak daripada membuat kalender loncat
      final tabular = hijriToJdnTabular(hy, hm, 1);
      if ((jdn - tabular).abs() > 3) {
        warnings.add(
          '"${entry.key}": $value melenceng ${(jdn - tabular).abs()} hari dari '
          'perhitungan - cek tahun/bulannya, dilewati',
        );
        continue;
      }
      parsed[(hy, hm)] = jdn;
    }

    // 2. panjang bulan antar-jangkar berurutan harus 29 atau 30 hari
    final keys = parsed.keys.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    final accepted = <(int, int), int>{};
    (int, int)? prevKey;
    for (final key in keys) {
      if (prevKey != null) {
        final (py, pm) = prevKey;
        final consecutive = pm == 12
            ? (key == (py + 1, 1))
            : (key == (py, pm + 1));
        if (consecutive) {
          final length = parsed[key]! - accepted[prevKey]!;
          if (length != 29 && length != 30) {
            warnings.add(
              '"${key.$1}-${key.$2.toString().padLeft(2, '0')}": membuat bulan '
              'sebelumnya $length hari (harus 29/30), dilewati',
            );
            continue;
          }
        }
      }
      accepted[key] = parsed[key]!;
      prevKey = key;
    }

    return HijriConfig(
      anchors: HijriAnchors(accepted),
      updatedAt: raw['updatedAt']?.toString() ?? '',
      source: raw['source']?.toString() ?? '',
      origin: origin,
      warnings: warnings,
    );
  }
}

/// Memuat konfigurasi dengan urutan: bundel (selalu ada, offline) ->
/// cache unduhan terakhir (menimpa bundel) -> unduhan baru dari server
/// (menimpa lagi & disimpan ke cache). Tiap tahap yang berhasil langsung
/// disiarkan ke widget lewat [notifyListeners], jadi UI tidak menunggu
/// jaringan.
///
/// Dipasang lewat [HijriConfigScope] supaya kalender, kartu jadwal, dan
/// hitung mundur Ramadan membaca berkas yang sama.
class HijriConfigController extends ChangeNotifier {
  HijriConfigController({
    this.assetPath = 'assets/hijri_config.json',
    this.remoteUrl = 'https://bilal-tarawih.vercel.app/api/hijri',
  });

  final String assetPath;

  /// URL JSON di server web (diedit lewat Keystatic di sana). Kosongkan
  /// untuk mematikan unduhan.
  final String remoteUrl;

  static const _cacheKey = 'hijri_config_cache';

  HijriConfig _config = HijriConfig.empty;
  HijriConfig get config => _config;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final text = await rootBundle.loadString(assetPath);
      _apply(HijriConfig.parse(text, origin: 'bundle'));
    } catch (e) {
      debugPrint('hijri: bundel gagal dibaca: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) _apply(HijriConfig.parse(cached, origin: 'cache'));
    } catch (e) {
      debugPrint('hijri: cache gagal dibaca: $e');
    }

    await refreshFromRemote();
  }

  /// Unduh ulang dari server. Aman dipanggil kapan saja (mis. tombol
  /// "perbarui" di halaman kalender); kegagalan jaringan cukup didiamkan
  /// karena bundel/cache sudah terpasang.
  Future<bool> refreshFromRemote() async {
    if (remoteUrl.isEmpty) return false;
    try {
      final res = await http
          .get(Uri.parse(remoteUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;

      final parsed = HijriConfig.parse(res.body, origin: 'remote');
      if (parsed.anchors.isEmpty) return false; // respons kosong/aneh: abaikan

      _apply(parsed);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, res.body);
      return true;
    } catch (e) {
      debugPrint('hijri: unduhan gagal: $e');
      return false;
    }
  }

  void _apply(HijriConfig next) {
    _config = next;
    notifyListeners();
  }
}

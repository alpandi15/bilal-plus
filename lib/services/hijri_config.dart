import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'hijri_calendar.dart';

/// Kunci metode bawaan: jangkar di akar berkas (`anchors`).
const defaultHijriMethod = 'pemerintah';

/// Satu set ketetapan tanggal - metode Pemerintah (akar berkas) atau salah
/// satu `variants` (mis. Muhammadiyah).
class HijriMethod {
  const HijriMethod({
    required this.key,
    required this.label,
    required this.source,
    required this.anchors,
  });

  final String key;
  final String label;
  final String source;
  final HijriAnchors anchors;
}

/// Berkas konfigurasi kalender hijriah. Bentuknya:
///
/// ```json
/// {
///   "updatedAt": "2027-02-07",
///   "source": "Sidang Isbat Kemenag RI",
///   "anchors": {
///     "1448-09": "2027-02-08",
///     "1448-10": { "date": "2027-03-09", "status": "tentative" }
///   },
///   "variants": {
///     "muhammadiyah": {
///       "label": "Muhammadiyah",
///       "source": "Maklumat PP Muhammadiyah",
///       "anchors": { "1448-09": "2027-02-08" }
///     }
///   }
/// }
/// ```
///
/// `anchors` (akar): ketetapan Pemerintah - kunci `tahun-bulan` hijriah,
/// nilai tanggal Masehi (YYYY-MM-DD) tanggal 1 bulan itu. Nilainya boleh
/// string (dianggap sudah resmi) atau objek `{date, status}` dengan status
/// `tentative` (belum diputuskan, mis. menunggu sidang isbat) atau
/// `confirmed`. Bulan yang tidak ada jatuh ke algoritma tabular. Kasus
/// "1 Ramadan mundur/maju sehari" = ubah satu baris.
///
/// `variants`: metode lain yang bisa dipilih pengguna, masing-masing
/// dengan `anchors` berbentuk sama. Tiap metode berdiri sendiri (bulan yang
/// tidak ada jatuh ke algoritma tabular, BUKAN ke jangkar Pemerintah) supaya
/// dua set ketetapan tidak tercampur menjadi bulan 28/31 hari.
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
    this.methods = const {},
    this.method = defaultHijriMethod,
  });

  /// Jangkar yang BERLAKU: metode terpilih + penyesuaian pengguna (lihat
  /// [resolve]). Hasil [parse] = metode Pemerintah apa adanya.
  final HijriAnchors anchors;
  final String updatedAt;
  final String source;

  /// Dari mana berkas ini: 'bundle', 'cache', atau 'remote'.
  final String origin;

  /// Jangkar yang DIBUANG saat validasi beserta alasannya - ditampilkan di
  /// halaman kalender supaya salah ketik di berkas tidak lewat begitu saja.
  final List<String> warnings;

  /// Semua metode di berkas, Pemerintah selalu ada dengan kunci
  /// [defaultHijriMethod].
  final Map<String, HijriMethod> methods;

  /// Metode yang dipakai [anchors].
  final String method;

  HijriMethod? get currentMethod => methods[method];

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
    final warnings = <String>[];
    final source = raw['source']?.toString() ?? '';

    final methods = <String, HijriMethod>{
      defaultHijriMethod: HijriMethod(
        key: defaultHijriMethod,
        label: 'Pemerintah (Sidang Isbat)',
        source: source,
        anchors: _parseAnchors(raw['anchors'], warnings, prefix: ''),
      ),
    };

    final variantsRaw = raw['variants'];
    if (variantsRaw is Map) {
      for (final entry in variantsRaw.entries) {
        final key = entry.key.toString();
        final v = entry.value;
        if (key == defaultHijriMethod || v is! Map) {
          warnings.add('varian "$key": bentuk tidak dikenal, dilewati');
          continue;
        }
        methods[key] = HijriMethod(
          key: key,
          label: v['label']?.toString() ?? key,
          source: v['source']?.toString() ?? '',
          anchors: _parseAnchors(v['anchors'], warnings, prefix: '$key: '),
        );
      }
    }

    return HijriConfig(
      anchors: methods[defaultHijriMethod]!.anchors,
      updatedAt: raw['updatedAt']?.toString() ?? '',
      source: source,
      origin: origin,
      warnings: warnings,
      methods: methods,
    );
  }

  static HijriAnchors _parseAnchors(
    Object? anchorsRaw,
    List<String> warnings, {
    required String prefix,
  }) {
    final entries = anchorsRaw is Map
        ? anchorsRaw.cast<String, dynamic>()
        : <String, dynamic>{};

    // 1. baca & validasi bentuk tiap entri
    final parsed = <(int, int), int>{};
    final tentative = <(int, int)>{};
    for (final entry in entries.entries) {
      final keyMatch = RegExp(r'^(\d{3,4})-(\d{1,2})$').firstMatch(entry.key);
      final value = entry.value;
      final dateText = value is Map ? value['date'] : value;
      if (keyMatch == null || dateText is! String) {
        warnings.add(
          '$prefix"${entry.key}": bentuk kunci/nilai tidak dikenal, dilewati',
        );
        continue;
      }
      final hy = int.parse(keyMatch.group(1)!);
      final hm = int.parse(keyMatch.group(2)!);
      if (hm < 1 || hm > 12) {
        warnings.add('$prefix"${entry.key}": bulan harus 1-12, dilewati');
        continue;
      }
      final date = DateTime.tryParse(dateText);
      if (date == null) {
        warnings.add(
          '$prefix"${entry.key}": tanggal "$dateText" tidak valid, dilewati',
        );
        continue;
      }
      final jdn = gregorianToJdn(date.year, date.month, date.day);

      // jangkar yang melenceng >3 hari dari algoritma hampir pasti salah
      // tahun/bulan - lebih baik ditolak daripada membuat kalender loncat
      final tabular = hijriToJdnTabular(hy, hm, 1);
      if ((jdn - tabular).abs() > 3) {
        warnings.add(
          '$prefix"${entry.key}": $dateText melenceng '
          '${(jdn - tabular).abs()} hari dari perhitungan - cek '
          'tahun/bulannya, dilewati',
        );
        continue;
      }
      parsed[(hy, hm)] = jdn;
      if (value is Map && value['status'] == 'tentative') {
        tentative.add((hy, hm));
      }
    }

    // 2. panjang bulan antar-jangkar berurutan harus 29 atau 30 hari
    final keys = parsed.keys.toList()..sort(_compareMonth);
    final accepted = <(int, int), int>{};
    (int, int)? prevKey;
    for (final key in keys) {
      if (prevKey != null && nextHijriMonth(prevKey.$1, prevKey.$2) == key) {
        final length = parsed[key]! - accepted[prevKey]!;
        if (length != 29 && length != 30) {
          warnings.add(
            '$prefix"${_monthKey(key)}": membuat bulan sebelumnya '
            '$length hari (harus 29/30), dilewati',
          );
          continue;
        }
      }
      accepted[key] = parsed[key]!;
      prevKey = key;
    }

    return HijriAnchors(
      accepted,
      tentative: tentative.where(accepted.containsKey).toSet(),
    );
  }

  /// Konfigurasi yang berlaku untuk pengguna: jangkar metode [method] (atau
  /// Pemerintah bila metode itu tidak ada di berkas) ditimpa [overrides]
  /// milik pengguna - `(tahun, bulan) -> JDN` tanggal 1 bulan itu.
  ///
  /// Penyesuaian yang melenceng >1 hari dari ketetapan metodenya dibuang
  /// (sudah basi - ketetapannya sendiri telah berubah jauh). Bila sebuah
  /// penyesuaian membuat bulan di sebelahnya bukan 29/30 hari, bulan
  /// sebelah itu ikut digeser berantai (ditandai `adjusted`, tetap
  /// dianggap perkiraan) - mis. 1 Ramadan mundur sehari padahal Ramadan
  /// resminya 29 hari, maka 1 Syawal ikut mundur.
  HijriConfig resolve({
    required String method,
    Map<(int, int), int> overrides = const {},
  }) {
    final chosen = methods[method] ?? methods[defaultHijriMethod];
    if (chosen == null) return this;

    final resolveWarnings = <String>[];
    final resolved = resolveAnchors(
      chosen.anchors,
      overrides,
      warnings: resolveWarnings,
    );

    return HijriConfig(
      anchors: resolved,
      updatedAt: updatedAt,
      source: chosen.source,
      origin: origin,
      warnings: [...warnings, ...resolveWarnings],
      methods: methods,
      method: chosen.key,
    );
  }
}

int _compareMonth((int, int) a, (int, int) b) =>
    a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2;

String _monthKey((int, int) k) => '${k.$1}-${k.$2.toString().padLeft(2, '0')}';

bool _validLength(int days) => days == 29 || days == 30;

/// Jangkar [base] ditimpa [overrides] - lihat [HijriConfig.resolve].
HijriAnchors resolveAnchors(
  HijriAnchors base,
  Map<(int, int), int> overrides, {
  List<String>? warnings,
}) {
  if (overrides.isEmpty) return base;

  final map = Map<(int, int), int>.of(base.byMonth);
  final tentative = Set<(int, int)>.of(base.tentativeMonths);
  final overridden = <(int, int)>{};
  final adjusted = <(int, int)>{};

  int firstDay((int, int) k) => map[k] ?? hijriToJdnTabular(k.$1, k.$2, 1);

  // 1. pasang penyesuaian pengguna yang masih masuk akal
  for (final key in overrides.keys.toList()..sort(_compareMonth)) {
    final jdn = overrides[key]!;
    if ((jdn - base.firstDayJdn(key.$1, key.$2)).abs() > 1) {
      warnings?.add(
        'penyesuaian ${_monthKey(key)} dibuang: ketetapannya sudah berubah',
      );
      continue;
    }
    // dua penyesuaian berurutan yang saling bertentangan: yang awal menang
    final prev = prevHijriMonth(key.$1, key.$2);
    if (overridden.contains(prev) && !_validLength(jdn - map[prev]!)) {
      warnings?.add(
        'penyesuaian ${_monthKey(key)} dibuang: bertentangan dengan '
        'penyesuaian ${_monthKey(prev)}',
      );
      continue;
    }
    map[key] = jdn;
    overridden.add(key);
    tentative.remove(key);
  }

  // 2. geser berantai bulan-bulan tetangga yang panjangnya jadi tidak sah
  for (final key in overridden) {
    var cur = key;
    for (var i = 0; i < 12; i++) {
      final next = nextHijriMonth(cur.$1, cur.$2);
      if (overridden.contains(next)) break;
      final length = firstDay(next) - firstDay(cur);
      if (_validLength(length)) break;
      map[next] = firstDay(cur) + (length < 29 ? 29 : 30);
      adjusted.add(next);
      tentative.remove(next);
      cur = next;
    }
    cur = key;
    for (var i = 0; i < 12; i++) {
      final prev = prevHijriMonth(cur.$1, cur.$2);
      if (overridden.contains(prev)) break;
      final length = firstDay(cur) - firstDay(prev);
      if (_validLength(length)) break;
      map[prev] = firstDay(cur) - (length < 29 ? 29 : 30);
      adjusted.add(prev);
      tentative.remove(prev);
      cur = prev;
    }
  }

  return HijriAnchors(
    map,
    tentative: tentative,
    overridden: overridden,
    adjusted: adjusted,
  );
}

/// Memuat konfigurasi dengan urutan: bundel (selalu ada, offline) ->
/// cache unduhan terakhir (menimpa bundel) -> unduhan baru dari server
/// (menimpa lagi & disimpan ke cache). Tiap tahap yang berhasil langsung
/// disiarkan ke widget lewat [notifyListeners], jadi UI tidak menunggu
/// jaringan.
///
/// Di atas berkas itu diterapkan pilihan pengguna: metode penetapan
/// ([method]) dan penyesuaian tanggal 1 per bulan ([overrideFor]),
/// keduanya disimpan di perangkat. [config] selalu hasil akhirnya, jadi
/// semua pemakai cukup membaca `config.anchors`.
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
  static const _methodKey = 'hijri_method';
  static const _overridesKey = 'hijri_overrides';

  /// Berkas apa adanya (sebelum pilihan pengguna).
  HijriConfig _file = HijriConfig.empty;
  HijriConfig _config = HijriConfig.empty;
  HijriConfig get config => _config;

  String _method = defaultHijriMethod;
  String get method => _method;

  final Map<(int, int), int> _overrides = {};

  List<HijriMethod> get methods => _file.methods.values.toList();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _method = prefs.getString(_methodKey) ?? defaultHijriMethod;
      final saved = prefs.getString(_overridesKey);
      if (saved != null) {
        _overrides.addAll(_parseOverrides(jsonDecode(saved) as Map));
      }
    } catch (e) {
      debugPrint('hijri: pilihan pengguna gagal dibaca: $e');
    }

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

  /// Ganti metode penetapan (kunci dari [methods]).
  Future<void> setMethod(String method) async {
    if (method == _method) return;
    _method = method;
    _recompute();
    await _save();
  }

  /// Penyesuaian tanggal 1 bulan [year]-[month], atau null bila mengikuti
  /// ketetapan metodenya.
  DateTime? overrideFor(int year, int month) {
    final jdn = _overrides[(year, month)];
    if (jdn == null) return null;
    final (y, m, d) = jdnToGregorian(jdn);
    return DateTime.utc(y, m, d);
  }

  /// Tanggal 1 bulan [year]-[month] menurut metode terpilih, TANPA
  /// penyesuaian bulan itu sendiri (penyesuaian bulan lain tetap berlaku).
  /// Pilihan yang ditawarkan ke pengguna = tanggal ini ±1 hari.
  DateTime baseFirstDay(int year, int month) {
    final others = Map.of(_overrides)..remove((year, month));
    final anchors = resolveAnchors(_methodAnchors, others);
    return anchors.toGregorian(year, month, 1);
  }

  /// Setel tanggal 1 bulan [year]-[month] ke [date]; null (atau tanggal yang
  /// sama dengan ketetapan) = kembali mengikuti ketetapan.
  Future<void> setOverride(int year, int month, DateTime? date) async {
    final key = (year, month);
    final base = baseFirstDay(year, month);
    if (date == null ||
        (date.year == base.year &&
            date.month == base.month &&
            date.day == base.day)) {
      if (_overrides.remove(key) == null) return;
    } else {
      _overrides[key] = gregorianToJdn(date.year, date.month, date.day);
    }
    _recompute();
    await _save();
  }

  HijriAnchors get _methodAnchors =>
      (_file.methods[_method] ?? _file.methods[defaultHijriMethod])?.anchors ??
      HijriAnchors.none;

  void _apply(HijriConfig file) {
    _file = file;
    _recompute();
  }

  void _recompute() {
    // penyesuaian yang kini sama persis dengan ketetapan resmi tidak
    // diperlukan lagi - dibuang diam-diam supaya ketetapan berikutnya
    // (bila berubah lagi) kembali diikuti
    final base = _methodAnchors;
    final redundant = [
      for (final e in _overrides.entries)
        if (base.has(e.key.$1, e.key.$2) &&
            !base.isTentative(e.key.$1, e.key.$2) &&
            base.firstDayJdn(e.key.$1, e.key.$2) == e.value)
          e.key,
    ];
    if (redundant.isNotEmpty) {
      redundant.forEach(_overrides.remove);
      _save();
    }

    _config = _file.resolve(method: _method, overrides: _overrides);
    notifyListeners();
  }

  /// Pilihan pengguna (metode & penyesuaian) untuk berkas cadangan.
  Map<String, Object?> exportSettings() => {
    'method': _method,
    'overrides': _overridesJson(),
  };

  /// Pulihkan pilihan dari berkas cadangan. [replace]: timpa semuanya;
  /// kalau tidak, pilihan di perangkat ini yang dipertahankan dan hanya
  /// penyesuaian bulan yang belum ada yang ditambahkan.
  Future<void> importSettings(
    Map<String, dynamic>? settings, {
    required bool replace,
  }) async {
    if (settings == null) return;
    final overrides = settings['overrides'];
    final parsed = overrides is Map
        ? _parseOverrides(overrides)
        : <(int, int), int>{};
    final method = settings['method'];
    if (replace) {
      if (method is String) _method = method;
      _overrides
        ..clear()
        ..addAll(parsed);
    } else {
      for (final e in parsed.entries) {
        _overrides.putIfAbsent(e.key, () => e.value);
      }
    }
    _recompute();
    await _save();
  }

  static Map<(int, int), int> _parseOverrides(Map raw) => {
    for (final e in raw.entries)
      if (RegExp(r'^(\d{3,4})-(\d{1,2})$').firstMatch(e.key.toString())
          case final m?)
        if (DateTime.tryParse(e.value.toString()) case final date?)
          (int.parse(m.group(1)!), int.parse(m.group(2)!)): gregorianToJdn(
            date.year,
            date.month,
            date.day,
          ),
  };

  Map<String, String> _overridesJson() => {
    for (final e in _overrides.entries)
      _monthKey(e.key): () {
        final (y, m, d) = jdnToGregorian(e.value);
        return '$y-${m.toString().padLeft(2, '0')}-'
            '${d.toString().padLeft(2, '0')}';
      }(),
  };

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_methodKey, _method);
      await prefs.setString(_overridesKey, jsonEncode(_overridesJson()));
    } catch (e) {
      debugPrint('hijri: pilihan pengguna gagal disimpan: $e');
    }
  }
}

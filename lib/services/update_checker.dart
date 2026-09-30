import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'system_channel.dart';

/// Repo GitHub tempat APK resmi dirilis (lihat docs/RELEASING.md).
const updateRepo = 'alpandi15/bilal-plus';

/// Halaman Release terbaru - dibuka bila tidak ada berkas APK terlampir.
const updateReleasesUrl = 'https://github.com/$updateRepo/releases/latest';

/// Versi baru yang tersedia di GitHub Releases.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.notes,
    required this.downloadUrl,
    required this.pageUrl,
  });

  /// "1.9.2" (tanpa awalan v).
  final String version;

  /// Catatan rilis (markdown sederhana dari CHANGELOG).
  final String notes;

  /// Tautan langsung APK; bila tidak ada, sama dengan [pageUrl].
  final String downloadUrl;
  final String pageUrl;
}

/// "1.10.0" > "1.9.2": dibandingkan per angka, bukan sebagai teks.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p
        in v.replaceFirst(RegExp('^v'), '').split('+').first.split('.'))
      int.tryParse(p) ?? 0,
  ];
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

/// Baca respons `GET /repos/{repo}/releases/latest`. Null bila bukan rilis
/// yang lebih baru dari [current].
@visibleForTesting
AppUpdate? parseLatestRelease(Map<String, dynamic> json, String current) {
  final tag = json['tag_name'] as String?;
  if (tag == null || json['draft'] == true || json['prerelease'] == true) {
    return null;
  }
  final version = tag.replaceFirst(RegExp('^v'), '');
  if (compareVersions(version, current) <= 0) return null;
  final page = json['html_url'] as String? ?? updateReleasesUrl;
  final apk = (json['assets'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .where((a) => '${a['name']}'.endsWith('.apk'))
      .firstOrNull;
  var notes = '${json['body'] ?? ''}';
  // bagian "cara pasang" di bawah garis tidak perlu tampil di aplikasi
  final cut = notes.indexOf('\n---');
  if (cut > 0) notes = notes.substring(0, cut);
  return AppUpdate(
    version: version,
    notes: notes.trim(),
    downloadUrl: apk?['browser_download_url'] as String? ?? page,
    pageUrl: page,
  );
}

/// Cek versi terbaru di GitHub Releases. Yang dikirim hanya permintaan biasa
/// ke API publik GitHub - tanpa data pengguna.
class UpdateChecker {
  UpdateChecker({http.Client? client, this.currentVersion})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Pengganti versi terpasang (uji); null = baca dari aplikasi.
  final String? currentVersion;

  static const _lastCheckKey = 'update_last_check';
  static const _skippedKey = 'update_skipped_version';

  /// Minimal selang cek otomatis.
  static const autoInterval = Duration(hours: 20);

  Future<String?> installedVersion() async =>
      currentVersion ?? await SystemChannel.appVersion();

  /// Versi yang lebih baru, null bila sudah terbaru. Melempar bila gagal
  /// terhubung (cek manual menampilkan pesannya).
  Future<AppUpdate?> check() async {
    final current = await installedVersion();
    if (current == null) return null;
    final res = await _client
        .get(
          Uri.parse('https://api.github.com/repos/$updateRepo/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null; // belum ada rilis
    if (res.statusCode != 200) throw Exception('server ${res.statusCode}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    return parseLatestRelease(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      current,
    );
  }

  /// Cek otomatis saat aplikasi dibuka: paling sering sekali per
  /// [autoInterval], diam bila gagal, dan tidak menawarkan versi yang sudah
  /// dilewati pengguna.
  Future<AppUpdate?> checkAutomatically() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_lastCheckKey) ?? 0;
      final since = DateTime.now().millisecondsSinceEpoch - last;
      if (since < autoInterval.inMilliseconds) return null;
      final update = await check();
      if (update == null || prefs.getString(_skippedKey) == update.version) {
        return null;
      }
      return update;
    } catch (e) {
      debugPrint('cek pembaruan: $e');
      return null;
    }
  }

  /// "Lewati versi ini": tidak ditawarkan lagi secara otomatis.
  static Future<void> skip(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedKey, version);
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../db/hadits_database.dart';

/// Server web Bilal Tarawih - sumber teks hadits (hanya teks publik; tidak
/// ada data pengguna yang dikirim).
const haditsApiBase = 'https://bilal-tarawih.vercel.app/api/hadits';

/// Hadits per permintaan (±280 KB terkompresi).
const _pageSize = 1000;

/// Perkiraan ukuran di HP per hadits (teks Arab + terjemahan).
const haditsBytesPerItem = 2350;

/// Status unduhan satu kitab.
class HaditsDownloadState {
  const HaditsDownloadState({this.done = 0, this.error});
  final int done;
  final String? error;
}

/// Mengunduh kitab hadits dari API web per halaman 1000 hadits dan
/// menyimpannya di [HaditsDatabase]. Bisa dilanjutkan bila terputus (mulai
/// dari halaman sesudah yang sudah tersimpan) & dibatalkan.
class HaditsDownloader extends ChangeNotifier {
  HaditsDownloader(this.db, {http.Client? client})
    : _client = client ?? http.Client();

  final HaditsDatabase db;
  final http.Client _client;

  static HaditsDownloader? _instance;
  static HaditsDownloader get instance =>
      _instance ??= HaditsDownloader(HaditsDatabase.instance);

  final _active = <String, HaditsDownloadState>{};
  final _cancelled = <String>{};

  /// Unduhan yang sedang berjalan (atau gagal terakhir kali).
  HaditsDownloadState? stateOf(String book) => _active[book];
  bool isRunning(String book) =>
      _active[book] != null && _active[book]!.error == null;

  void cancel(String book) {
    _cancelled.add(book);
  }

  Future<void> download(String book, int total) async {
    if (isRunning(book)) return;
    _cancelled.remove(book);
    var stored = await db.storedCount(book);
    _active[book] = HaditsDownloadState(done: stored);
    notifyListeners();
    try {
      // halaman berurutan per nomor; lanjutkan dari halaman yang belum penuh
      for (var page = stored ~/ _pageSize + 1; ; page++) {
        if (_cancelled.remove(book)) {
          _active.remove(book);
          notifyListeners();
          return;
        }
        final res = await _client
            .get(
              Uri.parse('$haditsApiBase/$book?page=$page&limit=$_pageSize'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 60));
        if (res.statusCode != 200) {
          throw Exception('server ${res.statusCode}');
        }
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
        if (body['success'] != true) {
          throw Exception('${body['message'] ?? 'gagal'}');
        }
        final data = (body['data'] as List).cast<Map>();
        await db.insertPage(book, [
          for (final h in data)
            Hadith(
              book: book,
              number: (h['number'] as num).toInt(),
              arab: '${h['arab'] ?? ''}'.trim(),
              translation: '${h['translate'] ?? ''}'.trim(),
            ),
        ]);
        stored = await db.storedCount(book);
        _active[book] = HaditsDownloadState(done: stored);
        notifyListeners();
        final pagination = (body['meta'] as Map?)?['pagination'] as Map?;
        if (data.length < _pageSize || pagination?['nextPage'] == null) break;
      }
      await db.markComplete(book, true);
      _active.remove(book);
      notifyListeners();
    } catch (e) {
      _active[book] = HaditsDownloadState(
        done: stored,
        error: 'Gagal mengunduh - periksa koneksi internet lalu coba lagi.',
      );
      debugPrint('hadits $book: $e');
      notifyListeners();
    }
  }
}

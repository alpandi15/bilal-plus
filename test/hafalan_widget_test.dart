import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/hafalan_widget_payload.dart';
import 'package:rindu_ramadan/services/quran_text.dart';
import 'package:rindu_ramadan/widgets/arabic_font.dart';

void main() {
  final quran = QuranText.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    File('assets/quran/uthmani.json').readAsStringSync(),
  );
  late AppDatabase db;
  setUp(
    () => db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  tearDown(() => db.close());

  Future<QuranText> load() async => quran;
  int idx(int surah, int ayah) =>
      quran.ayahsOf(surah).firstWhere((a) => a.number == ayah).index;

  test('belum ada hafalan: kosong (teks tidak dimuat)', () async {
    var loaded = false;
    final p = await hafalanWidgetPayload(db, () async {
      loaded = true;
      return quran;
    }, font: QuranFont.lpmq);
    expect(p['empty'], isTrue);
    expect(loaded, isFalse);
  });

  test('Al-Insyiqaq 1-3 hafal: widget menampilkan ayat 4', () async {
    await db.quranDao.setHafal(idx(84, 1), idx(84, 3), true);
    final p = await hafalanWidgetPayload(db, load, font: QuranFont.lpmq);
    expect(p['surah'], 84);
    expect(p['memorized'], 3);
    expect(p['ayahCount'], 25);
    final queue = (p['queue'] as List).cast<Map<String, Object?>>();
    expect(queue.first['n'], 4);
    expect(queue.first['i'], idx(84, 4));
    expect(queue.first['ar'], quran.ayah(idx(84, 4)).arabic);
    expect(queue.length, hafalanWidgetQueue);
  });

  test('ayat yang terlewat di tengah ikut diantre lebih dulu', () async {
    await db.quranDao.setHafal(idx(84, 1), idx(84, 2), true);
    await db.quranDao.setHafal(idx(84, 4), idx(84, 6), true);
    final p = await hafalanWidgetPayload(db, load, font: QuranFont.lpmq);
    final queue = (p['queue'] as List).cast<Map<String, Object?>>();
    expect(queue.map((q) => q['n']).take(3), [3, 7, 8]);
  });

  test('font Utsmani memakai teks Utsmani', () async {
    await db.quranDao.setHafal(idx(84, 1), idx(84, 1), true);
    final p = await hafalanWidgetPayload(db, load, font: QuranFont.uthmani);
    expect(p['font'], 'uthmani');
    final first = (p['queue'] as List).first as Map;
    expect(first['ar'], quran.ayah(idx(84, 2)).uthmani);
  });

  test('surah tuntas: antrean kosong', () async {
    await db.quranDao.setHafal(idx(114, 1), idx(114, 6), true);
    final p = await hafalanWidgetPayload(db, load, font: QuranFont.lpmq);
    expect(p['surah'], 114);
    expect(p['memorized'], 6);
    expect(p['queue'], isEmpty);
  });
}

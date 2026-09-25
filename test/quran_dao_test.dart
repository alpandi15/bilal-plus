import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/quran_index.dart';

void main() {
  late AppDatabase db;
  late QuranDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.quranDao;
  });
  tearDown(() => db.close());

  test('putaran pertama dibuat otomatis, belum mulai membaca', () async {
    final p = await dao.progress();
    expect(p.lastAyah, 0);
    expect(p.round, 1);
    expect(p.progress, 0);
    expect(p.nextAyah, 1);
  });

  test('sesi baca melanjutkan dari posisi terakhir', () async {
    await dao.logReading(date: '2027-02-08', toAyah: ayahIndex(2, 141));
    final second = await dao.logReading(
      date: '2027-02-09',
      toAyah: ayahIndex(2, 252),
    );
    expect(second.fromAyah, ayahIndex(2, 142));

    final p = await dao.progress();
    expect(p.lastAyah, ayahIndex(2, 252));
    expect(juzOf(p.lastAyah), 2);
    expect(p.nextAyah, ayahIndex(2, 253));
  });

  test('mundur ke belakang = posisi ikut sesi terbaru', () async {
    await dao.logReading(date: '2027-02-08', toAyah: 500);
    await dao.logReading(date: '2027-02-09', toAyah: 300);
    expect((await dao.progress()).lastAyah, 300);
  });

  test('sampai An-Nas = khatam, putaran berikutnya dimulai', () async {
    await dao.logReading(date: '2027-02-08', toAyah: 6000);
    await dao.logReading(date: '2027-03-01', toAyah: totalAyahs);

    final cycles = await dao.cycles();
    expect(cycles.single.completed, isTrue);
    expect(cycles.single.finishedAt, isNotNull);

    final p = await dao.progress();
    expect(p.lastAyah, 0);
    expect(p.completedCycles, 1);
    expect(p.round, 2);
  });

  test('membatalkan sesi khatam membuka putarannya kembali', () async {
    await dao.logReading(date: '2027-02-08', toAyah: 6000);
    final last = await dao.logReading(date: '2027-03-01', toAyah: totalAyahs);
    await dao.progress(); // memicu putaran baru yang masih kosong

    await dao.deleteLog(last.id);
    final p = await dao.progress();
    expect(p.lastAyah, 6000);
    expect(p.completedCycles, 0);
    expect(await dao.cycles(), hasLength(1));
  });

  test('ulangi dari awal: riwayat lama tetap ada, bukan khatam', () async {
    await dao.logReading(date: '2027-02-08', toAyah: 1000);
    final fresh = await dao.startNewCycle(targetDays: 30);

    final p = await dao.progress();
    expect(p.cycle.id, fresh.id);
    expect(p.cycle.targetDays, 30);
    expect(p.lastAyah, 0);
    expect(p.completedCycles, 0);

    final all = await dao.cycles();
    expect(all, hasLength(2));
    expect(all.last.finishedAt, isNotNull);
    expect(all.last.completed, isFalse);
    expect(await dao.logsOf(all.last.id), hasLength(1));
  });

  test('ulangi pada putaran kosong tidak menumpuk putaran', () async {
    await dao.startNewCycle();
    await dao.startNewCycle(targetDays: 15);
    final all = await dao.cycles();
    expect(all, hasLength(1));
    expect(all.single.targetDays, 15);
  });

  test('watchProgress memancarkan perubahan', () async {
    final seen = <int>[];
    final sub = dao.watchProgress().listen((p) => seen.add(p.lastAyah));
    await pumpEventQueue();
    await dao.logReading(date: '2027-02-08', toAyah: 42);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 42);
  });
}

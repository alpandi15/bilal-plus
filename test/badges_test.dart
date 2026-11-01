import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/db/app_database.dart';
import 'package:rindu_ramadan/services/badges.dart';
import 'package:rindu_ramadan/services/quran_index.dart';
import 'package:rindu_ramadan/utils/date_key.dart';

List<String> _days(String start, int n, {Set<int> skip = const {}}) {
  final s = parseDateKey(start);
  return [
    for (var i = 0; i < n; i++)
      if (!skip.contains(i)) dateKey(s.add(Duration(days: i))),
  ];
}

BadgeStatus _of(List<BadgeStatus> l, BadgeId id) =>
    l.firstWhere((b) => b.def.id == id);

void main() {
  group('streak', () {
    test(
      'ambang 7/30/100 pada hari run mencapainya; run terputus mulai lagi',
      () {
        final dates = [..._days('2026-01-01', 10), ..._days('2026-02-01', 40)];
        final r = streakRuns(dates, [7, 30, 100], '2026-03-12');
        expect(r.reached[7], '2026-01-07');
        expect(r.reached[30], '2026-03-02'); // 2026-02-01 + 29 hari
        expect(r.reached.containsKey(100), isFalse);
      },
    );

    test('run berjalan: berakhir hari ini atau kemarin, bukan lebih lama', () {
      final d = _days('2026-11-01', 5); // 1-5 Nov
      expect(streakRuns(d, [7], '2026-11-05').ongoing, 5);
      expect(streakRuns(d, [7], '2026-11-06').ongoing, 5); // hari ini belum
      expect(streakRuns(d, [7], '2026-11-07').ongoing, 0); // terputus
    });

    test('tanggal ganda tidak menggandakan hitungan', () {
      final r = streakRuns(
        ['2026-11-01', '2026-11-01', '2026-11-02'],
        [2],
        '2026-11-02',
      );
      expect(r.reached[2], '2026-11-02');
      expect(r.ongoing, 2);
    });
  });

  group('lencana', () {
    test('kosong: belum ada yang diraih', () {
      final l = evaluateBadges(const BadgeData(today: '2026-11-01'));
      expect(l.where((b) => b.earned), isEmpty);
      expect(l.length, 12);
    });

    test('Pekan Terjaga & Langkah Pertama dari 7 hari terjaga', () {
      final l = evaluateBadges(
        BadgeData(today: '2026-11-07', completeDates: _days('2026-11-01', 7)),
      );
      expect(_of(l, BadgeId.langkahPertama).earnedOn, '2026-11-01');
      expect(_of(l, BadgeId.pekanTerjaga).earnedOn, '2026-11-07');
      expect(_of(l, BadgeId.sebulanIstiqamah).earned, isFalse);
      expect(_of(l, BadgeId.sebulanIstiqamah).current, 7);
    });

    test('kumulatif: Subuh awal waktu, jama\'ah, tilawah mencapai ke-30', () {
      final l = evaluateBadges(
        BadgeData(
          today: '2026-12-31',
          subuhOnTimeDates: _days('2026-11-01', 30),
          jamaahDates: _days('2026-11-01', 29),
          tilawahDates: _days('2026-11-01', 30),
        ),
      );
      expect(_of(l, BadgeId.penjagaFajar).earnedOn, '2026-11-30');
      expect(_of(l, BadgeId.pecintaJamaah).earned, isFalse);
      expect(_of(l, BadgeId.pecintaJamaah).current, 29);
      expect(_of(l, BadgeId.rutinTilawah).earnedOn, '2026-11-30');
    });

    test(
      'Jumat Penuh: semua Jumat sebulan; bulan berjalan belum selesai belum dihitung',
      () {
        // Oktober 2026: Jumat 2, 9, 16, 23, 30
        final full = {
          '2026-10-02',
          '2026-10-09',
          '2026-10-16',
          '2026-10-23',
          '2026-10-30',
        };
        var l = evaluateBadges(
          BadgeData(today: '2026-11-01', jumatDates: full),
        );
        expect(_of(l, BadgeId.jumatPenuh).earnedOn, '2026-10-30');
        // kurang satu
        l = evaluateBadges(
          BadgeData(
            today: '2026-11-01',
            jumatDates: {...full}..remove('2026-10-16'),
          ),
        );
        expect(_of(l, BadgeId.jumatPenuh).earned, isFalse);
        // bulan berjalan: Jumat terakhir belum tiba -> belum
        l = evaluateBadges(
          const BadgeData(
            today: '2026-10-20',
            jumatDates: {'2026-10-02', '2026-10-09', '2026-10-16'},
          ),
        );
        expect(_of(l, BadgeId.jumatPenuh).earned, isFalse);
      },
    );

    test('Jumat Penuh tidak ditampilkan untuk perempuan', () {
      final l = evaluateBadges(
        const BadgeData(today: '2026-11-01', male: false),
      );
      expect(l.any((b) => b.def.id == BadgeId.jumatPenuh), isFalse);
      expect(l.length, 11);
    });

    test(
      'Sejuz Hafalan: semua ayat satu juz; tanggal = ayat terakhir dihafal',
      () {
        final (a, b) = juzRange(30);
        final hafal = {for (var i = a; i <= b; i++) i: '2026-10-01'};
        hafal[b] = '2026-10-15';
        var l = evaluateBadges(
          BadgeData(today: '2026-11-01', hafalanDates: hafal),
        );
        expect(_of(l, BadgeId.sejuzHafalan).earnedOn, '2026-10-15');
        hafal.remove(a);
        l = evaluateBadges(BadgeData(today: '2026-11-01', hafalanDates: hafal));
        expect(_of(l, BadgeId.sejuzHafalan).earned, isFalse);
      },
    );

    test('hutang lunas & khatam & Ramadan penuh', () {
      final l = evaluateBadges(
        const BadgeData(
          today: '2026-11-01',
          khatamDates: ['2026-05-01'],
          ramadanPenuh: ['2026-03-25'],
          debtAdded: 10,
          debtLeft: 0,
          debtSettledOn: '2026-10-20',
        ),
      );
      expect(_of(l, BadgeId.khatam).earnedOn, '2026-05-01');
      expect(_of(l, BadgeId.ramadanPenuh).earnedOn, '2026-03-25');
      expect(_of(l, BadgeId.pelunasHutang).earnedOn, '2026-10-20');
      // belum pernah punya hutang: tidak otomatis "lunas"
      final none = evaluateBadges(const BadgeData(today: '2026-11-01'));
      expect(_of(none, BadgeId.pelunasHutang).earned, isFalse);
    });

    test(
      'tanggal tersimpan menang & lencana tidak hilang bila data berubah',
      () {
        final l = evaluateBadges(
          const BadgeData(today: '2026-11-01'),
          stored: {'pekanTerjaga': '2026-09-09'},
        );
        expect(_of(l, BadgeId.pekanTerjaga).earnedOn, '2026-09-09');
        expect(
          _of(l, BadgeId.pekanTerjaga).progressText,
          contains('9 September 2026'),
        );
      },
    );
  });

  group('penyimpanan & perayaan', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('yang baru diraih dicatat & dirayakan sekali', () async {
      final statuses = evaluateBadges(
        BadgeData(today: '2026-11-07', completeDates: _days('2026-11-01', 7)),
      );
      var fresh = await BadgeStore.record(statuses);
      expect(fresh.toSet(), {BadgeId.langkahPertama, BadgeId.pekanTerjaga});
      expect((await BadgeStore.earned())['pekanTerjaga'], '2026-11-07');
      await BadgeStore.markSeen(fresh);
      fresh = await BadgeStore.record(statuses);
      expect(fresh, isEmpty);
    });
  });

  group('dari basis data', () {
    test('streak, jama\'ah, tilawah & Jumat dihitung dari catatan', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final dao = db.ibadahDao;
      final items = await dao.watchItems().first;
      int id(String k) => items.firstWhere((i) => i.key == k).id;
      // 7 hari lima waktu lengkap, semua berjama'ah (1-7 Nov 2026)
      for (final d in _days('2026-11-01', 7)) {
        for (final k in ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya']) {
          await dao.setValue(d, id(k), 1, jamaah: true);
        }
      }
      await db.quranDao.setHafal(6232, 6236, true);
      final data = await loadBadgeData(
        db,
        today: '2026-11-07',
        latitude: 3.59,
        longitude: 98.67,
        onTimeMinutes: 15,
        male: true,
      );
      expect(data.completeDates.length, 7);
      expect(data.jamaahDates.length, 35);
      final l = evaluateBadges(data);
      expect(_of(l, BadgeId.pekanTerjaga).earnedOn, '2026-11-07');
      expect(_of(l, BadgeId.pecintaJamaah).earnedOn, '2026-11-06'); // ke-30
    });
  });
}

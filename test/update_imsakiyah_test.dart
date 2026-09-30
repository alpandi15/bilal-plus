import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/models/prayer_models.dart';
import 'package:rindu_ramadan/pages/imsakiyah_page.dart';
import 'package:rindu_ramadan/services/hijri_config.dart';
import 'package:rindu_ramadan/services/ramadan_calendar.dart';
import 'package:rindu_ramadan/services/update_checker.dart';
import 'package:rindu_ramadan/widgets/update_sheet.dart';

// 1 Ramadan 1448 = 8 Feb 2027, 1 Syawal = 9 Mar 2027 (29 hari)
final _anchors = HijriConfig.parse(
  '{"anchors": {"1448-09": "2027-02-08", "1448-10": "2027-03-09"}}',
  origin: 'test',
).anchors;

Map<String, dynamic> _release(String tag, {bool apk = true}) => {
  'tag_name': tag,
  'draft': false,
  'prerelease': false,
  'html_url': 'https://github.com/alpandi15/bilal-plus/releases/tag/$tag',
  'body': '**Baru**\n- Imsakiyah\n\n---\n\n**Cara pasang:** ...',
  'assets': [
    if (apk)
      {
        'name': 'bilal-plus-${tag.substring(1)}.apk',
        'browser_download_url': 'https://example.test/app.apk',
      },
  ],
};

void main() {
  test('perbandingan versi per angka', () {
    expect(compareVersions('1.10.0', '1.9.2'), 1);
    expect(compareVersions('v1.9.1', '1.9.1'), 0);
    expect(compareVersions('1.9.1+16', '1.9.2'), -1);
    expect(compareVersions('2.0', '1.99.99'), 1);
  });

  test('rilis terbaru: hanya bila lebih baru, APK & catatan terbaca', () {
    final u = parseLatestRelease(_release('v1.10.0'), '1.9.1')!;
    expect(u.version, '1.10.0');
    expect(u.downloadUrl, 'https://example.test/app.apk');
    expect(u.notes, '**Baru**\n- Imsakiyah'); // tanpa bagian cara pasang
    expect(parseLatestRelease(_release('v1.9.1'), '1.9.1'), isNull);
    expect(parseLatestRelease(_release('v1.9.0'), '1.9.1'), isNull);
    // tanpa APK: arahkan ke halaman rilis
    final noApk = parseLatestRelease(_release('v2.0.0', apk: false), '1.9.1')!;
    expect(noApk.downloadUrl, noApk.pageUrl);
    expect(
      parseLatestRelease({..._release('v3.0.0'), 'draft': true}, '1.9.1'),
      isNull,
    );
  });

  test('catatan rilis: tebal & poin', () {
    final spans = releaseNoteSpans('**Baru**\n- Satu\n  lanjutan\n- Dua');
    expect(spans.first.text, 'Baru');
    expect(spans.map((s) => s.text).join(), 'Baru\n• Satu lanjutan\n• Dua');
  });

  test('imsakiyah Ramadan: sebulan penuh, imsak 10 menit sebelum subuh', () {
    final r = relevantRamadan(DateTime.utc(2027, 1, 1), _anchors);
    final rows = imsakiyahRows(
      start: r.start,
      days: r.days,
      latitude: 3.59,
      longitude: 98.67,
      anchors: _anchors,
    );
    expect(rows, hasLength(29));
    expect(rows.first.hijri.day, 1);
    expect(rows.first.hijri.month, 9);
    expect(rows.last.hijri.day, 29);
    for (final row in rows) {
      final t = row.times.times;
      expect(t[PrayerKey.fajr]!.difference(t[PrayerKey.imsak]!).inMinutes, 10);
    }
  });
}

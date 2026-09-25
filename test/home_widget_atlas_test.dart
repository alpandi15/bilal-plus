import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/services/home_widget_service_io.dart';

/// Memastikan sinkronisasi widget layar utama benar-benar menghasilkan
/// jadwal 7 hari + atlas langit (6 varian x [atlasFrames] frame PNG) -
/// channel `home_widget` & `path_provider` dipalsukan supaya bisa jalan di
/// mesin uji. Folder keluarannya bisa dipakai memeriksa gambar secara
/// visual: set env ATLAS_OUT_DIR.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sync widget menulis jadwal 7 hari & merender atlas langit', () async {
    final outDir =
        Platform.environment['ATLAS_OUT_DIR'] ??
        Directory.systemTemp.createTempSync('atlas').path;
    final store = <String, Object?>{};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (
      call,
    ) async {
      switch (call.method) {
        case 'saveWidgetData':
          store[call.arguments['id'] as String] = call.arguments['data'];
          return true;
        case 'getWidgetData':
          return store[call.arguments['id'] as String];
        case 'updateWidget':
          return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => outDir,
    );

    await syncPrayerHomeWidget(
      latitude: 3.5,
      longitude: 98.7,
      locationName: 'Kab. Deli Serdang',
    );

    final json = jsonDecode(store['schedule_json'] as String) as Map;
    expect(json['tz'], 'WIB');
    expect(json['tzId'], 'Asia/Jakarta');
    expect((json['days'] as List).length, 7);
    expect((json['days'] as List).first, contains('fajr'));
    expect((json['days'] as List).first['hijri'], contains(' H'));
    expect((json['days'] as List).first['hijriAfterMaghrib'], contains(' H'));
    expect(store['sky_atlas_version'], isNotNull);

    for (final v in [
      'dawn',
      'morning',
      'noon',
      'dusk',
      'night',
      'nightquiet',
    ]) {
      for (var f = 0; f < atlasFrames; f++) {
        final path = store['sky_${v}_$f'] as String?;
        expect(path, isNotNull, reason: 'sky_${v}_$f');
        expect(File(path!).lengthSync(), greaterThan(1000), reason: path);
      }
    }
  });
}

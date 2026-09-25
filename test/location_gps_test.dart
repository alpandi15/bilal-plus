// Uji alur "Gunakan lokasi saat ini": GPS mati -> dialog nyalakan GPS;
// izin ditolak permanen -> dialog buka pengaturan aplikasi; izin ditolak
// sekali -> pesan singkat; sukses -> lembar tertutup & lokasi berganti.
// Platform geolocator dipalsukan supaya tiap skenario bisa dimainkan.

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rindu_ramadan/main.dart';

class _FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  bool openedLocationSettings = false;
  bool openedAppSettings = false;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings = true;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings = true;
    return true;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: -6.9175, // Bandung
    longitude: 107.6191,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Future<void> _settle(WidgetTester tester, {int ticks = 6}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<_FakeGeolocator> _openPicker(WidgetTester tester) async {
  final fake = _FakeGeolocator();
  GeolocatorPlatform.instance = fake;
  // sudah ada pilihan tersimpan: init() tidak memanggil GPS otomatis
  SharedPreferences.setMockInitialValues({
    'prayer_location':
        '{"id":51,"name":"Kota Medan","lat":3.5952,"long":98.6722,"source":"kabupaten"}',
  });
  await tester.pumpWidget(const RinduRamadanApp(homeWidgets: false));
  await _settle(tester);
  await tester.tap(find.text('Kota Medan'));
  await _settle(tester);
  expect(find.text('Gunakan lokasi saat ini'), findsOneWidget);
  return fake;
}

void main() {
  testWidgets('GPS mati -> dialog nyalakan GPS -> buka pengaturan lokasi', (
    tester,
  ) async {
    final fake = await _openPicker(tester);
    fake.serviceEnabled = false;

    await tester.tap(find.text('Gunakan lokasi saat ini'));
    await _settle(tester);

    expect(find.text('GPS belum aktif'), findsOneWidget);
    await tester.tap(find.text('Nyalakan GPS'));
    await _settle(tester);
    expect(fake.openedLocationSettings, isTrue);
    // lembar masih terbuka & pilihan lama tidak tertimpa
    expect(find.text('Gunakan lokasi saat ini'), findsOneWidget);
    expect(find.text('Kota Medan'), findsWidgets);
  });

  testWidgets('Izin ditolak permanen -> dialog buka pengaturan aplikasi', (
    tester,
  ) async {
    final fake = await _openPicker(tester);
    fake.permission = LocationPermission.deniedForever;

    await tester.tap(find.text('Gunakan lokasi saat ini'));
    await _settle(tester);

    expect(find.text('Izin lokasi ditolak'), findsOneWidget);
    await tester.tap(find.text('Buka Pengaturan'));
    await _settle(tester);
    expect(fake.openedAppSettings, isTrue);
  });

  testWidgets('Izin ditolak sekali -> pesan, lembar tetap terbuka', (
    tester,
  ) async {
    final fake = await _openPicker(tester);
    fake.permission = LocationPermission.denied;

    await tester.tap(find.text('Gunakan lokasi saat ini'));
    await _settle(tester);

    expect(find.textContaining('Izin lokasi ditolak'), findsWidgets);
    expect(find.text('Gunakan lokasi saat ini'), findsOneWidget);
  });

  testWidgets('Sukses -> lembar tertutup, lokasi jadi kabupaten terdekat', (
    tester,
  ) async {
    await _openPicker(tester);

    await tester.tap(find.text('Gunakan lokasi saat ini'));
    await _settle(tester, ticks: 10);

    expect(find.text('Pilih Kabupaten / Kota'), findsNothing);
    expect(find.text('Kota Bandung'), findsOneWidget);
  });
}

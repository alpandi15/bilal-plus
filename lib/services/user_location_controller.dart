import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kabupaten_service.dart';

enum LocationSource { gps, kabupaten, default_ }

/// Nama sementara sebelum koordinat GPS berhasil dicocokkan ke nama daerah.
const namaGpsSementara = 'Lokasi Saat Ini';

/// Padanan `DEFAULT_LOCATION` (web): Kota Medan, dipakai bila GPS ditolak dan
/// user belum pernah memilih kabupaten.
const _defaultId = 51;
const _defaultName = 'Kota Medan';
const _defaultLat = 3.5952;
const _defaultLong = 98.6722;

class UserLocation {
  final int? id;
  final String name;
  final double lat;
  final double long;
  final LocationSource source;
  final bool gpsDenied;
  final double? distanceKm;

  const UserLocation({
    this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.source,
    this.gpsDenied = false,
    this.distanceKm,
  });

  static const defaultLocation = UserLocation(
    id: _defaultId,
    name: _defaultName,
    lat: _defaultLat,
    long: _defaultLong,
    source: LocationSource.default_,
  );

  UserLocation copyWith({
    int? id,
    String? name,
    double? lat,
    double? long,
    LocationSource? source,
    bool? gpsDenied,
    double? distanceKm,
  }) => UserLocation(
    id: id ?? this.id,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    long: long ?? this.long,
    source: source ?? this.source,
    gpsDenied: gpsDenied ?? this.gpsDenied,
    distanceKm: distanceKm ?? this.distanceKm,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'long': long,
    'source': source.name,
    'gpsDenied': gpsDenied,
    'distanceKm': distanceKm,
  };

  static UserLocation? fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final long = (json['long'] as num?)?.toDouble();
    if (lat == null || long == null) return null;
    return UserLocation(
      id: json['id'] as int?,
      name: json['name'] as String? ?? namaGpsSementara,
      lat: lat,
      long: long,
      source: LocationSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => LocationSource.default_,
      ),
      gpsDenied: json['gpsDenied'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

enum LocationStatus { idle, locating, ready }

/// Hasil permintaan lokasi GPS - dipakai UI untuk menuntun pengguna.
enum GpsResult {
  ok,

  /// Layanan lokasi (GPS) perangkat mati.
  serviceDisabled,

  /// Izin ditolak untuk kali ini - bisa diminta lagi.
  permissionDenied,

  /// Izin ditolak permanen ("jangan tanya lagi") - hanya bisa diubah lewat
  /// pengaturan aplikasi.
  permissionDeniedForever,

  /// Izin ada tapi posisi gagal dibaca (habis waktu, sinyal lemah, dsb).
  failed,
}

/// Padanan `useUserLocation` (web): urutan penentuan lokasi mengikuti pola
/// yang sama -
///   1. pilihan tersimpan (shared_preferences, padanan localStorage)
///   2. GPS perangkat
///   3. kabupaten yang dipilih manual lewat `setKabupaten`
///   4. default Kota Medan
///
/// Satu instance dipakai bersama oleh semua widget lewat `UserLocationScope`
/// (`InheritedNotifier`) supaya kartu jadwal sholat dan hitung mundur Ramadan
/// ikut berganti begitu lokasi baru dipilih, tanpa perlu paket state
/// management tambahan.
class UserLocationController extends ChangeNotifier {
  static const _storageKey = 'prayer_location';

  UserLocation _location = UserLocation.defaultLocation;
  LocationStatus _status = LocationStatus.idle;
  bool _deniedGps = false;
  bool _resolved = false;

  UserLocation get location => _location;
  LocationStatus get status => _status;
  bool get deniedGps => _deniedGps;

  /// Dipanggil sekali di awal (mis. dari `initState` halaman utama).
  Future<void> init() async {
    if (_resolved) return;
    _resolved = true;

    final stored = await _readStored();
    if (stored != null) {
      _location = stored;
      _deniedGps = stored.gpsDenied;
      _status = LocationStatus.ready;
      notifyListeners();

      // lokasi GPS lama yang belum sempat dinamai (mis. baru dipasang atau
      // dulu gagal karena offline) - coba namai lagi tanpa minta izin ulang
      if (stored.source == LocationSource.gps &&
          stored.name == namaGpsSementara) {
        _lengkapiNama(stored);
      }
      return;
    }

    await requestGps(fallbackToDefault: true);
  }

  Future<void> _apply(UserLocation next, {bool persist = true}) async {
    _location = next;
    _status = LocationStatus.ready;
    notifyListeners();
    if (persist) await _writeStored(next);
  }

  Future<void> _lengkapiNama(UserLocation lokasi) async {
    final terdekat = findNearestKabupaten(lokasi.lat, lokasi.long);
    if (terdekat == null) return;
    await _apply(
      lokasi.copyWith(
        id: terdekat.kabupaten.id,
        name: terdekat.kabupaten.name,
        distanceKm: terdekat.distanceKm,
      ),
    );
  }

  /// Minta izin GPS secara eksplisit (dipanggil dari tombol "Gunakan lokasi
  /// saat ini" atau otomatis sekali saat pertama kali dibuka).
  ///
  /// Mengembalikan [GpsResult] supaya UI bisa menuntun pengguna: mengaktifkan
  /// GPS di pengaturan, memberi izin, atau membuka pengaturan aplikasi bila
  /// izinnya ditolak permanen. Bila gagal dan [fallbackToDefault] true (hanya
  /// saat pertama kali dibuka, belum ada lokasi apa pun), lokasi diisi Kota
  /// Medan; selain itu lokasi yang sudah ada dibiarkan - pilihan kabupaten
  /// pengguna tidak boleh tertimpa gara-gara GPS gagal.
  Future<GpsResult> requestGps({bool fallbackToDefault = false}) async {
    _status = LocationStatus.locating;
    notifyListeners();

    GpsResult result;
    try {
      result = await _locate();
    } catch (_) {
      result = GpsResult.failed;
    }

    if (result != GpsResult.ok) {
      _deniedGps =
          result == GpsResult.permissionDenied ||
          result == GpsResult.permissionDeniedForever;
      if (fallbackToDefault) {
        await _apply(
          UserLocation.defaultLocation.copyWith(gpsDenied: _deniedGps),
        );
      } else {
        _status = LocationStatus.ready;
        notifyListeners();
      }
    }
    return result;
  }

  Future<GpsResult> _locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GpsResult.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return GpsResult.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return GpsResult.permissionDenied;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    _deniedGps = false;
    final lokasi = UserLocation(
      name: namaGpsSementara,
      lat: position.latitude,
      long: position.longitude,
      source: LocationSource.gps,
    );
    await _apply(lokasi);
    unawaited(_lengkapiNama(lokasi));
    return GpsResult.ok;
  }

  /// Membuka pengaturan lokasi perangkat (menyalakan GPS).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Membuka pengaturan aplikasi (untuk memberi izin yang ditolak permanen).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<void> setKabupaten(Kabupaten kabupaten) async {
    await _apply(
      UserLocation(
        id: kabupaten.id,
        name: kabupaten.name,
        lat: kabupaten.lat,
        long: kabupaten.long,
        source: LocationSource.kabupaten,
      ),
    );
  }

  Future<UserLocation?> _readStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return null;
      return UserLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeStored(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(location.toJson()));
    } catch (_) {
      // penyimpanan bisa gagal (mis. web di mode privat) - abaikan saja
    }
  }
}

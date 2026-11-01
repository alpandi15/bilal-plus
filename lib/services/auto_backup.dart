import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';

/// Cadangan otomatis ke folder pilihan pengguna (Storage Access Framework,
/// lihat `BackupFolder.kt`): saat aplikasi dibuka dan sudah lewat
/// [autoBackupEvery] sejak cadangan terakhir, satu berkas JSON ditulis ke
/// folder itu; hanya [autoBackupKeep] salinan terbaru yang disimpan.

const autoBackupEvery = Duration(days: 7);
const autoBackupKeep = 5;

const _prefix = 'bilalplus-cadangan-';
const _suffix = '.json';

/// Kunci pengaturan; [lastBackupKey] sama dengan yang dibaca halaman
/// Cadangan (cadangan manual) supaya statusnya satu.
abstract final class AutoBackupKeys {
  static const enabled = 'auto_backup_on';
  static const uri = 'auto_backup_uri';
  static const folder = 'auto_backup_folder';
  static const last = 'backup_last_at';
  static const error = 'auto_backup_error';
}

/// Satu salinan cadangan di folder.
class BackupCopy {
  const BackupCopy({
    required this.uri,
    required this.name,
    required this.modified,
    required this.size,
  });

  final String uri;
  final String name;
  final DateTime modified;
  final int size;
}

/// Akses ke folder cadangan. Implementasi nyata: [PlatformBackupFolder];
/// uji memakai folder palsu di memori.
abstract class BackupFolderApi {
  /// Pilih folder; null bila dibatalkan. (uri, nama tampilan)
  Future<(String, String)?> pick();
  Future<String> write(String tree, String name, Uint8List bytes);
  Future<List<BackupCopy>> list(String tree);
  Future<Uint8List> read(String doc);
  Future<bool> delete(String doc);

  /// Izin folder masih berlaku?
  Future<bool> hasAccess(String tree);
  Future<void> release(String tree);
}

class PlatformBackupFolder implements BackupFolderApi {
  const PlatformBackupFolder();
  static const _channel = MethodChannel('bilalplus/backup_folder');

  @override
  Future<(String, String)?> pick() async {
    final r = await _channel.invokeMapMethod<String, Object?>('pick');
    return r == null ? null : (r['uri']! as String, r['name']! as String);
  }

  @override
  Future<String> write(String tree, String name, Uint8List bytes) async =>
      (await _channel.invokeMethod<String>('write', {
        'tree': tree,
        'name': name,
        'bytes': bytes,
      }))!;

  @override
  Future<List<BackupCopy>> list(String tree) async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'list',
      {'tree': tree},
    );
    return [
      for (final r in rows ?? const <Map<Object?, Object?>>[])
        BackupCopy(
          uri: r['uri']! as String,
          name: r['name']! as String,
          modified: DateTime.fromMillisecondsSinceEpoch(
            (r['modified'] as num?)?.toInt() ?? 0,
          ),
          size: (r['size'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<Uint8List> read(String doc) async =>
      (await _channel.invokeMethod<Uint8List>('read', {'doc': doc}))!;

  @override
  Future<bool> delete(String doc) async =>
      await _channel.invokeMethod<bool>('delete', {'doc': doc}) ?? false;

  @override
  Future<bool> hasAccess(String tree) async =>
      await _channel.invokeMethod<bool>('hasAccess', {'tree': tree}) ?? false;

  @override
  Future<void> release(String tree) =>
      _channel.invokeMethod<void>('release', {'tree': tree});
}

/// Sudah waktunya mencadangkan lagi?
bool autoBackupDue(DateTime? last, DateTime now) =>
    last == null || now.difference(last) >= autoBackupEvery;

/// Nama berkas cadangan: urut menurut nama = urut menurut waktu (dengan
/// detik, supaya dua cadangan dalam semenit tidak berbenturan).
String autoBackupName(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '$_prefix${t.year}${two(t.month)}${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}${two(t.second)}$_suffix';
}

/// Salinan yang harus dihapus agar tersisa [keep] yang terbaru (urut nama,
/// lalu waktu ubah). Hanya berkas yang namanya dikenali yang dipertimbangkan.
List<BackupCopy> autoBackupPrune(
  List<BackupCopy> copies, {
  int keep = autoBackupKeep,
}) {
  final mine = [
    for (final c in copies)
      if (c.name.startsWith(_prefix) && c.name.endsWith(_suffix)) c,
  ]..sort((a, b) => b.name.compareTo(a.name)); // terbaru dulu
  return mine.length <= keep ? const [] : mine.sublist(keep);
}

/// Salinan terbaru dulu.
List<BackupCopy> autoBackupSorted(List<BackupCopy> copies) => [
  for (final c in copies)
    if (c.name.startsWith(_prefix) && c.name.endsWith(_suffix)) c,
]..sort((a, b) => b.name.compareTo(a.name));

/// Keadaan cadangan otomatis di perangkat ini.
class AutoBackupState {
  const AutoBackupState({
    required this.enabled,
    this.uri,
    this.folder,
    this.last,
    this.error,
  });

  final bool enabled;
  final String? uri;
  final String? folder;
  final DateTime? last;

  /// Pesan kegagalan terakhir (izin hilang, folder dihapus, ...).
  final String? error;

  bool get hasFolder => uri != null;
}

enum AutoBackupResult { notDue, done, noFolder, failed }

class AutoBackup {
  AutoBackup(this.api, this.service);

  final BackupFolderApi api;
  final BackupService service;

  static Future<AutoBackupState> state() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(AutoBackupKeys.last);
    return AutoBackupState(
      enabled: p.getBool(AutoBackupKeys.enabled) ?? false,
      uri: p.getString(AutoBackupKeys.uri),
      folder: p.getString(AutoBackupKeys.folder),
      last: last == null ? null : DateTime.tryParse(last),
      error: p.getString(AutoBackupKeys.error),
    );
  }

  static Future<void> setEnabled(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(AutoBackupKeys.enabled, on);
  }

  /// Simpan folder yang baru dipilih (dan aktifkan); folder lama dilepas
  /// izinnya.
  Future<void> setFolder(String uri, String name) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getString(AutoBackupKeys.uri);
    if (old != null && old != uri) await api.release(old);
    await p.setString(AutoBackupKeys.uri, uri);
    await p.setString(AutoBackupKeys.folder, name);
    await p.setBool(AutoBackupKeys.enabled, true);
    await p.remove(AutoBackupKeys.error);
  }

  /// Cadangkan bila aktif & sudah waktunya ([force] mengabaikan jadwal).
  /// Tidak pernah melempar: kegagalan disimpan sebagai pesan di
  /// [AutoBackupState.error].
  Future<AutoBackupResult> run({
    DateTime? now,
    bool force = false,
    Map<String, Object?> settings = const {},
  }) async {
    final p = await SharedPreferences.getInstance();
    final s = await state();
    final uri = s.uri;
    if (uri == null) return AutoBackupResult.noFolder;
    if (!force && !s.enabled) return AutoBackupResult.notDue;
    final t = now ?? DateTime.now();
    if (!force && !autoBackupDue(s.last, t)) return AutoBackupResult.notDue;
    try {
      if (!await api.hasAccess(uri)) {
        await p.setString(
          AutoBackupKeys.error,
          'Izin ke folder cadangan hilang. Pilih folder lagi.',
        );
        return AutoBackupResult.failed;
      }
      final data = await service.export(settings: settings);
      final bytes = Uint8List.fromList(utf8.encode(service.exportText(data)));
      await api.write(uri, autoBackupName(t), bytes);
      // buang salinan lama (kegagalan menghapus tidak membatalkan cadangan)
      try {
        for (final c in autoBackupPrune(await api.list(uri))) {
          await api.delete(c.uri);
        }
      } catch (_) {}
      await p.setString(AutoBackupKeys.last, t.toIso8601String());
      await p.remove(AutoBackupKeys.error);
      return AutoBackupResult.done;
    } catch (e) {
      await p.setString(
        AutoBackupKeys.error,
        'Gagal mencadangkan ke folder: ${_clean(e)}',
      );
      return AutoBackupResult.failed;
    }
  }

  static String _clean(Object e) =>
      e is PlatformException ? (e.message ?? e.code) : e.toString();

  /// Salinan di folder, terbaru dulu (kosong bila belum ada folder).
  Future<List<BackupCopy>> copies() async {
    final uri = (await state()).uri;
    if (uri == null) return const [];
    return autoBackupSorted(await api.list(uri));
  }
}

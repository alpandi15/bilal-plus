import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database_scope.dart';
import '../services/backup_service.dart';
import '../services/hijri_config_scope.dart';
import '../utils/date_key.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _cream = Color(0xFFFFF1D6);

const _lastBackupKey = 'backup_last_at';

/// Cadangkan & pulihkan seluruh catatan ibadah dan bacaan Al-Qur'an sebagai
/// satu berkas JSON - untuk pindah perangkat atau berjaga-jaga.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  DateTime? _lastBackup;
  (int, int)? _counts;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCounts();
  }

  Future<void> _loadLast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_lastBackupKey);
      if (mounted) {
        setState(() => _lastBackup = v == null ? null : DateTime.parse(v));
      }
    } catch (_) {}
  }

  Future<void> _loadCounts() async {
    final counts = await BackupService(AppDatabaseScope.of(context)).counts();
    if (mounted) setState(() => _counts = counts);
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _export() async {
    final db = AppDatabaseScope.of(context);
    final hijri = HijriConfigScope.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final service = BackupService(db);
      final data = await service.export(settings: hijri.exportSettings());
      final bytes = utf8.encode(service.exportText(data));
      final name = 'rindu-ramadan-${dateKey(DateTime.now())}.json';
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/json')],
          fileNameOverrides: [name],
          subject: 'Cadangan Rindu Ramadan',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (result.status != ShareResultStatus.dismissed) {
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupKey, now.toIso8601String());
        if (mounted) setState(() => _lastBackup = now);
      }
    } catch (e) {
      if (mounted) _snack('Gagal membuat cadangan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final db = AppDatabaseScope.of(context);
    final hijri = HijriConfigScope.of(context);

    final picked = await FilePicker.pickFiles(withData: true);
    final bytes = picked?.files.single.bytes;
    if (bytes == null || !mounted) return;

    final Map<String, dynamic> data;
    try {
      data = BackupService.decode(utf8.decode(bytes, allowMalformed: true));
    } on BackupException catch (e) {
      _snack(e.message);
      return;
    }

    final mode = await showModalBottomSheet<ImportMode>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => _ImportSheet(info: BackupService.info(data)),
    );
    if (mode == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await BackupService(db).import(data, mode: mode);
      await hijri.importSettings(
        (data['settings'] as Map?)?.cast<String, dynamic>(),
        replace: mode == ImportMode.replace,
      );
      if (mounted) {
        _snack(
          'Dipulihkan: ${result.ibadahLogs} catatan ibadah '
          '(${result.days} hari) & ${result.quranLogs} sesi baca',
        );
        _loadCounts();
      }
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _lastLabel() {
    final last = _lastBackup;
    if (last == null) return 'Belum pernah dicadangkan';
    final days = DateTime.now().difference(last).inDays;
    return switch (days) {
      0 => 'Terakhir dicadangkan hari ini',
      1 => 'Terakhir dicadangkan kemarin',
      _ => 'Terakhir dicadangkan $days hari lalu',
    };
  }

  @override
  Widget build(BuildContext context) {
    final last = _lastBackup;
    final stale = last == null || DateTime.now().difference(last).inDays >= 30;
    final counts = _counts;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(
            title: 'Cadangan Data',
            subtitle: 'Pindah perangkat tanpa kehilangan catatan',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  stale
                                      ? Icons.cloud_off_rounded
                                      : Icons.cloud_done_rounded,
                                  color: stale
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _lastLabel(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _stone,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              counts == null
                                  ? ' '
                                  : 'Di perangkat ini: ${counts.$1} catatan '
                                        'ibadah & ${counts.$2} sesi baca '
                                        "Al-Qur'an.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                            ),
                            if (stale)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Sebaiknya cadangkan minimal sebulan sekali.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _amber,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _busy ? null : _export,
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text(
                                'Buat & bagikan cadangan',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _amber,
                                side: const BorderSide(color: _line),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _busy ? null : _import,
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text(
                                'Pulihkan dari berkas',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _stone,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• Simpan berkas cadangan ke Google Drive atau '
                              'kirim ke diri sendiri lewat email/WhatsApp.\n'
                              '• Di perangkat baru, buka menu ini lalu '
                              '"Pulihkan dari berkas".\n'
                              '• Berkas berisi catatan ibadah, bacaan '
                              'Al-Qur\'an, hutang puasa, dan pilihan kalender '
                              'hijriah - tanpa lokasi.\n'
                              '• Android juga mencadangkan data aplikasi '
                              'otomatis ke akun Google bila Cadangan Google '
                              'aktif di pengaturan ponsel.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _stone,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({required this.info});
  final BackupInfo info;

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  ImportMode _mode = ImportMode.merge;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final range = info.firstDate == null
        ? 'tanpa catatan'
        : '${formatDateKeyShort(info.firstDate!)} ${info.firstDate!.substring(0, 4)} – '
              '${formatDateKeyShort(info.lastDate!)} ${info.lastDate!.substring(0, 4)}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pulihkan cadangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${info.ibadahLogs} catatan ibadah · ${info.quranLogs} sesi baca\n'
              '$range'
              '${info.exportedAt == null ? '' : '\nDibuat ${dateKey(info.exportedAt!.toLocal())}'}',
              style: const TextStyle(fontSize: 12, color: _muted, height: 1.5),
            ),
            const SizedBox(height: 14),
            _ModeTile(
              selected: _mode == ImportMode.merge,
              title: 'Gabungkan (disarankan)',
              detail:
                  'Catatan di perangkat ini tetap ada. Bila tanggal & ibadah '
                  'yang sama tercatat di keduanya, yang terbaru dipakai.',
              onTap: () => setState(() => _mode = ImportMode.merge),
            ),
            const SizedBox(height: 8),
            _ModeTile(
              selected: _mode == ImportMode.replace,
              title: 'Ganti semua',
              detail:
                  'Semua catatan di perangkat ini dihapus lalu diganti isi '
                  'berkas. Tidak bisa dibatalkan.',
              warning: true,
              onTap: () => setState(() => _mode = ImportMode.replace),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _mode == ImportMode.replace
                    ? const Color(0xFFDC2626)
                    : _amber,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(context, _mode),
              child: Text(
                _mode == ImportMode.replace ? 'Ganti semua data' : 'Gabungkan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.detail,
    required this.onTap,
    this.warning = false,
  });

  final bool selected, warning;
  final String title, detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = warning ? const Color(0xFFDC2626) : _amber;
    return Material(
      color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? accent : _line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? accent : _muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: warning && selected ? accent : _stone,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

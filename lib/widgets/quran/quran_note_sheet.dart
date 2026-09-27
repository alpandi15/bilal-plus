import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../services/quran_index.dart';
import '../../services/tajweed.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// "Al-Baqarah 1–5", "Al-Fatihah 7" atau "Al-Fatihah 7 – Al-Baqarah 3".
String formatAyahRange(int from, int to) {
  final (fs, fa) = surahAyahOf(from);
  final (ts, ta) = surahAyahOf(to);
  if (from == to) return '${surahName(fs)} $fa';
  if (fs == ts) return '${surahName(fs)} $fa–$ta';
  return '${surahName(fs)} $fa – ${surahName(ts)} $ta';
}

/// Tambah/ubah catatan pribadi untuk rentang ayat di dalam [surah].
/// Mengembalikan true bila tersimpan/terhapus.
Future<bool?> showQuranNoteSheet(
  BuildContext context, {
  required QuranDao dao,
  required int surah,
  required int fromAyah,
  int? toAyah,
  QuranNote? note,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (_) => _NoteSheet(
    dao: dao,
    surah: surah,
    from: note == null ? fromAyah : surahAyahOf(note.fromAyah).$2,
    to: note == null
        ? (toAyah ?? fromAyah)
        : surahAyahOf(note.toAyah).$1 == surah
        ? surahAyahOf(note.toAyah).$2
        : ayahCount(surah),
    note: note,
  ),
);

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.dao,
    required this.surah,
    required this.from,
    required this.to,
    this.note,
  });

  final QuranDao dao;
  final int surah, from, to;
  final QuranNote? note;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late int _from = widget.from, _to = widget.to;
  late final _body = TextEditingController(text: widget.note?.body);

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _body.text.trim();
    if (text.isEmpty) return;
    await widget.dao.saveNote(
      id: widget.note?.id,
      fromAyah: ayahIndex(widget.surah, _from),
      toAyah: ayahIndex(widget.surah, _to),
      body: text,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.dao.deleteNote(widget.note!.id);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _ayahPicker(String label, int value, int min, ValueChanged<int> on) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: [
          for (var a = min; a <= ayahCount(widget.surah); a++)
            DropdownMenuItem(value: a, child: Text('Ayat $a')),
        ],
        onChanged: (v) => v == null ? null : on(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Ubah catatan' : 'Catatan ayat',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            Text(
              '${surahName(widget.surah)} · hanya tersimpan di HP ini',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ayahPicker('Dari', _from, 1, (v) {
                  setState(() {
                    _from = v;
                    if (_to < v) _to = v;
                  });
                }),
                const SizedBox(width: 10),
                _ayahPicker('Sampai', _to, _from, (v) {
                  setState(() => _to = v);
                }),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              autofocus: !editing,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Tadabbur, pelajaran, hafalan, pertanyaan untuk ustadz…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _amber,
                    minimumSize: const Size(120, 48),
                  ),
                  onPressed: _save,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Keterangan warna tajwid.
Future<void> showTajweedLegend(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Warna tajwid',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 12),
          for (final r in TajweedRule.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: r.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${r.label}  ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: r.color,
                            ),
                          ),
                          TextSpan(text: r.description),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _stone,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Warna dihitung otomatis dari harakat & tanda Mushaf Standar '
              'Indonesia, dengan asumsi bacaan disambung (washal) dan berhenti '
              'di akhir ayat. Bila berhenti di tengah ayat, hukumnya bisa '
              'berbeda. Untuk belajar, tetap dampingi dengan guru/ustadz.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

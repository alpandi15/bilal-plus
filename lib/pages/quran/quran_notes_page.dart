import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/app_database_scope.dart';
import '../../services/quran_index.dart';
import '../../utils/date_key.dart';
import '../../widgets/quran/quran_note_sheet.dart';
import '../../widgets/sub_header.dart';
import 'quran_reader_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Semua catatan pribadi Al-Qur'an, dikelompokkan per surah.
class QuranNotesPage extends StatefulWidget {
  const QuranNotesPage({super.key});

  @override
  State<QuranNotesPage> createState() => _QuranNotesPageState();
}

class _QuranNotesPageState extends State<QuranNotesPage> {
  final _query = TextEditingController();
  Stream<List<QuranNote>>? _notes;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).quranDao;
    _notes ??= dao.watchNotes();
    final q = _query.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(
            title: "Catatan Qur'an",
            subtitle: 'Pribadi · hanya tersimpan di HP ini',
          ),
          Expanded(
            child: StreamBuilder<List<QuranNote>>(
              stream: _notes,
              builder: (context, snap) {
                final all = snap.data;
                if (all == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (all.isEmpty) return const _Empty();
                final notes = [
                  for (final n in all)
                    if (q.isEmpty ||
                        n.body.toLowerCase().contains(q) ||
                        formatAyahRange(
                          n.fromAyah,
                          n.toAyah,
                        ).toLowerCase().contains(q))
                      n,
                ];
                final bySurah = <int, List<QuranNote>>{};
                for (final n in notes) {
                  (bySurah[surahAyahOf(n.fromAyah).$1] ??= []).add(n);
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    TextField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari di ${all.length} catatan',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (notes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Tidak ada catatan yang cocok.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted),
                        ),
                      ),
                    for (final e in bySurah.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                        child: Text(
                          '${e.key}. ${surahName(e.key).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.6,
                            color: Color(0xCCB45309),
                          ),
                        ),
                      ),
                      for (final n in e.value)
                        _NoteCard(
                          note: n,
                          onOpen: () {
                            final (s, a) = surahAyahOf(n.fromAyah);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    QuranReaderPage(surah: s, ayah: a),
                              ),
                            );
                          },
                          onEdit: () => showQuranNoteSheet(
                            context,
                            dao: dao,
                            surah: e.key,
                            fromAyah: surahAyahOf(n.fromAyah).$2,
                            note: n,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onOpen,
    required this.onEdit,
  });

  final QuranNote note;
  final VoidCallback onOpen, onEdit;

  @override
  Widget build(BuildContext context) {
    final edited = note.updatedAt.difference(note.createdAt).inMinutes > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.sticky_note_2_rounded,
                    size: 18,
                    color: _amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatAyahRange(note.fromAyah, note.toAyah),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _stone,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.body,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: _stone,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${edited ? 'Diubah' : 'Dibuat'} '
                        '${formatDateKeyShort(dateKey(note.updatedAt))}',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ubah catatan',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18, color: _muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 48, color: _amber),
          SizedBox(height: 12),
          Text(
            'Belum ada catatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Saat membaca, ketuk ikon catatan di sebuah ayat untuk menulis '
            'tadabbur atau pelajaran dari ayat itu - bisa untuk beberapa '
            'ayat sekaligus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
          ),
        ],
      ),
    ),
  );
}

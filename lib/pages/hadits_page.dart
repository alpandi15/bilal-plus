import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/hadits_database.dart';
import '../services/app_settings.dart';
import '../services/hadits_download.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

String _mb(int bytes) {
  final mb = bytes / (1024 * 1024);
  return mb < 10 ? mb.toStringAsFixed(1) : mb.round().toString();
}

String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// Sembilan kitab hadits. Teks tiap kitab diunduh sekali dari server web
/// Bilal Tarawih lalu tersimpan & bisa dibaca offline.
class HaditsPage extends StatefulWidget {
  const HaditsPage({super.key, this.db, this.downloader});

  /// Pengganti untuk uji.
  final HaditsDatabase? db;
  final HaditsDownloader? downloader;

  @override
  State<HaditsPage> createState() => _HaditsPageState();
}

class _HaditsPageState extends State<HaditsPage> {
  late final HaditsDatabase _db = widget.db ?? HaditsDatabase.instance;
  late final HaditsDownloader _dl =
      widget.downloader ?? HaditsDownloader.instance;
  late final Stream<List<(HaditsBook, int)>> _books = _db.watchBooks();

  void _open(HaditsBook b) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HaditsBookPage(db: _db, book: b),
    ),
  );

  Future<void> _delete(HaditsBook b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${b.name}?'),
        content: const Text(
          'Teks kitab ini dihapus dari HP untuk menghemat ruang. Bisa '
          'diunduh lagi kapan saja.',
        ),
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
    if (ok == true) await _db.deleteBook(b.key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(title: 'Hadits', subtitle: '9 kitab · 38.102 hadits'),
          Expanded(
            child: ListenableBuilder(
              listenable: _dl,
              builder: (context, _) => StreamBuilder<List<(HaditsBook, int)>>(
                stream: _books,
                builder: (context, snap) {
                  final books = snap.data;
                  if (books == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      const _InfoCard(),
                      const SizedBox(height: 14),
                      for (final (b, stored) in books)
                        _BookCard(
                          book: b,
                          stored: stored,
                          state: _dl.stateOf(b.key),
                          running: _dl.isRunning(b.key),
                          onDownload: () => _dl.download(b.key, b.total),
                          onCancel: () => _dl.cancel(b.key),
                          onOpen: () => _open(b),
                          onDelete: () => _delete(b),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFA7F3D0)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.download_for_offline_rounded, size: 18, color: _emerald),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Unduh kitab yang ingin dibaca - sekali saja, lalu bisa dibuka '
            'tanpa internet. Yang diunduh hanya teks hadits dari server '
            'Bilal Tarawih; tidak ada data pribadi yang dikirim.',
            style: TextStyle(fontSize: 12, height: 1.45, color: _stone),
          ),
        ),
      ],
    ),
  );
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.stored,
    required this.state,
    required this.running,
    required this.onDownload,
    required this.onCancel,
    required this.onOpen,
    required this.onDelete,
  });

  final HaditsBook book;
  final int stored;
  final HaditsDownloadState? state;
  final bool running;
  final VoidCallback onDownload, onCancel, onOpen, onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = book.completedAt != null;
    final done = state?.done ?? stored;
    final partial = !complete && stored > 0 && !running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: complete ? onOpen : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: complete ? const Color(0xFFA7F3D0) : _line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: complete
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFF1D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: complete ? _emerald : _amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _stone,
                            ),
                          ),
                          Text(
                            complete
                                ? '${_thousands(stored)} hadits · tersimpan '
                                      '(±${_mb(stored * haditsBytesPerItem)} MB)'
                                : '${_thousands(book.total)} hadits · '
                                      'unduh ±${_mb(book.total * 290)} MB',
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    if (complete)
                      PopupMenuButton<String>(
                        tooltip: 'Lainnya',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: _muted,
                        ),
                        onSelected: (_) => onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus dari HP'),
                          ),
                        ],
                      )
                    else if (running)
                      IconButton(
                        tooltip: 'Batalkan',
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, color: _muted),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(partial ? 'Lanjutkan' : 'Unduh'),
                      ),
                  ],
                ),
                if (running || partial) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: book.total == 0 ? null : done / book.total,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF6E7CC),
                      valueColor: const AlwaysStoppedAnimation(_emerald),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    running
                        ? 'Mengunduh ${_thousands(done)} / '
                              '${_thousands(book.total)}…'
                        : 'Terhenti di ${_thousands(done)} / '
                              '${_thousands(book.total)}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
                if (state?.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      state!.error!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Membaca satu kitab: daftar bertahap (dimuat sambil digulir), cari kata
/// di terjemahan atau langsung nomor hadits.
class HaditsBookPage extends StatefulWidget {
  const HaditsBookPage({super.key, required this.db, required this.book});
  final HaditsDatabase db;
  final HaditsBook book;

  @override
  State<HaditsBookPage> createState() => _HaditsBookPageState();
}

class _HaditsBookPageState extends State<HaditsBookPage> {
  static const _chunk = 40;
  final _query = TextEditingController();
  final _rows = <Hadith>[];
  int? _total;
  bool _loading = false;
  int _generation = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final gen = ++_generation;
    final total = await widget.db.countMatching(widget.book.key, _query.text);
    if (!mounted || gen != _generation) return;
    setState(() {
      _rows.clear();
      _total = total;
    });
    await _more();
  }

  Future<void> _more() async {
    if (_loading || _total == null || _rows.length >= _total!) return;
    _loading = true;
    final gen = _generation;
    final page = await widget.db.page(
      widget.book.key,
      _query.text,
      offset: _rows.length,
      limit: _chunk,
    );
    _loading = false;
    if (!mounted || gen != _generation) return;
    setState(() => _rows.addAll(page));
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reset);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final size = (AppSettingsScope.maybeOf(context)?.readerSize ?? 28) - 6;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: widget.book.name,
            subtitle: total == null
                ? null
                : _query.text.trim().isEmpty
                ? '${_thousands(total)} hadits'
                : '${_thousands(total)} hasil',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _query,
              onChanged: _onQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari kata atau nomor hadits',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus',
                        onPressed: () {
                          _query.clear();
                          _onQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
          Expanded(
            child: total == null
                ? const Center(child: CircularProgressIndicator())
                : total == 0
                ? const Center(
                    child: Text(
                      'Tidak ditemukan.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 1200) _more();
                      return false;
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        6,
                        16,
                        32 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: _rows.length + (_rows.length < total ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _rows.length) {
                          _more();
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _HadithCard(
                          hadith: _rows[i],
                          book: widget.book,
                          arabicSize: size,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith,
    required this.book,
    required this.arabicSize,
  });

  final Hadith hadith;
  final HaditsBook book;
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'No. ${hadith.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _emerald,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Salin hadits',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '${hadith.arab}\n\n${hadith.translation}\n\n'
                          '(${book.name} no. ${hadith.number})',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hadits disalin')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18, color: _muted),
              ),
            ],
          ),
          if (hadith.arab.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ArabicText(
                hadith.arab,
                style: TextStyle(
                  fontSize: arabicSize,
                  height: 2,
                  color: const Color(0xFF1C1917),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              hadith.translation,
              style: const TextStyle(fontSize: 14, height: 1.6, color: _stone),
            ),
          ),
        ],
      ),
    );
  }
}

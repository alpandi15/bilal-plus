import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings.dart';
import '../widgets/arabic_font.dart';
import '../widgets/hadith_ref_text.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Satu bacaan di dalam sebuah do'a (satu do'a bisa punya beberapa versi).
class DoaReading {
  const DoaReading({
    required this.arabic,
    required this.latin,
    required this.arti,
    this.description,
    this.note,
    this.source,
  });

  final String arabic, latin, arti;
  final String? description, note, source;
}

class Doa {
  const Doa({required this.title, required this.tema, required this.readings});
  final String title, tema;
  final List<DoaReading> readings;

  /// Kumpulan do'a dari web Bilal Tarawih (assets/doa/doa.json).
  static Future<List<Doa>> load() async =>
      parse(await rootBundle.loadString('assets/doa/doa.json'));

  static List<Doa> parse(String raw) {
    String? opt(Object? v) {
      final s = '${v ?? ''}'.trim();
      return s.isEmpty ? null : s;
    }

    return [
      for (final d in (jsonDecode(raw) as List).cast<Map>())
        Doa(
          title: '${d['title']}',
          tema: '${d['tema']}',
          readings: [
            for (final v in (d['values'] as List).cast<Map>())
              DoaReading(
                arabic: '${v['arabic'] ?? ''}'.trim(),
                latin: '${v['latin'] ?? ''}'.trim(),
                arti: '${v['indonesia'] ?? ''}'.trim(),
                description: opt(v['description']),
                note: opt(v['note']),
                source: opt(v['perawih']),
              ),
          ],
        ),
    ];
  }
}

const _temaLabel = {'ramadan': 'Ramadan', 'umum': 'Harian', 'rajab': 'Rajab'};

/// Kumpulan do'a harian & Ramadan.
class DoaPage extends StatefulWidget {
  const DoaPage({super.key});

  @override
  State<DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends State<DoaPage> {
  List<Doa>? _all;
  String? _tema;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    Doa.load().then((d) {
      if (mounted) setState(() => _all = d);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final q = _query.text.trim().toLowerCase();
    final settings = AppSettingsScope.maybeOf(context);
    final list = [
      for (final d in all ?? const <Doa>[])
        if ((_tema == null || d.tema == _tema) &&
            (q.isEmpty ||
                d.title.toLowerCase().contains(q) ||
                d.readings.any((r) => r.arti.toLowerCase().contains(q))))
          d,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: "Kumpulan Do'a",
            subtitle: all == null ? null : "${all.length} do'a",
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF92400E)),
              onSelected: (v) {
                if (v == 'latin') {
                  settings?.setShowLatin(!(settings.showLatin));
                }
                if (v == 'arti') settings?.setShowArti(!(settings.showArti));
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'latin',
                  checked: settings?.showLatin ?? true,
                  child: const Text('Tampilkan latin'),
                ),
                CheckedPopupMenuItem(
                  value: 'arti',
                  checked: settings?.showArti ?? true,
                  child: const Text('Tampilkan terjemahan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: all == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
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
                          hintText: "Cari do'a",
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
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in [null, 'umum', 'ramadan', 'rajab'])
                            _Chip(
                              label: t == null ? 'Semua' : _temaLabel[t]!,
                              selected: _tema == t,
                              onTap: () => setState(() => _tema = t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final d in list)
                        _DoaCard(
                          doa: d,
                          showLatin: settings?.showLatin ?? true,
                          showArti: settings?.showArti ?? true,
                          arabicSize: (settings?.readerSize ?? 28) - 2,
                        ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            "Tidak ada do'a yang cocok.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _amber : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? _amber : _line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _stone,
          ),
        ),
      ),
    ),
  );
}

class _DoaCard extends StatelessWidget {
  const _DoaCard({
    required this.doa,
    required this.showLatin,
    required this.showArti,
    required this.arabicSize,
  });

  final Doa doa;
  final bool showLatin, showArti;
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 20,
                color: _amber,
              ),
            ),
            title: Text(
              doa.title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            subtitle: Text(
              [
                _temaLabel[doa.tema] ?? doa.tema,
                if (doa.readings.length > 1) '${doa.readings.length} bacaan',
              ].join(' · '),
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
            children: [
              for (final (i, r) in doa.readings.indexed) ...[
                if (i > 0) const Divider(height: 24, color: _line),
                if (r.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      r.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: _muted,
                      ),
                    ),
                  ),
                if (r.arabic.isNotEmpty)
                  ArabicText(
                    r.arabic,
                    style: TextStyle(
                      fontSize: arabicSize,
                      height: 2,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                if (showLatin && r.latin.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    r.latin,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
                if (showArti && r.arti.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.arti,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: _stone,
                    ),
                  ),
                ],
                if (r.source != null) ...[
                  const SizedBox(height: 6),
                  // "HR. Abu Daud no. 2010" -> buka hadits di aplikasi
                  HadithRefText(
                    r.source!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: _muted,
                    ),
                  ),
                ],
                if (r.note != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r.note!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

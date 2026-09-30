import 'package:flutter/material.dart';

import '../services/system_channel.dart';
import '../services/update_checker.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);

/// Lembar "Versi baru tersedia": catatan rilis + tombol unduh APK.
Future<void> showUpdateSheet(BuildContext context, AppUpdate update) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (context) => _UpdateSheet(update: update),
    );

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({required this.update});
  final AppUpdate update;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
                      ),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Color(0xFFF2D38A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bilal+ ${update.version} tersedia',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _stone,
                          ),
                        ),
                        const Text(
                          'Pasang menimpa versi lama - catatan ibadah tetap aman.',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (update.notes.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1E4CF)),
                    ),
                    child: SingleChildScrollView(
                      child: Text.rich(
                        TextSpan(children: releaseNoteSpans(update.notes)),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _stone,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  final ok = await SystemChannel.openUrl(update.downloadUrl);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Buka ${update.pageUrl}')),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Unduh pembaruan'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await UpdateChecker.skip(update.version);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        'Lewati versi ini',
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Nanti'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Markdown sederhana catatan rilis ("**tebal**", "- poin") jadi teks.
List<TextSpan> releaseNoteSpans(String md) {
  final spans = <TextSpan>[];
  final lines = md.replaceAll('\r', '').split('\n');
  final buf = StringBuffer();
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.startsWith('- ')) {
      buf.write('\n• ${line.substring(2)}');
    } else if (line.startsWith('  ') && buf.isNotEmpty) {
      buf.write(' ${line.trim()}'); // lanjutan poin
    } else if (line.isEmpty) {
      buf.write('\n');
    } else {
      buf.write('\n$line');
    }
  }
  final text = buf.toString().trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  final bold = RegExp(r'\*\*(.+?)\*\*');
  var at = 0;
  for (final m in bold.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    spans.add(
      TextSpan(
        text: m[1],
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}

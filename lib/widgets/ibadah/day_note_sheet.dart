import 'package:flutter/material.dart';

import '../../services/day_note.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _cream = Color(0xFFFFF1D6);

/// Baris "Catatan hari ini" di kartu ringkasan Ibadah: alasan & keterangan
/// bila sudah diisi, ajakan mengisi bila belum. Ketuk membuka
/// [showDayNoteSheet].
class DayNoteRow extends StatelessWidget {
  const DayNoteRow({
    super.key,
    required this.note,
    required this.isToday,
    required this.onTap,
  });

  final DayNote note;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = note.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              empty ? Icons.edit_note_rounded : Icons.sticky_note_2_outlined,
              size: 22,
              color: _amber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Catatan hari ini' : 'Catatan hari itu',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _stone,
                    ),
                  ),
                  Text(
                    empty
                        ? 'Ibadah lagi turun? Catat sebabnya - sakit, '
                              'perjalanan, sibuk…'
                        : note.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: empty ? _muted : _stone,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              empty ? Icons.add_rounded : Icons.chevron_right_rounded,
              size: 20,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lembar isi catatan harian: pilih alasan (boleh kosong) + keterangan
/// bebas. Mengembalikan catatan baru (kosong = dihapus), atau null bila
/// ditutup tanpa menyimpan.
Future<DayNote?> showDayNoteSheet(
  BuildContext context, {
  required DayNote note,
  required String title,
}) => showModalBottomSheet<DayNote>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _DayNoteSheet(note: note, title: title),
);

class _DayNoteSheet extends StatefulWidget {
  const _DayNoteSheet({required this.note, required this.title});

  final DayNote note;
  final String title;

  @override
  State<_DayNoteSheet> createState() => _DayNoteSheetState();
}

class _DayNoteSheetState extends State<_DayNoteSheet> {
  late DayReason? _reason = widget.note.reason;
  late final _text = TextEditingController(text: widget.note.text ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E5E4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Biar nanti di laporan kelihatan kenapa ibadah naik-turun. '
            'Hanya tersimpan di HP ini.',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in DayReason.values)
                ChoiceChip(
                  label: Text('${r.emoji} ${r.label}'),
                  selected: _reason == r,
                  selectedColor: _cream,
                  side: BorderSide(
                    color: _reason == r ? _amber : const Color(0xFFE7E5E4),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: _stone,
                    fontWeight: _reason == r
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  showCheckmark: false,
                  onSelected: (v) => setState(() => _reason = v ? r : null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            maxLines: 3,
            minLines: 2,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Keterangan (opsional), mis. demam sejak pagi',
              hintStyle: const TextStyle(fontSize: 13, color: _muted),
              filled: true,
              fillColor: const Color(0xFFFAFAF9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!widget.note.isEmpty)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _muted),
                  onPressed: () => Navigator.of(context).pop(const DayNote()),
                  child: const Text('Hapus'),
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pop(DayNote(reason: _reason, text: _text.text.trim())),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

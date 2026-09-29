import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/app_database_scope.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

const _scopeLabel = {
  IbadahScope.daily: 'Setiap hari',
  IbadahScope.ramadan: 'Siang Ramadan',
  IbadahScope.ramadanNight: 'Malam Ramadan',
  IbadahScope.sunnah: 'Hari yang disunnahkan',
  IbadahScope.qadha: 'Selama ada hutang puasa',
};

/// "Setiap hari", "Setiap Jumat", "Siang Ramadan · Senin & Kamis saja".
String ibadahScheduleLabel(IbadahItem item) {
  final days = weekdaysLabel(item.weekdays);
  if (days == null) return _scopeLabel[item.scope]!;
  return item.scope == IbadahScope.daily
      ? 'Setiap $days'
      : '${_scopeLabel[item.scope]} · $days saja';
}

/// Atur daftar ibadah: urutkan (seret), sembunyikan item bawaan, tambah &
/// hapus item sendiri, dan batasi ke hari tertentu (mis. Al-Kahfi tiap
/// Jumat). Catatan item yang disembunyikan tetap tersimpan.
Future<void> showIbadahManageSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) => IbadahManageSheet(scroll: scroll),
      ),
    );

class IbadahManageSheet extends StatelessWidget {
  const IbadahManageSheet({super.key, this.scroll});
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context) {
    final dao = AppDatabaseScope.of(context).ibadahDao;
    return StreamBuilder<List<IbadahItem>>(
      stream: dao.watchItems(includeInactive: true),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar ibadah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _amber),
                    onPressed: () => _add(context, dao),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Seret untuk mengurutkan. Ketuk ikon kalender untuk memilih '
                'hari (mis. hanya Jumat). Item yang disembunyikan tidak '
                'tampil di checklist, catatannya tetap tersimpan.',
                style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scroll,
                // ruang di atas navigasi sistem (gesture/tombol)
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: items.length,
                buildDefaultDragHandles: false,
                onReorder: (from, to) {
                  final ids = items.map((i) => i.id).toList();
                  final moved = ids.removeAt(from);
                  ids.insert(to > from ? to - 1 : to, moved);
                  dao.reorder(ids);
                },
                itemBuilder: (context, i) {
                  final item = items[i];
                  return _ManageTile(
                    key: ValueKey(item.id),
                    index: i,
                    item: item,
                    onActive: (v) => dao.setActive(item.id, v),
                    // sholat wajib tidak bisa dibatasi harinya
                    onDays: item.groupKey == sholatWajibGroup
                        ? null
                        : () => _pickDays(context, dao, item),
                    onDelete: item.builtIn
                        ? null
                        : () => dao.deleteCustomItem(item.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _add(BuildContext context, IbadahDao dao) async {
    final result =
        await showDialog<({String name, int? target, int? weekdays})>(
          context: context,
          builder: (_) => const _AddDialog(),
        );
    if (result == null) return;
    await dao.addCustomItem(
      name: result.name,
      kind: result.target == null ? IbadahKind.check : IbadahKind.counter,
      target: result.target ?? 1,
      weekdays: result.weekdays,
    );
  }

  Future<void> _pickDays(
    BuildContext context,
    IbadahDao dao,
    IbadahItem item,
  ) async {
    final result = await showDialog<({int? mask})>(
      context: context,
      builder: (_) => _DaysDialog(item: item),
    );
    if (result != null) await dao.setWeekdays(item.id, result.mask);
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    super.key,
    required this.index,
    required this.item,
    required this.onActive,
    required this.onDelete,
    this.onDays,
  });

  final int index;
  final IbadahItem item;
  final ValueChanged<bool> onActive;
  final VoidCallback? onDelete;
  final VoidCallback? onDays;

  @override
  Widget build(BuildContext context) {
    final limited = normalizeWeekdays(item.weekdays) != null;
    final detail = [
      ibadahScheduleLabel(item),
      if (item.kind == IbadahKind.counter) 'target ${item.target}',
      if (!item.builtIn) 'buatanmu',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.active ? Colors.white : const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_indicator_rounded, color: _muted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: item.active ? _stone : _muted,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: limited ? _amber : _muted,
                    fontWeight: limited ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          if (onDays != null)
            IconButton(
              tooltip: 'Atur hari',
              onPressed: onDays,
              icon: Icon(
                Icons.event_repeat_rounded,
                color: limited ? _amber : _muted,
              ),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline_rounded, color: _muted),
            ),
          Switch.adaptive(
            value: item.active,
            activeTrackColor: _amber,
            onChanged: onActive,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus "${item.name}"?'),
        content: const Text('Semua catatan item ini ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _amber),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete!();
  }
}

class _AddDialog extends StatefulWidget {
  const _AddDialog();

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController(text: '33');
  bool _counter = false;
  int? _weekdays;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final target = int.tryParse(_target.text);
    Navigator.pop(context, (
      name: name,
      target: _counter ? ((target ?? 1).clamp(1, 99999)) : null,
      weekdays: _weekdays,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah ibadah'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'mis. Sholawat, Baca hadits',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Centang')),
                ButtonSegment(value: true, label: Text('Hitungan')),
              ],
              selected: {_counter},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _counter = v.first),
            ),
            if (_counter) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target per hari'),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Hari',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            WeekdayPicker(
              mask: _weekdays,
              onChanged: (m) => setState(() => _weekdays = m),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _amber),
          onPressed: _submit,
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

/// Pilih hari untuk satu item; hasil `mask` null = setiap hari.
class _DaysDialog extends StatefulWidget {
  const _DaysDialog({required this.item});
  final IbadahItem item;

  @override
  State<_DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<_DaysDialog> {
  late int? _mask = normalizeWeekdays(widget.item.weekdays);

  @override
  Widget build(BuildContext context) {
    final scoped = widget.item.scope != IbadahScope.daily;
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            scoped
                ? 'Tampil pada ${_scopeLabel[widget.item.scope]!.toLowerCase()} '
                      'yang jatuh di hari terpilih.'
                : 'Tampil di checklist hanya pada hari terpilih - hari lain '
                      'tidak dihitung.',
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          WeekdayPicker(
            mask: _mask,
            onChanged: (m) => setState(() => _mask = m),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _amber),
          onPressed: () => Navigator.pop(context, (mask: _mask)),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

/// Chip "Setiap hari" + tujuh hari. [mask] null = setiap hari; memilih
/// semua hari atau mengosongkan pilihan kembali ke setiap hari.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({super.key, required this.mask, required this.onChanged});

  final int? mask;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final m = normalizeWeekdays(mask);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ChoiceChip(
          label: const Text('Setiap hari'),
          selected: m == null,
          selectedColor: _amber,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: m == null ? Colors.white : _stone),
          onSelected: (_) => onChanged(null),
        ),
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(weekdayShortNames[i]),
            tooltip: weekdayNames[i],
            selected: m != null && m & (1 << i) != 0,
            selectedColor: _amber,
            labelStyle: TextStyle(
              color: m != null && m & (1 << i) != 0 ? Colors.white : _stone,
              fontWeight: FontWeight.w600,
            ),
            showCheckmark: false,
            onSelected: (on) {
              final cur = m ?? 0;
              onChanged(
                normalizeWeekdays(on ? cur | (1 << i) : cur & ~(1 << i)),
              );
            },
          ),
      ],
    );
  }
}

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

/// Atur daftar ibadah: urutkan (seret), sembunyikan item bawaan, tambah &
/// hapus item sendiri. Catatan item yang disembunyikan tetap tersimpan.
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
                'Seret untuk mengurutkan. Item yang disembunyikan tidak '
                'tampil di checklist, catatannya tetap tersimpan.',
                style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
    final result = await showDialog<({String name, int? target})>(
      context: context,
      builder: (_) => const _AddDialog(),
    );
    if (result == null) return;
    await dao.addCustomItem(
      name: result.name,
      kind: result.target == null ? IbadahKind.check : IbadahKind.counter,
      target: result.target ?? 1,
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    super.key,
    required this.index,
    required this.item,
    required this.onActive,
    required this.onDelete,
  });

  final int index;
  final IbadahItem item;
  final ValueChanged<bool> onActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final detail = [
      _scopeLabel[item.scope]!,
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
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah ibadah'),
      content: Column(
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
        ],
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

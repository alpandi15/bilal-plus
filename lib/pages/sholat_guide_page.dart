import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/sholat_guide.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

/// Panduan bacaan sholat wajib, langkah demi langkah, dengan beberapa versi
/// (pendek/panjang/menurut madzhab). Versi bawaan mengikuti madzhab yang
/// dipilih; tiap langkah bisa dibandingkan dengan versi lain.
class SholatGuidePage extends StatefulWidget {
  const SholatGuidePage({super.key, this.fardhu = Fardhu.subuh});

  final Fardhu fardhu;

  @override
  State<SholatGuidePage> createState() => _SholatGuidePageState();
}

class _SholatGuidePageState extends State<SholatGuidePage> {
  late Fardhu _fardhu = widget.fardhu;
  SholatRole _role = SholatRole.sendiri;

  /// Versi yang dipilih manual per langkah (id -> indeks); sisanya bawaan
  /// madzhab.
  final _picked = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final madzhab = settings?.madzhab ?? Madzhab.syafii;
    final showLatin = settings?.showLatin ?? true;
    final showArti = settings?.showArti ?? true;
    final steps = sholatStepsFor(_fardhu, _role);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Bacaan Sholat',
            subtitle:
                '${_fardhu.label} · ${_fardhu.rakaat} rakaat · '
                'madzhab ${madzhab.label}',
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF92400E)),
              onSelected: (v) {
                if (v == 'latin') settings?.setShowLatin(!showLatin);
                if (v == 'arti') settings?.setShowArti(!showArti);
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'latin',
                  checked: showLatin,
                  child: const Text('Tampilkan latin'),
                ),
                CheckedPopupMenuItem(
                  value: 'arti',
                  checked: showArti,
                  child: const Text('Tampilkan terjemahan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _Pills<Fardhu>(
                  values: Fardhu.values,
                  selected: _fardhu,
                  label: (f) => f.label,
                  onSelected: (f) => setState(() => _fardhu = f),
                ),
                const SizedBox(height: 12),
                _MadzhabPicker(
                  selected: madzhab,
                  onSelected: (m) {
                    setState(_picked.clear);
                    settings?.setMadzhab(m);
                  },
                ),
                const SizedBox(height: 10),
                SegmentedButton<SholatRole>(
                  segments: [
                    for (final r in SholatRole.values)
                      ButtonSegment(value: r, label: Text(r.label)),
                  ],
                  selected: {_role},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() => _role = v.first),
                ),
                const SizedBox(height: 14),
                for (final (i, step) in steps.indexed)
                  _StepCard(
                    key: ValueKey(step.id),
                    number: i + 1,
                    step: step,
                    madzhab: madzhab,
                    selected: _picked[step.id] ?? step.defaultFor(madzhab),
                    showLatin: showLatin,
                    showArti: showArti,
                    onSelect: (v) => setState(() => _picked[step.id] = v),
                  ),
                const _SourceNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MadzhabPicker extends StatelessWidget {
  const _MadzhabPicker({required this.selected, required this.onSelected});
  final Madzhab selected;
  final ValueChanged<Madzhab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Madzhab',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const Text(
            'Menentukan versi bacaan yang ditampilkan lebih dulu. Semua versi '
            'tetap bisa dibandingkan di tiap langkah.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: _muted),
          ),
          const SizedBox(height: 10),
          _Pills<Madzhab>(
            values: Madzhab.values,
            selected: selected,
            label: (m) => m.hint == null ? m.label : '${m.label} · ${m.hint}',
            onSelected: onSelected,
            color: _emerald,
          ),
        ],
      ),
    );
  }
}

/// Deretan pil pilihan (turun ke baris berikut bila tidak muat).
class _Pills<T> extends StatelessWidget {
  const _Pills({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.color = _amber,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          _Pill(
            label: label(v),
            selected: v == selected,
            color: color,
            onTap: () => onSelected(v),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? color : _line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _stone,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xE6FFFFFF) : _emerald,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.number,
    required this.step,
    required this.madzhab,
    required this.selected,
    required this.showLatin,
    required this.showArti,
    required this.onSelect,
  });

  final int number;
  final SholatStep step;
  final Madzhab madzhab;
  final int? selected;
  final bool showLatin, showArti;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final v = selected == null ? null : step.variants[selected!];
    final skipped = step.defaultFor(madzhab) == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10785624),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1D6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _amber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.when,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (v != null && v.repeat > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${v.repeat}×',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _amber,
                    ),
                  ),
                ),
            ],
          ),
          if (step.variants.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, variant) in step.variants.indexed)
                  _Pill(
                    label: variant.label,
                    badge: variant.madzhab.contains(madzhab) ? '★' : null,
                    selected: i == selected,
                    color: _amber,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ],
          if (skipped) ...[
            const SizedBox(height: 10),
            _Notice(
              icon: Icons.info_outline_rounded,
              text:
                  'Tidak dibaca menurut madzhab ${madzhab.label}. Ketuk salah '
                  'satu versi di atas untuk melihat bacaannya.',
            ),
          ],
          if (v != null) ...[
            const SizedBox(height: 14),
            ArabicText(
              v.arabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                height: 2.0,
                color: Color(0xFF1C1917),
              ),
            ),
            if (showLatin) ...[
              const SizedBox(height: 10),
              Text(
                v.latin,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
            if (showArti) ...[
              const SizedBox(height: 8),
              Text(
                v.arti,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: _stone,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              [
                v.source,
                if (v.madzhab.isNotEmpty && v.madzhab.length < 4)
                  'bawaan ${v.madzhab.map((m) => m.label).join(', ')}',
              ].join(' · '),
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
          ],
          if (step.note != null) ...[
            const SizedBox(height: 10),
            _Notice(icon: Icons.auto_awesome_rounded, text: step.note!),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(
        '★ = versi bawaan madzhab yang dipilih. Teks Arab dari Hisnul Muslim '
        '(Sa\'id bin Ali Al-Qahthani) dan mushaf Al-Qur\'an; latin dan '
        'terjemahan hanya bantuan - pegang teks Arabnya dan tanyakan kepada '
        'guru/ustadz bila ragu. Perbedaan versi adalah khilaf yang '
        'dibenarkan; semuanya bersumber dari riwayat.',
        style: TextStyle(fontSize: 11, height: 1.5, color: _muted),
      ),
    );
  }
}

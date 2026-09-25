import 'package:flutter/material.dart';

import '../data/bilal_data.dart';
import '../services/app_settings.dart';
import '../services/bilal_tarawih.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Pembaca bacaan bilal tarawih 11 rakaat, per bagian (sebelum rakaat 1&2,
/// 3&4, ... sampai dzikir & doa sesudah witir) - sama dengan web Bilal
/// Tarawih. Geser atau pakai tombol di bawah untuk pindah bagian.
class BilalTarawihPage extends StatefulWidget {
  const BilalTarawihPage({super.key, this.initialSection = 0});

  final int initialSection;

  @override
  State<BilalTarawihPage> createState() => _BilalTarawihPageState();
}

class _BilalTarawihPageState extends State<BilalTarawihPage> {
  late int _index = widget.initialSection;
  late final _pages = PageController(initialPage: widget.initialSection);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int i) => _pages.animateToPage(
    i,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final showLatin = settings?.showLatin ?? true;
    final showArti = settings?.showArti ?? true;
    final size = settings?.readerSize ?? readerSizeDefault;
    final total = bilalSections.length;
    final section = bilalSections[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Bilal Tarawih 11 Rakaat',
            subtitle: 'Bagian ${_index + 1} dari $total · ${section.title}',
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
          _SectionStrip(index: _index, onSelected: _goTo),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _SectionView(
                key: PageStorageKey('bilal_$i'),
                number: i + 1,
                section: bilalSections[i],
                arabicSize: size,
                showLatin: showLatin,
                showArti: showArti,
              ),
            ),
          ),
          _BottomBar(
            index: _index,
            total: total,
            size: size,
            onBack: _index > 0 ? () => _goTo(_index - 1) : null,
            onNext: _index < total - 1 ? () => _goTo(_index + 1) : null,
            onSize: settings == null
                ? null
                : (delta) => settings.setReaderSize(size + delta),
          ),
        ],
      ),
    );
  }
}

/// Deretan nomor bagian + judul singkat, bisa diketuk untuk melompat.
class _SectionStrip extends StatefulWidget {
  const _SectionStrip({required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;

  @override
  State<_SectionStrip> createState() => _SectionStripState();
}

class _SectionStripState extends State<_SectionStrip> {
  final _keys = [for (final _ in bilalSections) GlobalKey()];

  @override
  void didUpdateWidget(_SectionStrip old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    // bawa pil bagian aktif ke tengah strip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.index].currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  static String _short(String title) => title
      .replaceFirst('Sebelum Shalat Witir Rakaat ke - ', 'Witir ')
      .replaceFirst('Sebelum Rakaat ke - ', 'Rakaat ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, section) in bilalSections.indexed)
                    Padding(
                      key: _keys[i],
                      padding: EdgeInsets.only(
                        right: i == bilalSections.length - 1 ? 0 : 8,
                      ),
                      child: _pill(i, section),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (widget.index + 1) / bilalSections.length),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: const Color(0xFFF6E7CC),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(int i, BilalSection section) {
    final selected = i == widget.index;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => widget.onSelected(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _amber : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? _amber : _line),
          ),
          child: Text(
            _short(section.title),
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
}

class _SectionView extends StatelessWidget {
  const _SectionView({
    super.key,
    required this.number,
    required this.section,
    required this.arabicSize,
    required this.showLatin,
    required this.showArti,
  });

  final int number;
  final BilalSection section;
  final double arabicSize;
  final bool showLatin, showArti;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          '$number. ${section.title}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _stone,
          ),
        ),
        if (number == 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: ArabicText(
              'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: arabicSize,
                height: 2.0,
                color: const Color(0xFF1C1917),
              ),
            ),
          )
        else
          const SizedBox(height: 12),
        for (final item in section.items)
          _ItemCard(
            item: item,
            arabicSize: arabicSize,
            showLatin: showLatin,
            showArti: showArti,
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.arabicSize,
    required this.showLatin,
    required this.showArti,
  });

  final BilalItem item;
  final double arabicSize;
  final bool showLatin, showArti;

  @override
  Widget build(BuildContext context) {
    final label = switch (item.kind) {
      BilalKind.seruan => null,
      BilalKind.doa => ('Doa', Icons.volunteer_activism_rounded),
      BilalKind.niat => ('Niat puasa', Icons.nightlight_round),
      BilalKind.dzikir => ('Dzikir', Icons.auto_awesome_rounded),
    };
    final latinSize = 13 + (arabicSize - readerSizeDefault) / 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: item.kind == BilalKind.seruan
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFDF8), Color(0xFFFFF5E4)],
              ),
        color: item.kind == BilalKind.seruan ? Colors.white : null,
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
          if (label != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(label.$2, size: 12, color: _amber),
                    const SizedBox(width: 4),
                    Text(
                      label.$1,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ArabicText(
            item.arabic,
            style: TextStyle(
              fontSize: arabicSize,
              height: 2.0,
              color: const Color(0xFF1C1917),
            ),
          ),
          if (showLatin && item.latin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.latin,
              style: TextStyle(
                fontSize: latinSize,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ],
          if (showArti && item.arti.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.arti,
              style: TextStyle(fontSize: latinSize, height: 1.5, color: _muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.total,
    required this.size,
    required this.onBack,
    required this.onNext,
    required this.onSize,
  });

  final int index, total;
  final double size;
  final VoidCallback? onBack, onNext;
  final ValueChanged<double>? onSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14785624),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Bagian sebelumnya',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Perkecil teks',
                onPressed: onSize == null || size <= readerSizeMin
                    ? null
                    : () => onSize!(-2),
                icon: const Icon(Icons.text_decrease_rounded, color: _amber),
              ),
              IconButton(
                tooltip: 'Perbesar teks',
                onPressed: onSize == null || size >= readerSizeMax
                    ? null
                    : () => onSize!(2),
                icon: const Icon(Icons.text_increase_rounded, color: _amber),
              ),
              Expanded(
                child: Text(
                  '${index + 1} / $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _stone,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _amber),
                onPressed: onNext,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

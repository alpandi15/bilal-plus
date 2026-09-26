import 'package:flutter/material.dart';

import '../../services/sholat_time.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

IconData jamaahIcon(bool jamaah) =>
    jamaah ? Icons.groups_rounded : Icons.person_rounded;

/// Pilihan besar "Berjama'ah / Sendiri" di lembar catat sholat.
class JamaahChoice extends StatelessWidget {
  const JamaahChoice({
    super.key,
    required this.jamaah,
    required this.soloWeight,
    required this.onChanged,
  });

  final bool jamaah;

  /// Nilai sholat sendiri yang berlaku (1 = tidak dikurangi).
  final double soloWeight;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "BERJAMA'AH?",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xCCB45309),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => showJamaahInfo(context, soloWeight: soloWeight),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, size: 14, color: _amber),
                  SizedBox(width: 3),
                  Text(
                    'Cara memilih',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Option(
                icon: jamaahIcon(true),
                label: "Berjama'ah",
                detail: 'Nilai penuh',
                selected: jamaah,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Option(
                icon: jamaahIcon(false),
                label: 'Sendiri',
                detail: soloWeight >= 1
                    ? 'Nilai penuh'
                    : 'Nilai ${soloWeightLabel(soloWeight)}',
                selected: !jamaah,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label, detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? _emerald : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _emerald : _line),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : _emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : _stone,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? const Color(0xE6FFFFFF) : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Pil kecil di bawah sholat yang sudah dicentang: "Jama'ah" / "Sendiri",
/// sekali ketuk untuk mengganti.
class JamaahPill extends StatelessWidget {
  const JamaahPill({super.key, required this.jamaah, required this.onTap});

  /// null = belum dicatat (catatan lama).
  final bool? jamaah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final j = jamaah;
    final color = j == false ? _muted : _emerald;
    return Semantics(
      button: true,
      label: j == null
          ? "Tandai berjama'ah atau sendiri"
          : j
          ? "Berjama'ah, ketuk untuk ganti ke sendiri"
          : "Sendiri, ketuk untuk ganti ke berjama'ah",
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: j == false
                ? const Color(0xFFF5F5F4)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: j == false ? _line : const Color(0xFFA7F3D0),
            ),
          ),
          // menyusut (bukan terpotong) pada font besar
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  j == null ? Icons.help_outline_rounded : jamaahIcon(j),
                  size: 11,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  j == null
                      ? '?'
                      : j
                      ? "Jama'ah"
                      : 'Sendiri',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
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

/// Panduan: kapan dicatat berjama'ah, cara cepat mengisinya, dan nilainya.
Future<void> showJamaahInfo(
  BuildContext context, {
  required double soloWeight,
  bool female = false,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Berjama'ah atau sendiri?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: jamaahIcon(true),
            color: _emerald,
            title: "Pilih Berjama'ah",
            text:
                'bila sholat bersama imam - di masjid, musholla, kantor, '
                'atau di rumah bersama keluarga - termasuk bila Anda yang '
                'menjadi imam. Tertinggal (masbuq) tetap berjama\'ah selama '
                'masih sempat mengikuti imam sebelum salam.',
          ),
          _InfoRow(
            icon: jamaahIcon(false),
            color: _muted,
            title: 'Pilih Sendiri',
            text:
                'bila sholat tanpa imam (munfarid), walaupun di masjid - '
                'misalnya datang sesudah jama\'ah selesai.',
          ),
          const _InfoRow(
            icon: Icons.touch_app_rounded,
            color: _amber,
            title: 'Cara cepat:',
            text:
                'Ketuk lingkaran sholat untuk mencentang, lalu ketuk label '
                'Jama\'ah / Sendiri di bawahnya untuk mengganti. Pilihan '
                'terakhir menjadi bawaan berikutnya - juga saat mencentang '
                'dari widget atau tombol "Sudah sholat" di notifikasi.',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              female
                  ? 'Bagi perempuan, sholat di rumah lebih utama - jadi '
                        'sholat sendiri tetap bernilai penuh. Pilihan jama\'ah '
                        'tetap dicatat di laporan.'
                  : 'Berjama\'ah bernilai penuh; sholat sendiri bernilai '
                        '${soloWeight >= 1 ? 'penuh juga' : soloWeightLabel(soloWeight)} '
                        'di persentase harian. "Sholat berjama\'ah lebih '
                        'utama dari sholat sendirian dengan dua puluh tujuh '
                        'derajat." (HR. Al-Bukhari & Muslim). Nilai ini bisa '
                        'diubah di Pengaturan > Sholat wajib.',
              style: const TextStyle(
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title, text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(fontSize: 13, height: 1.5, color: _stone),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../data/sholat_dalil.dart';
import '../arabic_font.dart';
import '../hadith_ref_text.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _red = Color(0xFFB91C1C);
const _blue = Color(0xFF1D4ED8);
const _teal = Color(0xFF0F766E);

const _names = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

/// Peringatan meninggalkan / mengqadha sholat tanpa uzur: dalil khusus
/// sholat [prayerKey] (bila ada), dalil umum, lalu pintu taubat.
Future<void> showSholatWarningSheet(BuildContext context, {String? prayerKey}) {
  final name = _names[prayerKey];
  final khusus = peringatanKhusus[prayerKey] ?? const <Dalil>[];
  return _show(
    context,
    icon: Icons.warning_amber_rounded,
    accent: _red,
    title: name == null
        ? 'Peringatan meninggalkan sholat'
        : 'Peringatan meninggalkan $name',
    subtitle:
        'Menunda sholat sampai habis waktunya tanpa uzur termasuk dosa '
        'besar. Bacalah sebagai pengingat, bukan untuk berputus asa.',
    children: [
      if (khusus.isNotEmpty) ...[
        _Heading('Khusus sholat $name', color: _red),
        for (final d in khusus) _DalilCard(d, accent: _red),
        if (prayerKey == 'dzuhur' || prayerKey == 'maghrib')
          const _Note(
            'Tidak ada hadits shahih yang khusus menyebut ancaman meninggalkan '
            'sholat ini - yang berlaku adalah ancaman umum di bawah.',
          ),
      ],
      const _Heading('Ancaman umum', color: _red),
      for (final d in peringatanUmum) _DalilCard(d, accent: _red),
      if (prayerKey == 'subuh') ...[
        const _Heading('Dan janjinya', color: _teal),
        const _DalilCard(keutamaanSubuh, accent: _teal),
      ],
      const _Heading('Pintu taubat selalu terbuka', color: _blue),
      const _Steps([
        'Segera kerjakan sholat yang tertinggal (qadha) - jangan ditunda '
            'lagi.',
        'Bertaubat sungguh-sungguh: menyesal, beristighfar, dan bertekad '
            'tidak mengulanginya.',
        'Siapkan diri sebelum adzan: pasang alarm, tidur lebih awal, '
            'tinggalkan urusan saat waktu sholat masuk.',
        'Perbanyak sholat sunnah & amal shalih.',
      ]),
      const _Note(
        'Tertidur atau lupa (tanpa disengaja) tidak berdosa - '
        'kaffaratnya menunaikan sholat itu begitu ingat:',
      ),
      for (final d in pintuTaubat) _DalilCard(d, accent: _blue),
      const _Disclaimer(),
    ],
  );
}

/// Panduan qashar & jamak saat safar.
Future<void> showQasharGuideSheet(BuildContext context) => _show(
  context,
  icon: Icons.luggage_rounded,
  accent: _teal,
  title: 'Qashar & jamak saat safar',
  subtitle:
      'Keringanan dari Allah bagi musafir - sholat tetap sah dengan '
      'nilai penuh.',
  children: [
    for (final b in panduanQashar) ...[
      _Heading(b.title, color: _teal),
      _Steps(b.points),
      for (final d in b.dalil) _DalilCard(d, accent: _teal),
    ],
    const _Disclaimer(),
  ],
);

Future<void> _show(
  BuildContext context, {
  required IconData icon,
  required Color accent,
  required String title,
  required String subtitle,
  required List<Widget> children,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFAF3),
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (context, scroll) => ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
        ),
        ...children,
      ],
    ),
  ),
);

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: color,
      ),
    ),
  );
}

class _DalilCard extends StatelessWidget {
  const _DalilCard(this.dalil, {required this.accent});
  final Dalil dalil;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border(left: BorderSide(color: accent, width: 3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F785624),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dalil.arabic != null) ...[
          ArabicText(
            dalil.arabic!,
            style: const TextStyle(
              fontSize: 21,
              height: 1.9,
              color: Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          dalil.text,
          style: const TextStyle(fontSize: 13.5, height: 1.5, color: _stone),
        ),
        const SizedBox(height: 6),
        HadithRefText(
          dalil.source,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps(this.points);
  final List<String> points;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 8),
                  child: Icon(Icons.circle, size: 5, color: _muted),
                ),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: _stone,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12.5, height: 1.45, color: _muted),
    ),
  );
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E6),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text(
      'Nomor hadits mengikuti kitab di aplikasi (ketuk untuk membaca '
      'lengkap). Ringkasan fiqih ini mengikuti pendapat jumhur ulama - untuk '
      'rincian & keadaan khusus, tanyakan kepada ustadz.',
      style: TextStyle(fontSize: 11.5, height: 1.45, color: _muted),
    ),
  );
}

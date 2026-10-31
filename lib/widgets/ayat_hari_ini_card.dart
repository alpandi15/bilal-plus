import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/quran/quran_reader_page.dart';
import '../services/app_settings.dart';
import '../services/ayat_harian.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/quran_text.dart';
import '../services/user_location_scope.dart';
import 'arabic_font.dart';
import 'quran/quran_ayah_text.dart';
import 'report/reveal.dart';

const _gold = Color(0xFFF2D38A);

/// Kartu "Ayat hari ini" di Beranda: ayatnya sama dengan widget & notifikasi
/// (dipilih dari tanggal), dengan font Al-Qur'an pilihan pengguna. Ketuk =
/// buka di pembaca.
class AyatHariIniCard extends StatelessWidget {
  const AyatHariIniCard({super.key});

  @override
  Widget build(BuildContext context) {
    final location = UserLocationScope.of(context).location;
    final today = calc.todayInZone(calc.timezoneFromLongitude(location.long));
    final font = AppSettingsScope.maybeOf(context)?.quranFont ?? QuranFont.lpmq;
    return FutureBuilder<QuranText>(
      future: QuranText.load(),
      builder: (context, snap) {
        final text = snap.data;
        if (text == null) return const SizedBox.shrink();
        final a = ayatContent(text, ayatOfDate(today), font: font);
        return Entrance(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QuranReaderPage(surah: a.surah, ayah: a.ayah),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3300503C),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        size: 16,
                        color: _gold,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'AYAT HARI INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: _gold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1FF2D38A),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0x66F2D38A)),
                        ),
                        child: Text(
                          a.label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  QuranAyahText(
                    a.arabic,
                    font: font,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 2,
                      color: Color(0xFFF4F1EA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.translation,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Color(0xFFB9D3CB),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Baca selengkapnya ›',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _gold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Salin ayat',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${a.arabic}\n\n${a.translation}\n'
                                  '(${a.label})',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ayat disalin')),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: _gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

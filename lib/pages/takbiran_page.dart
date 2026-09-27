import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/hijri_calendar.dart';
import '../services/hijri_config_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';
import 'tasbih_page.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _gold = Color(0xFFF2D38A);

class _Lafaz {
  const _Lafaz({
    required this.title,
    required this.arabic,
    required this.latin,
    required this.arti,
    this.note,
  });
  final String title, arabic, latin, arti;
  final String? note;
}

// Lafaz takbir yang lazim di Indonesia: takbir pendek (atsar Ibnu Mas'ud,
// Ibnu Abi Syaibah) lalu tambahan panjang yang dianjurkan Imam Syafi'i
// (al-Umm).
const _lafaz = [
  _Lafaz(
    title: 'Takbir',
    arabic:
        'اَللّٰهُ اَكْبَرُ، اَللّٰهُ اَكْبَرُ، اَللّٰهُ اَكْبَرُ، لَا اِلٰهَ '
        'اِلَّا اللّٰهُ وَاللّٰهُ اَكْبَرُ، اَللّٰهُ اَكْبَرُ وَلِلّٰهِ الْحَمْدُ',
    latin:
        'Allaahu akbar, Allaahu akbar, Allaahu akbar, laa ilaaha '
        'illallaahu wallaahu akbar, Allaahu akbar wa lillaahil hamd.',
    arti:
        'Allah Maha Besar, Allah Maha Besar, Allah Maha Besar. Tidak ada '
        'Tuhan selain Allah, dan Allah Maha Besar. Allah Maha Besar, dan '
        'segala puji hanya bagi Allah.',
    note:
        "Dibaca berulang (biasanya 3 kali) di awal. Sebagian ulama membaca "
        "takbir pembukanya dua kali - keduanya diamalkan.",
  ),
  _Lafaz(
    title: 'Takbir panjang',
    arabic:
        'اَللّٰهُ اَكْبَرُ كَبِيْرًا، وَالْحَمْدُ لِلّٰهِ كَثِيْرًا، '
        'وَسُبْحَانَ اللّٰهِ بُكْرَةً وَّاَصِيْلًا',
    latin:
        'Allaahu akbar kabiiraa, walhamdu lillaahi katsiiraa, wa '
        'subhaanallaahi bukrataw wa ashiilaa.',
    arti:
        'Allah Maha Besar dengan sebesar-besarnya, segala puji bagi Allah '
        'dengan sebanyak-banyaknya, dan Maha Suci Allah pagi dan petang.',
  ),
  _Lafaz(
    title: 'Lanjutan',
    arabic:
        'لَا اِلٰهَ اِلَّا اللّٰهُ وَلَا نَعْبُدُ اِلَّا اِيَّاهُ، '
        'مُخْلِصِيْنَ لَهُ الدِّيْنَ وَلَوْ كَرِهَ الْكٰفِرُوْنَ',
    latin:
        "Laa ilaaha illallaahu wa laa na'budu illaa iyyaah, mukhlishiina "
        'lahud diin, walau karihal kaafiruun.',
    arti:
        'Tidak ada Tuhan selain Allah, dan kami tidak menyembah kecuali '
        'kepada-Nya, dengan memurnikan agama bagi-Nya, walaupun orang-orang '
        'kafir membencinya.',
    note:
        'Di banyak daerah ditambah: walau karihal musyrikuun, walau '
        'karihal munaafiquun (walaupun orang musyrik & munafik membencinya).',
  ),
  _Lafaz(
    title: 'Penutup',
    arabic:
        'لَا اِلٰهَ اِلَّا اللّٰهُ وَحْدَهُ، صَدَقَ وَعْدَهُ، وَنَصَرَ '
        'عَبْدَهُ، وَاَعَزَّ جُنْدَهُ، وَهَزَمَ الْاَحْزَابَ وَحْدَهُ، لَا '
        'اِلٰهَ اِلَّا اللّٰهُ وَاللّٰهُ اَكْبَرُ، اَللّٰهُ اَكْبَرُ وَلِلّٰهِ '
        'الْحَمْدُ',
    latin:
        "Laa ilaaha illallaahu wahdah, shadaqa wa'dah, wa nashara 'abdah, "
        "wa a'azza jundah, wa hazamal ahzaaba wahdah. Laa ilaaha "
        'illallaahu wallaahu akbar, Allaahu akbar wa lillaahil hamd.',
    arti:
        'Tidak ada Tuhan selain Allah Yang Maha Esa. Dia menepati janji-Nya, '
        'menolong hamba-Nya, memuliakan tentara-Nya, dan mengalahkan '
        'golongan-golongan musuh sendirian. Tidak ada Tuhan selain Allah, '
        'Allah Maha Besar. Allah Maha Besar, dan segala puji bagi Allah.',
  ),
];

/// Takbiran Idulfitri & Iduladha: kapan malam takbiran berikutnya (menurut
/// kalender hijriah yang dipilih), waktu takbir, lafaz, dan penghitung.
class TakbiranPage extends StatelessWidget {
  const TakbiranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final showLatin = settings?.showLatin ?? true;
    final showArti = settings?.showArti ?? true;
    final anchors = HijriConfigScope.of(context).config.anchors;
    final loc = UserLocationScope.of(context).location;
    final today = calc.todayInZone(calc.timezoneFromLongitude(loc.long));

    // hari raya berikutnya (hari ini masih dihitung)
    (DateTime, int) next(int month, int day) {
      final h = anchors.fromJdn(
        gregorianToJdn(today.year, today.month, today.day),
      );
      for (final y in [h.year, h.year + 1]) {
        final d = anchors.toGregorian(y, month, day);
        if (!DateTime.utc(d.year, d.month, d.day).isBefore(today)) {
          return (d, y);
        }
      }
      return (anchors.toGregorian(h.year + 1, month, day), h.year + 1);
    }

    final (fitri, fitriYear) = next(10, 1);
    final (adha, adhaYear) = next(12, 10);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Takbiran',
            subtitle: 'Idulfitri & Iduladha',
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33312E81),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.nightlight_round, color: _gold, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'MALAM TAKBIRAN BERIKUTNYA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: _gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _EidRow(
                        name: 'Idulfitri $fitriYear H',
                        date: fitri,
                        today: today,
                      ),
                      const Divider(color: Color(0x33FFFFFF), height: 20),
                      _EidRow(
                        name: 'Iduladha $adhaYear H',
                        date: adha,
                        today: today,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: const Color(0xFF1E1B4B),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: () => openTasbih(
                          context,
                          title: 'Takbir',
                          arabic: 'اَللّٰهُ اَكْبَرُ',
                          latin: 'Allaahu akbar',
                          target: 33,
                        ),
                        icon: const Icon(Icons.touch_app_rounded),
                        label: const Text('Hitung takbir layar penuh'),
                      ),
                    ],
                  ),
                ),
                const _Title('WAKTU TAKBIRAN'),
                const _TimeCard(
                  icon: Icons.brightness_3_rounded,
                  title: 'Idulfitri - takbir mursal',
                  detail:
                      'Sejak terbenam matahari malam 1 Syawal sampai imam '
                      'memulai shalat Id. Dikumandangkan di masjid, rumah, '
                      'jalan, dan pasar - disunnahkan dikeraskan bagi '
                      'laki-laki.',
                  source:
                      '"...dan hendaklah kamu mengagungkan Allah (bertakbir) '
                      'atas petunjuk-Nya yang diberikan kepadamu." '
                      '(QS. Al-Baqarah: 185)',
                ),
                const _TimeCard(
                  icon: Icons.mosque_rounded,
                  title: 'Iduladha - takbir mursal & muqayyad',
                  detail:
                      'Mursal (kapan saja): sejak malam 10 Dzulhijjah sampai '
                      'imam memulai shalat Id. Muqayyad (sesudah sholat '
                      'fardhu): sejak Subuh hari Arafah (9 Dzulhijjah) sampai '
                      'Ashar hari tasyrik terakhir (13 Dzulhijjah).',
                ),
                const _Title('LAFAZ TAKBIR'),
                for (final l in _lafaz)
                  _LafazCard(
                    lafaz: l,
                    showLatin: showLatin,
                    showArti: showArti,
                  ),
                const SizedBox(height: 4),
                const Text(
                  "Takbir pendek dari atsar Ibnu Mas'ud (HR. Ibnu Abi "
                  "Syaibah); lafaz panjang dianjurkan Imam Syafi'i (al-Umm). "
                  'Tanggal hari raya mengikuti ketetapan kalender hijriah '
                  'yang dipilih di Pengaturan.',
                  style: TextStyle(fontSize: 11, height: 1.45, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EidRow extends StatelessWidget {
  const _EidRow({required this.name, required this.date, required this.today});
  final String name;
  final DateTime date, today;

  @override
  Widget build(BuildContext context) {
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final eve = DateTime.utc(date.year, date.month, date.day - 1);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Malam takbiran: ${formatDateKeyShort(dateKey(eve))} '
                'selepas Maghrib',
                style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              days <= 0 ? 'Hari ini' : '$days',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _gold,
              ),
            ),
            if (days > 0)
              const Text(
                'hari lagi',
                style: TextStyle(fontSize: 10, color: Color(0xCCFFFFFF)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.8,
        color: Color(0xCCB45309),
      ),
    ),
  );
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.source,
  });
  final IconData icon;
  final String title, detail;
  final String? source;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4338CA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: _muted,
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: 6),
                Text(
                  source!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _LafazCard extends StatelessWidget {
  const _LafazCard({
    required this.lafaz,
    required this.showLatin,
    required this.showArti,
  });
  final _Lafaz lafaz;
  final bool showLatin, showArti;

  @override
  Widget build(BuildContext context) {
    final size = AppSettingsScope.maybeOf(context)?.readerSize ?? 28;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lafaz.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4338CA),
            ),
          ),
          const SizedBox(height: 8),
          ArabicText(
            lafaz.arabic,
            style: TextStyle(
              fontSize: size,
              height: 2.1,
              color: const Color(0xFF1C1917),
            ),
          ),
          if (showLatin) ...[
            const SizedBox(height: 8),
            Text(
              lafaz.latin,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF92400E),
              ),
            ),
          ],
          if (showArti) ...[
            const SizedBox(height: 6),
            Text(
              lafaz.arti,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: _stone,
              ),
            ),
          ],
          if (lafaz.note != null) ...[
            const SizedBox(height: 8),
            Text(
              lafaz.note!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

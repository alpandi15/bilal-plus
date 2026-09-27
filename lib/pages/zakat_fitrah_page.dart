import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/zakat_fitrah_data.dart';
import '../services/app_settings.dart';
import '../widgets/arabic_font.dart';
import '../widgets/sub_header.dart';
import 'doa_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);

class ZakatPoin {
  const ZakatPoin(this.judul, this.detail);
  final String judul, detail;
}

class ZakatWaktu {
  const ZakatWaktu(this.hukum, this.tone, this.kapan, this.detail);
  final String hukum, tone, kapan, detail;
}

class ZakatLangkah {
  const ZakatLangkah(this.judul, this.detail, {this.peran, this.ucapan});
  final String judul, detail;

  /// 'pemberi' / 'penerima' - gelembung percakapan serah terima.
  final String? peran, ucapan;
}

const _toneColor = {
  'netral': Color(0xFF64748B),
  'wajib': Color(0xFFB45309),
  'utama': Color(0xFF047857),
  'makruh': Color(0xFFD97706),
  'haram': Color(0xFFDC2626),
};

/// Panduan Zakat Fitrah & Fidyah dengan kalkulator: kadar per jiwa, siapa
/// yang wajib, waktu, fidyah, tata cara serah terima, niat & doa. Naskah
/// sama dengan web Bilal Tarawih (lib/data/zakat_fitrah_data.dart).
class ZakatFitrahPage extends StatefulWidget {
  const ZakatFitrahPage({super.key});

  @override
  State<ZakatFitrahPage> createState() => _ZakatFitrahPageState();
}

class _ZakatFitrahPageState extends State<ZakatFitrahPage> {
  int _jiwa = 1;
  int _hariFidyah = 1;
  final _nominal = TextEditingController();
  List<Doa>? _doa;

  @override
  void initState() {
    super.initState();
    Doa.load().then((d) {
      if (mounted) setState(() => _doa = d);
    });
  }

  @override
  void dispose() {
    _nominal.dispose();
    super.dispose();
  }

  String _num(double v) {
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return s.replaceAll('.', ',').replaceAll(RegExp(r',?0+$'), '');
  }

  String _rupiah(int v) =>
      'Rp${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final showLatin = settings?.showLatin ?? true;
    final showArti = settings?.showArti ?? true;
    final perJiwa = int.tryParse(_nominal.text.replaceAll('.', '')) ?? 0;
    Doa? doa(String title) => _doa?.where((d) => d.title == title).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(
            title: 'Zakat Fitrah',
            subtitle: 'Kadar, waktu, fidyah & tata cara',
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
                // ------------------------------------------ kalkulator zakat
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33064E3B),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'KADAR PER JIWA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Color(0xFFF2D38A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: zakatKadar['utama'],
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: '  ≈ ${zakatKadar['setara']}'),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        zakatKadar['satuan']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Jumlah jiwa (termasuk tanggungan)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _Stepper(
                            value: _jiwa,
                            onChanged: (v) => setState(() => _jiwa = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nominal,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Nominal per jiwa dari panitia (opsional)',
                          labelStyle: const TextStyle(color: Color(0xCCFFFFFF)),
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0x1AFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2D38A),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total zakat fitrah',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0C3A33),
                              ),
                            ),
                            Text(
                              '${_num(_jiwa * 2.5)} kg beras '
                              '(≈ ${_num(_jiwa * 3.5)} liter)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0C3A33),
                              ),
                            ),
                            if (perJiwa > 0)
                              Text(
                                'atau ${_rupiah(perJiwa * _jiwa)} '
                                '($_jiwa × ${_rupiah(perJiwa)})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0C3A33),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Note(zakatKadar['dasar']!),
                _Note(zakatKadar['uang']!),
                _Note(zakatKadar['mutu']!),

                // -------------------------------------------- siapa wajib
                const _Title('SIAPA YANG WAJIB'),
                for (final (i, p) in zakatSyaratWajib.indexed)
                  _PoinTile(number: i + 1, poin: p),
                const _Title('IKUT DIBAYARKAN (TANGGUNGAN)'),
                for (final p in zakatDitanggung)
                  _PoinTile(icon: Icons.family_restroom_rounded, poin: p),

                // --------------------------------------------------- waktu
                const _Title('WAKTU MENUNAIKAN'),
                for (final (i, w) in zakatWaktu.indexed)
                  _WaktuTile(waktu: w, last: i == zakatWaktu.length - 1),

                // -------------------------------------------------- fidyah
                const _Title('FIDYAH'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${fidyahKadar['utama']} ',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _amber,
                              ),
                            ),
                            TextSpan(text: fidyahKadar['setara']),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13, color: _stone),
                      ),
                      Text(
                        fidyahKadar['satuan']!,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hari puasa yang ditinggalkan',
                              style: TextStyle(fontSize: 13, color: _stone),
                            ),
                          ),
                          _Stepper(
                            value: _hariFidyah,
                            dark: false,
                            onChanged: (v) => setState(() => _hariFidyah = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Total fidyah: $_hariFidyah mud ≈ '
                          '${_num(_hariFidyah * 0.675)} kg makanan pokok',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fidyahKadar['detail']!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final p in fidyahSiapa)
                  _PoinTile(icon: Icons.person_outline_rounded, poin: p),

                // ---------------------------------------------- tata cara
                const _Title('TATA CARA SERAH TERIMA DI MASJID'),
                for (final (i, s) in zakatTataCara.indexed)
                  _LangkahTile(number: i + 1, langkah: s),
                _Note(zakatCatatanAdat),

                // ------------------------------------------ niat & doa
                const _Title("NIAT & DO'A"),
                for (final title in const [
                  'Niat Zakat Fitrah',
                  'Niat Fidyah Puasa',
                  'Doa Menerima Zakat Fitrah (Amil/Panitia)',
                ])
                  if (doa(title) case final d?)
                    for (final r in d.readings)
                      _DoaCard(
                        title: d.title,
                        description: r.description,
                        arabic: r.arabic,
                        latin: r.latin,
                        arti: r.arti,
                        note: r.note,
                        showLatin: showLatin,
                        showArti: showArti,
                      ),
                _DoaCard(
                  title: "Do'a penutup",
                  description: zakatDoaPenutup['sumber'],
                  arabic: zakatDoaPenutup['arabic']!,
                  latin: zakatDoaPenutup['latin']!,
                  arti: zakatDoaPenutup['indonesia']!,
                  showLatin: showLatin,
                  showArti: showArti,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nominal uang mengikuti ketetapan panitia atau BAZNAS '
                  'setempat karena berbeda tiap tahun & daerah.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.dark = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : _amber;
    Widget button(IconData icon, String tip, int next, bool enabled) =>
        IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? () => onChanged(next) : null,
          icon: Icon(icon, color: enabled ? fg : fg.withValues(alpha: 0.35)),
        );
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0x1AFFFFFF) : const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, 'Kurangi', value - 1, value > 1),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          button(Icons.add_rounded, 'Tambah', value + 1, value < 99),
        ],
      ),
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

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 15, color: _amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF92400E),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PoinTile extends StatelessWidget {
  const _PoinTile({required this.poin, this.number, this.icon});
  final ZakatPoin poin;
  final int? number;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: number != null
              ? Text(
                  '$number',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _emerald,
                  ),
                )
              : Icon(icon, size: 17, color: _emerald),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poin.judul,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _stone,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                poin.detail,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WaktuTile extends StatelessWidget {
  const _WaktuTile({required this.waktu, required this.last});
  final ZakatWaktu waktu;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor[waktu.tone] ?? _muted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFF1E4CF)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          waktu.hukum,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waktu.kapan,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _stone,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waktu.detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangkahTile extends StatelessWidget {
  const _LangkahTile({required this.number, required this.langkah});
  final int number;
  final ZakatLangkah langkah;

  /// Teks dengan {isian} disorot.
  List<InlineSpan> _ucapan(String text) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in RegExp(r'\{([^}]*)\}').allMatches(text)) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(
        TextSpan(
          text: m[1],
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _amber,
            backgroundColor: Color(0xFFFFF1D6),
          ),
        ),
      );
      last = m.end;
    }
    spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final giver = langkah.peran == 'pemberi';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: _amber,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langkah.judul,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _stone,
                      ),
                    ),
                    Text(
                      langkah.detail,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (langkah.ucapan != null)
            Align(
              alignment: giver ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(
                  top: 8,
                  left: giver ? 36 : 56,
                  right: giver ? 20 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: giver ? Colors.white : const Color(0xFFECFDF5),
                  border: Border.all(
                    color: giver ? _line : const Color(0xFFA7F3D0),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(giver ? 4 : 18),
                    topRight: Radius.circular(giver ? 18 : 4),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      giver ? 'Pemberi zakat' : 'Panitia',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: giver ? _amber : _emerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: _ucapan(langkah.ucapan!)),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _stone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoaCard extends StatelessWidget {
  const _DoaCard({
    required this.title,
    required this.arabic,
    required this.latin,
    required this.arti,
    required this.showLatin,
    required this.showArti,
    this.description,
    this.note,
  });

  final String title, arabic, latin, arti;
  final String? description, note;
  final bool showLatin, showArti;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _stone,
          ),
        ),
        if (description != null)
          Text(
            description!,
            style: const TextStyle(fontSize: 12, height: 1.4, color: _muted),
          ),
        const SizedBox(height: 10),
        ArabicText(
          arabic,
          style: const TextStyle(
            fontSize: 24,
            height: 2,
            color: Color(0xFF1C1917),
          ),
        ),
        if (showLatin) ...[
          const SizedBox(height: 6),
          Text(
            latin,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF92400E),
            ),
          ),
        ],
        if (showArti) ...[
          const SizedBox(height: 6),
          Text(
            arti,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: _stone),
          ),
        ],
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(
            note!,
            style: const TextStyle(fontSize: 11.5, height: 1.4, color: _muted),
          ),
        ],
      ],
    ),
  );
}

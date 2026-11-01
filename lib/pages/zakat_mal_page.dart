import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/report_export.dart';
import '../services/zakat_mal.dart';
import '../widgets/ibadah/sholat_dalil_sheet.dart';
import '../widgets/sub_header.dart';
import 'zakat_fitrah_page.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Angka (rupiah/gram) dari teks berformat "1.250.000" atau "12,5".
double parseAmount(String s) {
  final t = s.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(t) ?? 0;
}

/// Hanya angka & titik ribuan; tampil "1.250.000".
class _ThousandsFormatter extends TextInputFormatter {
  const _ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Kalkulator zakat mal & zakat penghasilan: nisab 85 gram emas (harga diisi
/// sendiri), tarif 2,5%. Hasil bisa dibagikan sebagai gambar.
class ZakatMalPage extends StatefulWidget {
  const ZakatMalPage({super.key});

  @override
  State<ZakatMalPage> createState() => _ZakatMalPageState();
}

class _ZakatMalPageState extends State<ZakatMalPage> {
  final _boundary = GlobalKey();
  bool _penghasilan = false;
  GoldPrice _gold = const GoldPrice(0, null);
  bool _haul = true;

  final _harga = TextEditingController();
  final _tunai = TextEditingController();
  final _emas = TextEditingController();
  final _investasi = TextEditingController();
  final _piutang = TextEditingController();
  final _hutang = TextEditingController();
  final _gaji = TextEditingController();
  final _lain = TextEditingController();
  final _kebutuhan = TextEditingController();

  @override
  void initState() {
    super.initState();
    GoldPrice.load().then((g) {
      if (!mounted) return;
      setState(() {
        _gold = g;
        if (g.isSet) _harga.text = _fmt(g.perGram);
      });
    });
  }

  @override
  void dispose() {
    for (final c in [
      _harga,
      _tunai,
      _emas,
      _investasi,
      _piutang,
      _hutang,
      _gaji,
      _lain,
      _kebutuhan,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) => v.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );

  double get _price => parseAmount(_harga.text);

  Future<void> _saveGold() async {
    final v = _price;
    if (v <= 0) return;
    final g = await GoldPrice.save(v, DateTime.now());
    if (mounted) setState(() => _gold = g);
  }

  Future<void> _share() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final image = await captureReport(_boundary);
      if (!mounted) return;
      await shareReport(
        context,
        bytes: image.png,
        fileName: _penghasilan ? 'zakat-penghasilan.png' : 'zakat-mal.png',
        mimeType: 'image/png',
        subject: 'Perhitungan zakat',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stale = _gold.stale(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Zakat Mal',
            subtitle: 'Harta & penghasilan · nisab 85 gram emas',
            trailing: IconButton(
              tooltip: 'Dasar zakat',
              onPressed: () => showZakatMalSheet(context),
              icon: const Icon(Icons.menu_book_rounded, color: _amber),
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Zakat Mal'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Penghasilan'),
                            ),
                          ],
                          selected: {_penghasilan},
                          onSelectionChanged: (s) =>
                              setState(() => _penghasilan = s.first),
                        ),
                        const SizedBox(height: 14),
                        _Card(
                          title: 'HARGA EMAS PER GRAM',
                          children: [
                            _Field(
                              controller: _harga,
                              label: 'Harga emas hari ini',
                              prefix: 'Rp',
                              onChanged: (_) => setState(() {}),
                              onEditingComplete: _saveGold,
                              onTapOutside: _saveGold,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                !_gold.isSet
                                    ? 'Isi harga emas terkini (cek toko emas '
                                          'atau situs resmi) - aplikasi tidak '
                                          'mengambilnya dari internet.'
                                    : stale
                                    ? 'Harga terakhir diperbarui ${_gold.updatedAt == null ? '-' : '${DateTime.now().difference(_gold.updatedAt!).inDays} hari lalu'}. '
                                          'Perbarui supaya nisab akurat.'
                                    : 'Tersimpan di perangkat ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: stale || !_gold.isSet
                                      ? const Color(0xFFD97706)
                                      : _muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!_penghasilan)
                          ..._malForm()
                        else
                          ..._penghasilanForm(),
                        const SizedBox(height: 14),
                        RepaintBoundary(
                          key: _boundary,
                          child: _penghasilan
                              ? _penghasilanResult()
                              : _malResult(),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _amber,
                            side: const BorderSide(color: _line),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _price > 0 ? _share : null,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Bagikan sebagai gambar'),
                        ),
                        const SizedBox(height: 14),
                        const _Note(),
                        const SizedBox(height: 10),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: _amber),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ZakatFitrahPage(),
                            ),
                          ),
                          child: const Text('Zakat Fitrah & Fidyah ›'),
                        ),
                      ],
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

  List<Widget> _malForm() => [
    _Card(
      title: 'HARTA YANG DIMILIKI',
      children: [
        _Field(
          controller: _tunai,
          label: 'Uang tunai & tabungan',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _emas,
          label: 'Emas & perak simpanan (setara emas)',
          suffix: 'gram',
          decimal: true,
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _investasi,
          label: 'Investasi, saham, usaha',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _piutang,
          label: 'Piutang yang pasti kembali',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _hutang,
          label: 'Hutang jatuh tempo (dikurangkan)',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: _amber,
          value: _haul,
          onChanged: (v) => setState(() => _haul = v),
          title: const Text(
            'Sudah dimiliki satu tahun (haul)',
            style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
          ),
        ),
      ],
    ),
  ];

  List<Widget> _penghasilanForm() => [
    _Card(
      title: 'PENGHASILAN SEBULAN',
      children: [
        _Field(
          controller: _gaji,
          label: 'Gaji / penghasilan utama',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _lain,
          label: 'Penghasilan lain (bonus, usaha sampingan)',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        _Field(
          controller: _kebutuhan,
          label: 'Kebutuhan pokok (opsional, dikurangkan)',
          prefix: 'Rp',
          onChanged: (_) => setState(() {}),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Sebagian ulama menghitung dari penghasilan setelah kebutuhan '
            'pokok; kosongkan bila ingin dari penghasilan kotor.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
        ),
      ],
    ),
  ];

  Widget _malResult() {
    final r = hitungZakatMal(
      hargaEmasPerGram: _price,
      tunai: parseAmount(_tunai.text),
      emasGram: parseAmount(_emas.text),
      investasi: parseAmount(_investasi.text),
      piutang: parseAmount(_piutang.text),
      hutang: parseAmount(_hutang.text),
      haulTerpenuhi: _haul,
    );
    final ready = _price > 0;
    return _Result(
      title: 'ZAKAT MAL',
      ready: ready,
      wajib: r.wajib,
      headline: !ready
          ? 'Isi harga emas dulu'
          : r.wajib
          ? rupiah(r.zakat)
          : r.capaiNisab
          ? 'Belum satu haul'
          : 'Belum wajib zakat',
      lines: [
        ('Total harta', rupiah(r.harta)),
        ('Hutang', '- ${rupiah(r.hutang)}'),
        ('Harta bersih', rupiah(r.bersih)),
        ('Nisab (85 g emas)', rupiah(r.nisab)),
        if (ready && !r.capaiNisab)
          ('Kurang dari nisab', rupiah(r.kurangDariNisab)),
        if (r.capaiNisab && !r.haulTerpenuhi)
          ('Catatan', 'Zakat wajib setelah satu haul'),
      ],
    );
  }

  Widget _penghasilanResult() {
    final r = hitungZakatPenghasilan(
      hargaEmasPerGram: _price,
      gaji: parseAmount(_gaji.text),
      lain: parseAmount(_lain.text),
      kebutuhanPokok: parseAmount(_kebutuhan.text),
    );
    final ready = _price > 0;
    return _Result(
      title: 'ZAKAT PENGHASILAN',
      ready: ready,
      wajib: r.wajib,
      headline: !ready
          ? 'Isi harga emas dulu'
          : r.wajib
          ? '${rupiah(r.zakatBulanan)} / bulan'
          : 'Belum wajib zakat',
      lines: [
        ('Penghasilan sebulan', rupiah(r.bruto)),
        if (r.kebutuhan > 0) ('Kebutuhan pokok', '- ${rupiah(r.kebutuhan)}'),
        ('Dasar perhitungan', rupiah(r.dasar)),
        ('Nisab per bulan', rupiah(r.nisabBulanan)),
        if (ready && r.wajib) ('Setara setahun', rupiah(r.zakatTahunan)),
        if (ready && !r.wajib) ('Kurang dari nisab', rupiah(r.kurangDariNisab)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.prefix,
    this.suffix,
    this.decimal = false,
    this.onEditingComplete,
    this.onTapOutside,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix, suffix;
  final bool decimal;
  final ValueChanged<String> onChanged;
  final VoidCallback? onEditingComplete, onTapOutside;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
        else
          const _ThousandsFormatter(),
      ],
      onChanged: onChanged,
      onEditingComplete: () {
        onEditingComplete?.call();
        FocusScope.of(context).nextFocus();
      },
      onTapOutside: (_) {
        onTapOutside?.call();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix == null ? null : '$prefix ',
        suffixText: suffix,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// Kartu hasil - inilah yang dibagikan sebagai gambar.
class _Result extends StatelessWidget {
  const _Result({
    required this.title,
    required this.headline,
    required this.lines,
    required this.ready,
    required this.wajib,
  });

  final String title, headline;
  final List<(String, String)> lines;
  final bool ready, wajib;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: wajib
            ? const [Color(0xFF00503C), Color(0xFF0C3A33)]
            : const [Color(0xFF57534E), Color(0xFF292524)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Color(0xFFF2D38A),
                ),
              ),
            ),
            const Text(
              'Bilal+',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF2D38A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          headline,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        if (ready) ...[
          const SizedBox(height: 10),
          for (final (k, v) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                  Text(
                    v,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Perkiraan hitungan, bukan fatwa. Tanyakan lembaga zakat atau '
          'ustadz untuk kepastian.',
          style: TextStyle(
            fontSize: 10.5,
            color: Color(0x99FFFFFF),
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text(
      'Bukan fatwa. Aplikasi ini hanya alat bantu hitung berdasarkan nisab '
      '85 gram emas dan tarif 2,5% (rujukan BAZNAS & fatwa MUI No. 3/2003). '
      'Bentuk harta tertentu (pertanian, ternak, perdagangan) punya '
      'ketentuan sendiri - tanyakan lembaga zakat atau ustadz.',
      style: TextStyle(fontSize: 12, color: _stone, height: 1.5),
    ),
  );
}

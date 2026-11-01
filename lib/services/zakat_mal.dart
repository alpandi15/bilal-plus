import 'package:shared_preferences/shared_preferences.dart';

/// Zakat mal & zakat penghasilan: nisab = 85 gram emas, tarif 2,5% (rujukan
/// BAZNAS & fatwa MUI No. 3 Tahun 2003). Harga emas diisi pengguna sendiri
/// (tetap offline). Ini alat bantu hitung, bukan fatwa.

const nisabEmasGram = 85.0;
const zakatRate = 0.025;

/// Harga emas yang tidak diperbarui selama ini dianggap kedaluwarsa.
const goldPriceStaleAfter = Duration(days: 30);

class ZakatMalResult {
  const ZakatMalResult({
    required this.harta,
    required this.hutang,
    required this.bersih,
    required this.nisab,
    required this.haulTerpenuhi,
  });

  /// Total harta, hutang jatuh tempo, dan harta bersih (harta - hutang).
  final double harta, hutang, bersih;

  /// Nilai nisab dalam rupiah (85 g x harga emas).
  final double nisab;
  final bool haulTerpenuhi;

  bool get capaiNisab => nisab > 0 && bersih >= nisab;

  /// Wajib zakat: mencapai nisab DAN sudah satu haul.
  bool get wajib => capaiNisab && haulTerpenuhi;

  double get zakat => wajib ? bersih * zakatRate : 0;

  /// Kekurangan sampai nisab (0 bila sudah).
  double get kurangDariNisab =>
      capaiNisab ? 0 : (nisab - bersih).clamp(0, nisab);
}

ZakatMalResult hitungZakatMal({
  required double hargaEmasPerGram,
  double tunai = 0,
  double emasGram = 0,
  double investasi = 0,
  double piutang = 0,
  double hutang = 0,
  bool haulTerpenuhi = true,
}) {
  final harta = tunai + emasGram * hargaEmasPerGram + investasi + piutang;
  return ZakatMalResult(
    harta: harta,
    hutang: hutang,
    bersih: (harta - hutang).clamp(0, double.infinity),
    nisab: nisabEmasGram * hargaEmasPerGram,
    haulTerpenuhi: haulTerpenuhi,
  );
}

class ZakatPenghasilanResult {
  const ZakatPenghasilanResult({
    required this.bruto,
    required this.kebutuhan,
    required this.dasar,
    required this.nisabTahunan,
  });

  /// Penghasilan sebulan (gaji + lain-lain) dan kebutuhan pokok yang
  /// dikurangkan (opsional).
  final double bruto, kebutuhan;

  /// Dasar perhitungan zakat sebulan.
  final double dasar;
  final double nisabTahunan;

  /// Nisab disetarakan per bulan (nisab tahunan / 12).
  double get nisabBulanan => nisabTahunan / 12;

  bool get wajib => nisabTahunan > 0 && dasar >= nisabBulanan;
  double get zakatBulanan => wajib ? dasar * zakatRate : 0;
  double get zakatTahunan => zakatBulanan * 12;

  double get kurangDariNisab =>
      wajib ? 0 : (nisabBulanan - dasar).clamp(0, nisabBulanan);
}

ZakatPenghasilanResult hitungZakatPenghasilan({
  required double hargaEmasPerGram,
  double gaji = 0,
  double lain = 0,
  double kebutuhanPokok = 0,
}) {
  final bruto = gaji + lain;
  return ZakatPenghasilanResult(
    bruto: bruto,
    kebutuhan: kebutuhanPokok,
    dasar: (bruto - kebutuhanPokok).clamp(0, double.infinity),
    nisabTahunan: nisabEmasGram * hargaEmasPerGram,
  );
}

/// Harga emas yang diisi pengguna beserta tanggal terakhir diperbarui.
class GoldPrice {
  const GoldPrice(this.perGram, this.updatedAt);
  final double perGram;
  final DateTime? updatedAt;

  bool get isSet => perGram > 0;

  /// Perlu diperbarui? (belum pernah atau sudah lewat [goldPriceStaleAfter])
  bool stale(DateTime now) =>
      updatedAt == null || now.difference(updatedAt!) > goldPriceStaleAfter;

  static const _priceKey = 'zakat_gold_price';
  static const _atKey = 'zakat_gold_price_at';

  static Future<GoldPrice> load() async {
    final p = await SharedPreferences.getInstance();
    final at = p.getString(_atKey);
    return GoldPrice(
      p.getDouble(_priceKey) ?? 0,
      at == null ? null : DateTime.tryParse(at),
    );
  }

  static Future<GoldPrice> save(double perGram, DateTime now) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_priceKey, perGram);
    await p.setString(_atKey, now.toIso8601String());
    return GoldPrice(perGram, now);
  }
}

/// "Rp1.234.567" (pembulatan ke rupiah).
String rupiah(num v) {
  final n = v.round();
  final s = n.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${n < 0 ? '-' : ''}Rp$s';
}

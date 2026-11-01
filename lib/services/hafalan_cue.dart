import 'package:shared_preferences/shared_preferences.dart';

/// Mode "petunjuk awal" untuk menghafal: tiap ayat hanya menampilkan beberapa
/// kata pertamanya, sisanya dihafal dari ingatan. Dipakai di halaman Hafalan
/// dan widget layar utama.

/// Jumlah kata awal yang ditampilkan per ayat.
const cueWordsMin = 1, cueWordsMax = 3, cueWordsDefault = 1;

/// Jumlah ayat di widget (mode petunjuk): antrean widget memuat 8 ayat.
const cueCountMin = 2, cueCountMax = 8, cueCountDefault = 5;

/// [words] kata pertama dari [arabic] (bila ayatnya lebih pendek: seluruhnya).
String cueOf(String arabic, int words) {
  final parts = arabic.trim().split(RegExp(r'\s+'));
  return parts.take(words.clamp(cueWordsMin, cueWordsMax)).join(' ');
}

/// Ayat ini punya kata yang disembunyikan pada [words] kata awal?
bool cueHides(String arabic, int words) =>
    arabic.trim().split(RegExp(r'\s+')).length > words;

/// Tampilan widget Hafalan.
enum HafalanWidgetMode {
  /// satu ayat penuh (bisa ditutup kecuali kata pertama)
  full,

  /// beberapa ayat berikutnya, hanya kata awal tiap ayat
  cue;

  static HafalanWidgetMode parse(String? v) =>
      v == 'cue' ? HafalanWidgetMode.cue : HafalanWidgetMode.full;
}

/// Pilihan tampilan hafalan yang dibawa ke widget.
class HafalanWidgetOptions {
  const HafalanWidgetOptions({
    this.mode = HafalanWidgetMode.full,
    this.count = cueCountDefault,
    this.words = cueWordsDefault,
  });

  final HafalanWidgetMode mode;

  /// Jumlah ayat bila [mode] = cue.
  final int count;

  /// Kata awal per ayat bila [mode] = cue.
  final int words;

  /// Kunci pengaturan (dibaca juga di isolate latar).
  static const modeKey = 'hafalan_widget_mode';
  static const countKey = 'hafalan_widget_count';
  static const wordsKey = 'hafalan_cue_words';

  static HafalanWidgetOptions fromPrefs(SharedPreferences p) =>
      HafalanWidgetOptions(
        mode: HafalanWidgetMode.parse(p.getString(modeKey)),
        count: (p.getInt(countKey) ?? cueCountDefault).clamp(
          cueCountMin,
          cueCountMax,
        ),
        words: (p.getInt(wordsKey) ?? cueWordsDefault).clamp(
          cueWordsMin,
          cueWordsMax,
        ),
      );
}

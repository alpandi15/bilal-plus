import '../data/sholat_data.dart';

/// Madzhab fikih - menentukan versi bacaan yang dipilih lebih dulu.
enum Madzhab {
  syafii("Syafi'i", 'Lazim di Indonesia'),
  hanafi('Hanafi', null),
  maliki('Maliki', null),
  hanbali('Hanbali', null);

  const Madzhab(this.label, this.hint);
  final String label;
  final String? hint;

  static Madzhab parse(String? name) =>
      values.where((m) => m.name == name).firstOrNull ?? syafii;
}

/// Sholat fardhu yang bisa dipilih di panduan.
enum Fardhu {
  subuh('Subuh', 2),
  dzuhur('Dzuhur', 4),
  ashar('Ashar', 4),
  maghrib('Maghrib', 3),
  isya('Isya', 4);

  const Fardhu(this.label, this.rakaat);
  final String label;
  final int rakaat;
}

/// Peran saat sholat - mengubah lafaz niat.
enum SholatRole {
  sendiri('Sendiri'),
  makmum('Makmum'),
  imam('Imam');

  const SholatRole(this.label);
  final String label;
}

class SholatVariant {
  const SholatVariant({
    required this.label,
    required this.madzhab,
    required this.arabic,
    required this.latin,
    required this.arti,
    required this.source,
    this.repeat = 1,
  });

  final String label;

  /// Madzhab yang memakai versi ini sebagai bawaan (kosong = alternatif).
  final Set<Madzhab> madzhab;
  final String arabic, latin, arti, source;
  final int repeat;
}

class SholatStep {
  const SholatStep({
    required this.id,
    required this.title,
    required this.when,
    required this.variants,
    this.note,
  });

  final String id, title, when;
  final String? note;
  final List<SholatVariant> variants;

  /// Versi bawaan untuk [m]; null = langkah ini tidak dibaca menurut [m]
  /// (misalnya iftitah menurut Malikiyah, qunut Subuh menurut Hanafiyah).
  int? defaultFor(Madzhab m) {
    final i = variants.indexWhere((v) => v.madzhab.contains(m));
    return i < 0 ? null : i;
  }
}

/// Langkah-langkah sholat [f] secara berurutan, termasuk niat. Qunut hanya
/// untuk Subuh, tasyahud awal hanya untuk sholat 3-4 rakaat.
List<SholatStep> sholatStepsFor(Fardhu f, SholatRole role) {
  final byId = {for (final s in sholatSteps) s.id: s};
  final niat = sholatNiat[f.name]![role.index];
  return [
    SholatStep(
      id: 'niat',
      title: 'Niat',
      when: 'Di dalam hati, bersamaan dengan takbiratul ihram.',
      note:
          'Niat tempatnya di hati. Melafazkannya sebelum takbir dianjurkan '
          "menurut Syafi'iyah untuk membantu hati; menurut madzhab lain "
          'cukup di hati.',
      variants: [
        SholatVariant(
          label: role.label,
          madzhab: Madzhab.values.toSet(),
          arabic: niat.$1,
          latin: niat.$2,
          arti:
              'Aku berniat sholat fardhu ${f.label} ${_rakaat(f.rakaat)} '
              'rakaat menghadap kiblat, tunai'
              '${switch (role) {
                SholatRole.sendiri => '',
                SholatRole.makmum => ', sebagai makmum',
                SholatRole.imam => ', sebagai imam',
              }}, karena Allah Ta\'ala.',
          source: "Lafaz lazim madzhab Syafi'i",
        ),
      ],
    ),
    for (final s in sholatSteps)
      if (s.id != 'qunut' &&
          (s.id != 'tasyahud_awal' || f != Fardhu.subuh)) ...[
        s,
        // qunut: rakaat kedua Subuh sesudah i'tidal
        if (s.id == 'itidal' && f == Fardhu.subuh) byId['qunut']!,
      ],
  ];
}

String _rakaat(int n) => switch (n) {
  2 => 'dua',
  3 => 'tiga',
  _ => 'empat',
};

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/ibadah_insight.dart';
import '../../utils/date_key.dart';
import '../hadith_ref_text.dart';
import '../ibadah/sholat_log_sheet.dart' show sholatStatusColor;
import '../../services/sholat_time.dart';
import 'reveal.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _gold = Color(0xFFF2D38A);
const _green = Color(0xFF16A34A);
const _amber = Color(0xFFD97706);
const _red = Color(0xFFDC2626);
const _blue = Color(0xFF2563EB);

/// Latar krem laporan - juga latar gambar/PDF yang diekspor.
const reportBackground = Color(0xFFFFFAF3);

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// "Senin, 21 September 2026".
String longDate(String key) {
  final d = parseDateKey(key);
  return '${_hari[d.weekday - 1]}, ${d.day} ${monthName(d.month)} ${d.year}';
}

/// Gradasi kartu skor menurut predikat.
List<Color> gradeColors(Grade g) => switch (g) {
  Grade.luarBiasa ||
  Grade.sangatBaik ||
  Grade.baik => const [Color(0xFF00503C), Color(0xFF0C3A33)],
  Grade.cukup => const [Color(0xFFB45309), Color(0xFF78350F)],
  Grade.perluDitingkatkan => const [Color(0xFF9A3412), Color(0xFF7F1D1D)],
  Grade.berhalangan ||
  Grade.kosong => const [Color(0xFF475569), Color(0xFF1E293B)],
};

IconData insightIcon(InsightIcon i) => switch (i) {
  InsightIcon.sholat => Icons.mosque_rounded,
  InsightIcon.awalWaktu => Icons.schedule_rounded,
  InsightIcon.jamaah => Icons.groups_rounded,
  InsightIcon.tilawah => Icons.menu_book_rounded,
  InsightIcon.dhuha => Icons.wb_sunny_rounded,
  InsightIcon.malam => Icons.bedtime_rounded,
  InsightIcon.dzikir => Icons.spa_rounded,
  InsightIcon.sedekah => Icons.volunteer_activism_rounded,
  InsightIcon.puasa => Icons.restaurant_rounded,
  InsightIcon.streak => Icons.local_fire_department_rounded,
  InsightIcon.naik => Icons.trending_up_rounded,
  InsightIcon.turun => Icons.trending_down_rounded,
  InsightIcon.alarm => Icons.alarm_rounded,
  InsightIcon.qadha => Icons.history_rounded,
  InsightIcon.masjid => Icons.location_city_rounded,
  InsightIcon.bintang => Icons.auto_awesome_rounded,
  InsightIcon.kalender => Icons.calendar_month_rounded,
  InsightIcon.rawatib => Icons.add_task_rounded,
  InsightIcon.umum => Icons.checklist_rounded,
};

/* -------------------------------------------------------------------------- */
/*  Kepala ber-merek (ikut di gambar/PDF)                                      */
/* -------------------------------------------------------------------------- */

class ReportBrand extends StatelessWidget {
  const ReportBrand({super.key, required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.mosque_rounded, color: _gold, size: 22),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _stone,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
          ],
        ),
      ),
      const Text(
        'Bilal+',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Color(0xFFB45309),
        ),
      ),
    ],
  );
}

class ReportFooter extends StatelessWidget {
  const ReportFooter({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Laporan ini disusun otomatis di perangkatmu dari catatan ibadah '
          'yang kamu isi - tanpa AI online dan tanpa mengirim data ke mana '
          'pun. Ia pengingat untuk memperbaiki diri, bukan penilaian amal: '
          'diterima atau tidaknya amal hanyalah hak Allah.',
          style: TextStyle(fontSize: 10.5, height: 1.5, color: _muted),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Dibuat dengan Bilal+',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFFB45309),
        ),
      ),
    ],
  );
}

/* -------------------------------------------------------------------------- */
/*  Kartu skor                                                                 */
/* -------------------------------------------------------------------------- */

/// Kartu utama: cincin skor yang terisi & angka yang menghitung naik.
class ScoreHero extends StatelessWidget {
  const ScoreHero({
    super.key,
    required this.fraction,
    required this.grade,
    required this.title,
    required this.subtitle,
    this.chips = const [],
    this.centerLabel = 'tuntas',
    this.empty = false,
  });

  final double fraction;
  final Grade grade;
  final String title, subtitle;
  final List<HeroChip> chips;
  final String centerLabel;

  /// Tanpa data: cincin kosong, angka "–".
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final colors = gradeColors(grade);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // cahaya emas lembut di pojok kanan atas (di luar padding supaya
          // tidak terpotong persegi; sudut kartu yang memotongnya)
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x4DF2D38A), Color(0x00F2D38A)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Reveal(
                      duration: 1300,
                      curve: Curves.easeOutCubic,
                      builder: (context, t) => SizedBox.square(
                        dimension: 112,
                        child: CustomPaint(
                          painter: _RingPainter(empty ? 0 : fraction * t),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  empty
                                      ? '–'
                                      : '${(fraction * 100 * t).round()}%',
                                  style: const TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    color: Colors.white,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  centerLabel,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xCCFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Reveal(
                            delay: 250,
                            duration: 600,
                            builder: (context, t) => Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 8 * (1 - t)),
                                child: Text(
                                  grade.label,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, c) in chips.indexed)
                        Reveal(
                          delay: 500 + i * 90,
                          duration: 500,
                          curve: Curves.easeOutBack,
                          builder: (context, t) => Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.8 + 0.2 * t,
                              child: c,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroChip extends StatelessWidget {
  const HeroChip(this.icon, this.text, {super.key, this.color = Colors.white});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x26FFFFFF),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x26FFFFFF),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [Color(0xFFF2D38A), Color(0xFFFFF3C4), Color(0xFFF2D38A)],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/* -------------------------------------------------------------------------- */
/*  Kartu pembungkus & judul bagian                                            */
/* -------------------------------------------------------------------------- */

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14785624),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xCCB45309),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*  Sholat wajib                                                               */
/* -------------------------------------------------------------------------- */

Color prayerColor(PrayerState s) => switch (s) {
  PrayerState.onTime => sholatStatusColor[SholatStatus.onTime]!,
  PrayerState.late => sholatStatusColor[SholatStatus.late]!,
  PrayerState.jamak => sholatStatusColor[SholatStatus.jamak]!,
  PrayerState.uzur => sholatStatusColor[SholatStatus.uzur]!,
  PrayerState.qadha => sholatStatusColor[SholatStatus.qadha]!,
  PrayerState.untimed => const Color(0xFFD6A93E),
  PrayerState.ongoing => _amber,
  PrayerState.upcoming => const Color(0xFFA8A29E),
  PrayerState.missed => const Color(0xFF78716C),
  PrayerState.excused => const Color(0xFFA8A29E),
};

String prayerLabel(PrayerRow p) => switch (p.state) {
  PrayerState.onTime => 'Awal waktu',
  PrayerState.late => 'Telat ${p.delay} mnt',
  PrayerState.jamak => 'Jamak',
  PrayerState.uzur => 'Qadha (uzur)',
  PrayerState.qadha => 'Qadha',
  PrayerState.untimed => 'Tercatat',
  PrayerState.ongoing => 'Sampai ${p.until ?? ''}',
  PrayerState.upcoming => 'Belum masuk',
  PrayerState.missed => 'Terlewat',
  PrayerState.excused => 'Berhalangan',
};

IconData prayerIcon(PrayerState s) => switch (s) {
  PrayerState.onTime || PrayerState.jamak => Icons.check_rounded,
  PrayerState.late || PrayerState.untimed => Icons.check_rounded,
  PrayerState.uzur || PrayerState.qadha => Icons.history_rounded,
  PrayerState.ongoing => Icons.hourglass_top_rounded,
  PrayerState.upcoming => Icons.more_horiz_rounded,
  PrayerState.missed => Icons.close_rounded,
  PrayerState.excused => Icons.remove_rounded,
};

class PrayerStrip extends StatelessWidget {
  const PrayerStrip({super.key, required this.prayers});
  final List<PrayerRow> prayers;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, p) in prayers.indexed)
        Expanded(
          child: Reveal(
            delay: 150 + i * 90,
            duration: 650,
            curve: Curves.easeOutBack,
            builder: (context, t) {
              final c = prayerColor(p.state);
              final filled = p.done;
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * t,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? c : c.withValues(alpha: 0.1),
                          border: Border.all(color: c, width: filled ? 0 : 1.5),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          prayerIcon(p.state),
                          size: 22,
                          color: filled ? Colors.white : c,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _stone,
                        ),
                      ),
                      Text(
                        prayerLabel(p),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: c,
                        ),
                      ),
                      if (p.time != null)
                        Text(
                          p.time!,
                          style: const TextStyle(fontSize: 9.5, color: _muted),
                        ),
                      if (p.done && p.jamaah != null || p.qashar)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.jamaah != null)
                                Icon(
                                  p.jamaah!
                                      ? Icons.groups_rounded
                                      : Icons.person_rounded,
                                  size: 12,
                                  color: p.jamaah! ? _green : _muted,
                                ),
                              if (p.qashar)
                                const Padding(
                                  padding: EdgeInsets.only(left: 3),
                                  child: Text(
                                    'Q',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}

/* -------------------------------------------------------------------------- */
/*  Bar kategori                                                               */
/* -------------------------------------------------------------------------- */

Color fractionColor(double f) => f >= 0.8 ? _green : (f >= 0.4 ? _amber : _red);

class CategoryBars extends StatelessWidget {
  const CategoryBars({super.key, required this.rows});
  final List<CategoryRow> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, r) in rows.indexed)
        Padding(
          padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 14),
          child: Reveal(
            delay: 200 + i * 110,
            duration: 900,
            builder: (context, t) {
              final c = r.total == 0 ? _muted : fractionColor(r.fraction);
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(insightIcon(r.icon), size: 16, color: c),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _stone,
                          ),
                        ),
                      ),
                      Text(
                        r.total == 0
                            ? '–'
                            : '${(r.done * t).round()}/${r.total}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: c,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Stack(
                      children: [
                        Container(height: 8, color: const Color(0xFFF5F5F4)),
                        FractionallySizedBox(
                          widthFactor: (r.fraction * t).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c.withValues(alpha: 0.65), c],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    ],
  );
}

/* -------------------------------------------------------------------------- */
/*  Wawasan: yang baik / perlu ditingkatkan / rekomendasi                      */
/* -------------------------------------------------------------------------- */

Color _kindColor(InsightKind k) => switch (k) {
  InsightKind.good => _green,
  InsightKind.improve => _amber,
  InsightKind.tip => _blue,
};

class InsightSection extends StatelessWidget {
  const InsightSection({
    super.key,
    required this.kind,
    required this.title,
    required this.insights,
    this.emptyText,
    this.delay = 0,
  });

  final InsightKind kind;
  final String title;
  final List<Insight> insights;

  /// Teks bila kosong; null = bagian disembunyikan.
  final String? emptyText;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty && emptyText == null) return const SizedBox.shrink();
    final c = _kindColor(kind);
    final icon = switch (kind) {
      InsightKind.good => Icons.check_circle_rounded,
      InsightKind.improve => Icons.flag_rounded,
      InsightKind.tip => Icons.lightbulb_rounded,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          delay: delay,
          child: Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c == _green
                          ? const Color(0xFF15803D)
                          : (c == _amber ? const Color(0xFFB45309) : _blue),
                    ),
                  ),
                ),
                if (insights.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${insights.length}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: c,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (insights.isEmpty)
          Entrance(
            delay: delay + 80,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                emptyText!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _stone,
                ),
              ),
            ),
          ),
        for (final (i, ins) in insights.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              delay: delay + 80 + i * 110,
              child: InsightCard(ins),
            ),
          ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard(this.insight, {super.key});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final c = _kindColor(insight.kind);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F785624),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        insightIcon(insight.icon),
                        size: 19,
                        color: c,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              color: _stone,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            insight.detail,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: _muted,
                            ),
                          ),
                          if (insight.ref != null) ...[
                            const SizedBox(height: 6),
                            HadithRefText(
                              insight.ref!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  Bilah aksi: bagikan gambar / PDF                                           */
/* -------------------------------------------------------------------------- */

class ReportActions extends StatelessWidget {
  const ReportActions({
    super.key,
    required this.enabled,
    required this.busy,
    required this.onImage,
    required this.onPdf,
  });

  final bool enabled, busy;
  final VoidCallback onImage, onPdf;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _line)),
      boxShadow: [
        BoxShadow(
          color: Color(0x14785624),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFFCD34D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: enabled && !busy ? onImage : null,
                icon: const Icon(Icons.image_rounded, size: 20),
                label: const Text(
                  'Gambar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFFB45309),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: enabled && !busy ? onPdf : null,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text(
                  'PDF',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Kualitas sholat wajib sepanjang rentang: bar bertumpuk (awal waktu,
/// jamak/uzur, terlambat, qadha, tak tercatat) + tiga angka ringkas.
class SholatQuality extends StatelessWidget {
  const SholatQuality({
    super.key,
    required this.onTime,
    required this.valid,
    required this.late,
    required this.qadha,
    required this.missed,
    required this.jamaahPercent,
  });

  final int onTime, valid, late, qadha, missed;
  final int? jamaahPercent;

  @override
  Widget build(BuildContext context) {
    final timed = onTime + late + qadha + valid;
    final parts = [
      (onTime, sholatStatusColor[SholatStatus.onTime]!, 'Awal waktu'),
      (valid, sholatStatusColor[SholatStatus.jamak]!, 'Jamak/uzur'),
      (late, sholatStatusColor[SholatStatus.late]!, 'Terlambat'),
      (qadha, sholatStatusColor[SholatStatus.qadha]!, 'Qadha'),
      (missed, const Color(0xFFD6D3D1), 'Tak tercatat'),
    ].where((p) => p.$1 > 0).toList();

    Widget tile(String value, String label, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
      ),
    );

    if (parts.isEmpty) {
      return const Text(
        'Belum ada catatan sholat bulan ini.',
        style: TextStyle(fontSize: 12.5, color: _muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          delay: 300,
          duration: 1000,
          builder: (context, t) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 14,
              color: const Color(0xFFF5F5F4),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: t.clamp(0.0, 1.0),
                child: Row(
                  children: [
                    for (final p in parts)
                      Expanded(
                        flex: p.$1,
                        child: Container(color: p.$2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.$3} ${p.$1}',
                    style: const TextStyle(fontSize: 10.5, color: _muted),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            tile(
              timed == 0 ? '–' : '${((onTime + valid) * 100 / timed).round()}%',
              'tepat waktu',
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 8),
            tile(
              jamaahPercent == null ? '–' : '$jamaahPercent%',
              "berjama'ah",
              const Color(0xFF0D9488),
            ),
            const SizedBox(width: 8),
            tile(
              '$qadha',
              'qadha tanpa uzur',
              qadha > 0 ? const Color(0xFFDC2626) : const Color(0xFF78716C),
            ),
          ],
        ),
      ],
    );
  }
}

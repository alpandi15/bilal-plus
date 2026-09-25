import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prayer_models.dart';
import '../services/hijri_config_scope.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/ramadan_calendar.dart';
import '../services/user_location_scope.dart';
import 'hijri_settings_sheet.dart';

const _cardRadius = BorderRadius.all(Radius.circular(26));

// bayangan dilukis di luar ClipRRect supaya tidak ikut terpotong
const _cardShadow = BoxDecoration(
  borderRadius: _cardRadius,
  boxShadow: [
    BoxShadow(color: Color(0x26291E0F), blurRadius: 28, offset: Offset(0, 12)),
  ],
);

const _cardFill = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xB8FFFDF7), Color(0x94FFF4E0)],
  ),
);

// garis tepi dilukis di atas ornamen (foregroundDecoration)
const _cardBorder = BoxDecoration(
  borderRadius: _cardRadius,
  border: Border.fromBorderSide(BorderSide(color: Color(0x99FFFFFF))),
);

/// Cangkang kartu: bayangan -> clip membulat -> isi + ornamen glow yang
/// menempel ke tepi kartu (bukan ke tepi padding) -> konten.
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardShadow,
      child: ClipRRect(
        borderRadius: _cardRadius,
        child: Container(
          decoration: _cardFill,
          foregroundDecoration: _cardBorder,
          child: Stack(
            children: [
              const Positioned.fill(child: _Ornament()),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _bigDigitStyle = TextStyle(
  fontSize: 40,
  fontWeight: FontWeight.w800,
  height: 1.05,
  color: Color(0xFF44403C),
  fontFeatures: [FontFeature.tabularFigures()],
);

const _smallDigitStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w800,
  height: 1.1,
  color: Color(0xFF1C1917),
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Satu kolom angka yang bergulir ala odometer: digit lama tergeser ke atas,
/// digit baru masuk dari bawah - padanan komponen `Digit` (countdown.tsx).
class _RollingDigit extends StatefulWidget {
  const _RollingDigit({
    required this.value,
    required this.delay,
    required this.style,
  });
  final String value;
  final Duration delay;
  final TextStyle style;

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 550),
    vsync: this,
  )..value = 1;
  late final Animation<double> _t = CurvedAnimation(
    parent: _ctrl,
    curve: const Cubic(0.16, 1, 0.3, 1),
  );

  String _from = '';
  String? _incoming;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
  }

  @override
  void didUpdateWidget(covariant _RollingDigit old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;

    _from = old.value;
    _incoming = widget.value;
    _ctrl.value = 0;
    _delayTimer?.cancel();
    _delayTimer = Timer(widget.delay, () {
      if (!mounted) return;
      _ctrl.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _incoming = null);
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final incoming = _incoming;
        // Stack.clipBehavior hanya memotong anak Positioned yang overflow;
        // FractionalTranslation itu transformasi saat paint, jadi perlu
        // ClipRect sungguhan agar digit yang keluar/masuk tidak bocor.
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // placeholder tak terlihat: mengunci lebar & tinggi kolom
              Opacity(opacity: 0, child: Text('0', style: widget.style)),
              if (incoming != null)
                FractionalTranslation(
                  translation: Offset(0, -1.05 * _t.value),
                  child: Text(_from, style: widget.style),
                ),
              FractionalTranslation(
                translation: Offset(
                  0,
                  incoming == null ? 0 : 1.05 * (1 - _t.value),
                ),
                child: Text(incoming ?? widget.value, style: widget.style),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Angka bergulir multi-digit. Digit paling kanan (satuan) berganti lebih
/// dulu, digit di kirinya menyusul dengan jeda kecil - padanan
/// `RollingNumber`.
class _RollingNumber extends StatelessWidget {
  const _RollingNumber({
    required this.value,
    this.digits = 2,
    required this.style,
  });
  final int value;
  final int digits;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final chars = value
        .clamp(0, 999999)
        .toString()
        .padLeft(digits, '0')
        .split('');
    final last = chars.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          _RollingDigit(
            value: chars[i],
            delay: Duration(milliseconds: ((last - i) * 110).round()),
            style: style,
          ),
      ],
    );
  }
}

class _Ornament extends StatelessWidget {
  const _Ornament();
  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          right: -64,
          top: -80,
          child: _Glow(size: 176, color: Color(0x73FBBF24)),
        ),
        Positioned(
          left: -64,
          bottom: -80,
          child: _Glow(size: 176, color: Color(0x4710B981)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, 0.7],
        ),
      ),
    ),
  );
}

/// Kartu hitung mundur menuju Ramadan (atau nomor hari Ramadan bila sudah
/// masuk), dengan digit bergulir ala odometer - padanan `Countdown`
/// (`countdown.tsx`) di halaman beranda web.
///
/// Tanggal 1 Ramadan-nya dibaca dari konfigurasi kalender hijriah
/// (`hijri_config.json`, jangkar bulan 9) lewat [HijriConfigScope] - sumber
/// yang sama dengan kalender hijriah, jadi keduanya tidak bisa bertentangan.
/// Tahun yang belum punya jangkar memakai perhitungan tabular dan diberi
/// keterangan "(perkiraan)".
class RamadanCountdown extends StatefulWidget {
  const RamadanCountdown({super.key});

  @override
  State<RamadanCountdown> createState() => _RamadanCountdownState();
}

class _RamadanCountdownState extends State<RamadanCountdown> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = UserLocationScope.of(context).location;
    final tz = calc.timezoneFromLongitude(location.long);
    // Ramadan dipilih dari tanggal kalender di zona lokasi, bukan zona
    // perangkat - lewat tengah malam WIT tanggalnya sudah berganti walau
    // ponsel yang di WIB belum.
    final anchors = HijriConfigScope.of(context).config.anchors;
    final today = calc.todayInZone(tz, _now);
    final afterMaghrib = !_now.isBefore(
      calc
          .calculatePrayerTimes(
            latitude: location.lat,
            longitude: location.long,
            date: today,
          )
          .times[PrayerKey.maghrib]!,
    );
    final status = ramadanStatus(
      today: today,
      afterMaghrib: afterMaghrib,
      anchors: anchors,
    );
    if (status.phase == RamadanPhase.eid) {
      return _EidCard(
        status: status,
        // tanggal Masehi-nya masih hari terakhir Ramadan = sudah lewat
        // Maghrib, malam takbiran
        takbiran: today.isBefore(status.ramadan.end),
        next: relevantRamadan(status.ramadan.end, anchors),
      );
    }
    final ramadan = status.ramadan;

    // Malam sebelum 1 Ramadan (hari hijriah berganti saat maghrib). Dibuat
    // via DateTime.utc, sama seperti `todayInZone`, supaya selisih hari di
    // bawah selalu kelipatan 24 jam yang bersih - tidak bergeser mengikuti
    // zona waktu sistem perangkat.
    final eve = DateTime.utc(
      ramadan.start.year,
      ramadan.start.month,
      ramadan.start.day - 1,
    );
    final startsAt = calc
        .calculatePrayerTimes(
          latitude: location.lat,
          longitude: location.long,
          date: eve,
        )
        .times[PrayerKey.maghrib]!;

    final started = !_now.isBefore(startsAt);

    if (started) {
      final elapsed = today.difference(eve).inDays;
      final dayNumber = (elapsed + (afterMaghrib ? 1 : 0)).clamp(
        1,
        ramadan.days,
      );
      return _Card(
        child: _Compact(
          kicker: 'RAMADAN ${ramadan.hijriYear} H 🌙',
          title: 'Alhamdulillah, hari ke-$dayNumber',
          lines: [
            'Idulfitri insyaa Allah ${_formatTanggal(ramadan.end)}'
                '${ramadan.statusLabel.isNotEmpty ? ' (${ramadan.statusLabel})' : ''}',
          ],
          number: dayNumber,
          unit: 'HARI',
          footer: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: dayNumber / ramadan.days,
              minHeight: 6,
              backgroundColor: const Color(0x33B45309),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            ),
          ),
        ),
      );
    }

    final diff = startsAt.difference(_now);
    final totalSeconds = diff.isNegative ? 0 : diff.inSeconds;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return _Card(
      child: _Compact(
        kicker: 'MENUJU RAMADAN ${ramadan.hijriYear} H 🌙',
        title: _formatTanggal(ramadan.start),
        titleSuffix: ramadan.statusLabel.isNotEmpty
            ? ' (${ramadan.statusLabel})'
            : null,
        lines: [
          'Mulai Maghrib ${_formatTanggalSingkat(eve)} · '
              '${calc.formatInZone(startsAt.toUtc(), tz)} ${calc.tzLabel[tz]}',
        ],
        showMethod: true,
        number: days,
        digits: days > 99 ? 3 : 2,
        unit: 'HARI LAGI',
        footer: Row(
          children: [
            _ClockPill(label: 'jam', value: hours),
            const SizedBox(width: 8),
            _ClockPill(label: 'menit', value: minutes),
            const SizedBox(width: 8),
            _ClockPill(label: 'detik', value: seconds),
          ],
        ),
      ),
    );
  }
}

/// Tata letak ringkas kartu: keterangan di kiri, angka bergulir di kanan,
/// [footer] opsional selebar kartu di bawahnya.
class _Compact extends StatelessWidget {
  const _Compact({
    required this.kicker,
    required this.title,
    required this.lines,
    required this.number,
    required this.unit,
    this.titleSuffix,
    this.digits = 2,
    this.showMethod = false,
    this.footer,
  });

  final String kicker, title, unit;
  final String? titleSuffix;
  final List<String> lines;
  final int number, digits;
  final bool showMethod;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: title),
                        if (titleSuffix != null)
                          TextSpan(
                            text: titleSuffix,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF78716C),
                            ),
                          ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF292524),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (final l in lines)
                    Text(
                      l,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF78716C),
                        height: 1.35,
                      ),
                    ),
                  if (showMethod) const _MethodLink(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _RollingNumber(
                  value: number,
                  digits: digits,
                  style: _bigDigitStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    color: Color(0xCCB45309),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ],
    );
  }
}

/// Suasana Idulfitri: sejak Maghrib hari terakhir Ramadan (malam takbiran)
/// sampai Maghrib [eidDays] Syawal, sebelum hitung mundur beralih ke
/// Ramadan berikutnya ([next]).
class _EidCard extends StatelessWidget {
  const _EidCard({
    required this.status,
    required this.takbiran,
    required this.next,
  });
  final RamadanStatus status;
  final bool takbiran;
  final RamadanDate next;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: _Compact(
        kicker: 'IDULFITRI ${status.ramadan.hijriYear} H 🌙',
        title: takbiran ? 'Malam takbiran' : 'Selamat Hari Raya Idulfitri',
        lines: [
          takbiran
              ? 'Allahu akbar, Allahu akbar, walillahilhamd.'
              : 'Taqabbalallahu minna wa minkum.',
          'Ramadan berikutnya insyaa Allah ${_formatTanggal(next.start)}'
              '${next.statusLabel.isNotEmpty ? ' (${next.statusLabel})' : ''}',
        ],
        number: status.day,
        digits: 1,
        unit: 'SYAWAL',
      ),
    );
  }
}

/// "Ikuti: Pemerintah · ubah" - membuka pengaturan metode & penyesuaian
/// tanggal.
class _MethodLink extends StatelessWidget {
  const _MethodLink();

  @override
  Widget build(BuildContext context) {
    final config = HijriConfigScope.of(context).config;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showHijriSettingsSheet(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 11, color: Color(0xFF78716C)),
            children: [
              TextSpan(
                text:
                    'Ikuti: ${config.currentMethod?.label ?? 'Pemerintah'} · ',
              ),
              const TextSpan(
                text: 'ubah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu bagian jam:menit:detik hitung mundur - pil tipis.
class _ClockPill extends StatelessWidget {
  const _ClockPill({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RollingNumber(value: value, style: _smallDigitStyle),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF78716C)),
            ),
          ],
        ),
      ),
    );
  }
}

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _formatTanggal(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';
String _formatTanggalSingkat(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';

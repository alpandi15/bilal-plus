import 'package:flutter/material.dart';

import '../services/adzan_messages.dart';
import '../services/adzan_notifications.dart';
import '../services/app_settings.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/sholat_time.dart';
import '../services/system_channel.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/arabic_font.dart';

const _gold = Color(0xFFF2D38A);

const _names = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

/// Adzan layar penuh (seperti alarm): muncul di atas layar kunci saat waktu
/// sholat masuk bila "Adzan layar penuh" aktif. [payload] =
/// "alarm|YYYY-MM-DD|kunci" dari notifikasinya.
class AdzanAlarmPage extends StatefulWidget {
  const AdzanAlarmPage({super.key, required this.payload});
  final String payload;

  @override
  State<AdzanAlarmPage> createState() => _AdzanAlarmPageState();
}

class _AdzanAlarmPageState extends State<AdzanAlarmPage> {
  bool _busy = false;

  late final List<String> _parts = widget.payload
      .replaceFirst(adzanAlarmPrefix, '')
      .split('|');
  String get _date => _parts.isNotEmpty ? _parts[0] : '';
  String get _key => _parts.length > 1 ? _parts[1] : 'dzuhur';

  @override
  void dispose() {
    // aplikasi tidak lagi tampil di atas layar kunci
    SystemChannel.clearLockScreen();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _done() async {
    setState(() => _busy = true);
    await logSholatFromAlarm(widget.payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sholat ${_names[_key]} tercatat. Barakallahu fik!'),
      ),
    );
    _close();
  }

  Future<void> _snooze(AdzanMessage m) async {
    await AdzanNotifications.instance.snooze(
      widget.payload,
      title: 'Pengingat: ${m.title}',
      body: m.body,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diingatkan lagi 5 menit lagi.')),
    );
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final loc = UserLocationScope.of(context).location;
    final gender = AppSettingsScope.maybeOf(context)?.gender;
    final date = _date.isEmpty
        ? calc.todayInZone(calc.timezoneFromLongitude(loc.long))
        : parseDateKey(_date);
    final schedule = calc.calculatePrayerTimes(
      latitude: loc.lat,
      longitude: loc.long,
      date: date,
    );
    final prayer = sholatPrayerKey[_key];
    final time = prayer == null ? '' : schedule.labels[prayer]!;
    final zone = calc.tzLabel[schedule.timezone];
    final m = adzanMessage(
      key: _key,
      date: date,
      time: '$time $zone',
      place: loc.name,
      gender: gender,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2A44), Color(0xFF00503C), Color(0xFF0C3A33)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        loc.name,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: _close,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.mosque_rounded, color: _gold, size: 64),
                const SizedBox(height: 16),
                const ArabicText(
                  'حَيَّ عَلَى الصَّلَاةِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 34, height: 1.8, color: _gold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waktu ${_names[_key]}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$time $zone',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  m.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: const Color(0xFF0C3A33),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _busy ? null : _done,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Sudah sholat'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _busy ? null : () => _snooze(m),
                        icon: const Icon(Icons.snooze_rounded),
                        label: const Text('Tunda 5 menit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _close,
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/adzan_notifications.dart';
import '../services/app_settings.dart';
import '../services/hijri_config_scope.dart';
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../widgets/hijri_settings_sheet.dart';
import '../widgets/ibadah/ibadah_manage_sheet.dart';
import '../widgets/ibadah/jamaah_info.dart';
import '../widgets/privacy_note.dart';
import '../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

/// Pilihan batas awal waktu (menit sesudah adzan).
const _onTimeChoices = [10, 15, 20, 30];

/// Pilihan pengingat sebelum adzan (0 = mati).
const _reminderChoices = [0, 10, 15, 20, 30];

const _prayerNames = {
  'subuh': 'Subuh',
  'dzuhur': 'Dzuhur',
  'ashar': 'Ashar',
  'maghrib': 'Maghrib',
  'isya': 'Isya',
};

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final hijri = HijriConfigScope.of(context).config;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          const SubHeader(title: 'Pengaturan'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                const _Title('TENTANG SAYA'),
                _Group(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _NameField(),
                          const SizedBox(height: 14),
                          const Text(
                            'Jenis kelamin',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _stone,
                            ),
                          ),
                          const Text(
                            'Untuk narasi ajakan: laki-laki diajak sholat '
                            'berjamaah di masjid, termasuk Sholat Jumat.',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<Gender>(
                            segments: const [
                              ButtonSegment(
                                value: Gender.male,
                                label: Text('Laki-laki'),
                              ),
                              ButtonSegment(
                                value: Gender.female,
                                label: Text('Perempuan'),
                              ),
                            ],
                            emptySelectionAllowed: true,
                            showSelectedIcon: false,
                            selected: {?settings.gender},
                            onSelectionChanged: (v) {
                              if (v.isNotEmpty) settings.setGender(v.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Title('NOTIFIKASI ADZAN'),
                const _AdzanGroup(),
                const SizedBox(height: 20),
                const _Title('PENGINGAT PUASA'),
                const _FastReminderGroup(),
                const SizedBox(height: 20),
                const _Title('SHOLAT WAJIB'),
                _Group(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Nilai sholat sendiri',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _stone,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: "Berjama'ah atau sendiri?",
                                visualDensity: VisualDensity.compact,
                                onPressed: () => showJamaahInfo(
                                  context,
                                  soloWeight: settings.effectiveSoloWeight,
                                  female: settings.gender == Gender.female,
                                ),
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 18,
                                  color: _amber,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            settings.gender == Gender.female
                                ? "Untuk perempuan, sholat sendiri tetap "
                                      "bernilai penuh (sholat di rumah lebih "
                                      "utama). Pilihan jama'ah tetap dicatat."
                                : "Dibanding berjama'ah (100%) di persentase "
                                      "harian & laporan. Bawaan 1/27: sholat "
                                      "berjama'ah lebih utama 27 derajat "
                                      "(HR. Al-Bukhari & Muslim).",
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                          if (settings.gender != Gender.female) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final w in soloWeightChoices)
                                  ChoiceChip(
                                    label: Text(soloWeightLabel(w)),
                                    selected:
                                        (settings.soloWeight - w).abs() <
                                        0.0001,
                                    selectedColor: const Color(0xFFFDE68A),
                                    onSelected: (_) =>
                                        settings.setSoloWeight(w),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _line),
                    SwitchListTile.adaptive(
                      activeTrackColor: _amber,
                      value: settings.sholatTime,
                      onChanged: settings.setSholatTime,
                      title: const Text(
                        'Catat jam & tempat sholat',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      subtitle: const Text(
                        'Saat mencentang sholat wajib, pilih jam & tempat '
                        '(masjid/rumah). Laporan menunjukkan awal waktu, '
                        'terlambat, atau qadha.',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ),
                    if (settings.sholatTime) ...[
                      const Divider(height: 1, color: _line),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Batas awal waktu',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _stone,
                              ),
                            ),
                            const Text(
                              'Lewat dari ini sesudah adzan dihitung terlambat.',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final m in _onTimeChoices)
                                  ChoiceChip(
                                    label: Text('$m menit'),
                                    selected: settings.onTimeMinutes == m,
                                    selectedColor: const Color(0xFFFDE68A),
                                    onSelected: (_) =>
                                        settings.setOnTimeMinutes(m),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const _Title('DZIKIR & TASBIH'),
                _Group(
                  children: [
                    SwitchListTile.adaptive(
                      activeTrackColor: _amber,
                      value: settings.haptic,
                      onChanged: settings.setHaptic,
                      title: const Text(
                        'Getar saat menghitung',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      subtitle: const Text(
                        'Getar ringan tiap ketukan di tasbih & dzikir, getar '
                        'panjang saat target tercapai.',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Title('KALENDER & IBADAH'),
                _Group(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.event_repeat_rounded,
                        color: _amber,
                      ),
                      title: const Text(
                        'Metode & penyesuaian tanggal hijriah',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      subtitle: Text(
                        'Mengikuti ${hijri.currentMethod?.label ?? 'Pemerintah'}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showHijriSettingsSheet(context),
                    ),
                    const Divider(height: 1, color: _line),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: _amber),
                      title: const Text(
                        'Daftar ibadah harian',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _stone,
                        ),
                      ),
                      subtitle: const Text(
                        'Urutkan, sembunyikan, tambah ibadah sendiri',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showIbadahManageSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Title('PRIVASI & DATA'),
                const PrivacyNote(),
              ],
            ),
          ),
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
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Color(0xCCB45309),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: Column(children: children),
    ),
  );
}

class _AdzanGroup extends StatelessWidget {
  const _AdzanGroup();

  Future<void> _toggle(
    BuildContext context,
    AppSettingsController settings,
    bool on,
  ) async {
    if (on) {
      final granted = await AdzanNotifications.instance.requestPermissions();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi ditolak - aktifkan di pengaturan ponsel.',
              ),
            ),
          );
        }
        return;
      }
    }
    await settings.setAdzan(on);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final place = UserLocationScope.of(context).location.name;
    final male = settings.gender == Gender.male;
    return _Group(
      children: [
        SwitchListTile.adaptive(
          activeTrackColor: _amber,
          value: settings.adzan,
          onChanged: (v) => _toggle(context, settings, v),
          title: const Text(
            'Notifikasi saat adzan',
            style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
          ),
          subtitle: Text(
            male
                ? 'Pemberitahuan tiap waktu sholat masuk, dengan ajakan sholat '
                      'berjamaah di masjid. Tombol "Sudah sholat" langsung '
                      'mencatat.'
                : 'Pemberitahuan tiap waktu sholat masuk, dengan ajakan sholat '
                      'di awal waktu. Tombol "Sudah sholat" langsung mencatat.',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        if (settings.adzan) ...[
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waktu sholat',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final k in adzanPrayerKeys)
                      FilterChip(
                        label: Text(_prayerNames[k]!),
                        selected: settings.adzanPrayers.contains(k),
                        selectedColor: const Color(0xFFFDE68A),
                        onSelected: (_) => settings.toggleAdzanPrayer(k),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  male
                      ? 'Pengingat berangkat ke masjid'
                      : 'Pengingat sebelum adzan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _stone,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in _reminderChoices)
                      ChoiceChip(
                        label: Text(m == 0 ? 'Mati' : '$m mnt sebelum'),
                        selected: settings.reminderMinutes == m,
                        selectedColor: const Color(0xFFFDE68A),
                        onSelected: (_) => settings.setReminderMinutes(m),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: _amber),
                  onPressed: () => AdzanNotifications.instance.showTest(
                    settings: settings,
                    placeName: place,
                  ),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Coba notifikasi'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Notifikasi malam sebelum Hari Tarwiyah & Arafah.
class _FastReminderGroup extends StatelessWidget {
  const _FastReminderGroup();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return _Group(
      children: [
        SwitchListTile.adaptive(
          activeTrackColor: _amber,
          value: settings.fastReminder,
          onChanged: (on) async {
            if (on) await AdzanNotifications.instance.requestPermissions();
            await settings.setFastReminder(on);
          },
          title: const Text(
            'Puasa Tarwiyah & Arafah',
            style: TextStyle(fontWeight: FontWeight.w700, color: _stone),
          ),
          subtitle: const Text(
            'Notifikasi pukul 20.00 malam sebelumnya: ajakan niat puasa & '
            'siapkan sahur. Tanggalnya mengikuti kalender hijriah aplikasi.',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
        ),
      ],
    );
  }
}

/// Nama panggilan untuk sapaan di Beranda - tersimpan saat selesai diketik.
class _NameField extends StatefulWidget {
  const _NameField();

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _controller = TextEditingController(
    text: AppSettingsScope.read(context)?.userName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => AppSettingsScope.read(context)?.setUserName(_controller.text);

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.done,
    maxLength: 30,
    onSubmitted: (_) => _save(),
    onTapOutside: (_) {
      FocusScope.of(context).unfocus();
      _save();
    },
    decoration: const InputDecoration(
      labelText: 'Nama panggilan',
      hintText: 'Untuk sapaan di Beranda',
      counterText: '',
      isDense: true,
      prefixIcon: Icon(Icons.badge_outlined),
    ),
  );
}

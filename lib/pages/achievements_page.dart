import 'package:flutter/material.dart';

import '../db/app_database_scope.dart';
import '../services/app_settings.dart';
import '../services/badges.dart';
import '../services/prayer_calculator.dart' as calc;
import '../services/report_export.dart';
import '../services/sholat_time.dart';
import '../services/user_location_scope.dart';
import '../utils/date_key.dart';
import '../widgets/sub_header.dart';

const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);

class _Loaded {
  const _Loaded(this.data, this.statuses);
  final BadgeData data;
  final List<BadgeStatus> statuses;
}

/// Pencapaian: lencana yang dihitung dari catatanmu sendiri. Hanya penanda
/// syukur - tidak ada papan peringkat, dan berbagi sepenuhnya pilihan.
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  Future<_Loaded>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_Loaded> _load() async {
    final db = AppDatabaseScope.of(context);
    final location = UserLocationScope.of(context).location;
    final settings = AppSettingsScope.maybeOf(context);
    final today = dateKey(
      calc.todayInZone(calc.timezoneFromLongitude(location.long)),
    );
    final data = await loadBadgeData(
      db,
      today: today,
      latitude: location.lat,
      longitude: location.long,
      onTimeMinutes: settings?.onTimeMinutes ?? defaultOnTimeMinutes,
      male: settings?.gender == Gender.male,
    );
    final statuses = evaluateBadges(data, stored: await BadgeStore.earned());
    final fresh = await BadgeStore.record(statuses);
    if (fresh.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final first = statuses.firstWhere((s) => s.def.id == fresh.first);
        await _celebrate(first, more: fresh.length - 1);
        await BadgeStore.markSeen(fresh);
      });
    }
    return _Loaded(data, statuses);
  }

  Future<void> _celebrate(BadgeStatus s, {int more = 0}) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFFFFAF3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: _BadgeMedal(def: s.def, earned: true, size: 96),
          ),
          const SizedBox(height: 14),
          const Text(
            'Alhamdulillah!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lencana "${s.def.name}" diraih.'
            '${more > 0 ? ' (+$more lencana lain)' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _stone),
          ),
          const SizedBox(height: 8),
          const Text(
            'Niatkan karena Allah - lencana hanyalah penanda syukur. '
            'Tetaplah istiqamah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );

  void _detail(BadgeStatus s, BadgeData data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFAF3),
      builder: (_) => _DetailSheet(status: s, data: data),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAF3),
    body: Column(
      children: [
        FutureBuilder<_Loaded>(
          future: _future,
          builder: (context, snap) {
            final n = snap.data?.statuses.where((s) => s.earned).length;
            final total = snap.data?.statuses.length;
            return SubHeader(
              title: 'Pencapaian',
              subtitle: n == null ? null : '$n dari $total lencana',
            );
          },
        ),
        Expanded(
          child: FutureBuilder<_Loaded>(
            future: _future,
            builder: (context, snap) {
              final loaded = snap.data;
              if (loaded == null) {
                return snap.hasError
                    ? Center(child: Text('Gagal memuat: ${snap.error}'))
                    : const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1D6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Lencana dihitung dari catatanmu di perangkat '
                              'ini dan hanya untukmu. Tidak ada peringkat '
                              'atau perbandingan - niatkan beramal karena '
                              'Allah, bukan untuk dilihat.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _stone,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.82,
                            padding: EdgeInsets.zero,
                            children: [
                              for (final s in loaded.statuses)
                                _BadgeCard(
                                  status: s,
                                  hint: badgeHint(s, loaded.data),
                                  onTap: () => _detail(s, loaded.data),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Medali bulat: berwarna bila diraih, abu-abu bila belum.
class _BadgeMedal extends StatelessWidget {
  const _BadgeMedal({required this.def, required this.earned, this.size = 64});
  final BadgeDef def;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: earned
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(def.color, Colors.white, 0.25)!, def.color],
            )
          : null,
      color: earned ? null : const Color(0xFFE7E5E4),
      boxShadow: earned
          ? [
              BoxShadow(
                color: def.color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: Icon(
      earned ? def.icon : Icons.lock_outline_rounded,
      size: size * 0.46,
      color: earned ? Colors.white : const Color(0xFFA8A29E),
    ),
  );
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.status,
    required this.hint,
    required this.onTap,
  });
  final BadgeStatus status;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: s.earned ? s.def.color.withValues(alpha: 0.4) : _line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BadgeMedal(def: s.def, earned: s.earned),
              const SizedBox(height: 10),
              Text(
                s.def.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: s.earned ? _stone : _muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint ?? s.progressText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  height: 1.3,
                ),
              ),
              if (!s.earned) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: s.fraction,
                    minHeight: 5,
                    backgroundColor: _line,
                    valueColor: AlwaysStoppedAnimation(s.def.color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.status, required this.data});
  final BadgeStatus status;
  final BadgeData data;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final image = await captureReport(_boundary);
      if (!mounted) return;
      await shareReport(
        context,
        bytes: image.png,
        fileName: 'lencana-${widget.status.def.id.name}.png',
        mimeType: 'image/png',
        subject: 'Lencana ${widget.status.def.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final hint = badgeHint(s, widget.data);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _boundary,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00503C), Color(0xFF0C3A33)],
                  ),
                ),
                child: Column(
                  children: [
                    _BadgeMedal(def: s.def, earned: s.earned, size: 88),
                    const SizedBox(height: 12),
                    Text(
                      s.def.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.def.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hint ?? s.progressText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF2D38A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bilal+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (s.earned) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: _line),
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Bagikan sebagai gambar (opsional)'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Berbagi itu pilihan, tidak perlu. Niatkan karena Allah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: _muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

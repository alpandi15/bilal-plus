import 'dart:math';

import 'package:flutter/material.dart';

import '../../db/app_database_scope.dart';
import '../../services/app_settings.dart';
import '../../services/murajaah_quiz.dart';
import '../../services/quran_text.dart';
import '../../widgets/arabic_font.dart';
import '../../widgets/quran/quran_ayah_text.dart';
import '../../widgets/sub_header.dart';

const _amber = Color(0xFFB45309);
const _stone = Color(0xFF44403C);
const _muted = Color(0xFF78716C);
const _line = Color(0xFFF1E4CF);
const _emerald = Color(0xFF047857);
const _red = Color(0xFFB91C1C);

/// Kuis sambung ayat dari ayat yang sudah kamu hafal: awal ayat tampil,
/// pilih lanjutannya.
class MurajaahQuizPage extends StatefulWidget {
  const MurajaahQuizPage({super.key});

  @override
  State<MurajaahQuizPage> createState() => _MurajaahQuizPageState();
}

class _MurajaahQuizPageState extends State<MurajaahQuizPage> {
  List<QuizQuestion>? _questions;
  int _at = 0;
  int _score = 0;
  int? _picked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questions == null && !_loading) _load();
  }

  bool _loading = false;

  Future<void> _load() async {
    _loading = true;
    final dao = AppDatabaseScope.of(context).quranDao;
    final font = AppSettingsScope.maybeOf(context)?.quranFont ?? QuranFont.lpmq;
    final memorized = await dao.watchHafalan().first;
    final text = await QuranText.load();
    if (!mounted) return;
    setState(() {
      _questions = buildQuiz(text, memorized, Random(), font: font);
      _at = 0;
      _score = 0;
      _picked = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      body: Column(
        children: [
          SubHeader(
            title: 'Kuis sambung ayat',
            subtitle: qs == null || qs.isEmpty || _at >= qs.length
                ? "Dari hafalanmu"
                : 'Soal ${_at + 1} dari ${qs.length}',
          ),
          Expanded(
            child: qs == null
                ? const Center(child: CircularProgressIndicator())
                : qs.isEmpty
                ? const _NoQuestions()
                : _at >= qs.length
                ? _result(qs.length)
                : _question(context, qs[_at], qs.length),
          ),
        ],
      ),
    );
  }

  Widget _result(int total) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _score == total
                ? Icons.emoji_events_rounded
                : Icons.task_alt_rounded,
            size: 56,
            color: _emerald,
          ),
          const SizedBox(height: 12),
          Text(
            '$_score dari $total benar',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _stone,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _emerald),
            onPressed: _load,
            child: const Text('Main lagi'),
          ),
        ],
      ),
    ),
  );

  Widget _question(BuildContext context, QuizQuestion q, int total) {
    final font = AppSettingsScope.maybeOf(context)?.quranFont ?? QuranFont.lpmq;
    final size = AppSettingsScope.maybeOf(context)?.readerSize ?? 28;
    final style = TextStyle(
      fontSize: size - 4,
      height: 1.9,
      color: const Color(0xFF1C1917),
    );
    final answered = _picked != null;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: _at / total,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: _line,
                  valueColor: const AlwaysStoppedAnimation(_emerald),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lanjutkan ayat berikut:',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line),
                  ),
                  child: QuranAyahText(
                    answered ? q.full : '${q.prompt} ...',
                    font: font,
                    style: style.copyWith(fontSize: size),
                  ),
                ),
                for (final (i, o) in q.options.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: !answered
                          ? Colors.white
                          : i == q.correct
                          ? const Color(0xFFD1FAE5)
                          : i == _picked
                          ? const Color(0xFFFEE2E2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: answered
                            ? null
                            : () => setState(() {
                                _picked = i;
                                if (i == q.correct) _score++;
                              }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !answered
                                  ? _line
                                  : i == q.correct
                                  ? _emerald
                                  : i == _picked
                                  ? _red
                                  : _line,
                            ),
                          ),
                          child: QuranAyahText(o, font: font, style: style),
                        ),
                      ),
                    ),
                  ),
                if (answered) ...[
                  const SizedBox(height: 6),
                  Text(
                    _picked == q.correct
                        ? 'Benar, masyaa Allah!'
                        : 'Belum tepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _picked == q.correct ? _emerald : _red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _amber),
                    onPressed: () => setState(() {
                      _at++;
                      _picked = null;
                    }),
                    child: Text(_at + 1 >= total ? 'Lihat hasil' : 'Lanjut'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoQuestions extends StatelessWidget {
  const _NoQuestions();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text(
        'Belum ada ayat hafalan yang cukup panjang untuk dijadikan soal. '
        'Tandai ayat yang sudah dihafal di menu Hafalan, lalu coba lagi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, height: 1.5),
      ),
    ),
  );
}

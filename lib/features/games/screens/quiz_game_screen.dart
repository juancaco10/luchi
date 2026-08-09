import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../education/providers/chapters_provider.dart';
import '../data/game_catalog.dart';
import '../data/quiz_question_bank.dart';
import '../logic/game_audio.dart';
import '../models/game_id.dart';
import '../models/level_config.dart';
import '../providers/games_progress_provider.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/level_outcome_overlay.dart';

/// "Exploración Nocturna" — juego 1, el quiz. Ruta `/game/explorar/play/:level`.
///
/// El motor de preguntas del prototipo (temporizador, racha, feedback de
/// Luchi) funcionaba bien y se conserva casi intacto; lo que cambia es de
/// dónde saca las preguntas (por tema, según `QuizLevel`) y cómo termina:
/// antes eran siempre las mismas 10 preguntas sueltas de un banco de 15 sin
/// tema ni estructura, ahora cada uno de los 10 niveles enseña un tema
/// (o combinación) y las estrellas dependen del acierto, no de una nota
/// arbitraria de "500 puntos".
class QuizGameScreen extends ConsumerStatefulWidget {
  const QuizGameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen> {
  late QuizLevel _config;
  late List<ShuffledQuizQuestion> _questions;
  int _currentIndex = 0;
  int _correct = 0;
  int _streak = 0;
  int _timeLeft = 0;
  Timer? _timer;
  int? _selectedIndex;
  bool _isAnswered = false;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _config = GameCatalog.level(GameId.explorar, widget.level) as QuizLevel;
    _startRound();
  }

  void _startRound() {
    final pool = QuizQuestionBank.forTopics(_config.topics)..shuffle();
    final picked = pool.length >= _config.questionCount
        ? pool.take(_config.questionCount).toList()
        : List.generate(
            _config.questionCount,
            (i) => pool[i % pool.length],
          );
    _questions = picked.map(ShuffledQuizQuestion.from).toList();
    _currentIndex = 0;
    _correct = 0;
    _streak = 0;
    _selectedIndex = null;
    _isAnswered = false;
    _result = null;
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timeLeft = _config.secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _streak = 0;
    });
  }

  void _answer(int index) {
    if (_isAnswered) return;
    _timer?.cancel();
    final q = _questions[_currentIndex];
    final correct = index == q.correctIndex;
    GameAudio.instance.sfx(correct ? GameSfx.star : GameSfx.fail);
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (correct) {
        _correct++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isAnswered = false;
      });
      _resetTimer();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final ratio = _correct / _questions.length;
    final won = ratio >= 0.6;
    final stars = !won ? 0 : (ratio >= 1.0 ? 3 : (ratio >= 0.8 ? 2 : 1));

    // El primer nivel del quiz sigue siendo la puerta del capítulo 1: si se
    // aprueba, se marca completado igual que antes. Es la única atadura al
    // sistema de capítulos y solo aplica a este juego.
    if (won && widget.level == 1) {
      ref.read(chaptersProvider.notifier).markCompleted(1);
    }

    setState(() {
      _result = GameResult(
        won: won,
        stars: stars,
        detail: '$_correct de ${_questions.length} respuestas correctas.',
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return GameScaffold(
        confirmExit: false,
        child: LevelOutcomeOverlay(
          gameId: GameId.explorar,
          level: widget.level,
          result: _result!,
          onRetry: () => setState(_startRound),
        ),
      );
    }

    final q = _questions[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: context.colors.onSurface),
            onPressed: _confirmExit,
          ),
          title: Text(
            'Nivel ${widget.level} · Exploración Nocturna',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregunta ${_currentIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: context.text.bodyMedium?.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_streak > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          '🔥 Racha x$_streak',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      '$_correct ✓',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _timeLeft / _config.secondsPerQuestion,
                    minHeight: 8,
                    backgroundColor: context.firefly.cardSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeLeft < _config.secondsPerQuestion * 0.3
                          ? context.colors.error
                          : context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: context.firefly.cardGradient,
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        q.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                ),
                const SizedBox(height: 20),
                Column(
                  children: q.options.asMap().entries.map((e) {
                    final idx = e.key;
                    final optText = e.value;

                    Color btnBg = context.firefly.cardSurface;
                    Color borderCol = context.firefly.cardBorder;
                    Color? textCol = context.text.bodyMedium?.color;

                    if (_isAnswered) {
                      if (idx == q.correctIndex) {
                        btnBg = context.firefly.success.withValues(alpha: 0.2);
                        borderCol = context.firefly.success;
                        textCol = context.firefly.success;
                      } else if (idx == _selectedIndex) {
                        btnBg = context.colors.error.withValues(alpha: 0.2);
                        borderCol = context.colors.error;
                        textCol = context.colors.error;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _answer(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: btnBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: borderCol.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + idx),
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    color: borderCol,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                optText,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textCol,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_isAnswered) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪲', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.explanation,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _next,
                    child: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Siguiente pregunta ➔'
                          : 'Ver resultado',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final wasActive = _timer?.isActive ?? false;
    _timer?.cancel();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.colors.primary, width: 2),
        ),
        title: Text(
          '¿Salir del juego?',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: ctx.colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Perderás tu progreso actual en esta partida.',
          style: TextStyle(fontFamily: 'Nunito', color: ctx.colors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: ctx.text.bodySmall?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      context.go('/game');
    } else if (wasActive && !_isAnswered) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_timeLeft > 1) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          _onTimeOut();
        }
      });
    }
  }
}

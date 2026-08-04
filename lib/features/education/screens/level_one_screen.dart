import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chapters_provider.dart';

// ── Model ──────────────────────────────────────────────────────────

class QuestionItem {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final int timerSeconds;

  const QuestionItem({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.timerSeconds = 30,
  });
}

class ShuffledQuestion {
  final String text;
  final List<String> shuffledOptions;
  final int correctShuffledIndex;
  final String explanation;
  final int timerSeconds;

  ShuffledQuestion({
    required this.text,
    required this.shuffledOptions,
    required this.correctShuffledIndex,
    required this.explanation,
    required this.timerSeconds,
  });

  factory ShuffledQuestion.fromQuestion(QuestionItem item) {
    final originalCorrectText = item.options[item.correctAnswerIndex];
    final listCopy = List<String>.from(item.options)..shuffle();
    final newCorrectIndex = listCopy.indexOf(originalCorrectText);

    return ShuffledQuestion(
      text: item.text,
      shuffledOptions: listCopy,
      correctShuffledIndex: newCorrectIndex,
      explanation: item.explanation,
      timerSeconds: item.timerSeconds,
    );
  }
}

// ── Bank of 15 Validated Questions ──────────────────────────────────

final List<QuestionItem> _questionBank = [
  const QuestionItem(
    text: 'Las luciérnagas son insectos que pertenecen al mismo grupo que las mariquitas.',
    options: ['Verdadero', 'Falso'],
    correctAnswerIndex: 0,
    explanation: '🪲 ¡Así es! Ambas son coleópteros (escarabajos).',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Por qué brillan las luciérnagas?',
    options: [
      'Para calentarse en el frío',
      'Para comunicarse y encontrar pareja',
      'Porque comen plantas brillantes',
      'Para asustar a los carros'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Usan destellos de bioluminiscencia como un código de señas amoroso.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Qué problema grave afecta a las luciérnagas en la ciudad?',
    options: [
      'El ruido de los carros',
      'La contaminación lumínica (luces artificiales)',
      'La falta de televisión',
      'El exceso de agua limpia'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 La luz artificial ciega y desorienta su propia luz de noche.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: 'La luz de la luciérnaga es una "luz fría" que casi no produce calor.',
    options: ['Verdadero', 'Falso'],
    correctAnswerIndex: 0,
    explanation: '🪲 ¡El 90% de su energía se convierte en luz y casi nada en calor!',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Cómo se llama la reacción química natural con la que producen su luz?',
    options: [
      'Bioluminiscencia',
      'Fotosíntesis',
      'Electricidad pura',
      'Combustión'
    ],
    correctAnswerIndex: 0,
    explanation: '🪲 ¡Bioluminiscencia! Mezclan luciferina y oxígeno en su cuerpo.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Dónde viven las larvas de luciérnaga antes de aprender a volar?',
    options: [
      'En las nubes',
      'En la tierra húmeda y bajo hojas secas',
      'En el agua de mar',
      'En los techos de las casas'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Viven en la tierra húmeda, por eso cuidar el suelo es tan importante.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: 'Las luces de los patios y postes de luz confunden a las luciérnagas de noche.',
    options: ['Verdadero', 'Falso'],
    correctAnswerIndex: 0,
    explanation: '🪲 Les dificulta encontrar pareja porque no ven sus destellos.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿De qué se alimentan las larvas de luciérnaga en la naturaleza?',
    options: [
      'De fruta fresca',
      'De caracoles y babosas pequeñas',
      'De azúcar',
      'De hojas de plástico'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 ¡Son pequeñas cazadoras que ayudan a controlar caracoles en el jardín!',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Qué porcentaje de especies de luciérnagas está en riesgo de desaparecer?',
    options: [
      'Alrededor del 5%',
      'Alrededor del 20% (1 de cada 5)',
      'El 100%',
      'Casi 0%'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 1 de cada 5 especies necesita nuestra ayuda urgente.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Cuál es la mejor acción que puedes hacer en casa esta noche?',
    options: [
      'Dejar todas las luces del patio encendidas',
      'Apagar luces exteriores innecesarias',
      'Encender fuegos artificiales',
      'Usar pesticidas en el pasto'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Apagar luces innecesarias devuelve la oscuridad natural a la noche.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: 'Los pesticidas y venenos del jardín son seguros para las luciérnagas.',
    options: ['Verdadero', 'Falso'],
    correctAnswerIndex: 1,
    explanation: '🪲 ¡Falso! Los venenos dañan las larvas que viven en la tierra.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿En qué momento del día están más activas las luciérnagas?',
    options: [
      'Al mediodía con mucho sol',
      'En la noche y al anochecer',
      'A las 6 de la mañana',
      'Solo cuando llueve'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Ellas aman la penumbra y la tranquilidad de la noche.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Qué tipo de lugar prefieren las luciérnagas para vivir felices?',
    options: [
      'Desiertos secos',
      'Lugares húmedos, bosques y jardines naturales',
      'Estaciones de tren',
      'Estacionamientos de cemento'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Necesitan humedad y vegetación tupida.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: 'Apagar la luz exterior ayuda a que las luciérnagas se encuentren más fácil.',
    options: ['Verdadero', 'Falso'],
    correctAnswerIndex: 0,
    explanation: '🪲 ¡Verdadero! Permite que sus destellos resalten en la oscuridad.',
    timerSeconds: 30,
  ),
  const QuestionItem(
    text: '¿Qué plantas ayudan a crear un hábitat ideal para las luciérnagas?',
    options: [
      'Flores de plástico',
      'Plantas nativas y vegetación natural',
      'Cactus de desierto',
      'Piedras pintadas'
    ],
    correctAnswerIndex: 1,
    explanation: '🪲 Las plantas nativas ofrecen sombra, humedad y refugio perfecto.',
    timerSeconds: 30,
  ),
];

// ── LevelOneScreen (Kahoot Game Widget) ───────────────────────────────

class LevelOneScreen extends ConsumerStatefulWidget {
  const LevelOneScreen({super.key});

  @override
  ConsumerState<LevelOneScreen> createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends ConsumerState<LevelOneScreen> {
  late List<ShuffledQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  int _timeLeft = 30;
  Timer? _timer;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    // Pick 10 random out of 15 and shuffle their options
    final bankCopy = List<QuestionItem>.from(_questionBank)..shuffle();
    final selectedTen = bankCopy.take(10).toList();
    _questions = selectedTen.map((q) => ShuffledQuestion.fromQuestion(q)).toList();

    setState(() {
      _currentIndex = 0;
      _score = 0;
      _lives = 3;
      _streak = 0;
      _selectedIndex = null;
      _isAnswered = false;
      _isGameOver = false;
    });

    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timeLeft = _questions[_currentIndex].timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    if (_isAnswered || _isGameOver) return;
    setState(() {
      _isAnswered = true;
      _lives--;
      _streak = 0;
    });

    if (_lives <= 0) {
      _finishGame();
    }
  }

  void _answerQuestion(int index) {
    if (_isAnswered || _isGameOver) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final isCorrect = index == q.correctShuffledIndex;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;

      if (isCorrect) {
        _streak++;
        // Kahoot scoring: Base 100 + Time Bonus (up to 50) + Streak Multiplier
        double timeBonus = (_timeLeft / q.timerSeconds) * 50;
        double streakMult = _streak >= 3 ? 1.5 : (_streak >= 2 ? 1.2 : 1.0);
        int earned = ((100 + timeBonus) * streakMult).round();
        _score += earned;
      } else {
        _streak = 0;
        _lives--;
      }
    });

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 1500), _finishGame);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1 && _lives > 0) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isAnswered = false;
      });
      _resetTimer();
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    setState(() => _isGameOver = true);

    // Reward player and update chapter progress if passed (>= 500 pts)
    if (_score >= 500) {
      ref.read(chaptersProvider.notifier).markCompleted(1);
      await ref.read(authProvider.notifier).addPoints(_score ~/ 10);
    }

    if (!mounted) return;
    _showResultDialog();
  }

  void _showResultDialog() {
    final passed = _score >= 500;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: ctx.colors.primary, width: 2),
        ),
        title: Column(
          children: [
            Text(passed ? '🎉 ¡Felicidades!' : '💪 ¡Casi lo logras!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: ctx.colors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                )),
            const SizedBox(height: 8),
            Text(passed ? '⭐ ⭐ ⭐' : '⭐',
                style: const TextStyle(fontSize: 28)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puntaje Final: $_score Puntos',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ctx.colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              passed
                  ? '¡Has demostrado ser un auténtico Guardián de las Luciérnagas!'
                  : 'Luchi confía en ti. ¡Inténtalo de nuevo para repasar!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: ctx.text.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: Text('Salir', style: TextStyle(color: ctx.text.bodySmall?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _startNewGame();
            },
            child: const Text('Jugar de nuevo',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                )),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox();
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.colors.onSurface),
          onPressed: () {
            _timer?.cancel();
            context.go('/home');
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎮 Juega con Luchi',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                )),
          ],
        ),
        actions: [
          // Lives Display (Hearts)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(3, (i) {
                return Icon(
                  i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: i < _lives ? context.colors.error : context.text.bodySmall?.color,
                  size: 20,
                );
              }),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Header Status Row (Progress, Streak, Score)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pregunta ${_currentIndex + 1}/10',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: context.text.bodyMedium?.color,
                        fontWeight: FontWeight.w700,
                      )),
                  if (_streak > 1)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text('🔥 Racha x$_streak',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          )),
                    ),
                  Text('$_score pts',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      )),
                ],
              ),

              const SizedBox(height: 12),

              // Countdown Timer Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _timeLeft / q.timerSeconds,
                  minHeight: 8,
                  backgroundColor: context.firefly.cardSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timeLeft < 10 ? context.colors.error : context.colors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Question Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: context.firefly.cardGradient,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
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

              // Option Buttons Grid / List
              Column(
                children: q.shuffledOptions.asMap().entries.map((e) {
                  final idx = e.key;
                  final optText = e.value;

                  Color btnBg = context.firefly.cardSurface;
                  Color borderCol = context.firefly.cardBorder;
                  Color? textCol = context.text.bodyMedium?.color;

                  if (_isAnswered) {
                    if (idx == q.correctShuffledIndex) {
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
                    onTap: () => _answerQuestion(idx),
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
                              color: borderCol.withOpacity(0.2),
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

              // Luchi Feedback Card & Next Button
              if (_isAnswered) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
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
                  onPressed: _nextQuestion,
                  child: const Text('Siguiente pregunta ➔',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      )),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

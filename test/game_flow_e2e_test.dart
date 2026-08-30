import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luchi/core/network/api_client.dart';
import 'package:luchi/core/storage/local_storage.dart';
import 'package:luchi/core/theme/firefly_colors.dart';
import 'package:luchi/core/utils/constants.dart';
import 'package:luchi/features/games/data/game_catalog.dart';
import 'package:luchi/features/games/data/quiz_question_bank.dart';
import 'package:luchi/features/games/models/game_id.dart';
import 'package:luchi/features/games/models/level_config.dart';
import 'package:luchi/features/games/providers/games_progress_provider.dart';
import 'package:luchi/features/games/screens/level_select_screen.dart';
import 'package:luchi/features/games/screens/map_hub_screen.dart';
import 'package:luchi/features/games/screens/quiz_game_screen.dart';

class _NullHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":"test"}',
      400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ThemeData get _testTheme => ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(),
      extensions: [FireflyColors.dark],
    );

/// Encuentra qué pregunta del banco se está mostrando y devuelve el texto de
/// la respuesta correcta, leyendo las opciones pintadas en pantalla.
String _correctAnswerFor(WidgetTester tester) {
  final bank = QuizQuestionBank.forTopics([QuizTopic.queSon]);
  for (final q in bank) {
    if (tester.any(find.text(q.text))) {
      return q.options[q.correctIndex];
    }
  }
  fail('No se encontró la pregunta actual en la pantalla');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('games_flow_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.chaptersBox);
    await Hive.openBox(AppConstants.sightingsBox);
    await Hive.openBox(AppConstants.gamesBox);
    await Hive.openBox(AppConstants.badgesBox);
    await LocalStorage.instance.initForTesting();
  });

  tearDown(() async {
    // Hive.close() espera a transacciones en vuelo; en el reloj falso de
    // testWidgets la escritura de recordResult nunca llega a completarse y
    // close() colgaría el runner. El proceso termina solo con el suite.
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets(
      'ganar el nivel 1 del quiz, salir al menú: estrellas guardadas y nivel 2 desbloqueado',
      (tester) async {
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _NullHttpAdapter(),
      ),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/game/explorar/play/1',
      routes: [
        GoRoute(
          path: '/game/explorar/play/:level',
          builder: (c, s) => QuizGameScreen(
            level: int.parse(s.pathParameters['level']!),
          ),
        ),
        GoRoute(
          path: '/game/explorar',
          builder: (c, s) => LevelSelectScreen(gameId: GameId.explorar),
        ),
        GoRoute(
          path: '/game',
          builder: (c, s) => const MapHubScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp.router(
          theme: _testTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    // ── Se juega el nivel 1 respondiendo todo bien ──────────────
    for (var i = 0; i < 5; i++) {
      final correct = _correctAnswerFor(tester);
      await tester.tap(find.text(correct));
      await tester.pump();

      if (i < 4) {
        await tester.tap(find.text('Siguiente pregunta ➔'));
        await tester.pump();
      }
    }
    await tester.tap(find.text('Ver resultado'));
    // El overlay monta LevelOutcomeOverlay → _credit() → recordResult(). En el
    // reloj falso de testWidgets la escritura real a Hive no llega a cerrarse
    // (la persistencia en disco se cubre en games_progress_test.dart, que
    // corre en zona async real); aquí solo se verifica el flujo en memoria.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    // Se ve el "ganaste" con estrellas y las dos salidas: el selector de
    // niveles de este juego y el menú de juegos.
    expect(find.text('¡Nivel superado!'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(find.text('Selector de niveles'), findsOneWidget);
    expect(find.text('Menú de juegos'), findsOneWidget);
    debugPrint(
        'ESTADO tras ganar: totalStars=${container.read(gamesProgressProvider).totalStars} '
        'starsN1=${container.read(gamesProgressProvider).of(GameId.explorar).starsFor(1)} '
        'highestUnlocked=${container.read(gamesProgressProvider).of(GameId.explorar).highestUnlocked} '
        'rewardVisible=${tester.any(find.textContaining('puntos'))}');

    // Que las animaciones de estrellas terminen (evita timers colgados).
    await tester.pump(const Duration(seconds: 2));

    // ── Salir y volver al menú de juegos ────────────────────────
    await tester.scrollUntilVisible(
      find.text('Menú de juegos'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Menú de juegos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    debugPrint('LOCATION tras tap: ${router.routerDelegate.currentConfiguration.uri}');
    debugPrint('TEXTS en pantalla: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList()}');

    // El hub debe mostrar la estrella ganada en la tarjeta del juego.
    final hubTexts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .toList();
    debugPrint('HUB TEXTS: $hubTexts');
    expect(find.text('3 / 30'), findsOneWidget);

    // ── Entrar al juego: el nivel 2 ya no está con candado ──────
    await tester.tap(find.text('3 / 30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    debugPrint(
        'LEVEL SELECT: locks=${find.byIcon(Icons.lock_rounded).evaluate().length}');
    // El nivel 2 ya no está con candado: se ven los nodos 1 y 2 (con número,
    // no con candado) y todos los demás cerrados.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    final totalLevels = GameCatalog.levels(GameId.explorar).length;
    expect(find.byIcon(Icons.lock_rounded).evaluate().length, totalLevels - 2);

    // La persistencia en disco (Hive) tras ganar se cubre en
    // games_progress_test.dart, que corre en zona async real: un contenedor
    // nuevo lee la caja y ve las estrellas guardadas.

    // Desmonta el árbol: libera timers/streams pendientes antes del teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Luchi/core/network/api_client.dart';
import 'package:Luchi/core/theme/firefly_colors.dart';
import 'package:Luchi/core/utils/constants.dart';
import 'package:Luchi/features/games/models/game_id.dart';
import 'package:Luchi/features/games/providers/games_progress_provider.dart';
import 'package:Luchi/features/games/screens/level_select_screen.dart';

/// Adaptador HTTP de mentira: toda llamada a la red responde 400 al instante,
/// sin tocar internet ni dejar timers colgando.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('games_ui_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.gamesBox);
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('el selector de niveles refleja estrellas y desbloqueo tras ganar',
      (tester) async {
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _NullHttpAdapter(),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          // Sin AppTheme de la app: google_fonts intenta descargar la
          // tipografía en tests y revienta. Los tokens de marca (`context.firefly`)
          // son lo único que el selector de niveles necesita del tema.
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(),
            extensions: [FireflyColors.dark],
          ),
          home: LevelSelectScreen(gameId: GameId.explorar),
        ),
      ),
    );
    await tester.pump();

    // Antes de jugar: el nivel 1 está abierto (muestra el número), el 2
    // cerrado (candado), y "0/30" de total.
    expect(find.text('0/30'), findsOneWidget);
    final locksBefore = find.byIcon(Icons.lock_rounded).evaluate().length;
    expect(locksBefore, greaterThan(0));

    // Se gana el nivel 1 con 2 estrellas, igual que hace LevelOutcomeOverlay.
    // runAsync: la persistencia de Hive es I/O real, y el reloj de
    // testWidgets no puede avanzarla.
    await tester.runAsync(() => container
        .read(gamesProgressProvider.notifier)
        .recordResult(GameId.explorar, 1, const GameResult(won: true, stars: 2)));
    await tester.pump();

    // Total actualizado y hay un candado menos (el del nivel 2 se abrió).
    expect(find.text('2/30'), findsOneWidget);
    expect(
      find.byIcon(Icons.lock_rounded).evaluate().length,
      locksBefore - 1,
    );
  });

  testWidgets('el selector no se desborda en pantalla pequeña con texto grande',
      (tester) async {
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _NullHttpAdapter(),
      ),
    ]);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(),
            extensions: [FireflyColors.dark],
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: LevelSelectScreen(gameId: GameId.explorar),
        ),
      ),
    );
    await tester.pump();

    // Si algo se recorta, RenderFlex lanza un FlutterError aquí mismo. La
    // cuadrícula además debe seguir mostrando nodos.
    expect(find.text('1'), findsOneWidget);
  });
}
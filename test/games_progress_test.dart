import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guardianes_luciernagas/core/utils/constants.dart';
import 'package:guardianes_luciernagas/features/games/models/game_id.dart';
import 'package:guardianes_luciernagas/features/games/providers/games_progress_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('games_box_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.gamesBox);
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('ganar un nivel guarda estrellas, desbloquea el siguiente y persiste',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(gamesProgressProvider);
    expect(before.of(GameId.explorar).starsFor(1), 0);
    expect(before.of(GameId.explorar).highestUnlocked, 1);

    final reward = await container
        .read(gamesProgressProvider.notifier)
        .recordResult(GameId.explorar, 1, const GameResult(won: true, stars: 2));

    expect(reward.newStars, 2);
    expect(reward.points, greaterThan(0));
    expect(reward.unlockedNextLevel, isTrue);

    final after = container.read(gamesProgressProvider);
    expect(after.of(GameId.explorar).starsFor(1), 2);
    expect(after.of(GameId.explorar).isUnlocked(2), isTrue);
    expect(after.of(GameId.explorar).highestUnlocked, 2);
    expect(after.totalStars, 2);

    // Un nivel ya superado no vuelve a pagar ni a subir la marca.
    final repeated = await container
        .read(gamesProgressProvider.notifier)
        .recordResult(GameId.explorar, 1, const GameResult(won: true, stars: 1));
    expect(repeated.newStars, 0);
    expect(repeated.points, 0);

    // "Reinicio de la app": un contenedor nuevo lee la caja Hive.
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final reloaded = container2.read(gamesProgressProvider);
    expect(reloaded.of(GameId.explorar).starsFor(1), 2);
    expect(reloaded.of(GameId.explorar).highestUnlocked, 2);
    expect(reloaded.totalStars, 2);
  });

  test('no ganar un nivel no cambia el progreso', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final reward = await container.read(gamesProgressProvider.notifier).recordResult(
          GameId.guiar,
          3,
          const GameResult.lost(),
        );

    expect(reward.newStars, 0);
    final state = container.read(gamesProgressProvider);
    expect(state.of(GameId.guiar).starsFor(3), 0);
    expect(state.of(GameId.guiar).highestUnlocked, 1);
  });
}

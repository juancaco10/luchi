import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/storage/local_storage.dart';

/// Sonido de los minijuegos.
///
/// Estado actual: **no hay archivos de audio en el repo todavía**. Este
/// servicio está terminado y es seguro llamarlo desde cualquier juego: si el
/// asset no existe, la llamada es un no-op silencioso y se recuerda para no
/// volver a intentarlo. Cuando se añadan los `.mp3` a `assets/audio/games/`
/// y se declaren en `pubspec.yaml`, el sonido aparece solo, sin tocar ni una
/// línea de los juegos.
///
/// Dos decisiones deliberadas frente al prototipo anterior:
/// - **Un solo `AudioPlayer` por canal** (efectos y música), reutilizado. El
///   código previo creaba un `AudioPlayer()` en cada efecto y no lo liberaba
///   nunca: una fuga por cada toque de pantalla.
/// - **Sin `flame_audio`**: su caché es global y estática, incompatible con
///   un interruptor de sonido que el usuario pueda apagar de verdad.
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  static const _prefsKey = 'games_sound_enabled';
  static const _basePath = 'audio/games/';

  // Creados de forma diferida: no hay assets de audio todavía, y un
  // `AudioPlayer` instancia canales de plataforma que no deben crearse hasta
  // que de verdad se vaya a reproducir (si no, rompe entornos sin plugin,
  // como los widget tests).
  late final AudioPlayer _sfx = AudioPlayer(playerId: 'games_sfx');
  late final AudioPlayer _music = AudioPlayer(playerId: 'games_bgm');

  /// Assets que ya se comprobaron: nombre → existe. Evita golpear el bundle
  /// en cada disparo de un efecto que sabemos que falta.
  final Map<String, bool> _available = {};

  bool? _enabledCache;

  bool get enabled =>
      _enabledCache ??=
          LocalStorage.instance.prefs.getBool(_prefsKey) ?? true;

  Future<void> setEnabled(bool value) async {
    _enabledCache = value;
    await LocalStorage.instance.prefs.setBool(_prefsKey, value);
    if (!value) await stopMusic();
  }

  Future<bool> _exists(String name) async {
    final cached = _available[name];
    if (cached != null) return cached;
    try {
      await rootBundle.load('assets/$_basePath$name');
      return _available[name] = true;
    } catch (_) {
      return _available[name] = false;
    }
  }

  /// Efecto corto. Nunca hace esperar al juego: si algo falla, se ignora.
  Future<void> sfx(GameSfx sound) async {
    if (!enabled) return;
    final name = sound.file;
    if (!await _exists(name)) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('$_basePath$name'), volume: 0.6);
    } catch (e) {
      debugPrint('GameAudio.sfx($name) falló: $e');
    }
  }

  /// Ambiente en bucle. Volumen bajo a propósito: acompaña, no compite.
  Future<void> music(String name) async {
    if (!enabled) return;
    if (!await _exists(name)) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('$_basePath$name'), volume: 0.25);
    } catch (e) {
      debugPrint('GameAudio.music($name) falló: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Se llama al salir de una pantalla de juego, no al cerrar la app: los
  /// dos reproductores viven lo que vive el proceso.
  Future<void> leaveGame() => stopMusic();
}

/// Catálogo cerrado de efectos. Un enum en vez de strings sueltos para que
/// añadir un sonido nuevo obligue a nombrarlo en un único sitio.
enum GameSfx {
  tap('tap.mp3'),
  draw('draw.mp3'),
  arrive('arrive.mp3'),
  fail('fail.mp3'),
  star('star.mp3'),
  win('win.mp3'),
  lose('lose.mp3'),
  shield('shield.mp3'),
  bloom('bloom.mp3');

  const GameSfx(this.file);
  final String file;
}

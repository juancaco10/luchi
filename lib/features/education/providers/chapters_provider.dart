import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter_model.dart';
import '../../../core/storage/local_storage.dart';

// ── State ─────────────────────────────────────────────────────────

class ChaptersState {
  final List<ChapterModel> chapters;
  final bool isLoading;
  final String? error;

  /// True si `chapters` no vino de la red en la última carga (es caché o,
  /// solo con ALLOW_SEED_DATA, datos de ejemplo). Sin esto la UI no puede
  /// distinguir "datos frescos" de "lo último que se guardó antes de que
  /// fallara la red".
  final bool isStale;

  const ChaptersState({
    this.chapters = const [],
    this.isLoading = false,
    this.error,
    this.isStale = false,
  });

  /// `error`/`isStale` no llevan `??` sobre el valor previo: antes
  /// `error: error ?? this.error` hacía imposible limpiar un error una vez
  /// puesto (pasar `null` explícito no lo borraba). Aquí el valor pasado —
  /// incluido `null` — siempre gana.
  ChaptersState copyWith({
    List<ChapterModel>? chapters,
    bool? isLoading,
    Object? error = _unset,
    bool isStale = false,
  }) =>
      ChaptersState(
        chapters: chapters ?? this.chapters,
        isLoading: isLoading ?? this.isLoading,
        error: identical(error, _unset) ? this.error : error as String?,
        isStale: isStale,
      );
}

const _unset = Object();

// ── Notifier ──────────────────────────────────────────────────────

class ChaptersNotifier extends StateNotifier<ChaptersState> {
  ChaptersNotifier() : super(const ChaptersState()) {
    loadChapters();
  }

  Future<void> loadChapters() async {
    // Los capítulos y sus videos viven empaquetados en el APK
    // (`ChapterModel.getMockChapters()` → `assets/videos/{id}.mp4`), así
    // "Aprender" funciona sin conexión y no depende del backend. El backend
    // solo guarda el progreso (qué capítulos completó el usuario); ese
    // estado se conserva en la caché local y se aplica sobre la lista fija.
    final seed = ChapterModel.getMockChapters();

    // Estado de progreso persistido (is_completed/is_unlocked) de la última
    // vez; se pisa sobre los capítulos locales para no perder el avance del
    // niño aunque se reabra la app.
    final cachedRaw = LocalStorage.instance.getCachedChapters();
    final cached = cachedRaw.isNotEmpty
        ? cachedRaw.map(ChapterModel.fromJson).toList()
        : const <ChapterModel>[];

    state = state.copyWith(
      chapters: seed.map((c) {
        final prev = cached.firstWhere((x) => x.id == c.id, orElse: () => c);
        return c.copyWith(
          isCompleted: prev.isCompleted,
          isUnlocked: prev.isUnlocked,
        );
      }).toList(),
      isLoading: false,
      isStale: false,
    );

    // Persistir el progreso ya conocido para que siga consistente.
    LocalStorage.instance.cacheChapters(
      state.chapters.map((c) => c.toJson()).toList(),
    );
  }

  void markCompleted(int chapterId) {
    final updated = state.chapters.map<ChapterModel>((c) {
      if (c.id == chapterId) return c.copyWith(isCompleted: true);
      // Unlock next chapter
      if (c.orderIndex == _getOrderIndex(chapterId, state.chapters) + 1) {
        return c.copyWith(isUnlocked: true);
      }
      return c;
    }).toList();
    state = state.copyWith(chapters: updated, isStale: state.isStale);

    LocalStorage.instance.cacheChapters(
      updated.map((c) => c.toJson()).toList(),
    );
  }

  int _getOrderIndex(int id, List<ChapterModel> chapters) {
    return chapters.firstWhere((c) => c.id == id, orElse: () => chapters.first).orderIndex;
  }
}

// ── Providers ─────────────────────────────────────────────────────

final chaptersProvider = StateNotifierProvider<ChaptersNotifier, ChaptersState>(
  (ref) => ChaptersNotifier(),
);

final chapterByIdProvider = Provider.family<ChapterModel?, String>((ref, id) {
  final chapters = ref.watch(chaptersProvider).chapters;
  try {
    return chapters.firstWhere((c) => c.id.toString() == id);
  } catch (_) {
    return null;
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';

// ── State ─────────────────────────────────────────────────────────

class ChaptersState {
  final List<ChapterModel> chapters;
  final bool isLoading;
  final String? error;

  const ChaptersState({
    this.chapters = const [],
    this.isLoading = false,
    this.error,
  });

  ChaptersState copyWith({
    List<ChapterModel>? chapters,
    bool? isLoading,
    String? error,
  }) => ChaptersState(
    chapters: chapters ?? this.chapters,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

// ── Notifier ──────────────────────────────────────────────────────

class ChaptersNotifier extends StateNotifier<ChaptersState> {
  ChaptersNotifier(this._ref) : super(const ChaptersState()) {
    loadChapters();
  }

  final Ref _ref;

  Future<void> loadChapters() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.chapters,
      );
      final List data = response.data!['chapters'] as List;
      final List<ChapterModel> chapters = data.map<ChapterModel>((j) => ChapterModel.fromJson(j as Map<String, dynamic>)).toList();
      await LocalStorage.instance.cacheChapters(
        chapters.map<Map<String, dynamic>>((c) => c.toJson()).toList(),
      );
      state = state.copyWith(chapters: chapters, isLoading: false);
    } catch (_) {
      // Fallback to mock data or cache
      final cached = LocalStorage.instance.getCachedChapters();
      if (cached.isNotEmpty) {
        state = state.copyWith(
          chapters: cached.map<ChapterModel>((j) => ChapterModel.fromJson(j)).toList(),
          isLoading: false,
        );
      } else {
        // Use mock data for demo/offline
        state = state.copyWith(chapters: ChapterModel.getMockChapters(), isLoading: false);

      }
    }
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
    state = state.copyWith(chapters: updated);
    
    LocalStorage.instance.cacheChapters(
      updated.map((c) => c.toJson()).toList(),
    );
  }

  int _getOrderIndex(int id, List<ChapterModel> chapters) {
    return chapters.firstWhere((c) => c.id == id, orElse: () => chapters.first).orderIndex;
  }
}

int _getOrder(int id, List<ChapterModel> chapters) =>
    chapters.firstWhere((c) => c.id == id).orderIndex;

// ── Providers ─────────────────────────────────────────────────────

final chaptersProvider = StateNotifierProvider<ChaptersNotifier, ChaptersState>(
  (ref) => ChaptersNotifier(ref),
);

final chapterByIdProvider = Provider.family<ChapterModel?, String>((ref, id) {
  final chapters = ref.watch(chaptersProvider).chapters;
  try {
    return chapters.firstWhere((c) => c.id.toString() == id);
  } catch (_) {
    return null;
  }
});

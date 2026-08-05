import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mission_model.dart';
import '../../../core/data/cached_list_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';

// ── State ─────────────────────────────────────────────────────────

class MissionsState {
  final List<MissionModel> missions;
  final bool isLoading;
  final String? error;
  final int? justCompletedId;

  /// True si `missions` no vino de la red esta vez (caché o, solo con
  /// ALLOW_SEED_DATA, datos de ejemplo). Ver ChaptersState.isStale.
  final bool isStale;

  const MissionsState({
    this.missions = const [],
    this.isLoading = false,
    this.error,
    this.justCompletedId,
    this.isStale = false,
  });

  /// `error` ya no lleva `??` sobre el valor previo: antes
  /// `error: error ?? this.error` hacía imposible limpiarlo pasando `null`.
  MissionsState copyWith({
    List<MissionModel>? missions,
    bool? isLoading,
    Object? error = _unset,
    Object? justCompletedId = _unset,
    bool isStale = false,
  }) =>
      MissionsState(
        missions: missions ?? this.missions,
        isLoading: isLoading ?? this.isLoading,
        error: identical(error, _unset) ? this.error : error as String?,
        justCompletedId: identical(justCompletedId, _unset)
            ? this.justCompletedId
            : justCompletedId as int?,
        isStale: isStale,
      );

  List<MissionModel> get dailyMissions =>
      missions.where((m) => m.type == MissionType.daily).toList();

  List<MissionModel> get weeklyMissions =>
      missions.where((m) => m.type == MissionType.weekly).toList();

  int get completedCount => missions.where((m) => m.isCompleted).length;
}

const _unset = Object();

// ── Notifier ──────────────────────────────────────────────────────

class MissionsNotifier extends StateNotifier<MissionsState> {
  MissionsNotifier(this._ref) : super(const MissionsState()) {
    loadMissions();
  }

  final Ref _ref;

  Future<void> loadMissions() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await loadCachedList<MissionModel>(
      api: _ref.read(apiClientProvider),
      path: ApiEndpoints.missions,
      envelopeKey: 'missions',
      fromJson: MissionModel.fromJson,
      toJson: (m) => m.toJson(),
      readCache: LocalStorage.instance.getCachedMissions,
      writeCache: LocalStorage.instance.cacheMissions,
      seed: MissionModel.getMockMissions,
    );

    state = state.copyWith(
      missions: result.items,
      isLoading: false,
      error: result.error?.message,
      isStale: result.isStale,
    );
  }

  /// Complete a mission — calls API and updates local state
  Future<int> completeMission(int missionId) async {
    final mission = state.missions.firstWhere((m) => m.id == missionId);
    if (mission.isCompleted) return 0;

    // Optimistically update
    final updated = state.missions
        .map<MissionModel>((m) => m.id == missionId ? m.copyWith(isCompleted: true) : m)
        .toList();
    state = state.copyWith(
      missions: updated,
      justCompletedId: missionId,
      isStale: state.isStale,
    );

    // Call API (best-effort, no rollback on failure)
    try {
      await _ref.read(apiClientProvider).post(
        ApiEndpoints.completeMission,
        data: {'mission_id': missionId},
      );
    } catch (_) {
      // Offline — mission still marked as done locally
    }

    return mission.pointsReward;
  }

  void clearJustCompleted() =>
      state = state.copyWith(justCompletedId: null, isStale: state.isStale);
}

// ── Providers ─────────────────────────────────────────────────────

final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>(
  (ref) => MissionsNotifier(ref),
);

final missionByIdProvider = Provider.family<MissionModel?, String>((ref, id) {
  final missions = ref.watch(missionsProvider).missions;
  try {
    return missions.firstWhere((m) => m.id.toString() == id);
  } catch (_) {
    return null;
  }
});

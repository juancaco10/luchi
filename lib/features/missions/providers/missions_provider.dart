import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mission_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';

// ── State ─────────────────────────────────────────────────────────

class MissionsState {
  final List<MissionModel> missions;
  final bool isLoading;
  final String? error;
  final int? justCompletedId;

  const MissionsState({
    this.missions = const [],
    this.isLoading = false,
    this.error,
    this.justCompletedId,
  });

  MissionsState copyWith({
    List<MissionModel>? missions,
    bool? isLoading,
    String? error,
    int? justCompletedId,
  }) => MissionsState(
    missions: missions ?? this.missions,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    justCompletedId: justCompletedId ?? this.justCompletedId,
  );

  List<MissionModel> get dailyMissions =>
      missions.where((m) => m.type == MissionType.daily).toList();

  List<MissionModel> get weeklyMissions =>
      missions.where((m) => m.type == MissionType.weekly).toList();

  int get completedCount => missions.where((m) => m.isCompleted).length;
}

// ── Notifier ──────────────────────────────────────────────────────

class MissionsNotifier extends StateNotifier<MissionsState> {
  MissionsNotifier(this._ref) : super(const MissionsState()) {
    loadMissions();
  }

  final Ref _ref;

  Future<void> loadMissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.missions,
      );
      final List data = response.data!['missions'] as List;
      final List<MissionModel> missions = data
          .map<MissionModel>((j) => MissionModel.fromJson(j as Map<String, dynamic>))
          .toList();
      await LocalStorage.instance.cacheMissions(
        missions.map<Map<String, dynamic>>((m) => m.toJson()).toList(),
      );
      state = state.copyWith(missions: missions, isLoading: false);
    } catch (_) {
      final cached = LocalStorage.instance.getCachedMissions();
      if (cached.isNotEmpty) {
        state = state.copyWith(
          missions: cached.map<MissionModel>((j) => MissionModel.fromJson(j)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(missions: MissionModel.getMockMissions(), isLoading: false);

      }
    }
  }

  /// Complete a mission — calls API and updates local state
  Future<int> completeMission(int missionId) async {
    final mission = state.missions.firstWhere((m) => m.id == missionId);
    if (mission.isCompleted) return 0;

    // Optimistically update
    final updated = state.missions
        .map<MissionModel>((m) => m.id == missionId ? m.copyWith(isCompleted: true) : m)
        .toList();
    state = state.copyWith(missions: updated, justCompletedId: missionId);

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

  void clearJustCompleted() => state = state.copyWith(justCompletedId: null);
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

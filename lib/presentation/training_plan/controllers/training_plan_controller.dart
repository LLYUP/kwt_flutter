import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class TrainingPlanState {
  final bool isBusy;
  final String? error;
  final List<TrainingPlanEntry> plans;

  const TrainingPlanState({
    this.isBusy = false,
    this.error,
    this.plans = const [],
  });

  TrainingPlanState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<TrainingPlanEntry>? plans,
  }) {
    return TrainingPlanState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      plans: plans ?? this.plans,
    );
  }
}

class TrainingPlanController extends StateNotifier<TrainingPlanState> {
  final Ref _ref;

  TrainingPlanController(this._ref) : super(const TrainingPlanState()) {
    _init();
  }

  Future<void> _init() async {
    await fetchTrainingPlan();
  }

  Future<void> fetchTrainingPlan() async {
    final client = _ref.read(kwtClientProvider);
    if (client == null) {
      state = state.copyWith(error: '未登录', clearError: false);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final results = await client.fetchTrainingPlan();
      state = state.copyWith(plans: results, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final trainingPlanControllerProvider = StateNotifierProvider.autoDispose<TrainingPlanController, TrainingPlanState>((ref) {
  return TrainingPlanController(ref);
});

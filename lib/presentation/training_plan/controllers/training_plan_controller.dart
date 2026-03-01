import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class TrainingPlanState {
  final bool isBusy;
  final String? error;
  final List<TrainingPlanEntry> plans;
  final List<String> termOptions;
  final String selectedTerm;

  const TrainingPlanState({
    this.isBusy = false,
    this.error,
    this.plans = const [],
    this.termOptions = const [],
    this.selectedTerm = '全部',
  });

  List<TrainingPlanEntry> get filteredPlans {
    if (selectedTerm == '全部') return plans;
    return plans.where((p) => p.term == selectedTerm).toList();
  }

  TrainingPlanState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<TrainingPlanEntry>? plans,
    List<String>? termOptions,
    String? selectedTerm,
  }) {
    return TrainingPlanState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      plans: plans ?? this.plans,
      termOptions: termOptions ?? this.termOptions,
      selectedTerm: selectedTerm ?? this.selectedTerm,
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

  void setTerm(String term) {
    state = state.copyWith(selectedTerm: term);
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
      
      // 提取拥有的独特学期并排序（倒序）
      final terms = results.map((e) => e.term).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      final options = ['全部', ...terms];

      state = state.copyWith(
        plans: results, 
        termOptions: options,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final trainingPlanControllerProvider = StateNotifierProvider.autoDispose<TrainingPlanController, TrainingPlanState>((ref) {
  return TrainingPlanController(ref);
});

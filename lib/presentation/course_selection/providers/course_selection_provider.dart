import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class CourseSelectionState {
  final bool isLoading;
  final String? error;
  final List<CourseSelectionEntry>? results;

  const CourseSelectionState({
    this.isLoading = false,
    this.error,
    this.results,
  });

  CourseSelectionState copyWith({
    bool? isLoading,
    String? error,
    List<CourseSelectionEntry>? results,
  }) {
    return CourseSelectionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      results: results ?? this.results,
    );
  }
}

class CourseSelectionNotifier extends AutoDisposeNotifier<CourseSelectionState> {
  @override
  CourseSelectionState build() {
    return const CourseSelectionState();
  }

  Future<void> fetchResults(String termId, {String cxsj = 'skjg'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(kwtClientProvider);
      if (client == null) {
        throw Exception('未登录，请先登录');
      }

      final results = await client.fetchCourseSelectionResults(
        termId: termId,
        cxsj: cxsj,
      );

      state = state.copyWith(
        isLoading: false,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final courseSelectionProvider = AutoDisposeNotifierProvider<CourseSelectionNotifier, CourseSelectionState>(() {
  return CourseSelectionNotifier();
});

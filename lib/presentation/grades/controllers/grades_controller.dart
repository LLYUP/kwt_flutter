import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart'; // import to use global providers

class GradesState {
  final bool isBusy;
  final String? error;
  final List<GradeEntry> grades;
  final List<GradeEntry> filteredGrades;
  final String selectedTerm;
  final List<String> termOptions;
  final String searchQuery;

  const GradesState({
    this.isBusy = false,
    this.error,
    this.grades = const [],
    this.filteredGrades = const [],
    this.selectedTerm = '',
    this.termOptions = const [],
    this.searchQuery = '',
  });

  GradesState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<GradeEntry>? grades,
    List<GradeEntry>? filteredGrades,
    String? selectedTerm,
    List<String>? termOptions,
    String? searchQuery,
  }) {
    return GradesState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      grades: grades ?? this.grades,
      filteredGrades: filteredGrades ?? this.filteredGrades,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      termOptions: termOptions ?? this.termOptions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
  
  String get averageScore {
    if (filteredGrades.isEmpty) return '0.0';
    double total = 0;
    int count = 0;
    for (final grade in filteredGrades) {
      final score = double.tryParse(grade.score);
      if (score != null) {
        total += score;
        count++;
      }
    }
    if (count == 0) return '0.0';
    return (total / count).toStringAsFixed(1);
  }
}

class GradesController extends StateNotifier<GradesState> {
  final Ref _ref;

  GradesController(this._ref) : super(const GradesState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final client = _ref.read(kwtClientProvider);
      if (client != null) {
        final terms = await client.fetchTermOptions();
        List<String> options = ['全部学期', ...terms];
        String term = state.selectedTerm;
        if (term.isEmpty && terms.isNotEmpty) {
          term = terms.first;
        }
        state = state.copyWith(termOptions: options, selectedTerm: term);
      }
    } catch (_) {}
  }

  void setTerm(String term) {
    state = state.copyWith(selectedTerm: term);
  }
  
  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    
    final lowerQuery = query.toLowerCase();
    final filtered = state.grades.where((grade) {
      return lowerQuery.isEmpty || 
          grade.courseName.toLowerCase().contains(lowerQuery) ||
          grade.courseCode.toLowerCase().contains(lowerQuery);
    }).toList();
    
    state = state.copyWith(searchQuery: query, filteredGrades: filtered);
  }

  Future<void> fetchGrades() async {
    final client = _ref.read(kwtClientProvider);
    if (client == null) {
      state = state.copyWith(error: '未登录', clearError: false);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final termParam = state.selectedTerm == '全部学期' ? '' : state.selectedTerm;
      final data = await client.fetchGradesStructured(term: termParam);
      
      // Re-apply current search query to new data
      final lowerQuery = state.searchQuery.toLowerCase();
      final filtered = data.where((grade) {
        return lowerQuery.isEmpty || 
            grade.courseName.toLowerCase().contains(lowerQuery) ||
            grade.courseCode.toLowerCase().contains(lowerQuery);
      }).toList();
      
      state = state.copyWith(grades: data, filteredGrades: filtered, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final gradesControllerProvider = StateNotifierProvider.autoDispose<GradesController, GradesState>((ref) {
  return GradesController(ref);
});

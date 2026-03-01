import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/services/kwt_client.dart';

class ClassroomTimetableState {
  final bool isBusy;
  final String? error;
  final List<String> termOptions;
  final String selectedTerm;
  final String classroomQuery;
  final String classroomId;
  final List<Map<String, String>> searchResults;
  final List<TimetableEntry> timetable;

  const ClassroomTimetableState({
    this.isBusy = false,
    this.error,
    this.termOptions = const [],
    this.selectedTerm = '',
    this.classroomQuery = '',
    this.classroomId = '',
    this.searchResults = const [],
    this.timetable = const [],
  });

  ClassroomTimetableState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<String>? termOptions,
    String? selectedTerm,
    String? classroomQuery,
    String? classroomId,
    List<Map<String, String>>? searchResults,
    List<TimetableEntry>? timetable,
  }) {
    return ClassroomTimetableState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      termOptions: termOptions ?? this.termOptions,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      classroomQuery: classroomQuery ?? this.classroomQuery,
      classroomId: classroomId ?? this.classroomId,
      searchResults: searchResults ?? this.searchResults,
      timetable: timetable ?? this.timetable,
    );
  }
}

class ClassroomTimetableController extends StateNotifier<ClassroomTimetableState> {
  final Ref _ref;

  ClassroomTimetableController(this._ref) : super(const ClassroomTimetableState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final client = _ref.read(kwtClientProvider);
      if (client != null) {
        final terms = await client.fetchTermOptions();
        String term = state.selectedTerm;
        if (term.isEmpty && terms.isNotEmpty) {
          term = terms.first;
        }
        state = state.copyWith(termOptions: terms, selectedTerm: term);
      }
    } catch (_) {}
  }

  void setTerm(String term) {
    state = state.copyWith(selectedTerm: term);
  }

  void setClassroomQuery(String query) {
    if (state.classroomQuery == query) return;
    state = state.copyWith(classroomQuery: query, classroomId: '');
  }

  void setClassroom(String name, String id) {
    state = state.copyWith(classroomQuery: name, classroomId: id);
  }

  Future<void> searchClassrooms(String keyword) async {
    final client = _ref.read(kwtClientProvider);
    if (client == null || keyword.trim().isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    try {
      final results = await client.searchClassrooms(keyword: keyword.trim());
      state = state.copyWith(searchResults: results);
    } catch (_) {
      state = state.copyWith(searchResults: []);
    }
  }

  Future<void> fetchTimetable() async {
    if (state.classroomQuery.trim().isEmpty) {
      state = state.copyWith(error: '请输入教室名称', clearError: false);
      return;
    }

    final client = _ref.read(kwtClientProvider);
    if (client == null) {
      state = state.copyWith(error: '未登录', clearError: false);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    
    try {
      final termParam = state.selectedTerm;
      final data = await client.fetchClassroomTimetableStructured(
        term: termParam,
        timeMode: KwtClient.defaultTimeMode,
        classroom: state.classroomQuery.trim(),
        classroomId: state.classroomId,
      );
      state = state.copyWith(timetable: data, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final classroomTimetableControllerProvider = StateNotifierProvider.autoDispose<ClassroomTimetableController, ClassroomTimetableState>((ref) {
  return ClassroomTimetableController(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/services/kwt_client.dart';

class ClassTimetableState {
  final bool isBusy;
  final String? error;
  final List<String> termOptions;
  final String selectedTerm;
  final String classQuery;
  final List<TimetableEntry> timetable;

  const ClassTimetableState({
    this.isBusy = false,
    this.error,
    this.termOptions = const [],
    this.selectedTerm = '',
    this.classQuery = '',
    this.timetable = const [],
  });

  ClassTimetableState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<String>? termOptions,
    String? selectedTerm,
    String? classQuery,
    List<TimetableEntry>? timetable,
  }) {
    return ClassTimetableState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      termOptions: termOptions ?? this.termOptions,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      classQuery: classQuery ?? this.classQuery,
      timetable: timetable ?? this.timetable,
    );
  }
}

class ClassTimetableController extends StateNotifier<ClassTimetableState> {
  final Ref _ref;

  ClassTimetableController(this._ref) : super(const ClassTimetableState()) {
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

  void setClassQuery(String query) {
    state = state.copyWith(classQuery: query);
  }

  Future<void> fetchTimetable() async {
    if (state.classQuery.trim().isEmpty) {
      state = state.copyWith(error: '请输入班级名称', clearError: false);
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
      final data = await client.fetchClassTimetableStructured(
        term: termParam,
        timeMode: KwtClient.defaultTimeMode,
        className: state.classQuery.trim(),
      );
      state = state.copyWith(timetable: data, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final classTimetableControllerProvider = StateNotifierProvider.autoDispose<ClassTimetableController, ClassTimetableState>((ref) {
  return ClassTimetableController(ref);
});

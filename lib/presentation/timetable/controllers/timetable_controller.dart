import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/utils/timetable_utils.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/config/app_config.dart';

class TimetableState {
  final bool isBusy;
  final String? error;
  final List<TimetableEntry> timetable;
  final List<MergedTimetableEntry> mergedTimetable;
  final int weekNo;
  final String selectedTerm;
  final String selectedDate;
  final String timeMode;
  final bool initialized;

  const TimetableState({
    this.isBusy = false,
    this.error,
    this.timetable = const [],
    this.mergedTimetable = const [],
    this.weekNo = 1,
    this.selectedTerm = '',
    this.selectedDate = '',
    this.timeMode = '',
    this.initialized = false,
  });

  TimetableState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<TimetableEntry>? timetable,
    List<MergedTimetableEntry>? mergedTimetable,
    int? weekNo,
    String? selectedTerm,
    String? selectedDate,
    String? timeMode,
    bool? initialized,
  }) {
    return TimetableState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      timetable: timetable ?? this.timetable,
      mergedTimetable: mergedTimetable ?? this.mergedTimetable,
      weekNo: weekNo ?? this.weekNo,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      selectedDate: selectedDate ?? this.selectedDate,
      timeMode: timeMode ?? this.timeMode,
      initialized: initialized ?? this.initialized,
    );
  }
}

class TimetableController extends StateNotifier<TimetableState> {
  final Ref _ref;

  TimetableController(this._ref) : super(const TimetableState()) {
    _initFromSettings();
  }

  Future<void> _initFromSettings() async {
    final settings = _ref.read(settingsProvider);
    final term = await settings.getTerm() ?? AppConfig.defaultTerm;
    final savedStart = await settings.getStartDate() ?? '';
    final timeMode = AppConfig.defaultTimeMode;

    int autoWeek = 1;
    String dateStr = DateTime.now().toIso8601String().substring(0, 10);

    if (savedStart.isNotEmpty) {
      autoWeek = _computeWeekFromStart(savedStart);
      final start = DateTime.tryParse(savedStart);
      if (start != null) {
        final rq = start.add(Duration(days: (autoWeek - 1) * 7));
        dateStr = rq.toIso8601String().substring(0, 10);
      }
    }

    state = state.copyWith(
      selectedTerm: term,
      timeMode: timeMode,
      weekNo: autoWeek,
      selectedDate: dateStr,
      initialized: true,
    );

    // Initial fetch if client is available
    if (_ref.read(kwtClientProvider) != null) {
      await fetchTimetable();
    }
  }

  int _computeWeekFromStart(String startDate) {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 1;
    final now = DateTime.now();
    final diff = now.difference(DateTime(start.year, start.month, start.day)).inDays;
    if (diff < 0) return 1;
    final week = (diff ~/ 7) + 1;
    return week < 1 ? 1 : week;
  }

  Future<void> setWeek(int week) async {
    final settings = _ref.read(settingsProvider);
    final startUrl = await settings.getStartDate();
    final start = DateTime.tryParse(startUrl ?? state.selectedDate);
    
    String updatedDate = state.selectedDate;
    if (start != null && startUrl != null) {
      final rq = start.add(Duration(days: (week - 1) * 7));
      updatedDate = rq.toIso8601String().substring(0, 10);
    }
    
    state = state.copyWith(weekNo: week, selectedDate: updatedDate);
    await fetchTimetable();
  }

  Future<void> fetchTimetable() async {
    final client = _ref.read(kwtClientProvider);
    if (client == null) {
      state = state.copyWith(error: '未登录', clearError: false);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final data = await client.fetchPersonalTimetableStructured(
        date: state.selectedDate,
        timeMode: state.timeMode,
        termId: state.selectedTerm,
      );
      state = state.copyWith(
        timetable: data,
        mergedTimetable: mergeContinuousCourses(data),
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final timetableControllerProvider = StateNotifierProvider.autoDispose<TimetableController, TimetableState>((ref) {
  return TimetableController(ref);
});

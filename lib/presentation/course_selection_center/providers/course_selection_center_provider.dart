import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class CourseSelectionCenterState {
  final bool isLoading;
  final String? error;
  final List<CourseSelectionRoundEntry>? rounds;

  const CourseSelectionCenterState({
    this.isLoading = false,
    this.error,
    this.rounds,
  });

  CourseSelectionCenterState copyWith({
    bool? isLoading,
    String? error,
    List<CourseSelectionRoundEntry>? rounds,
  }) {
    return CourseSelectionCenterState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rounds: rounds ?? this.rounds,
    );
  }
}

class CourseSelectionCenterNotifier extends AutoDisposeNotifier<CourseSelectionCenterState> {
  @override
  CourseSelectionCenterState build() {
    return const CourseSelectionCenterState();
  }

  Future<void> fetchRounds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(kwtClientProvider);
      if (client == null) throw Exception('未登录，请先登录');

      final rounds = await client.fetchCourseSelectionRounds();
      state = state.copyWith(isLoading: false, rounds: rounds);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> enterSelection(String roundId) async {
    final client = ref.read(kwtClientProvider);
    if (client == null) throw Exception('未登录，请先登录');

    final ok = await client.checkMzlist();
    if (!ok) throw Exception('选课前置检查未通过');

    await client.enterCourseSelection(roundId);
    return true;
  }
}

final courseSelectionCenterProvider = AutoDisposeNotifierProvider<CourseSelectionCenterNotifier, CourseSelectionCenterState>(() {
  return CourseSelectionCenterNotifier();
});

// --- 课程筛选参数 ---

class CourseFilterParams {
  final String categoryId;
  final String courseName;
  final String teacher;
  final String weekday;
  final String startPeriod;
  final String endPeriod;
  final bool filterFull;
  final bool filterConflict;
  final bool filterRestricted;

  const CourseFilterParams({
    this.categoryId = '',
    this.courseName = '',
    this.teacher = '',
    this.weekday = '',
    this.startPeriod = '',
    this.endPeriod = '',
    this.filterFull = false,
    this.filterConflict = true,
    this.filterRestricted = true,
  });
}

// --- 选课课程列表 Provider ---

class ElectiveCourseListState {
  final bool isLoading;
  final String? error;
  final List<ElectiveCourseEntry> courses;
  final List<MapEntry<String, String>> categories;
  final bool categoriesLoaded;

  const ElectiveCourseListState({
    this.isLoading = false,
    this.error,
    this.courses = const [],
    this.categories = const [],
    this.categoriesLoaded = false,
  });

  ElectiveCourseListState copyWith({
    bool? isLoading,
    String? error,
    List<ElectiveCourseEntry>? courses,
    List<MapEntry<String, String>>? categories,
    bool? categoriesLoaded,
  }) {
    return ElectiveCourseListState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      courses: courses ?? this.courses,
      categories: categories ?? this.categories,
      categoriesLoaded: categoriesLoaded ?? this.categoriesLoaded,
    );
  }
}

class ElectiveCourseListNotifier extends AutoDisposeFamilyNotifier<ElectiveCourseListState, String> {
  CourseFilterParams _lastFilter = const CourseFilterParams();

  @override
  ElectiveCourseListState build(String arg) {
    return const ElectiveCourseListState();
  }

  String get roundId => arg;

  /// 动态加载类别列表
  Future<void> loadCategories() async {
    if (state.categoriesLoaded) return;
    try {
      final client = ref.read(kwtClientProvider);
      if (client == null) return;

      final cats = await client.fetchCourseCategories(roundId);
      state = state.copyWith(categories: cats, categoriesLoaded: true);
    } catch (_) {
      // 类别加载失败不阻塞使用，保留空列表
    }
  }

  Future<void> fetchCourses(CourseFilterParams filter) async {
    _lastFilter = filter;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(kwtClientProvider);
      if (client == null) throw Exception('未登录，请先登录');

      final courses = await client.fetchElectiveCourses(
        roundId: roundId,
        courseName: filter.courseName,
        teacher: filter.teacher,
        categoryId: filter.categoryId,
        weekday: filter.weekday,
        startPeriod: filter.startPeriod,
        endPeriod: filter.endPeriod,
        filterFull: filter.filterFull,
        filterConflict: filter.filterConflict,
        filterRestricted: filter.filterRestricted,
        pageSize: 200,
      );

      state = state.copyWith(isLoading: false, courses: courses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 选课
  Future<Map<String, dynamic>> selectCourse({
    required String jx0404id,
    required String kcid,
  }) async {
    final client = ref.read(kwtClientProvider);
    if (client == null) throw Exception('未登录');

    final result = await client.selectCourse(jx0404id: jx0404id, kcid: kcid);
    // 选课后自动刷新列表
    await fetchCourses(_lastFilter);
    return result;
  }

  /// 退课
  Future<Map<String, dynamic>> deselectCourse({
    required String jx0404id,
  }) async {
    final client = ref.read(kwtClientProvider);
    if (client == null) throw Exception('未登录');

    final result = await client.deselectCourse(jx0404id: jx0404id);
    // 退课后自动刷新列表
    await fetchCourses(_lastFilter);
    return result;
  }

  Future<void> exitSelection() async {
    final client = ref.read(kwtClientProvider);
    if (client == null) return;
    await client.exitCourseSelection();
  }
}

final electiveCourseListProvider = AutoDisposeNotifierProvider.family<ElectiveCourseListNotifier, ElectiveCourseListState, String>(() {
  return ElectiveCourseListNotifier();
});

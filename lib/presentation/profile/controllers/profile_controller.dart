import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart'; // import to use global providers

class ProfileState {
  final bool isLoggedIn;
  final String? studentId;
  final String? studentName;
  final String selectedTerm;
  final String selectedStartDate;
  final List<String> termOptions;
  final bool isLoadingTerms;

  const ProfileState({
    this.isLoggedIn = false,
    this.studentId,
    this.studentName,
    this.selectedTerm = '',
    this.selectedStartDate = '',
    this.termOptions = const [],
    this.isLoadingTerms = false,
  });

  ProfileState copyWith({
    bool? isLoggedIn,
    String? studentId,
    String? studentName,
    String? selectedTerm,
    String? selectedStartDate,
    List<String>? termOptions,
    bool? isLoadingTerms,
  }) {
    return ProfileState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      selectedStartDate: selectedStartDate ?? this.selectedStartDate,
      termOptions: termOptions ?? this.termOptions,
      isLoadingTerms: isLoadingTerms ?? this.isLoadingTerms,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileController(this._ref) : super(const ProfileState()) {
    _load();
  }

  Future<void> _load() async {
    final settings = _ref.read(settingsProvider);
    final term = await settings.getTerm() ?? '';
    final startDate = await settings.getStartDate() ?? '';
    final loggedIn = await settings.isLoggedIn();
    final studentId = await settings.getStudentId();
    final studentName = await settings.getStudentName();

    state = state.copyWith(
      selectedTerm: term,
      selectedStartDate: startDate,
      isLoggedIn: loggedIn,
      studentId: studentId,
      studentName: studentName,
    );

    if (loggedIn) {
      _loadTerms();
    }
  }

  Future<void> _loadTerms() async {
    state = state.copyWith(isLoadingTerms: true);
    try {
      final client = _ref.read(kwtClientProvider);
      if (client != null) {
        final terms = await client.fetchTermOptions();
        if (terms.isNotEmpty) {
          String newTerm = state.selectedTerm;
          if (newTerm.isEmpty) {
            newTerm = terms.first;
            await saveTerm(newTerm);
          }
          state = state.copyWith(termOptions: terms, selectedTerm: newTerm);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) state = state.copyWith(isLoadingTerms: false);
    }
  }

  Future<void> saveTerm(String term) async {
    if (term == state.selectedTerm) return;
    state = state.copyWith(selectedTerm: term);
    await _ref.read(settingsProvider).saveTerm(term);
  }

  Future<void> saveStartDate(String date) async {
    if (date == state.selectedStartDate) return;
    state = state.copyWith(selectedStartDate: date);
    await _ref.read(settingsProvider).saveStartDate(date);
  }

  Future<void> logout() async {
    final client = _ref.read(kwtClientProvider);
    if (client != null) {
      try {
        await client.logout();
        await client.clearCookies();
      } catch (_) {}
    }
    await _ref.read(settingsProvider).clearAuth();
    _ref.read(kwtClientProvider.notifier).state = null;
    state = state.copyWith(isLoggedIn: false, studentId: null, studentName: null);
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final client = _ref.read(kwtClientProvider);
    if (client == null || state.studentId == null) {
      return {'success': false, 'message': '用户未登录或状态异常'};
    }
    try {
      final res = await client.changePassword(
        account: state.studentId!,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (res['success'] == true) {
        // 修改密码成功后系统自动下线了，需要清除本地状态
        await logout();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': '修改密码异常: $e'};
    }
  }
}

final profileControllerProvider = StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController(ref);
});

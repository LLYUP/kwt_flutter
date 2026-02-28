import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/config/app_config.dart';

// 提供全局共享的单例 SettingsService
final settingsProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// 管理全局 KwtClient 的状态（登录后才存在有效实例）
final kwtClientProvider = StateProvider<KwtClient?>((ref) => null);

// --- Login Controller ---

class LoginState {
  final bool isBusy;
  final String? error;
  final Uint8List? captcha;
  final String selectedNetworkEnvironment;
  final bool rememberPassword;
  final String? studentId;
  final String? password;

  const LoginState({
    this.isBusy = false,
    this.error,
    this.captcha,
    this.selectedNetworkEnvironment = 'intranet',
    this.rememberPassword = false,
    this.studentId,
    this.password,
  });

  LoginState copyWith({
    bool? isBusy,
    String? error,
    Uint8List? captcha,
    String? selectedNetworkEnvironment,
    bool? rememberPassword,
    String? studentId,
    String? password,
  }) {
    // 允许通过显式传 null 清除 error
    return LoginState(
      isBusy: isBusy ?? this.isBusy,
      error: error != null ? (error.isEmpty ? null : error) : this.error,
      captcha: captcha ?? this.captcha,
      selectedNetworkEnvironment: selectedNetworkEnvironment ?? this.selectedNetworkEnvironment,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      studentId: studentId ?? this.studentId,
      password: password ?? this.password,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final Ref _ref;
  KwtClient? _tempClient;

  LoginController(this._ref) : super(const LoginState()) {
    _init();
  }

  Future<void> _init() async {
    final settings = _ref.read(settingsProvider);
    final savedEnv = await settings.getNetworkEnvironment();
    final remember = await settings.getRememberPassword();
    
    String? savedSid;
    String? savedPwd;
    
    if (remember) {
      savedSid = await settings.getRememberedStudentId();
      savedPwd = await settings.getSavedPassword();
    }

    state = state.copyWith(
      selectedNetworkEnvironment: savedEnv ?? 'intranet',
      rememberPassword: remember,
      studentId: savedSid,
      password: savedPwd,
    );

    await _initClient();
  }

  Future<void> _initClient() async {
    final serverUrl = state.selectedNetworkEnvironment == 'internet'
        ? NetworkEnvironment.internet.baseUrl
        : NetworkEnvironment.intranet.baseUrl;
    _tempClient = await KwtClient.createPersisted(baseUrl: serverUrl);
    await fetchCaptcha();
  }

  void changeNetworkEnvironment(String env) async {
    if (env == state.selectedNetworkEnvironment) return;
    state = state.copyWith(selectedNetworkEnvironment: env);
    await _initClient();
  }

  void toggleRememberPassword(bool value) async {
    state = state.copyWith(rememberPassword: value);
    if (!value) {
      await _ref.read(settingsProvider).setRememberPassword(false);
    }
  }

  Future<void> fetchCaptcha() async {
    if (_tempClient == null) return;
    state = state.copyWith(isBusy: true, error: '');
    try {
      final img = await _tempClient!.fetchCaptcha();
      state = state.copyWith(captcha: img, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '获取验证码失败: $e', isBusy: false);
    }
  }

  /// 登录，成功返回 true
  Future<bool> login(String account, String password, String verifyCode) async {
    if (_tempClient == null) return false;
    
    state = state.copyWith(isBusy: true, error: '');
    
    try {
      final ok = await _tempClient!.login(
        userAccount: account,
        userPassword: password,
        verifyCode: verifyCode,
      );
      
      if (!ok) {
        state = state.copyWith(error: '登录失败，请检查账号/密码/验证码', isBusy: false);
        await fetchCaptcha();
        return false;
      }
      
      // 保存登录态
      final settings = _ref.read(settingsProvider);
      await settings.setLoggedIn(true);
      await settings.saveNetworkEnvironment(state.selectedNetworkEnvironment);
      
      if (account.isNotEmpty) {
        await settings.saveStudentId(account);
      }
      
      await settings.setRememberPassword(state.rememberPassword);
      if (state.rememberPassword) {
        await settings.saveRememberedStudentId(account);
        await settings.savePassword(password);
      }
      
      // 尝试获取 profile（不阻塞登录）
      try {
        final info = await _tempClient!.fetchProfileInfo();
        final name = (info['name'] ?? '').trim();
        if (name.isNotEmpty) {
          await settings.saveStudentName(name);
        }
      } catch (_) {}
      
      // 将 _tempClient 升级为全局 Client
      _ref.read(kwtClientProvider.notifier).state = _tempClient;
      state = state.copyWith(isBusy: false);
      return true;
      
    } catch (e) {
      state = state.copyWith(error: '登录异常: $e', isBusy: false);
      return false;
    }
  }
}

// 暴露 Provider 给 UI
final loginControllerProvider = StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref);
});

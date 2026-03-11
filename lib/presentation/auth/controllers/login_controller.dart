import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/config/app_config.dart';

final settingsProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final kwtClientProvider = StateProvider<KwtClient?>((ref) => null);


class LoginState {
  final bool isBusy;
  final String? error;
  final Uint8List? captcha;
  final String selectedNetworkEnvironment;
  final bool rememberPassword;
  final String? studentId;
  final String? password;
  final String? customServerUrl;

  const LoginState({
    this.isBusy = false,
    this.error,
    this.captcha,
    this.selectedNetworkEnvironment = 'intranet',
    this.rememberPassword = false,
    this.studentId,
    this.password,
    this.customServerUrl,
  });

  LoginState copyWith({
    bool? isBusy,
    String? error,
    Uint8List? captcha,
    String? selectedNetworkEnvironment,
    bool? rememberPassword,
    String? studentId,
    String? password,
    String? customServerUrl,
  }) {
    return LoginState(
      isBusy: isBusy ?? this.isBusy,
      error: error != null ? (error.isEmpty ? null : error) : this.error,
      captcha: captcha ?? this.captcha,
      selectedNetworkEnvironment: selectedNetworkEnvironment ?? this.selectedNetworkEnvironment,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      studentId: studentId ?? this.studentId,
      password: password ?? this.password,
      customServerUrl: customServerUrl ?? this.customServerUrl,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final Ref _ref;
  KwtClient? _tempClient;
  Timer? _debounceTimer;

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
    
    final savedCustomUrl = await settings.getCustomServerUrl();

    state = state.copyWith(
      selectedNetworkEnvironment: savedEnv ?? 'intranet',
      rememberPassword: remember,
      studentId: savedSid,
      password: savedPwd,
      customServerUrl: savedCustomUrl,
    );

    await _initClient();
  }

  Future<void> _initClient() async {
    String serverUrl;
    if (state.selectedNetworkEnvironment == 'internet') {
      serverUrl = NetworkEnvironment.internet.baseUrl;
    } else if (state.selectedNetworkEnvironment == 'custom') {
      serverUrl = state.customServerUrl ?? '';
    } else {
      serverUrl = NetworkEnvironment.intranet.baseUrl;
    }
    
    _tempClient = await KwtClient.createPersisted(baseUrl: serverUrl);
    await fetchCaptcha();
  }

  void changeNetworkEnvironment(String env) async {
    if (env == state.selectedNetworkEnvironment) return;
    state = state.copyWith(selectedNetworkEnvironment: env);
    await _ref.read(settingsProvider).saveNetworkEnvironment(env);
    await _initClient();
  }

  void changeCustomServerUrl(String url) async {
    if (url == state.customServerUrl) return;
    state = state.copyWith(customServerUrl: url);
    await _ref.read(settingsProvider).saveCustomServerUrl(url);
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (state.selectedNetworkEnvironment == 'custom') {
        await _initClient();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void toggleRememberPassword(bool value) async {
    state = state.copyWith(rememberPassword: value);
    if (!value) {
      await _ref.read(settingsProvider).setRememberPassword(false);
    }
  }

  Future<void> fetchCaptcha({bool clearError = true}) async {
    if (_tempClient == null) return;
    state = state.copyWith(isBusy: true, error: clearError ? '' : state.error);
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
        await fetchCaptcha(clearError: false);
        return false;
      }
      
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
      
      try {
        final info = await _tempClient!.fetchProfileInfo();
        final name = (info['name'] ?? '').trim();
        if (name.isNotEmpty) {
          await settings.saveStudentName(name);
        }
      } catch (_) {}
      
      _ref.read(kwtClientProvider.notifier).state = _tempClient;
      state = state.copyWith(isBusy: false);
      return true;
      
    } catch (e) {
      state = state.copyWith(error: '登录异常: $e', isBusy: false);
      await fetchCaptcha(clearError: false); // 异常时也刷新验证码
      return false;
    }
  }

}

final loginControllerProvider = StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref);
});

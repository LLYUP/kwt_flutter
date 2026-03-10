import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class ForgotPasswordState {
  final bool isBusy;
  final String? error;
  final Uint8List? captcha;
  final String? successMessage;

  const ForgotPasswordState({
    this.isBusy = false,
    this.error,
    this.captcha,
    this.successMessage,
  });

  ForgotPasswordState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    Uint8List? captcha,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ForgotPasswordState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      captcha: captcha ?? this.captcha,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;
  KwtClient? _tempClient;

  ForgotPasswordController(this._ref) : super(const ForgotPasswordState()) {
    _initClient();
  }

  Future<void> _initClient() async {
    final loginState = _ref.read(loginControllerProvider);
    final serverUrl = loginState.selectedNetworkEnvironment == 'internet'
        ? NetworkEnvironment.internet.baseUrl
        : NetworkEnvironment.intranet.baseUrl;
        
    _tempClient = await KwtClient.createPersisted(baseUrl: serverUrl);
    await fetchCaptcha();
  }

  Future<void> fetchCaptcha() async {
    if (_tempClient == null) return;
    state = state.copyWith(isBusy: true, clearError: true, clearSuccess: true);
    try {
      final bytes = await _tempClient!.fetchCaptcha();
      state = state.copyWith(isBusy: false, captcha: bytes);
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: '获取验证码失败，请重试',
      );
    }
  }

  Future<bool> resetPassword({
    required String account,
    required String idCard,
    required String captcha,
  }) async {
    if (account.isEmpty || idCard.isEmpty || captcha.isEmpty) {
      state = state.copyWith(error: '账号、身份证号、验证码不能为空');
      return false;
    }
    
    if (_tempClient == null) return false;

    state = state.copyWith(isBusy: true, clearError: true, clearSuccess: true);
    try {
      final res = await _tempClient!.resetPassword(
        account: account,
        idCard: idCard,
        captcha: captcha,
      );
      
      final bool success = res['success'] == true;
      final String msg = res['message'] ?? (success ? '密码重置成功' : '验证信息错误或重置失败');
      
      if (success) {
        state = state.copyWith(isBusy: false, successMessage: msg);
        return true;
      } else {
        state = state.copyWith(isBusy: false, error: msg);
        fetchCaptcha(); // Refresh captcha on error
        return false;
      }
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '网络请求失败：$e');
      fetchCaptcha(); // Refresh captcha on error
      return false;
    }
  }
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref);
});

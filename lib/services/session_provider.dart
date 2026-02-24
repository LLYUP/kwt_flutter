// 会话管理：集中管理 KwtClient 生命周期、登录状态与会话失效跳转
import 'package:flutter/material.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/pages/login_page.dart';

/// 会话状态管理器
///
/// 持有 [KwtClient] 实例与登录信息，通过 [InheritedWidget] 向下传递。
/// 提供 [safeCall] 统一处理 [AuthExpiredException]，避免各页面重复捕获。
class SessionNotifier extends ChangeNotifier {
  SessionNotifier({KwtClient? client}) : _client = client;

  KwtClient? _client;
  KwtClient get client {
    assert(_client != null, 'KwtClient is not initialized! Check if user is logged in.');
    return _client!;
  }

  /// 替换底层 client（例如网络环境切换后重新创建）
  void updateClient(KwtClient? newClient) {
    _client = newClient;
    notifyListeners();
  }

  /// 统一的网络请求包装：自动处理 [AuthExpiredException]
  ///
  /// 使用方式：
  /// ```dart
  /// final data = await session.safeCall(context, () => client.fetchGrades(...));
  /// ```
  Future<T?> safeCall<T>(BuildContext context, Future<T> Function() action) async {
    try {
      return await action();
    } on AuthExpiredException catch (e) {
      await _handleAuthExpired(context, e.message);
      return null;
    }
  }

  /// 处理会话失效：清除本地状态并跳转登录页
  Future<void> _handleAuthExpired(BuildContext context, String message) async {
    try {
      await _client?.clearCookies();
    } catch (_) {}
    await SettingsService().clearAuth();
    updateClient(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// 执行退出登录流程
  Future<void> logout(BuildContext context) async {
    try {
      await _client?.logout();
      await _client?.clearCookies();
    } catch (_) {}
    await SettingsService().clearAuth();
    updateClient(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

/// InheritedWidget 包装，供子树通过 [SessionProvider.of] 获取会话管理器
class SessionProvider extends InheritedNotifier<SessionNotifier> {
  const SessionProvider({
    super.key,
    required SessionNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SessionNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<SessionProvider>();
    assert(provider != null, 'SessionProvider not found in widget tree');
    return provider!.notifier!;
  }

  /// 不注册依赖的读取方式（适用于事件回调中，避免不必要的重建）
  static SessionNotifier read(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<SessionProvider>();
    assert(provider != null, 'SessionProvider not found in widget tree');
    return provider!.notifier!;
  }
}

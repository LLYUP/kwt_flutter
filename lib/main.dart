// 应用入口与全局路由配置：负责初始化主题、本地化、登录态判断与页面跳转
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kwt_flutter/pages/login_page.dart';
import 'package:kwt_flutter/pages/tab_scaffold.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/services/session_provider.dart';
import 'package:kwt_flutter/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 预初始化 SharedPreferences 缓存
  await SettingsService.init();
  runApp(
    SessionProvider(
      notifier: SessionNotifier(),
      child: const MyApp(),
    ),
  );
}

/// 根组件：提供主题、本地化与路由，按登录态进入首页或登录页
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const _AppBootstrap(),
    );
  }
}

/// 启动引导：初始化登录态与 KwtClient，决定进入主界面或登录页
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = SettingsService();
    final loggedIn = await settings.isLoggedIn();
    if (loggedIn) {
      final serverUrl = await settings.getCurrentServerUrl();
      final client = await KwtClient.createPersisted(baseUrl: serverUrl);
      if (mounted) {
        SessionProvider.read(context).updateClient(client);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TabScaffold()),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

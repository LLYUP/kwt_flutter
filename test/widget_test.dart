// 基础冒烟测试：验证应用可以正常启动
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kwt_flutter/main.dart';

void main() {
  testWidgets('App smoke test - shows login or loading', (WidgetTester tester) async {
    // 预设空的 SharedPreferences（表示未登录状态）
    SharedPreferences.setMockInitialValues({});

    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 应用应该显示加载指示器（_AppBootstrap 正在初始化）
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

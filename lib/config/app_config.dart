import 'package:flutter/foundation.dart';

/// 应用环境配置
enum AppEnvironment {
  development,
  staging,
  production,
}

/// 网络环境配置
enum NetworkEnvironment {
  intranet('校园网环境', 'http://10.110.225.76'),
  internet('外网环境', 'http://222.187.129.200:51234');

  const NetworkEnvironment(this.displayName, this.baseUrl);
  
  final String displayName;
  final String baseUrl;
}

/// 应用配置管理
class AppConfig {
  // 私有构造函数
  AppConfig._();
  
  /// 当前应用环境
  static AppEnvironment get environment {
    if (kDebugMode) {
      return AppEnvironment.development;
    } else if (kProfileMode) {
      return AppEnvironment.staging;
    } else {
      return AppEnvironment.production;
    }
  }
  
  /// 应用基础信息
  static const String appName = '轻悦校园';
  static const String appVersion = '3.7.3';
  static const String appDescription = '轻悦校园教务系统查询应用';
  
  /// GitHub 配置（用于检查更新）
  static const String githubOwner = 'yuan-power-plus';
  static const String githubRepo = 'kwt_flutter';
  static String get githubApiUrl => 'https://api.github.com/repos/$githubOwner/$githubRepo';
  static String get githubReleasesUrl => '$githubApiUrl/releases';
  
  /// 网络配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  /// 缓存配置
  static const Duration cookieExpiration = Duration(days: 7);
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  
  /// 默认值配置
  static const String defaultTimeMode = '2AA072D3F1D747B98B4F5F84683493E5';
  
  /// 动态获取当前学期（根据月份推算）
  static String get defaultTerm {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (month >= 8) {
      // 8月(及之后)进入秋季学期
      return '$year-${year + 1}-1';
    } else if (month <= 1) {
      // 1月还在上一年的秋季学期
      return '${year - 1}-$year-1';
    } else {
      // 2月~7月是春季学期
      return '${year - 1}-$year-2';
    }
  }
  static const NetworkEnvironment defaultNetworkEnvironment = NetworkEnvironment.intranet;
  
  /// 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  /// UI 配置
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  
  /// 错误重试配置
  static const int maxRetryCount = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  /// 日志配置
  static bool get enableLogging => environment != AppEnvironment.production;
  static bool get enableCrashlytics => environment == AppEnvironment.production;
  
  /// 调试配置
  static bool get isDebug => environment == AppEnvironment.development;
  static bool get isRelease => environment == AppEnvironment.production;
  
  /// 功能开关配置
  static const Map<String, bool> featureFlags = {
    'enableDarkMode': true,
    'enableBiometric': false,
    'enablePushNotifications': false,
    'enableAnalytics': false,
  };
  
  /// 检查功能是否启用
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
  
  /// 获取网络环境配置
  static NetworkEnvironment getNetworkEnvironment(String key) {
    switch (key) {
      case 'internet':
        return NetworkEnvironment.internet;
      case 'intranet':
      default:
        return NetworkEnvironment.intranet;
    }
  }
  
  /// 获取环境特定配置
  static T getEnvironmentConfig<T>(
    T development,
    T staging,
    T production,
  ) {
    switch (environment) {
      case AppEnvironment.development:
        return development;
      case AppEnvironment.staging:
        return staging;
      case AppEnvironment.production:
        return production;
    }
  }
}

/// API 端点配置
class ApiEndpoints {
  // 认证相关
  static const String captcha = '/jsxsd/verifycode.servlet';
  static const String login = '/jsxsd/xk/LoginToXk';
  static const String forgotPassword = '/jsxsd/system/newResetPasswd.do';
  static const String profile = '/jsxsd/framework/xsMainV.htmlx';
  
  // 课表相关
  static const String personalTimetable = '/jsxsd/framework/mainV_index_loadkb.htmlx';
  static const String classTimetable = '/jsxsd/kbcx/kbxx_xzb_ifr';
  static const String searchClasses = '/jsxsd/kbcx/querySkbj';
  
  // 成绩相关
  static const String grades = '/jsxsd/kscj/cjcx_list';
  static const String gradesQuery = '/jsxsd/kscj/cjcx_query';
  static const String examLevel = '/jsxsd/kscj/djkscj_list';
  
  // 系统信息
  static const String termOptions = '/jsxsd/kscj/cjcx_query';
  static const String termOptionsFallback1 = '/jsxsd/kscj/cjcx_list';
  static const String termOptionsFallback2 = '/jsxsd/kbcx/kbxx_xzb';
  
  // 教材信息
  static const String textbooks = '/jsxsd/nxsjc/xsjcqr';
  
  // 教室课表
  static const String classroomTimetable = '/jsxsd/kbcx/kbxx_classroom_ifr';
  static const String searchClassrooms = '/jsxsd/view/kbxx/kbcx/jx0601_select.htmlx';

  // 培养方案
  static const String trainingPlan = '/jsxsd/pyfa/pyfa_query';

  // 选课结果查询
  static const String courseSelectionResults = '/jsxsd/xkgl/loadXsxkjgList';

  // 消息通知
  static const String messageNotifications = '/jsxsd/ggly/xxtz_query';

  // 选课中心
  static const String courseSelectionCenter = '/jsxsd/xsxk/xklc_list';
  static const String mzlistCheck = '/jsxsd/xsxk/mzlist.do';
  static const String enterCourseSelection = '/jsxsd/xsxk/newXsxkzx';
  static const String courseSelectionBottom = '/jsxsd/xsxk/selectBottom';
  static const String courseSelectionNum = '/jsxsd/xsxk/selectNum';
  static const String electiveCourseList = '/jsxsd/xsxkkc/xsxkGgxxkxk';
  static const String electiveCourseFormPage = '/jsxsd/xsxkkc/getGgxxk';
  static const String exitCourseSelection = '/jsxsd/xsxk/xsxk_exit';
  static const String selectCourse = '/jsxsd/xsxkkc/ggxxkxkOper';
  static const String deselectCourse = '/jsxsd/xsxkjg/xstkOper';
}
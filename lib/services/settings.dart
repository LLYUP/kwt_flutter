import 'package:shared_preferences/shared_preferences.dart';
import 'package:kwt_flutter/config/app_config.dart';

class SettingsService {
  static const _keyTerm = 'kwt.term';
  static const _keyStartDate = 'kwt.startDate';
  static const _keyLoggedIn = 'kwt.loggedIn';
  static const _keyStudentId = 'kwt.studentId';
  static const _keyStudentName = 'kwt.studentName';
  static const _keyNetworkEnvironment = 'kwt.networkEnvironment';
  static const _keyRememberPassword = 'kwt.rememberPassword';
  static const _keySavedPassword = 'kwt.savedPassword';
  static const _keyRememberedStudentId = 'kwt.rememberedStudentId';
  static const _keyCustomServerUrl = 'kwt.customServerUrl';

  /// 缓存的 SharedPreferences 实例
  static SharedPreferences? _prefs;

  /// 在 main() 中调用一次，预初始化 SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 获取缓存实例（若未初始化则自动获取）
  Future<SharedPreferences> get _sp async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveTerm(String term) async {
    final sp = await _sp;
    await sp.setString(_keyTerm, term);
  }

  Future<void> saveStartDate(String date) async {
    final sp = await _sp;
    await sp.setString(_keyStartDate, date);
  }

  Future<String?> getTerm() async {
    final sp = await _sp;
    return sp.getString(_keyTerm);
  }

  Future<String?> getStartDate() async {
    final sp = await _sp;
    return sp.getString(_keyStartDate);
  }

  Future<void> setLoggedIn(bool v) async {
    final sp = await _sp;
    await sp.setBool(_keyLoggedIn, v);
  }

  Future<bool> isLoggedIn() async {
    final sp = await _sp;
    return sp.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> saveStudentId(String id) async {
    final sp = await _sp;
    await sp.setString(_keyStudentId, id);
  }

  Future<String?> getStudentId() async {
    final sp = await _sp;
    return sp.getString(_keyStudentId);
  }

  Future<void> saveStudentName(String name) async {
    final sp = await _sp;
    await sp.setString(_keyStudentName, name);
  }

  Future<String?> getStudentName() async {
    final sp = await _sp;
    return sp.getString(_keyStudentName);
  }

  /// 清除本地登录态与基础账户信息
  Future<void> clearAuth() async {
    final sp = await _sp;
    await sp.setBool(_keyLoggedIn, false);
    await sp.remove(_keyStudentId);
    await sp.remove(_keyStudentName);
  }

  Future<void> saveNetworkEnvironment(String environment) async {
    final sp = await _sp;
    await sp.setString(_keyNetworkEnvironment, environment);
  }

  Future<String?> getNetworkEnvironment() async {
    final sp = await _sp;
    return sp.getString(_keyNetworkEnvironment);
  }

  Future<String> getCurrentServerUrl() async {
    final environment = await getNetworkEnvironment();
    if (environment == 'internet') {
      return NetworkEnvironment.internet.baseUrl;
    } else if (environment == 'custom') {
      return await getCustomServerUrl() ?? '';
    }
    return NetworkEnvironment.intranet.baseUrl;
  }

  Future<void> saveCustomServerUrl(String url) async {
    final sp = await _sp;
    await sp.setString(_keyCustomServerUrl, url);
  }

  Future<String?> getCustomServerUrl() async {
    final sp = await _sp;
    return sp.getString(_keyCustomServerUrl);
  }

  Future<void> setRememberPassword(bool remember) async {
    final sp = await _sp;
    await sp.setBool(_keyRememberPassword, remember);
    if (!remember) {
      await sp.remove(_keySavedPassword);
      await sp.remove(_keyRememberedStudentId);
    }
  }

  Future<bool> getRememberPassword() async {
    final sp = await _sp;
    return sp.getBool(_keyRememberPassword) ?? false;
  }

  Future<void> savePassword(String password) async {
    final sp = await _sp;
    await sp.setString(_keySavedPassword, password);
  }

  Future<String?> getSavedPassword() async {
    final sp = await _sp;
    return sp.getString(_keySavedPassword);
  }

  Future<void> saveRememberedStudentId(String studentId) async {
    final sp = await _sp;
    await sp.setString(_keyRememberedStudentId, studentId);
  }

  Future<String?> getRememberedStudentId() async {
    final sp = await _sp;
    return sp.getString(_keyRememberedStudentId);
  }
}

import 'dart:typed_data';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/services/api/auth_api.dart';
import 'package:kwt_flutter/services/api/timetable_api.dart';
import 'package:kwt_flutter/services/api/grade_api.dart';
import 'package:kwt_flutter/services/api/system_api.dart';
import 'package:kwt_flutter/services/api/textbook_api.dart';
import 'package:kwt_flutter/services/api/training_plan_api.dart';
import 'package:kwt_flutter/services/api/course_selection_api.dart';
import 'package:kwt_flutter/services/api/message_notification_api.dart';
import 'package:kwt_flutter/services/api/course_selection_center_api.dart';

export 'package:kwt_flutter/services/api/api_client.dart' show AuthExpiredException;

/// 轻悦校园后端客户端 (Facade)
class KwtClient {
  static const String defaultTimeMode = AppConfig.defaultTimeMode;

  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  late final TimetableApi _timetableApi;
  late final GradeApi _gradeApi;
  late final SystemApi _systemApi;
  late final TextbookApi _textbookApi;
  late final TrainingPlanApi _trainingPlanApi;
  late final CourseSelectionApi _courseSelectionApi;
  late final MessageNotificationApi _messageNotificationApi;
  late final CourseSelectionCenterApi _courseSelectionCenterApi;

  KwtClient._internal(this._apiClient) {
    _authApi = AuthApi(_apiClient);
    _timetableApi = TimetableApi(_apiClient);
    _gradeApi = GradeApi(_apiClient);
    _systemApi = SystemApi(_apiClient);
    _textbookApi = TextbookApi(_apiClient);
    _trainingPlanApi = TrainingPlanApi(_apiClient);
    _courseSelectionApi = CourseSelectionApi(_apiClient);
    _messageNotificationApi = MessageNotificationApi(_apiClient);
    _courseSelectionCenterApi = CourseSelectionCenterApi(_apiClient);
  }

  /// 创建带持久化 Cookie 存储的客户端
  static Future<KwtClient> createPersisted({required String baseUrl}) async {
    final apiClient = await ApiClient.createPersisted(baseUrl: baseUrl);
    return KwtClient._internal(apiClient);
  }

  String get baseUrl => _apiClient.baseUrl;

  /// 获取登录验证码图片
  Future<Uint8List> fetchCaptcha() => _authApi.fetchCaptcha();

  /// 登录教务系统
  Future<bool> login({
    required String userAccount,
    required String userPassword,
    required String verifyCode,
  }) {
    return _authApi.login(
      userAccount: userAccount,
      userPassword: userPassword,
      verifyCode: verifyCode,
    );
  }

  /// 找回密码/重置密码
  Future<Map<String, dynamic>> resetPassword({
    required String account,
    required String idCard,
    required String captcha,
  }) {
    return _authApi.resetPassword(
      account: account,
      idCard: idCard,
      captcha: captcha,
    );
  }

  /// 修改密码
  Future<Map<String, dynamic>> changePassword({
    required String account,
    required String oldPassword,
    required String newPassword,
  }) {
    return _authApi.changePassword(
      account: account,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// 退出登录
  Future<void> logout() => _authApi.logout();

  /// 清除本地 Cookie
  Future<void> clearCookies() => _apiClient.clearCookies();

  /// 拉取主页并尝试解析姓名等基本信息
  Future<Map<String, String>> fetchProfileInfo() => _systemApi.fetchProfileInfo();

  /// 从多处页面提取可用学期选项
  Future<List<String>> fetchTermOptions() => _systemApi.fetchTermOptions();


  /// 拉取个人课表（结构化实体）
  Future<List<TimetableEntry>> fetchPersonalTimetableStructured({
    required String date,
    required String timeMode,
    required String termId,
    bool showWeekend = false,
  }) {
    return _timetableApi.fetchPersonalTimetableStructured(
      date: date,
      timeMode: timeMode,
      termId: termId,
      showWeekend: showWeekend,
    );
  }

  /// 拉取班级课表（结构化实体）
  Future<List<TimetableEntry>> fetchClassTimetableStructured({
    required String term,
    required String timeMode,
    String department = '',
    String grade = '',
    String major = '',
    String classId = '',
    String className = '',
    String weekStart = '',
    String weekEnd = '',
    String weekdayStart = '',
    String weekdayEnd = '',
    String sectionStart = '',
    String sectionEnd = '',
  }) {
    return _timetableApi.fetchClassTimetableStructured(
      term: term,
      timeMode: timeMode,
      department: department,
      grade: grade,
      major: major,
      classId: classId,
      className: className,
      weekStart: weekStart,
      weekEnd: weekEnd,
      weekdayStart: weekdayStart,
      weekdayEnd: weekdayEnd,
      sectionStart: sectionStart,
      sectionEnd: sectionEnd,
    );
  }

  /// 拉取教室课表（结构化实体）
  Future<List<TimetableEntry>> fetchClassroomTimetableStructured({
    required String term,
    required String timeMode,
    String classroom = '',
    String classroomId = '',
    String department = '',
    String weekStart = '',
    String weekEnd = '',
    String weekdayStart = '',
    String weekdayEnd = '',
    String sectionStart = '',
    String sectionEnd = '',
  }) {
    return _timetableApi.fetchClassroomTimetableStructured(
      term: term,
      timeMode: timeMode,
      classroom: classroom,
      classroomId: classroomId,
      department: department,
      weekStart: weekStart,
      weekEnd: weekEnd,
      weekdayStart: weekdayStart,
      weekdayEnd: weekdayEnd,
      sectionStart: sectionStart,
      sectionEnd: sectionEnd,
    );
  }

  /// 搜索教室名称
  Future<List<Map<String, String>>> searchClassrooms({
    required String keyword,
  }) {
    return _timetableApi.searchClassrooms(keyword: keyword);
  }

  /// 搜索班级
  Future<List<Map<String, String>>> searchClasses({
    required String keyword,
    int maxRow = 10,
  }) {
    return _timetableApi.searchClasses(keyword: keyword, maxRow: maxRow);
  }

  /// 拉取课程成绩（原始二维表形式）
  Future<List<List<String>>> fetchGrades({
    required String term,
    String courseProperty = '',
    String courseAttr = '',
    String courseName = '',
    String display = 'all',
    String mold = '',
  }) {
    return _gradeApi.fetchGrades(
      term: term,
      courseProperty: courseProperty,
      courseAttr: courseAttr,
      courseName: courseName,
      display: display,
      mold: mold,
    );
  }

  /// 拉取课程成绩（结构化实体）
  Future<List<GradeEntry>> fetchGradesStructured({
    required String term,
    String courseProperty = '',
    String courseAttr = '',
    String courseName = '',
    String display = 'all',
    String mold = '',
  }) {
    return _gradeApi.fetchGradesStructured(
      term: term,
      courseProperty: courseProperty,
      courseAttr: courseAttr,
      courseName: courseName,
      display: display,
      mold: mold,
    );
  }

  /// 拉取等级考试成绩（结构化实体）
  Future<List<ExamLevelEntry>> fetchExamLevel() {
    return _gradeApi.fetchExamLevel();
  }

  /// 拉取教材信息
  Future<List<TextbookEntry>> fetchTextbooks({
    required String termId,
    String department = '',
    String courseName = '',
    String teacher = '',
    String schoolCode = '',
  }) {
    return _textbookApi.fetchTextbooks(
      termId: termId,
      department: department,
      courseName: courseName,
      teacher: teacher,
      schoolCode: schoolCode,
    );
  }

  /// 拉取培养方案
  Future<List<TrainingPlanEntry>> fetchTrainingPlan() {
    return _trainingPlanApi.fetchTrainingPlan();
  }

  /// 拉取选课结果
  Future<List<CourseSelectionEntry>> fetchCourseSelectionResults({
    required String termId,
    String cxsj = 'skjg',
  }) {
    return _courseSelectionApi.fetchCourseSelectionResults(
      termId: termId,
      cxsj: cxsj,
    );
  }

  /// 拉取消息通知
  Future<List<MessageNotificationEntry>> fetchMessageNotifications() {
    return _messageNotificationApi.fetchMessageNotifications();
  }

  /// 拉取选课轮次列表
  Future<List<CourseSelectionRoundEntry>> fetchCourseSelectionRounds() {
    return _courseSelectionCenterApi.fetchCourseSelectionRounds();
  }

  /// 选课前置检查
  Future<bool> checkMzlist() {
    return _courseSelectionCenterApi.checkMzlist();
  }

  /// 进入选课会话
  Future<void> enterCourseSelection(String roundId) {
    return _courseSelectionCenterApi.enterCourseSelection(roundId);
  }

  /// 动态获取通选课类别
  Future<List<MapEntry<String, String>>> fetchCourseCategories(String roundId) {
    return _courseSelectionCenterApi.fetchCourseCategories(roundId);
  }

  /// 获取可选公选课列表
  Future<List<ElectiveCourseEntry>> fetchElectiveCourses({
    required String roundId,
    String courseName = '',
    String teacher = '',
    String categoryId = '',
    String weekday = '',
    String startPeriod = '',
    String endPeriod = '',
    bool filterFull = false,
    bool filterConflict = true,
    bool filterRestricted = true,
    int page = 0,
    int pageSize = 50,
  }) {
    return _courseSelectionCenterApi.fetchElectiveCourses(
      roundId: roundId,
      courseName: courseName,
      teacher: teacher,
      categoryId: categoryId,
      weekday: weekday,
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      filterFull: filterFull,
      filterConflict: filterConflict,
      filterRestricted: filterRestricted,
      page: page,
      pageSize: pageSize,
    );
  }

  /// 退出选课
  Future<bool> exitCourseSelection() {
    return _courseSelectionCenterApi.exitCourseSelection();
  }

  /// 选课
  Future<Map<String, dynamic>> selectCourse({
    required String jx0404id,
    required String kcid,
  }) {
    return _courseSelectionCenterApi.selectCourse(jx0404id: jx0404id, kcid: kcid);
  }

  /// 退课
  Future<Map<String, dynamic>> deselectCourse({required String jx0404id}) {
    return _courseSelectionCenterApi.deselectCourse(jx0404id: jx0404id);
  }
}

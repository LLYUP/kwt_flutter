import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class CourseSelectionCenterApi {
  final ApiClient _client;

  CourseSelectionCenterApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  /// 获取选课轮次列表
  Future<List<CourseSelectionRoundEntry>> fetchCourseSelectionRounds() async {
    final response = await dio.get(
      ApiEndpoints.courseSelectionCenter,
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseCourseSelectionRounds(html);
  }

  /// 免听/免修前置检查
  Future<bool> checkMzlist() async {
    final response = await dio.post(
      ApiEndpoints.mzlistCheck,
      options: Options(
        headers: {
          'Referer': '$baseUrl/',
        },
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['success'] == true;
    }
    // 如果返回的是字符串 JSON
    if (data is String) {
      try {
        final json = jsonDecode(data);
        return json['success'] == true;
      } catch (_) {}
    }
    return false;
  }

  /// 进入选课（激活选课会话）
  Future<void> enterCourseSelection(String roundId) async {
    await dio.get(
      '${ApiEndpoints.enterCourseSelection}?jx0502zbid=$roundId',
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
  }

  /// 从公选课页面动态解析通选课类别
  Future<List<MapEntry<String, String>>> fetchCourseCategories(String roundId) async {
    final response = await dio.get(
      ApiEndpoints.electiveCourseFormPage,
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseCourseCategories(html);
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
  }) async {
    final queryParams = {
      'kcxx': courseName,
      'skls': teacher,
      'skxq': weekday,
      'skjc': startPeriod,
      'endJc': endPeriod,
      'sfym': filterFull.toString(),
      'sfct': filterConflict.toString(),
      'szjylb': categoryId,
      'sfxx': filterRestricted.toString(),
      'skfs': '',
    };

    final form = FormData.fromMap({
      'sEcho': '1',
      'iColumns': '12',
      'sColumns': '',
      'iDisplayStart': page * pageSize,
      'iDisplayLength': pageSize,
      'mDataProp_0': 'kch',
      'mDataProp_1': 'kcmc',
      'mDataProp_2': 'xf',
      'mDataProp_3': 'skls',
      'mDataProp_4': 'sksj',
      'mDataProp_5': 'skdd',
      'mDataProp_6': 'xqmc',
      'mDataProp_7': 'xkrs',
      'mDataProp_8': 'syrs',
      'mDataProp_9': 'ctsm',
      'mDataProp_10': 'szkcflmc',
      'mDataProp_11': 'czOper',
    });

    final response = await dio.post(
      ApiEndpoints.electiveCourseList,
      queryParameters: queryParams,
      data: form,
      options: Options(
        headers: {
          'Referer': '$baseUrl${ApiEndpoints.courseSelectionBottom}?jx0502zbid=$roundId&sfylxkstr=',
        },
      ),
    );

    final data = response.data;
    Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String) {
      json = jsonDecode(data);
    } else {
      return [];
    }

    final list = json['aaData'] as List<dynamic>? ?? [];
    return list.map((item) => ElectiveCourseEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// 退出选课
  Future<bool> exitCourseSelection() async {
    final response = await dio.get(
      ApiEndpoints.exitCourseSelection,
      queryParameters: {'jx0404id': '1'},
      options: Options(
        headers: {'Referer': '$baseUrl/'},
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['success'] == true;
    }
    if (data is String) {
      try {
        final json = jsonDecode(data);
        return json['success'] == true;
      } catch (_) {}
    }
    return false;
  }

  /// 选课操作
  Future<Map<String, dynamic>> selectCourse({
    required String jx0404id,
    required String kcid,
  }) async {
    final response = await dio.get(
      ApiEndpoints.selectCourse,
      queryParameters: {
        'kcid': kcid,
        'cfbs': 'null',
        'jx0404id': jx0404id,
        'xkzy': '',
        'trjf': '',
      },
      options: Options(
        headers: {'Referer': '$baseUrl/'},
      ),
    );
    return _parseOperResponse(response.data);
  }

  /// 退课操作
  Future<Map<String, dynamic>> deselectCourse({
    required String jx0404id,
  }) async {
    final response = await dio.get(
      ApiEndpoints.deselectCourse,
      queryParameters: {
        'jx0404id': jx0404id,
      },
      options: Options(
        headers: {'Referer': '$baseUrl/'},
      ),
    );
    return _parseOperResponse(response.data);
  }

  Map<String, dynamic> _parseOperResponse(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {'success': false, 'message': '未知响应'};
  }
}

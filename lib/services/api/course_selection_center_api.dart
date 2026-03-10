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

  String _formPage = ApiEndpoints.electiveCourseFormPage;
  String _listApi = ApiEndpoints.electiveCourseList;
  String _selectApi = ApiEndpoints.selectCourse;
  String _deselectApi = ApiEndpoints.deselectCourse;

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

  /// 进入选课（激活选课会话）并动态解析该轮次的真实接口
  Future<void> enterCourseSelection(String roundId) async {
    await dio.get(
      '${ApiEndpoints.enterCourseSelection}?jx0502zbid=$roundId',
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );

    // 尝试动态解析该轮次对应的接口（如必修课、公共课的不同路径）
    // 每次进入新轮次都会刷新这些接口
    _formPage = ApiEndpoints.electiveCourseFormPage;
    _listApi = ApiEndpoints.electiveCourseList;
    _selectApi = ApiEndpoints.selectCourse;
    _deselectApi = ApiEndpoints.deselectCourse;

    try {
      final bottomRes = await dio.get(
        '${ApiEndpoints.courseSelectionBottom}?jx0502zbid=$roundId&sfylxkstr=',
        options: ResponseHelper.createHtmlRequestOptions(baseUrl),
      );
      final bottomHtml = ResponseHelper.decodeAndValidateHtml(bottomRes);

      // 匹配完整的 src="..." 路径，防止丢失参数或匹配错分支
      final formPageMatch = RegExp(r'src="(/jsxsd/xsxkkc/get[a-zA-Z0-9_]+[^"]*)"').firstMatch(bottomHtml);
      if (formPageMatch != null) {
        String fullSrc = formPageMatch.group(1)!;
        // 如果包含 &amp; 需要解码
        fullSrc = fullSrc.replaceAll('&amp;', '&');
        
        // 分离路径和参数
        final parts = fullSrc.split('?');
        _formPage = parts[0];
        
        final queryParams = <String, dynamic>{'jx0502zbid': roundId};
        if (parts.length > 1) {
          final params = parts[1].split('&');
          for (final p in params) {
            final kv = p.split('=');
            if (kv.length == 2 && kv[0] != 'jx0502zbid') {
              queryParams[kv[0]] = kv[1];
            }
          }
        }

        // 请求该嵌页以提取真实的查课/选课接口
        final formRes = await dio.get(
          _formPage,
          queryParameters: queryParams,
          options: ResponseHelper.createHtmlRequestOptions(baseUrl),
        );
        final formHtml = ResponseHelper.decodeAndValidateHtml(formRes);

        // 匹配真实的查课列表接口。注意，不同轮次的名字可能叫 xsxkBxxk, xsxkXxxk, xsxkGgxxkxk 等
        final listMatch = RegExp(r'url\s*:\s*["' + "'" + r'](/jsxsd/xsxkkc/xsxk[a-zA-Z0-9_]+)["' + "'" + r']').firstMatch(formHtml);
        final listFallbackMatch = RegExp(r'/jsxsd/xsxkkc/xsxk[a-zA-Z0-9_]+').firstMatch(formHtml);
        
        if (listMatch != null) {
          _listApi = listMatch.group(1)!;
        } else if (listFallbackMatch != null) {
          _listApi = listFallbackMatch.group(0)!;
        }

        final selectMatch = RegExp(r'/jsxsd/xsxkkc/[a-zA-Z0-9_]+Oper').firstMatch(formHtml);
        if (selectMatch != null) {
          _selectApi = selectMatch.group(0)!;
        }

        final deselectMatch = RegExp(r'/jsxsd/xsxkjg/[a-zA-Z0-9_]+Oper').firstMatch(formHtml);
        if (deselectMatch != null) {
          _deselectApi = deselectMatch.group(0)!;
        }
      }
    } catch (_) {
      // 解析失败则保留默认的公选课接口
    }
  }

  /// 从公选课页面动态解析通选课类别
  Future<List<MapEntry<String, String>>> fetchCourseCategories(String roundId) async {
    final response = await dio.get(
      _formPage,
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
      _listApi,
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
      _selectApi,
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
      _deselectApi,
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

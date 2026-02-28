import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class GradeApi {
  final ApiClient _client;

  GradeApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  Future<List<List<String>>> fetchGrades({
    required String term,
    String courseProperty = '',
    String courseAttr = '',
    String courseName = '',
    String display = 'all',
    String mold = '',
  }) async {
    final form = FormData.fromMap({
      'kksj': term,
      'kcxz': courseProperty,
      'kcsx': courseAttr,
      'kcmc': courseName,
      'xsfs': display,
      'mold': mold,
    });
    final response = await dio.post(
      '/kscj/cjcx_list',
      data: form,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeHtmlResponse(response);
    return KwtParser.extractTableRows(html);
  }

  Future<List<GradeEntry>> fetchGradesStructured({
    required String term,
    String courseProperty = '',
    String courseAttr = '',
    String courseName = '',
    String display = 'all',
    String mold = '',
  }) async {
    final form = FormData.fromMap({
      'kksj': term,
      'kcxz': courseProperty,
      'kcsx': courseAttr,
      'kcmc': courseName,
      'xsfs': display,
      'mold': mold,
    });
    final response = await dio.post(
      '/kscj/cjcx_list',
      data: form,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseGrades(html);
  }

  Future<List<ExamLevelEntry>> fetchExamLevel() async {
    final response = await dio.get(
      '/kscj/djkscj_list',
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseExamLevel(html);
  }
}

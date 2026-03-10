import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class CourseSelectionApi {
  final ApiClient _client;

  CourseSelectionApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  Future<List<CourseSelectionEntry>> fetchCourseSelectionResults({
    required String termId,
    String cxsj = 'skjg', // "skjg" for selected courses, "tkjg" for dropped courses
  }) async {
    final form = FormData.fromMap({
      'xnxqid': termId,
      'cxsj': cxsj,
    });
    
    final response = await dio.post(
      ApiEndpoints.courseSelectionResults,
      data: form,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseCourseSelection(html);
  }
}

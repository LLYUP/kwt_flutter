import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class TextbookApi {
  final ApiClient _client;

  TextbookApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  Future<List<TextbookEntry>> fetchTextbooks({
    required String termId,
    String department = '',
    String courseName = '',
    String teacher = '',
    String schoolCode = '',
  }) async {
    final form = FormData.fromMap({
      'xnxqid': termId,
      'kkyx': department,
      'kcmc': courseName,
      'skjs': teacher,
      'xxdm': schoolCode,
    });
    
    final response = await dio.post(
      ApiEndpoints.textbooks,
      data: form,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseTextbooks(html);
  }
}

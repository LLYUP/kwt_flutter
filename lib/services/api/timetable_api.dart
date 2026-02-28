import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class TimetableApi {
  final ApiClient _client;

  TimetableApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;


  Future<List<TimetableEntry>> fetchPersonalTimetableStructured({
    required String date,
    required String timeMode,
    required String termId,
    bool showWeekend = false,
  }) async {
    final response = await dio.get(
      '/jsxsd/framework/mainV_index_loadkb.htmlx',
      queryParameters: {
        'rq': date,
        'sjmsValue': timeMode,
        'xnxqid': termId,
        'xswk': showWeekend.toString(),
      },
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parsePersonalTimetableStructured(html);
  }

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
  }) async {
    final form = FormData.fromMap({
      'xnxqh': term,
      'kbjcmsid': timeMode,
      'skyx': department,
      'sknj': grade,
      'skzy': major,
      'skbjid': classId,
      'skbj': className,
      'zc1': weekStart,
      'zc2': weekEnd,
      'skxq1': weekdayStart,
      'skxq2': weekdayEnd,
      'jc1': sectionStart,
      'jc2': sectionEnd,
    });
    final response = await dio.post(
      '/jsxsd/kbcx/kbxx_xzb_ifr',
      data: form,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeHtmlResponse(response);
    return KwtParser.parseClassTimetableStructured(html);
  }

  Future<List<Map<String, String>>> searchClasses({
    required String keyword,
    int maxRow = 10,
  }) async {
    final response = await dio.post(
      '/jsxsd/kbcx/querySkbj',
      data: FormData.fromMap({'skbj': keyword, 'maxRow': maxRow.toString()}),
      options: Options(
        headers: {
          'Referer': '$baseUrl/',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        responseType: ResponseType.json,
        validateStatus: (s) => true,
      ),
    );
    final data = response.data;
    if (data is Map && data['list'] is List) {
      final List list = data['list'];
      return list.map<Map<String, String>>((e) => {
            'id': (e['xx04id'] ?? '').toString(),
            'name': (e['bj'] ?? '').toString(),
          }).toList();
    }
    return [];
  }
}

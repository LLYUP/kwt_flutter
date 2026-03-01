import 'package:dio/dio.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class SystemApi {
  final ApiClient _client;

  SystemApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  Future<Map<String, String>> fetchProfileInfo() async {
    try {
      final res = await dio.get(
        ApiEndpoints.profile,
        options: ResponseHelper.createHtmlRequestOptions(baseUrl),
      );
      final html = ResponseHelper.decodeHtmlResponse(res);
      return KwtParser.parseProfileInfo(html);
    } catch (_) {
      return {'name': ''};
    }
  }

  Future<List<String>> fetchTermOptions() async {
    Future<List<String>> tryGet(String path) async {
      try {
        final res = await dio.get(
          path,
          options: ResponseHelper.createHtmlRequestOptions(baseUrl),
        );
        final html = ResponseHelper.decodeHtmlResponse(res);
        return KwtParser.parseTermOptions(html);
      } catch (_) {
        return [];
      }
    }

    var terms = await tryGet(ApiEndpoints.termOptions);
    if (terms.isEmpty) {
      terms = await tryGet(ApiEndpoints.termOptionsFallback1);
    }
    if (terms.isEmpty) {
      terms = await tryGet(ApiEndpoints.termOptionsFallback2);
    }
    int termKey(String t) {
      final m = RegExp(r'^(\d{4})-\d{4}-(\d)').firstMatch(t);
      if (m != null) {
        final y = int.tryParse(m.group(1) ?? '0') ?? 0;
        final s = int.tryParse(m.group(2) ?? '0') ?? 0;
        return y * 10 + s;
      }
      return 0;
    }
    terms.sort((a, b) => termKey(b).compareTo(termKey(a)));
    return terms;
  }
}

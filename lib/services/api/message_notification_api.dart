import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class MessageNotificationApi {
  final ApiClient _client;

  MessageNotificationApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  Future<List<MessageNotificationEntry>> fetchMessageNotifications() async {
    final response = await dio.get(
      ApiEndpoints.messageNotifications,
      options: ResponseHelper.createHtmlRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeAndValidateHtml(response);
    return KwtParser.parseMessageNotifications(html);
  }
}

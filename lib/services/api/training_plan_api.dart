import 'package:dio/dio.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/parsers/kwt_parser.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class TrainingPlanApi {
  final ApiClient _apiClient;

  TrainingPlanApi(this._apiClient);

  Dio get dio => _apiClient.dio;
  String get baseUrl => _apiClient.baseUrl;

  /// 拉取培养方案列表
  Future<List<TrainingPlanEntry>> fetchTrainingPlan() async {
    final response = await dio.get(
      ApiEndpoints.trainingPlan,
      options: ResponseHelper.createFormRequestOptions(baseUrl),
    );
    final html = ResponseHelper.decodeHtmlResponse(response);
    return KwtParser.parseTrainingPlan(html);
  }
}

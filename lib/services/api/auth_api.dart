import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  String _b64(String? s) => base64Encode(utf8.encode(s ?? ''));

  Future<Uint8List> fetchCaptcha() async {
    final response = await dio.get(
      '/jsxsd/verifycode.servlet',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Referer': '$baseUrl/',
          'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        },
      ),
    );
    return Uint8List.fromList((response.data as List<int>));
  }

  Future<bool> login({
    required String userAccount,
    required String userPassword,
    required String verifyCode,
  }) async {
    final encoded = '${_b64(userAccount)}%%%${_b64(userPassword)}';
    final params = {
      'loginMethod': 'LoginToXk',
      'userAccount': userAccount,
      'userPassword': userPassword,
      'RANDOMCODE': verifyCode,
      'encoded': encoded,
    };
    final response = await dio.post(
      '/jsxsd/xk/LoginToXk',
      queryParameters: params,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {
          'Referer': '$baseUrl/',
        },
        validateStatus: (code) => true,
      ),
    );
    final html = ResponseHelper.decodeHtmlResponse(response);
    final failed = RegExp(r'(验证码|密码错误|失败|不存在|错误)', caseSensitive: false).hasMatch(html);
    return !failed;
  }

  Future<void> logout() async {
    try {
      await dio.post(
        '/jsxsd/xk/LoginToXk',
        queryParameters: {'method': 'exit'},
        options: Options(
          headers: {'Referer': '$baseUrl/'},
          validateStatus: (s) => true,
        ),
      );
    } catch (_) {}
  }
}

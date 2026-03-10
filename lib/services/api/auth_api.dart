import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kwt_flutter/services/api/api_client.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/utils/response_helper.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  String get baseUrl => _client.baseUrl;
  Dio get dio => _client.dio;

  String _b64(String? s) => base64Encode(utf8.encode(s ?? ''));

  Future<Uint8List> fetchCaptcha() async {
    final response = await dio.get(
      ApiEndpoints.captcha,
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
      ApiEndpoints.login,
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

  Future<Map<String, dynamic>> resetPassword({
    required String account,
    required String idCard,
    required String captcha,
  }) async {
    final encoded = base64Encode(utf8.encode(account));
    final params = {
      'encoded': encoded,
      'passwordfindmethod': '0',
      'account': account,
      'sfzjh': idCard,
      'RANDOMCODE': captcha,
      'pwdAnswer1': '',
      'pwdAnswer2': '',
      'pwdAnswer3': '',
      'pwdAnswer4': '',
      'email': '',
    };
    
    try {
      final response = await dio.post(
        ApiEndpoints.forgotPassword,
        queryParameters: {'randomCode': captcha},
        data: params,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Referer': '$baseUrl/'},
          validateStatus: (status) => true,
        ),
      );
      
      final html = ResponseHelper.decodeHtmlResponse(response);
      
      final bool isSuccess = html.contains('密码重置成功') || 
                             html.contains('重置成功') || 
                             html.contains('success: true') ||
                             html.contains('success":true') ||
                             html.contains('success": true');
      
      String msg = '';
      
      // Try extracting message via regex because unquoted keys like {message: "..."} 
      final msgMatch = RegExp('message\\s*:\\s*["\']([^"\']+)["\']').firstMatch(html) 
                    ?? RegExp('"message"\\s*:\\s*["\']([^"\']+)["\']').firstMatch(html);
                    
      if (msgMatch != null) {
        msg = msgMatch.group(1)!;
      } else if (isSuccess) {
        msg = '密码已成功重置';
      } else {
        final alertMatch = RegExp(r"alert\(['\u0022](.*?)['\u0022]\)").firstMatch(html);
        if (alertMatch != null) {
          msg = alertMatch.group(1)!;
        } else {
          msg = html.contains('验证') ? '验证码错误、账号或身份证号不存在' : '密码重置请求已发送，请检查结果。';
        }
      }

      return {'success': isSuccess, 'message': msg};
    } catch (e) {
      print('--- [DEBUG] resetPassword HTTP catch exception: $e ---');
      return {'success': false, 'message': '网络请求失败: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await dio.post(
        ApiEndpoints.login,
        queryParameters: {'method': 'exit'},
        options: Options(
          headers: {'Referer': '$baseUrl/'},
          validateStatus: (s) => true,
        ),
      );
    } catch (_) {}
  }
}

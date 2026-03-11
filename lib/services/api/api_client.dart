import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';


class AuthExpiredException implements Exception {
  AuthExpiredException([this.message = '登录已失效']);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  final Dio dio;
  final CookieJar cookieJar;
  final String baseUrl;

  ApiClient({
    Dio? dio,
    CookieJar? cookieJar,
    required this.baseUrl,
  })  : cookieJar = cookieJar ?? CookieJar(),
        dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl, 
          followRedirects: true,
          connectTimeout: AppConfig.connectionTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        )) {
    this.dio.interceptors.add(CookieManager(this.cookieJar));
    this.dio.interceptors.add(_buildUnifiedInterceptor());
  }

  static Future<ApiClient> createPersisted({required String baseUrl}) async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = Directory('${dir.path}/cookies');
    if (!cookieDir.existsSync()) cookieDir.createSync(recursive: true);
    final jar = PersistCookieJar(storage: FileStorage(cookieDir.path));
    return ApiClient(cookieJar: jar, baseUrl: baseUrl);
  }

  bool _htmlLooksLikeLoginPage(String html) {
    final lc = html.toLowerCase();
    if (html.contains('请先登录系统')) return true;
    final hasLoginFields = lc.contains('useraccount') && lc.contains('userpassword');
    final hasCaptcha = lc.contains('/verifycode.servlet') || lc.contains('randomcode');
    if (hasLoginFields) return true;
    if (hasCaptcha && lc.contains('login')) return true;
    return false;
  }

  Interceptor _buildUnifiedInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('[DIO][REQ] ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[DIO][RES] ${response.statusCode} ${response.requestOptions.uri}');
        }
        try {
          final contentType = (response.headers['content-type']?.join(';') ?? '').toLowerCase();
          final looksHtml = contentType.contains('text/html') || contentType.contains('text/plain');
          if (looksHtml) {
            String html = '';
            final data = response.data;
            if (data is List<int>) {
              html = utf8.decode(data, allowMalformed: true);
            } else if (data is Uint8List) {
              html = utf8.decode(data, allowMalformed: true);
            } else if (data is String) {
              html = data;
            }
            if (html.isNotEmpty && _htmlLooksLikeLoginPage(html)) {
              return handler.reject(DioException(
                requestOptions: response.requestOptions,
                error: AuthExpiredException('登录已失效，请重新登录'),
                type: DioExceptionType.badResponse,
                response: response,
              ));
            }
          }
        } catch (_) {}
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[DIO][ERR] ${error.type} ${error.requestOptions.uri}: ${error.message}');
        }
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          handler.next(DioException(
            requestOptions: error.requestOptions,
            type: error.type,
            error: '请求超时，请稍后重试',
          ));
          return;
        }
        if (error.type == DioExceptionType.unknown) {
          handler.next(DioException(
            requestOptions: error.requestOptions,
            type: error.type,
            error: '网络连接失败，请检查网络设置',
          ));
          return;
        }
        handler.next(error);
      },
    );
  }

  Future<void> clearCookies() async {
    try {
      await cookieJar.deleteAll();
    } catch (_) {}
  }
}

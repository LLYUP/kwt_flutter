import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/kwt_client.dart';

class ResponseHelper {
  static String decodeHtmlResponse(Response response) {
    final bytes = Uint8List.fromList((response.data as List<int>));
    return utf8.decode(bytes, allowMalformed: true);
  }
  
  static String decodeAndValidateHtml(Response response) {
    final html = decodeHtmlResponse(response);
    
    if (_htmlLooksLikeLoginPage(html)) {
      throw AuthExpiredException('登录已失效，请重新登录');
    }
    
    return html;
  }
  
  static bool _htmlLooksLikeLoginPage(String html) {
    final lc = html.toLowerCase();
    if (html.contains('请先登录系统')) return true;
    final hasLoginFields = lc.contains('useraccount') && lc.contains('userpassword');
    final hasCaptcha = lc.contains('/verifycode.servlet') || lc.contains('randomcode');
    if (hasLoginFields) return true;
    if (hasCaptcha && lc.contains('login')) return true;
    return false;
  }
  
  static Options createHtmlRequestOptions(String baseUrl, {
    Map<String, String>? additionalHeaders,
  }) {
    final headers = {
      'Referer': '$baseUrl/',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
      ...?additionalHeaders,
    };
    
    return Options(
      responseType: ResponseType.bytes,
      headers: headers,
    );
  }
  
  static Options createFormRequestOptions(String baseUrl) {
    return Options(
      responseType: ResponseType.bytes,
      headers: {
        'Referer': '$baseUrl/',
        'Content-Type': 'multipart/form-data',
      },
    );
  }
}
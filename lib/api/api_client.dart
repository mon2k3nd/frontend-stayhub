import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  class ApiClient {
    // Android Emulator: 10.0.2.2 | Real device: --dart-define=API_BASE_URL=http://192.168.x.x:8089
    static const String _baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8089',
    );

    static final ApiClient _instance = ApiClient._internal();
    factory ApiClient() => _instance;
    late final Dio _dio;
    final FlutterSecureStorage _storage = const FlutterSecureStorage();

    ApiClient._internal() {
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ));
      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true, responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ));
      }
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) await clearToken();
          return handler.next(e);
        },
      ));
    }

    Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async =>
        _parse(await _dio.get(path, queryParameters: params));
    Future<Map<String, dynamic>> post(String path, dynamic data) async =>
        _parse(await _dio.post(path, data: data));
    Future<Map<String, dynamic>> put(String path, dynamic data) async =>
        _parse(await _dio.put(path, data: data));
    Future<void> delete(String path) async => await _dio.delete(path);
    Future<Map<String, dynamic>> uploadFile(String path, FormData formData) async =>
        _parse(await _dio.post(path, data: formData,
            options: Options(contentType: 'multipart/form-data')));

    Map<String, dynamic> _parse(Response res) {
      final d = res.data;
      return d is Map<String, dynamic> ? d : {'data': d};
    }

    Future<void> saveToken(String token) async =>
        _storage.write(key: 'access_token', value: token);

    Future<void> clearToken() async {
      for (final k in ['access_token','user_id','user_role','user_name','plan_type','phone_number','user_email']) {
        await _storage.delete(key: k);
      }
    }

    static String parseError(dynamic e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) return data['message'].toString();
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return 'Kết nối quá thời gian chờ. Vui lòng thử lại!';
          case DioExceptionType.connectionError:
            return 'Không thể kết nối máy chủ. Kiểm tra mạng!';
          default: return 'Lỗi kết nối. Vui lòng thử lại!';
        }
      }
      return 'Đã xảy ra lỗi. Vui lòng thử lại!';
    }
  }
  
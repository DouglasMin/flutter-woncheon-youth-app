import 'package:dio/dio.dart';
import 'package:woncheon_youth/core/api/auth_event_bus.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/core/storage/secure_storage.dart';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_TokenRefreshInterceptor(_storage, _dio));
  }

  final SecureStorageService _storage;
  late final Dio _dio;

  Dio get dio => _dio;
}

/// Uses QueuedInterceptor so concurrent 401s are serialized —
/// only one refresh fires at a time.
class _TokenRefreshInterceptor extends QueuedInterceptor {
  _TokenRefreshInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryResponse = await _retry(err.requestOptions);
          return handler.resolve(retryResponse);
        }
        await _storage.clearAll();
        AuthEventBus.instance.emit(AuthEvent.forceLogout);
      } on Object {
        await _storage.clearAll();
        AuthEventBus.instance.emit(AuthEvent.forceLogout);
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Use a separate Dio instance to avoid interceptor recursion
      final response = await Dio(
        BaseOptions(baseUrl: AppConstants.apiBaseUrl),
      ).post<Map<String, dynamic>>(
        Endpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

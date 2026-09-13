import 'package:dio/dio.dart';

import '../../core/env.dart';
import 'token_service.dart';

/// dio configurado com a base da api e o jwt (token de acesso, vida longa,
/// sem refresh) no header. quando da 401 a sessao e limpa; a proxima
/// navegacao cai no redirect do go_router e manda pro login.
class ApiClient {
  ApiClient(this._tokenService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenService.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenService _tokenService;

  Dio get dio => _dio;
}

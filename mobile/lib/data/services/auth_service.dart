import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../local/dono_cache.dart';
import '../models/auth_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  AuthService(this._tokenService) : _client = ApiClient(_tokenService);

  final TokenService _tokenService;
  final ApiClient _client;

  Future<LoginResponse> login(String siape, String senha) async {
    try {
      final res = await _client.dio.post(
        '/api/usuarios/login/',
        data: LoginRequest(siape: siape, senha: senha).toJson(),
      );
      final login = LoginResponse.fromJson(res.data as Map<String, dynamic>);
      await trocarDonoDoCache(siape);
      await _tokenService.saveSession(login);
      return login;
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  /// nao apaga o banco: sem rede nao da pra logar de novo, e perder o cache
  /// deixaria o app inutilizavel offline.
  Future<void> logout() => _tokenService.clear();
}

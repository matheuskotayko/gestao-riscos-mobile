import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../local/dono_cache.dart';
import '../models/auth_model.dart';
import '../models/usuario_model.dart';
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
      await _tokenService.salvarCredencialOffline(siape, senha, login);
      return login;
    } on DioException catch (e) {
      // servidor respondeu (credencial errada, erro interno): erro dele mesmo
      if (e.response != null) throw ApiError.fromDio(e);
      return _entrarOffline(siape, senha, e);
    }
  }

  /// api muda: revalida contra a credencial do ultimo login neste aparelho.
  Future<LoginResponse> _entrarOffline(
    String siape,
    String senha,
    DioException erroDeRede,
  ) async {
    final cred = await _tokenService.credencialOffline();
    // sem credencial desse siape aqui nao da pra provar quem e — o problema
    // que o usuario precisa resolver continua sendo a conexao
    if (cred == null || cred.siape != siape) throw ApiError.fromDio(erroDeRede);
    if (!cred.confere(siape, senha)) throw ApiError('SIAPE ou senha inválidos.');

    final login = LoginResponse(
      token: cred.token,
      usuario: UsuarioModel.fromJson(cred.usuario),
    );
    await trocarDonoDoCache(siape);
    await _tokenService.saveSession(login);
    return login;
  }

  /// nao apaga o banco: sem rede nao da pra logar de novo, e perder o cache
  /// deixaria o app inutilizavel offline.
  Future<void> logout() => _tokenService.clear();
}

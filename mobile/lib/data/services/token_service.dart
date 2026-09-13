import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_model.dart';
import '../models/usuario_model.dart';

/// sessao persistida. o backend manda um jwt de acesso com vida longa: na
/// pratica o token nunca expira e nao tem refresh — so guarda ele e manda
/// no header de toda requisicao.
class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyUsuario = 'usuario';

  Future<void> saveSession(LoginResponse res) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: res.token),
      _storage.write(
        key: _keyUsuario,
        value: jsonEncode(res.usuario.toStorageJson()),
      ),
    ]);
  }

  Future<void> updateUsuario(UsuarioModel usuario) => _storage.write(
    key: _keyUsuario,
    value: jsonEncode(usuario.toStorageJson()),
  );

  Future<String?> getToken() => _lerSeguro(_keyToken);

  Future<bool> hasToken() async {
    final t = await _lerSeguro(_keyToken);
    return t != null && t.isNotEmpty;
  }

  Future<UsuarioModel?> getUsuario() async {
    final raw = await _lerSeguro(_keyUsuario);
    if (raw == null || raw.isEmpty) return null;
    return UsuarioModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// le do secure storage tolerando dado cifrado ilegivel (tipo quando a
  /// chave do android keystore fica dessincronizada depois de reinstalar
  /// o app). sem isso, uma falha de decriptacao no redirect do go_router
  /// trava a tela preta pra sempre em vez de so cair no login.
  Future<String?> _lerSeguro(String chave) async {
    try {
      return await _storage.read(key: chave);
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> clear() => _storage.deleteAll();
}

extension _UsuarioStorage on UsuarioModel {
  /// guarda so o necessario pra reconstruir o UsuarioModel depois (mesmas
  /// chaves do json da api, pra reaproveitar o UsuarioModel.fromJson).
  Map<String, dynamic> toStorageJson() => {
    'uuid': uuid,
    'id': id,
    'siape': siape,
    'nome': nome,
    'email': email,
    'is_superuser': isSuperuser,
    'ativo': ativo,
    'cargo': cargo,
    'sem_equipe_desde': semEquipeDesde?.toIso8601String(),
    'setores': setores
        .map(
          (s) => {
            'id': s.id,
            'nome': s.nome,
            'sigla': s.sigla,
            'sigla_centro': s.siglaCentro,
            'nome_centro': s.nomeCentro,
            'tipo_unidade': s.tipoUnidade,
            'fonte_oficial': s.fonteOficial,
            'ativo': s.ativo,
            'label_curto': s.labelCurto,
            'label_completo': s.labelCompleto,
          },
        )
        .toList(),
  };
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/credencial_offline.dart';
import '../models/auth_model.dart';
import '../models/usuario_model.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'token';
  static const _keyUsuario = 'usuario';
  static const _keyCredencial = 'credencial_offline';
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
  Future<void> salvarCredencialOffline(
    String siape,
    String senha,
    LoginResponse res,
  ) => _storage.write(
    key: _keyCredencial,
    value: jsonEncode(
      CredencialOffline.nova(
        siape: siape,
        senha: senha,
        token: res.token,
        usuario: res.usuario.toStorageJson(),
      ).toJson(),
    ),
  );
  Future<CredencialOffline?> credencialOffline() async {
    final raw = await _lerSeguro(_keyCredencial);
    if (raw == null || raw.isEmpty) return null;
    return CredencialOffline.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

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

  Future<String?> _lerSeguro(String chave) async {
    try {
      return await _storage.read(key: chave);
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsuario);
  }
}

extension _UsuarioStorage on UsuarioModel {
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

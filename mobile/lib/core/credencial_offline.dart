import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _aleatorio = Random.secure();

class CredencialOffline {
  const CredencialOffline({
    required this.siape,
    required this.salt,
    required this.hash,
    required this.token,
    required this.usuario,
  });
  final String siape;
  final String salt;
  final String hash;
  final String token;
  final Map<String, dynamic> usuario;
  factory CredencialOffline.nova({
    required String siape,
    required String senha,
    required String token,
    required Map<String, dynamic> usuario,
  }) {
    final salt = base64Encode(
      List.generate(16, (_) => _aleatorio.nextInt(256)),
    );
    return CredencialOffline(
      siape: siape,
      salt: salt,
      hash: derivarHash(senha, salt),
      token: token,
      usuario: usuario,
    );
  }
  bool confere(String siape, String senha) =>
      siape == this.siape && derivarHash(senha, salt) == hash;
  Map<String, dynamic> toJson() => {
    'siape': siape,
    'salt': salt,
    'hash': hash,
    'token': token,
    'usuario': usuario,
  };
  factory CredencialOffline.fromJson(Map<String, dynamic> json) =>
      CredencialOffline(
        siape: json['siape'] as String,
        salt: json['salt'] as String,
        hash: json['hash'] as String,
        token: json['token'] as String,
        usuario: json['usuario'] as Map<String, dynamic>,
      );
}

String derivarHash(String senha, String salt, {int iteracoes = 10000}) {
  final hmac = Hmac(sha256, utf8.encode(senha));
  var bloco = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
  final resultado = [...bloco];
  for (var i = 1; i < iteracoes; i++) {
    bloco = hmac.convert(bloco).bytes;
    for (var j = 0; j < resultado.length; j++) {
      resultado[j] ^= bloco[j];
    }
  }
  return base64Encode(resultado);
}

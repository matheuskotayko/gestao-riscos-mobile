import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _aleatorio = Random.secure();

/// o que permite revalidar o login sem servidor. a senha nunca e guardada:
/// fica so o hash derivado dela, com salt proprio. o secure storage ja cifra
/// tudo isso — o hash e a camada de baixo, pra quem conseguir ler o arquivo.
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

  /// confere a senha digitada contra o hash guardado. so vale pro mesmo siape:
  /// cada aparelho guarda a credencial de um usuario por vez.
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

/// pbkdf2-hmac-sha256 de um bloco. as iteracoes existem pra encarecer a
/// tentativa de adivinhar a senha a partir do hash extraido do aparelho.
String derivarHash(String senha, String salt, {int iteracoes = 10000}) {
  final hmac = Hmac(sha256, utf8.encode(senha));
  // bloco 1 do pbkdf2: salt seguido do indice do bloco em big-endian
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

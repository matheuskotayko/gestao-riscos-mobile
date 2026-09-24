import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/credencial_offline.dart';

CredencialOffline _nova({
  String siape = '202512603',
  String senha = '12345678',
}) => CredencialOffline.nova(
  siape: siape,
  senha: senha,
  token: 'jwt-do-ultimo-login',
  usuario: const {'siape': '202512603', 'nome': 'Administrador SIGR'},
);
void main() {
  test('senha correta confere', () {
    expect(_nova().confere('202512603', '12345678'), isTrue);
  });
  test('senha errada nao confere', () {
    expect(_nova().confere('202512603', '1234567'), isFalse);
  });
  test('siape de outro usuario nao confere nem com a senha certa', () {
    expect(_nova().confere('2094815', '12345678'), isFalse);
  });
  test('a senha nao aparece no que e guardado', () {
    final json = _nova(senha: 'senhaSecreta123').toJson().toString();
    expect(json.contains('senhaSecreta123'), isFalse);
  });
  test('salt novo a cada credencial, entao hashes diferentes', () {
    expect(_nova().hash, isNot(_nova().hash));
  });
  test('sobrevive a serializacao', () {
    final original = _nova();
    final volta = CredencialOffline.fromJson(original.toJson());
    expect(volta.confere('202512603', '12345678'), isTrue);
    expect(volta.token, original.token);
  });
  test('mesmo salt e senha derivam o mesmo hash', () {
    expect(derivarHash('abc', 'sal'), derivarHash('abc', 'sal'));
    expect(derivarHash('abc', 'sal'), isNot(derivarHash('abc', 'outro')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:gestao_risco_mobile/data/local/dono_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _risco(String uuid) => {
  'uuid': uuid,
  'setor': 1,
  'objetivo': 1,
  'macroprocesso': 1,
  'categoria': 'Operacional',
  'evento': 'Evento $uuid',
  'probabilidade': 5,
  'impacto': 5,
  'nivel_risco': 25,
  'prob_residual': 4,
  'imp_residual': 3,
  'nivel_residual': 12,
  'ativo': true,
};

/// O cache local sobrevive ao logout, entao a troca de usuario e o momento em
/// que o que sobrou do anterior precisa sair.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dao = DaoSync.instance;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    Banco.testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) => Banco.criarSchema(d),
      ),
    );
    await dao.aplicarDoServidor(Recurso.risco, _risco('r1'));
  });

  tearDown(() async {
    await Banco.testDb?.close();
    Banco.testDb = null;
  });

  test('mesmo siape mantem o cache (logout e login de volta)', () async {
    await trocarDonoDoCache('202512603');
    await trocarDonoDoCache('202512603');

    expect((await dao.riscos()).length, 1);
  });

  test('siape diferente limpa o cache do usuario anterior', () async {
    await trocarDonoDoCache('202512603');

    await trocarDonoDoCache('2094815');

    expect(await dao.riscos(), isEmpty);
  });

  test('primeiro login do aparelho preserva o que ja foi baixado', () async {
    await trocarDonoDoCache('202512603');

    expect((await dao.riscos()).length, 1);
  });
}

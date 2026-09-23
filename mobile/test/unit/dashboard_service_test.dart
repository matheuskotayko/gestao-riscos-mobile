import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/api_error.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:gestao_risco_mobile/data/services/dashboard_service.dart';
import 'package:gestao_risco_mobile/data/services/token_service.dart';
import 'package:gestao_risco_mobile/data/sync/conectividade.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _rota = '/api/riscos/planos/dashboard/';

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

/// Quando a api nao responde, o dashboard tem que vir do cache local mesmo com
/// o aparelho "online" — foi o que quebrou o app no celular ligado numa rede
/// que nao alcancava o backend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter adapter;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    Banco.testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) => Banco.criarSchema(d),
      ),
    );
    await DaoSync.instance.aplicarDoServidor(Recurso.risco, _risco('r1'));
    // otimista de proposito: o aparelho tem rede, o backend e que nao responde
    Conectividade.definirParaTeste(online: true);
    dio = Dio(BaseOptions(baseUrl: 'http://x'));
    adapter = DioAdapter(dio: dio);
  });

  tearDown(() async {
    await Banco.testDb?.close();
    Banco.testDb = null;
  });

  test('api inalcancavel cai no cache mesmo com o aparelho online', () async {
    adapter.onGet(
      _rota,
      (s) => s.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: _rota),
          reason: 'sem rota ate o servidor',
        ),
      ),
    );

    final dash = await DashboardService(TokenService(), dio: dio).carregar();

    expect(dash.totalPlanos, 1);
    expect(dash.riscosPorNivel.alto, 1); // residual 12 do risco em cache
  });

  test('erro com resposta do servidor continua estourando', () async {
    adapter.onGet(_rota, (s) => s.reply(500, {'erro': 'boom'}));

    expect(
      () => DashboardService(TokenService(), dio: dio).carregar(),
      throwsA(isA<ApiError>()),
    );
  });
}

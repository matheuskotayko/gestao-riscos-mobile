import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// estado de conexao do dispositivo. "online" e otimista: qualquer interface
/// ativa (wifi/dados moveis/ethernet) ja conta como online, mesmo sem
/// checar se realmente tem internet de verdade do outro lado.
class Conectividade {
  Conectividade._({bool escutarPlataforma = true}) {
    if (escutarPlataforma) {
      Connectivity().onConnectivityChanged.listen(_atualizar);
      Connectivity().checkConnectivity().then(_atualizar);
    }
  }
  static Conectividade instance = Conectividade._();

  /// substitui o singleton por um que nao fala com a plataforma (testes).
  static void definirParaTeste({bool online = true}) {
    instance = Conectividade._(escutarPlataforma: false).._online = online;
  }

  bool _online = true;
  bool get online => _online;

  /// simula uma mudanca de conexao nos testes.
  void emitirParaTeste({required bool online}) => _atualizar(
    online ? [ConnectivityResult.wifi] : [ConnectivityResult.none],
  );

  final _controller = StreamController<bool>.broadcast();

  /// emite true quando a conexao volta (offline -> online).
  Stream<bool> get aoVoltar => _controller.stream.where((online) => online);

  Stream<bool> get mudancas => _controller.stream;

  void _atualizar(List<ConnectivityResult> resultados) {
    final agora = resultados.any((r) => r != ConnectivityResult.none);
    if (agora != _online) {
      _online = agora;
      _controller.add(agora);
    }
  }
}

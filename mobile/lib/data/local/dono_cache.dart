import 'banco.dart';

const _chave = 'dono_cache';

/// marca de quem e o cache local. o banco sobrevive ao logout (sem rede nao
/// da pra logar de novo, e apagar deixaria o app inutil offline), entao quem
/// entra depois pode ser outra pessoa — e cada usuario enxerga so os setores
/// dele. troca de siape limpa o que sobrou do anterior.
Future<void> trocarDonoDoCache(String siape) async {
  final dono = await Banco.instance.lerEstatico(_chave);
  if (dono != null && dono != siape) await Banco.instance.limpar();
  await Banco.instance.guardarEstatico(_chave, siape);
}

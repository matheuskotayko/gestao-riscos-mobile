import 'banco.dart';

const _chave = 'dono_cache';
Future<void> trocarDonoDoCache(String siape) async {
  final dono = await Banco.instance.lerEstatico(_chave);
  if (dono != null && dono != siape) await Banco.instance.limpar();
  await Banco.instance.guardarEstatico(_chave, siape);
}

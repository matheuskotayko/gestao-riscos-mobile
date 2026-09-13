import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// abre a camera ou a galeria (conforme a origem) e copia a foto pra um
/// arquivo permanente no diretorio de documentos do app — sobrevive mesmo
/// se fechar o app antes de sincronizar. devolve o caminho do arquivo, ou
/// null se o usuario cancelou.
Future<String?> tirarFotoEvidencia({
  ImageSource origem = ImageSource.camera,
  Future<XFile?> Function(ImageSource)? camera,
  Future<Directory> Function()? diretorio,
}) async {
  final tirar = camera ??
      (ImageSource s) => ImagePicker().pickImage(
            source: s,
            maxWidth: 1600,
            imageQuality: 70,
          );
  final foto = await tirar(origem);
  if (foto == null) return null;

  final dir = await (diretorio ?? getApplicationDocumentsDirectory)();
  final ext = p.extension(foto.path).isEmpty ? '.jpg' : p.extension(foto.path);
  final destino = p.join(
    dir.path,
    'evidencias',
    '${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  await Directory(p.dirname(destino)).create(recursive: true);
  await File(foto.path).copy(destino);
  return destino;
}

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

typedef Coordenada = ({double latitude, double longitude});
Future<Coordenada> capturarLocalizacao({
  Future<bool> Function()? servicoHabilitado,
  Future<LocationPermission> Function()? checarPermissao,
  Future<LocationPermission> Function()? pedirPermissao,
  Future<Position> Function()? posicaoAtual,
}) async {
  final habilitado = servicoHabilitado ?? Geolocator.isLocationServiceEnabled;
  final checar = checarPermissao ?? Geolocator.checkPermission;
  final pedir = pedirPermissao ?? Geolocator.requestPermission;
  final posicao =
      posicaoAtual ??
      () => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
  if (!await habilitado()) {
    throw 'Ative o GPS do celular para registrar a localização.';
  }
  var permissao = await checar();
  if (permissao == LocationPermission.denied) {
    permissao = await pedir();
  }
  if (permissao == LocationPermission.denied ||
      permissao == LocationPermission.deniedForever) {
    throw 'Permissão de localização negada.';
  }
  final p = await posicao();
  return (latitude: p.latitude, longitude: p.longitude);
}

Future<String?> enderecoDe(
  double latitude,
  double longitude, {
  Future<List<Placemark>> Function(double, double)? geocoder,
}) async {
  try {
    final lugares = await (geocoder ?? placemarkFromCoordinates)(
      latitude,
      longitude,
    );
    if (lugares.isEmpty) return null;
    final p = lugares.first;
    final rua = [
      p.street,
      if ((p.subThoroughfare ?? '').isNotEmpty) p.subThoroughfare,
    ].where((s) => (s ?? '').isNotEmpty).join(', ');
    final partes = [
      if (rua.isNotEmpty) rua,
      p.subLocality,
      p.locality,
    ].where((s) => (s ?? '').isNotEmpty).cast<String>().toList();
    return partes.isEmpty ? null : partes.join(' — ');
  } catch (_) {
    return null;
  }
}

Future<void> abrirNoMapa(double latitude, double longitude) async {
  final uri = Uri.parse(
    'geo:$latitude,$longitude?q=$latitude,$longitude(Risco)',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Nenhum app de mapas encontrado.';
  }
}

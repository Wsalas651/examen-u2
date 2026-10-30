import 'ubicacion.dart';

abstract interface class ServicioUbicacion {
  /// Cada escucha se cancela al abandonar la pantalla o pasar a segundo plano.
  Stream<Ubicacion> observar();
}

class FalloUbicacion implements Exception {
  final String motivo;
  const FalloUbicacion(this.motivo);
  @override
  String toString() => motivo;
}

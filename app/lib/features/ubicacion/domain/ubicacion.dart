import 'dart:math' as math;

/// Coordenadas propias del dominio, independientes del proveedor de GPS.
class Ubicacion {
  final double latitud;
  final double longitud;
  final double precisionMetros;
  const Ubicacion(this.latitud, this.longitud, this.precisionMetros);

  double distanciaA(Ubicacion otra) {
    const radioTierra = 6371000.0;
    double rad(double grados) => grados * math.pi / 180;
    final dLat = rad(otra.latitud - latitud);
    final dLon = rad(otra.longitud - longitud);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitud)) *
            math.cos(rad(otra.latitud)) *
            math.pow(math.sin(dLon / 2), 2);
    return radioTierra * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}

class LugarInteres {
  final String nombre;
  final Ubicacion centro;
  final double radioMetros;
  const LugarInteres({
    required this.nombre,
    required this.centro,
    this.radioMetros = 150,
  });
  bool contiene(Ubicacion punto) => centro.distanciaA(punto) <= radioMetros;

  // Centro de demostración solicitado por el examen; no es dirección verificada.
  static const clinica = LugarInteres(
    nombre: 'Clínica La Luz',
    centro: Ubicacion(-18.0066, -70.2463, 0),
  );
}

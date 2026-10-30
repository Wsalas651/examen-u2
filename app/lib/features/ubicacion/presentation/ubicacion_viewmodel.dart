import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/servicio_ubicacion.dart';
import '../domain/ubicacion.dart';

enum EstadoUbicacion { inicial, buscando, localizada, eleccionMapa, pausada }

class UbicacionViewModel extends ChangeNotifier {
  final ServicioUbicacion servicio;
  final LugarInteres lugar;
  final Duration tiempoLimite;
  StreamSubscription<Ubicacion>? _escucha;
  Timer? _limite;
  int _sesion = 0;
  bool _cerrado = false;
  EstadoUbicacion estado = EstadoUbicacion.inicial;
  Ubicacion? ubicacion;
  String? motivo;
  bool manual = false;

  // Construir el ViewModel no solicita ubicación.
  UbicacionViewModel({
    required this.servicio,
    this.lugar = LugarInteres.clinica,
    this.tiempoLimite = const Duration(seconds: 10),
  });

  bool get permiteElegir => estado == EstadoUbicacion.eleccionMapa || manual;
  bool get dentro => ubicacion != null && lugar.contiene(ubicacion!);
  double? get distancia => ubicacion?.distanciaA(lugar.centro);

  Future<void> iniciar() async {
    if (_cerrado || _escucha != null || estado == EstadoUbicacion.buscando) {
      return;
    }
    final sesion = ++_sesion;
    estado = EstadoUbicacion.buscando;
    motivo = null;
    manual = false;
    notifyListeners();
    _limite = Timer(tiempoLimite, () => _fallar('Tiempo agotado', sesion));
    try {
      _escucha = servicio.observar().listen(
        (punto) {
          if (_cerrado || sesion != _sesion) return;
          _limite?.cancel();
          ubicacion = punto;
          estado = EstadoUbicacion.localizada;
          notifyListeners();
        },
        onError: (Object error) => _fallar(
          error is FalloUbicacion
              ? error.motivo
              : 'No se pudo obtener la ubicación',
          sesion,
        ),
        onDone: () => _fallar('El servicio de ubicación se detuvo', sesion),
      );
    } catch (_) {
      _fallar('No se pudo obtener la ubicación', sesion);
    }
  }

  void _fallar(String error, int sesion) {
    if (_cerrado || sesion != _sesion) return;
    unawaited(detener());
    estado = EstadoUbicacion.eleccionMapa;
    ubicacion = null;
    manual = false;
    motivo = error;
    notifyListeners();
  }

  void elegir(double latitud, double longitud) {
    if (!permiteElegir || _cerrado) return;
    ubicacion = Ubicacion(latitud, longitud, 0);
    manual = true;
    estado = EstadoUbicacion.eleccionMapa;
    notifyListeners();
  }

  Future<void> usarMapa() async {
    await detener();
    if (_cerrado) return;
    estado = EstadoUbicacion.eleccionMapa;
    ubicacion = null;
    manual = false;
    motivo = 'Selección manual activada';
    notifyListeners();
  }

  Future<void> detener() async {
    ++_sesion;
    _limite?.cancel();
    final escucha = _escucha;
    _escucha = null;
    if (estado == EstadoUbicacion.buscando) estado = EstadoUbicacion.pausada;
    await escucha?.cancel();
  }

  @override
  void dispose() {
    _cerrado = true;
    unawaited(detener());
    super.dispose();
  }
}

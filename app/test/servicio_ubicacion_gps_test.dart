import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sitra_luz/features/ubicacion/data/servicio_ubicacion_gps.dart';

class PlataformaGpsSimulada extends GeolocatorPlatform {
  LocationSettings? ajustes;
  final posiciones = StreamController<Position>();
  final estados = StreamController<ServiceStatus>();
  Completer<LocationPermission>? permisoPendiente;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permisoPendiente == null
      ? LocationPermission.whileInUse
      : permisoPendiente!.future;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    ajustes = locationSettings;
    return posiciones.stream;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => estados.stream;
  void cerrar() {
    unawaited(posiciones.close());
    unawaited(estados.close());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform original;
  late PlataformaGpsSimulada plataforma;
  setUp(() {
    original = GeolocatorPlatform.instance;
    plataforma = PlataformaGpsSimulada();
    GeolocatorPlatform.instance = plataforma;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    GeolocatorPlatform.instance = original;
    debugDefaultTargetPlatformOverride = null;
    plataforma.cerrar();
  });
  test(
    'PASS: proveedor nativo con precisión media, 30 segundos y 50 metros',
    () async {
      final escucha = ServicioUbicacionGps().observar().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      final ajustes = plataforma.ajustes! as AndroidSettings;
      expect(ajustes.accuracy, LocationAccuracy.medium);
      expect(ajustes.intervalDuration, const Duration(seconds: 30));
      expect(ajustes.distanceFilter, 50);
      expect(ajustes.forceLocationManager, isTrue);
      expect(plataforma.posiciones.hasListener, isTrue);
      expect(plataforma.estados.hasListener, isTrue);
      await escucha.cancel();
      expect(plataforma.posiciones.hasListener, isFalse);
      expect(plataforma.estados.hasListener, isFalse);
    },
  );
  test(
    'PASS: salir mientras se resuelve el permiso no deja escuchas tardías',
    () async {
      plataforma.permisoPendiente = Completer<LocationPermission>();
      final escucha = ServicioUbicacionGps().observar().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await escucha.cancel();
      plataforma.permisoPendiente!.complete(LocationPermission.whileInUse);
      await Future<void>.delayed(Duration.zero);
      expect(plataforma.ajustes, isNull);
      expect(plataforma.posiciones.hasListener, isFalse);
      expect(plataforma.estados.hasListener, isFalse);
    },
  );
}

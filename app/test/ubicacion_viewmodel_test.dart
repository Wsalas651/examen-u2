import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitra_luz/features/ubicacion/domain/servicio_ubicacion.dart';
import 'package:sitra_luz/features/ubicacion/domain/ubicacion.dart';
import 'package:sitra_luz/features/ubicacion/presentation/ubicacion_viewmodel.dart';

/// Sustituye al GPS: no usa plugins, emulador ni permisos.
class ServicioUbicacionSimulado implements ServicioUbicacion {
  int solicitudes = 0;
  int escuchasActivas = 0;
  late final StreamController<Ubicacion> lecturas = StreamController<Ubicacion>(
    onListen: () => escuchasActivas++,
    onCancel: () => escuchasActivas--,
  );
  @override
  Stream<Ubicacion> observar() {
    solicitudes++;
    return lecturas.stream;
  }

  void cerrar() {
    unawaited(lecturas.close());
  }
}

Future<void> entregarEventos() => Future<void>.delayed(Duration.zero);

void main() {
  late ServicioUbicacionSimulado gps;
  late UbicacionViewModel vm;
  setUp(() {
    gps = ServicioUbicacionSimulado();
    vm = UbicacionViewModel(servicio: gps);
  });
  tearDown(() async {
    vm.dispose();
    gps.cerrar();
  });

  test('PASS 4a: construir el ViewModel no solicita ubicación', () {
    expect(gps.solicitudes, 0);
    expect(gps.escuchasActivas, 0);
    expect(vm.estado, EstadoUbicacion.inicial);
  });

  test('PASS 4b: lectura -18.0066, -70.2463 y precisión de 35 m', () async {
    await vm.iniciar();
    gps.lecturas.add(const Ubicacion(-18.0066, -70.2463, 35));
    await entregarEventos();
    expect(vm.ubicacion!.latitud, -18.0066);
    expect(vm.ubicacion!.longitud, -70.2463);
    expect(vm.ubicacion!.precisionMetros, 35);
    expect(vm.estado, EstadoUbicacion.localizada);
  });

  test(
    'PASS 4c: GPS apagado permite elegir y se solicita una sola vez',
    () async {
      await vm.iniciar();
      gps.lecturas.addError(const FalloUbicacion('GPS apagado'));
      await entregarEventos();
      expect(vm.estado, EstadoUbicacion.eleccionMapa);
      expect(vm.motivo, 'GPS apagado');
      expect(vm.permiteElegir, isTrue);
      expect(gps.solicitudes, 1);
      expect(gps.escuchasActivas, 0);
      vm.elegir(-18.0057, -70.2463);
      expect(vm.manual, isTrue);
      expect(vm.ubicacion!.latitud, -18.0057);
    },
  );

  test(
    'PASS 5a: zona de 150 m incluye punto de 100 m y excluye punto de 300 m',
    () {
      const lugar = LugarInteres.clinica;
      const dentro = Ubicacion(-18.0057, -70.2463, 35);
      const fuera = Ubicacion(-18.0039, -70.2463, 35);
      expect(lugar.centro.distanciaA(dentro), closeTo(100, 1));
      expect(lugar.centro.distanciaA(fuera), closeTo(300, 1));
      expect(lugar.contiene(dentro), isTrue);
      expect(lugar.contiene(fuera), isFalse);
      expect(lugar.contiene(lugar.centro), isTrue);
    },
  );

  test('PASS 5b: al salir no queda ninguna escucha activa', () async {
    await vm.iniciar();
    expect(gps.escuchasActivas, 1);
    await vm.detener();
    expect(gps.escuchasActivas, 0);
    gps.lecturas.add(const Ubicacion(-18.0039, -70.2463, 35));
    await entregarEventos();
    expect(vm.ubicacion, isNull);
  });

  test('PASS: solicitudes simultáneas conservan una sola escucha', () async {
    await Future.wait([vm.iniciar(), vm.iniciar()]);
    expect(gps.solicitudes, 1);
    expect(gps.escuchasActivas, 1);
  });

  test('PASS: permiso denegado ofrece selección manual y libera GPS', () async {
    await vm.iniciar();
    gps.lecturas.addError(
      const FalloUbicacion('Permiso de ubicación denegado'),
    );
    await entregarEventos();
    expect(vm.motivo, contains('denegado'));
    expect(vm.permiteElegir, isTrue);
    expect(gps.escuchasActivas, 0);
  });

  testWidgets('PASS: sin lectura a los 10 segundos muestra Tiempo agotado', (
    tester,
  ) async {
    await vm.iniciar();
    await tester.pump(const Duration(seconds: 9));
    expect(vm.estado, EstadoUbicacion.buscando);
    await tester.pump(const Duration(seconds: 1));
    expect(vm.motivo, 'Tiempo agotado');
    expect(vm.estado, EstadoUbicacion.eleccionMapa);
    expect(gps.escuchasActivas, 0);
  });

  testWidgets(
    'PASS: una lectura cancela el tiempo límite sin apagar seguimiento',
    (tester) async {
      await vm.iniciar();
      gps.lecturas.add(const Ubicacion(-18.0066, -70.2463, 35));
      await tester.pump();
      await tester.pump(const Duration(seconds: 40));
      expect(vm.estado, EstadoUbicacion.localizada);
      expect(vm.motivo, isNull);
      expect(gps.escuchasActivas, 1);
    },
  );

  test('PASS: dispose cancela inmediatamente la escucha', () async {
    final servicio = ServicioUbicacionSimulado();
    final modelo = UbicacionViewModel(servicio: servicio);
    await modelo.iniciar();
    modelo.dispose();
    expect(servicio.escuchasActivas, 0);
    servicio.cerrar();
  });
}

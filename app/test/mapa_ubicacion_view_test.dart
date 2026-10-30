import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitra_luz/core/routes/mapa_route_observer.dart';
import 'package:sitra_luz/features/ubicacion/domain/ubicacion.dart';
import 'package:sitra_luz/features/ubicacion/presentation/mapa_ubicacion_view.dart';
import 'ubicacion_viewmodel_test.dart' show ServicioUbicacionSimulado;

void main() {
  testWidgets('PASS: mapa dibuja radio real y al volver libera la escucha', (
    tester,
  ) async {
    final gps = ServicioUbicacionSimulado();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [mapaRouteObserver],
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => MapaUbicacionView(servicio: gps)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(gps.escuchasActivas, 1);
    gps.lecturas.add(const Ubicacion(-18.0066, -70.2463, 35));
    await tester.pump();
    final circulos = tester
        .widget<CircleLayer>(find.byType(CircleLayer))
        .circles;
    expect(circulos.map((c) => c.radius), containsAll([150.0, 35.0]));
    expect(circulos.every((c) => c.useRadiusInMeter), isTrue);
    expect(find.text('Precisión ± 35 m'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(
      find.text('Estás dentro de la zona de Clínica La Luz'),
      findsOneWidget,
    );
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(gps.escuchasActivas, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    gps.cerrar();
  });
}

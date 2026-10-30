import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routes/mapa_route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/servicio_ubicacion.dart';
import '../domain/ubicacion.dart';
import 'ubicacion_viewmodel.dart';

class MapaUbicacionView extends StatefulWidget {
  final ServicioUbicacion servicio;
  const MapaUbicacionView({super.key, required this.servicio});
  @override
  State<MapaUbicacionView> createState() => _MapaUbicacionViewState();
}

class _MapaUbicacionViewState extends State<MapaUbicacionView>
    with WidgetsBindingObserver, RouteAware {
  late final UbicacionViewModel vm;
  final mapa = MapController();
  bool mapaListo = false;
  bool centradoInicial = false;
  bool mapaSinRed = false;
  bool cubierta = false;
  bool reanudarGps = false;
  PageRoute<dynamic>? ruta;
  static const azul = AppColors.primary;
  static const verde = AppColors.secondary;
  LatLng punto(Ubicacion u) => LatLng(u.latitud, u.longitud);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vm = UbicacionViewModel(servicio: widget.servicio)..addListener(actualizar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(vm.iniciar());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final actual = ModalRoute.of(context);
    if (actual is PageRoute && actual != ruta) {
      mapaRouteObserver.unsubscribe(this);
      ruta = actual;
      mapaRouteObserver.subscribe(this, actual);
    }
  }

  void actualizar() {
    if (!mounted) return;
    if (mapaListo && !centradoInicial && vm.ubicacion != null) {
      mapa.move(punto(vm.ubicacion!), 16);
      centradoInicial = true;
    }
    setState(() {});
  }

  void pausar() {
    reanudarGps =
        vm.estado == EstadoUbicacion.buscando ||
        vm.estado == EstadoUbicacion.localizada;
    unawaited(vm.detener());
  }

  void reanudar() {
    if (reanudarGps && !cubierta) {
      reanudarGps = false;
      unawaited(vm.iniciar());
    }
  }

  @override
  void didPop() {
    unawaited(vm.detener());
  }

  @override
  void didPushNext() {
    cubierta = true;
    pausar();
  }

  @override
  void didPopNext() {
    cubierta = false;
    reanudar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Los diálogos de permiso también producen inactive: esperar hidden/paused.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!reanudarGps) pausar();
    } else if (state == AppLifecycleState.resumed) {
      reanudar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mapaRouteObserver.unsubscribe(this);
    vm.removeListener(actualizar);
    vm.dispose();
    mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = vm.ubicacion;
    final buscando = vm.estado == EstadoUbicacion.buscando;
    final gpsActivo = vm.estado == EstadoUbicacion.localizada;
    final colorZona = vm.dentro ? verde : azul;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa de cercanía',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'SITRA-Luz · Tacna',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver lugar de interés',
            onPressed: () => mapa.move(punto(vm.lugar.centro), 16),
            icon: const Icon(Icons.local_hospital_outlined, color: verde),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapa,
                    options: MapOptions(
                      initialCenter: punto(vm.lugar.centro),
                      initialZoom: 16,
                      minZoom: 3,
                      maxZoom: 19,
                      onMapReady: () {
                        mapaListo = true;
                        actualizar();
                      },
                      onTap: (_, p) => vm.elegir(p.latitude, p.longitude),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'ap.sitra.luz.clinica',
                        maxNativeZoom: 19,
                        errorTileCallback: (_, _, _) {
                          if (!mapaSinRed && mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => mapaSinRed = true);
                            });
                          }
                        },
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: punto(vm.lugar.centro),
                            radius: vm.lugar.radioMetros,
                            useRadiusInMeter: true,
                            color: verde.withValues(alpha: .10),
                            borderColor: verde.withValues(alpha: .65),
                            borderStrokeWidth: 2,
                          ),
                          if (u != null && !vm.manual)
                            CircleMarker(
                              point: punto(u),
                              radius: u.precisionMetros,
                              useRadiusInMeter: true,
                              color: Colors.blue.withValues(alpha: .20),
                              borderColor: Colors.blue.withValues(alpha: .7),
                              borderStrokeWidth: 1.5,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: punto(vm.lugar.centro),
                            width: 170,
                            height: 90,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    vm.lugar.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: azul,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: verde,
                                  size: 38,
                                ),
                              ],
                            ),
                          ),
                          if (u != null)
                            Marker(
                              point: punto(u),
                              width: 30,
                              height: 30,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: vm.manual
                                      ? Colors.deepOrange
                                      : Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x44000000),
                                      blurRadius: 9,
                                    ),
                                  ],
                                ),
                                child: vm.manual
                                    ? const Icon(
                                        Icons.touch_app,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: ColoredBox(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              child: Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(fontSize: 11, color: azul),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                vm.permiteElegir
                                    ? Icons.touch_app_outlined
                                    : Icons.eco_outlined,
                                size: 17,
                                color: verde,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  vm.permiteElegir
                                      ? 'Toca el mapa para ubicarte'
                                      : 'Ubicación de bajo consumo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 35,
                    right: 14,
                    child: Column(
                      children: [
                        _control(
                          Icons.add,
                          'Acercar',
                          () => mapa.move(
                            mapa.camera.center,
                            (mapa.camera.zoom + 1).clamp(3, 19),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _control(
                          Icons.remove,
                          'Alejar',
                          () => mapa.move(
                            mapa.camera.center,
                            (mapa.camera.zoom - 1).clamp(3, 19),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _control(
                          Icons.my_location,
                          'Centrar mi ubicación',
                          u == null ? null : () => mapa.move(punto(u), 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .46,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radar_rounded, color: verde, size: 22),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'Tu ubicación',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          vm.manual
                              ? 'MANUAL'
                              : buscando
                              ? 'BUSCANDO'
                              : gpsActivo
                              ? 'GPS'
                              : 'SIN GPS',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: verde,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (buscando) ...[
                      const LinearProgressIndicator(minHeight: 3, color: verde),
                      const SizedBox(height: 8),
                      const Text(
                        'Buscando tu ubicación… hasta 10 segundos.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    if (vm.motivo != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${vm.motivo}. ${vm.manual ? 'Puedes ajustar el punto tocando el mapa.' : 'Elige tu ubicación tocando el mapa.'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF805000),
                          ),
                        ),
                      ),
                    if (u != null) ...[
                      Row(
                        children: [
                          Expanded(child: _coordenada('LATITUD', u.latitud)),
                          const SizedBox(width: 10),
                          Expanded(child: _coordenada('LONGITUD', u.longitud)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.manual
                            ? 'Ubicación elegida en el mapa · sin precisión GPS'
                            : 'Precisión ± ${u.precisionMetros.round()} m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorZona.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              vm.dentro
                                  ? Icons.check_circle_outline
                                  : Icons.explore_outlined,
                              color: colorZona,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estás ${vm.dentro ? 'dentro' : 'fuera'} de la zona de ${vm.lugar.nombre}',
                                    style: TextStyle(
                                      color: colorZona,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${vm.distancia!.round()} m al centro · zona de 150 m',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: buscando || gpsActivo
                                ? null
                                : () => vm.iniciar(),
                            icon: const Icon(Icons.gps_fixed, size: 18),
                            label: Text(gpsActivo ? 'GPS activo' : 'Usar GPS'),
                            style: FilledButton.styleFrom(
                              backgroundColor: azul,
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => vm.usarMapa(),
                            icon: const Icon(
                              Icons.touch_app_outlined,
                              size: 18,
                            ),
                            label: const Text('Elegir en mapa'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      mapaSinRed
                          ? 'No se pudo cargar parte del mapa. Revisa tu conexión a Internet.'
                          : 'Zona de demostración · precisión media · 30 s / 50 m',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordenada(String etiqueta, double valor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E7EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor.toStringAsFixed(6),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: azul,
          ),
        ),
      ],
    ),
  );
  Widget _control(IconData icono, String texto, VoidCallback? accion) =>
      Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: IconButton(
          tooltip: texto,
          onPressed: accion,
          icon: Icon(icono, color: accion == null ? Colors.grey : azul),
        ),
      );
}

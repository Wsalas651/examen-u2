import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/servicio_ubicacion.dart';
import '../domain/ubicacion.dart';

/// Única clase de la app que conoce la biblioteca de GPS.
class ServicioUbicacionGps implements ServicioUbicacion {
  @override
  Stream<Ubicacion> observar() {
    late StreamController<Ubicacion> salida;
    StreamSubscription<Position>? posiciones;
    StreamSubscription<ServiceStatus>? servicio;
    var activa = true;
    Ubicacion? anterior;
    DateTime? ultimaEmision;
    void fallar(String motivo) {
      if (activa) salida.addError(FalloUbicacion(motivo));
    }

    Future<void> clasificarFallo(Object error) async {
      try {
        if (error is LocationServiceDisabledException ||
            !await Geolocator.isLocationServiceEnabled()) {
          fallar('GPS apagado');
        } else if (error is PermissionDeniedException) {
          fallar('Permiso de ubicación denegado');
        } else {
          fallar('No se pudo obtener la ubicación');
        }
      } catch (_) {
        fallar('No se pudo acceder al servicio de ubicación');
      }
    }

    Future<void> iniciar() async {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) {
          fallar('GPS apagado');
          return;
        }
        if (!activa) return;
        var permiso = await Geolocator.checkPermission();
        if (!activa) return;
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (!activa) return;
        if (permiso == LocationPermission.denied ||
            permiso == LocationPermission.deniedForever) {
          fallar(
            permiso == LocationPermission.deniedForever
                ? 'Permiso denegado. Actívalo en Ajustes para usar el GPS.'
                : 'Permiso de ubicación denegado',
          );
          return;
        }
        final LocationSettings ajustes =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.medium,
                // Proveedor nativo de Android: no exige activar Google Location Accuracy.
                forceLocationManager: true,
                intervalDuration: const Duration(seconds: 30),
                distanceFilter: 50,
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.medium,
                distanceFilter: 50,
              );
        servicio = Geolocator.getServiceStatusStream().listen((estado) {
          if (estado == ServiceStatus.disabled) fallar('GPS apagado');
        }, onError: (_) => fallar('No se pudo comprobar el GPS'));
        posiciones = Geolocator.getPositionStream(locationSettings: ajustes).listen(
          (p) {
            if (!activa) return;
            final punto = Ubicacion(p.latitude, p.longitude, p.accuracy);
            final ahora = DateTime.now();
            // Android puede entregar eventos antes del intervalo solicitado.
            // Ambas condiciones deben cumplirse después de la primera lectura.
            if (ultimaEmision != null &&
                (ahora.difference(ultimaEmision!) <
                        const Duration(seconds: 30) ||
                    anterior!.distanciaA(punto) < 50)) {
              return;
            }
            if (!p.accuracy.isFinite || p.accuracy < 0) return;
            ultimaEmision = ahora;
            anterior = punto;
            salida.add(punto);
          },
          onError: (Object error) => unawaited(clasificarFallo(error)),
          onDone: () => fallar('El servicio de ubicación se detuvo'),
        );
        // Cubre un apagado durante la solicitud de permisos.
        if (!await Geolocator.isLocationServiceEnabled()) fallar('GPS apagado');
      } catch (_) {
        fallar('No se pudo acceder al servicio de ubicación');
      }
    }

    salida = StreamController<Ubicacion>(
      onListen: iniciar,
      onCancel: () async {
        activa = false;
        await posiciones?.cancel();
        await servicio?.cancel();
        debugPrint('GPS detenido');
      },
    );
    return salida.stream;
  }
}

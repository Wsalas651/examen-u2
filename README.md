# Examen U2 — SITRA-Luz

**Tipo de evaluación:** examen práctico individual de la Unidad II.

**Curso:** Soluciones Móviles II — Universidad Privada de Tacna.

**Aplicación:** SITRA-Luz, desarrollada con Flutter y Dart.

**Repositorio:** [Wsalas651/examen-u2](https://github.com/Wsalas651/examen-u2).

Se implementó una funcionalidad de ubicación que permite visualizar la posición del usuario, conocer su precisión y determinar si se encuentra cerca de un lugar de interés. La solución mantiene la separación entre presentación, dominio y datos, contempla el consumo de batería y permite continuar mediante selección manual cuando la ubicación no está disponible.

## Desarrollo de los cinco puntos

### 1. Separación de la ubicación

Se creó la entidad `Ubicacion`, que contiene latitud, longitud y precisión en metros. El contrato `ServicioUbicacion` se inyecta en `UbicacionViewModel`; únicamente la clase de datos `ServicioUbicacionGps` importa la biblioteca `geolocator`. La pantalla presenta las coordenadas recibidas.

### 2. Precisión media y detención del seguimiento

El servicio solicita precisión media, con un intervalo de 30 segundos y un desplazamiento mínimo de 50 metros. Después de la primera lectura se verifican ambas condiciones antes de actualizar la posición. Si no se recibe una lectura en 10 segundos, se muestra «Tiempo agotado». Al salir del mapa o pasar la app a segundo plano se cancelan las escuchas y se registra «GPS detenido».

### 3. Radio de precisión y alternativa manual

Se integró OpenStreetMap con su atribución visible. La posición se representa mediante un círculo azul cuyo radio corresponde a la precisión de la lectura, acompañada del texto «Precisión ± N m». Ante GPS apagado, permiso denegado o tiempo agotado, se informa el motivo y se permite elegir una ubicación tocando el mapa.

### 4. Pruebas unitarias del ViewModel

Se implementó un servicio simulado para comprobar que construir el ViewModel no solicita ubicación, que una lectura en `-18.0066, -70.2463` con precisión de `35 m` se expone correctamente y que un GPS apagado habilita la elección manual tras una sola solicitud. Las pruebas se ejecutan sin emulador ni GPS.

### 5. Zona de cercanía y cancelación

Se incorporó el lugar de interés «Clínica La Luz», con centro de demostración en `-18.0066, -70.2463` y radio de `150 m`. La distancia se calcula mediante Haversine y se muestra si el usuario está dentro o fuera de la zona. Las pruebas verifican un punto interior de aproximadamente 100 m, otro exterior de 300 m y la ausencia de escuchas activas después de detener el seguimiento.

Las coordenadas del lugar corresponden al ejercicio y no representan una dirección comercial verificada. Los 35 m de precisión se utilizan en pruebas; la aplicación presenta la precisión recibida del dispositivo.

## Archivos del proyecto afectados

Las rutas son relativas a la raíz de este repositorio. El proyecto móvil se encuentra en **`app/`**.

| Ubicación del archivo | Cambio realizado |
|---|---|
| [app/lib/features/ubicacion/domain/ubicacion.dart](app/lib/features/ubicacion/domain/ubicacion.dart) | Entidad de ubicación, cálculo de distancia y configuración de la zona de interés. |
| [app/lib/features/ubicacion/domain/servicio_ubicacion.dart](app/lib/features/ubicacion/domain/servicio_ubicacion.dart) | Contrato del servicio y errores de dominio. |
| [app/lib/features/ubicacion/data/servicio_ubicacion_gps.dart](app/lib/features/ubicacion/data/servicio_ubicacion_gps.dart) | Acceso a ubicación, precisión media, filtros y cancelación del servicio. |
| [app/lib/features/ubicacion/presentation/ubicacion_viewmodel.dart](app/lib/features/ubicacion/presentation/ubicacion_viewmodel.dart) | Estado de ubicación, tiempo límite, selección manual y detención. |
| [app/lib/features/ubicacion/presentation/mapa_ubicacion_view.dart](app/lib/features/ubicacion/presentation/mapa_ubicacion_view.dart) | Mapa, precisión, coordenadas, selección manual y aviso de cercanía. |
| [app/lib/core/routes/mapa_route_observer.dart](app/lib/core/routes/mapa_route_observer.dart) | Observación del ciclo de navegación del mapa. |
| [app/lib/core/routes/app_router.dart](app/lib/core/routes/app_router.dart) | Ruta `/mapa` e inyección del servicio de ubicación. |
| [app/lib/core/widgets/sitra_app_bar.dart](app/lib/core/widgets/sitra_app_bar.dart) | Acceso al mapa desde los módulos. |
| [app/lib/features/auth/presentation/views/login_view.dart](app/lib/features/auth/presentation/views/login_view.dart) | Acceso al mapa desde el inicio de sesión. |
| [app/android/app/src/main/AndroidManifest.xml](app/android/app/src/main/AndroidManifest.xml) | Permisos de ubicación en primer plano. |
| [app/pubspec.yaml](app/pubspec.yaml) y [app/pubspec.lock](app/pubspec.lock) | Dependencias del mapa y GPS, incluida la resolución del plugin Android local. |
| [app/test/ubicacion_viewmodel_test.dart](app/test/ubicacion_viewmodel_test.dart) | Servicio simulado y pruebas de ubicación, errores, cercanía y cancelación. |
| [app/test/mapa_ubicacion_view_test.dart](app/test/mapa_ubicacion_view_test.dart) | Prueba del círculo, atribución, aviso de cercanía y salida de la pantalla. |
| [app/test/servicio_ubicacion_gps_test.dart](app/test/servicio_ubicacion_gps_test.dart) | Pruebas de configuración y cancelación durante un permiso pendiente. |
| [packages/geolocator_android/](packages/geolocator_android/) | Copia local del plugin 5.2.1 de Baseflow, conservando su licencia MIT. |
| [packages/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java](packages/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java) | Corrección de la selección del proveedor para recibir Set Location en emuladores Android. |
| [packages/geolocator_android/android/src/test/java/com/baseflow/geolocator/location/EmulatorLocationProviderTest.java](packages/geolocator_android/android/src/test/java/com/baseflow/geolocator/location/EmulatorLocationProviderTest.java) | Cinco pruebas nativas de selección de proveedor. |
| [packages/geolocator_android/SITRA_PATCH.md](packages/geolocator_android/SITRA_PATCH.md) | Descripción técnica y procedencia de la corrección del plugin. |
| [app/GUIA_MAPA_U2.md](app/GUIA_MAPA_U2.md) y [app/README.md](app/README.md) | Documentación complementaria del proyecto móvil. |

## Compatibilidad con Set Location

Se corrigió la selección del proveedor en emuladores Android para recibir las posiciones GPS enviadas desde sus controles extendidos. En dispositivos físicos se conserva la selección original. El cambio mantiene precisión media, 30 segundos, 50 metros y el límite de 10 segundos; no fija coordenadas dentro de la app. Al incluir código nativo Android, requiere reconstruir la aplicación.

## Validación

Se verificaron **49 pruebas de Flutter**, el análisis estático sin observaciones y **cinco pruebas nativas adicionales** de selección del proveedor Android. La aplicación se compila como APK de desarrollo.
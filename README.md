# Examen U2 — SITRA-Luz

**Tipo de evaluación:** examen práctico individual de la Unidad II.

**Curso:** Soluciones Móviles II — Universidad Privada de Tacna.

**Aplicación:** SITRA-Luz, desarrollada con Flutter y Dart.

**Repositorio:** [Wsalas651/examen-u2](https://github.com/Wsalas651/examen-u2).

El examen comprende cinco puntos de cuatro puntos cada uno, con un total de veinte puntos. La implementación incorpora ubicación, visualización cartográfica, manejo de errores y pruebas, manteniendo la separación entre presentación, dominio y datos.

## Historia de usuario

> Como usuario de la app, quiero ver en el mapa dónde estoy y saber si estoy cerca de un lugar de interés, sin que la app agote la batería rápidamente ni se quede en blanco cuando el GPS falla.

## 1. Separe la ubicación del resto de la app — 4 puntos

**Objetivo:** obtener la ubicación desde la lógica de pantalla sin depender directamente de la biblioteca de GPS, para poder probarla sin utilizar el dispositivo.

**Tareas desarrolladas:**

1. Se creó la entidad propia `Ubicacion`, que contiene `latitud`, `longitud` y `precisionMetros`.
2. Se definió el contrato `ServicioUbicacion`. La clase `ServicioUbicacionGps`, perteneciente a datos, es la única clase de la aplicación que importa `geolocator`. El ViewModel recibe el contrato mediante su constructor y no importa esa biblioteca; el router se encarga de construir e inyectar el servicio concreto.
3. Se incorporaron las tarjetas LATITUD y LONGITUD en el mapa para presentar la lectura recibida. La posición del emulador puede establecerse desde sus controles extendidos mediante Set Location.

**Resultado:** la pantalla y el ViewModel trabajan con una entidad y un contrato propios, lo que permite sustituir el acceso a GPS por un servicio simulado en las pruebas.

## 2. Pida la ubicación con precisión media y apague el GPS al salir — 4 puntos

**Objetivo:** moderar el consumo de batería y mantener el seguimiento únicamente mientras se necesita en la pantalla del mapa.

**Tareas desarrolladas:**

1. Se configuró `LocationAccuracy.medium`, evitando solicitar la máxima precisión.
2. Se establecieron un intervalo de 30 segundos y un desplazamiento mínimo de 50 metros. Después de la primera lectura, un filtro adicional exige que se cumplan ambas condiciones antes de emitir una actualización.
3. Se implementó un temporizador de 10 segundos en el ViewModel. Si no llega una lectura dentro del plazo, se muestra «Tiempo agotado» y se habilita la selección manual.
4. Se conectó la salida del mapa con `detener()`. Al cancelar el stream, el servicio libera las escuchas de posición y estado y registra «GPS detenido». También se contempla el paso a segundo plano y la cobertura por otra pantalla.

**Resultado:** se limitan las actualizaciones y se liberan los recursos de ubicación al abandonar la pantalla. Esta detención corresponde a las escuchas de la aplicación; no cambia el interruptor global de Ubicación de Android.

## 3. Muestre el radio de precisión y una alternativa sin GPS — 4 puntos

**Objetivo:** informar al usuario sobre la exactitud de su ubicación y permitir el uso del mapa cuando no se obtiene una lectura del dispositivo.

**Tareas desarrolladas:**

1. Se integró OpenStreetMap mediante `FlutterMap`, con la atribución «© OpenStreetMap contributors» visible y enlazada a su página de copyright.
2. Se añadió un círculo azul para la posición del usuario, con `radius: u.precisionMetros` y `useRadiusInMeter: true`. Debajo del mapa se presenta «Precisión ± N m», utilizando la precisión recibida. El círculo verde corresponde a la zona del lugar de interés.
3. Se contemplaron GPS apagado, permiso denegado y tiempo agotado. La pantalla muestra el motivo y permite elegir un punto mediante un toque en el mapa. La selección se identifica como manual y no se presenta como una lectura GPS.

**Resultado:** la interfaz comunica la precisión disponible y conserva una alternativa de ubicación cuando el servicio falla.

## 4. Ejecute tres pruebas unitarias del ViewModel de ubicación — 4 puntos

**Objetivo:** verificar el ViewModel sin emulador ni GPS, reemplazando el servicio por una implementación simulada.

**Tareas desarrolladas:**

1. **Prueba a — construcción:** comprueba que crear el ViewModel no solicita ubicación y mantiene cero escuchas activas.
2. **Prueba b — lectura simulada:** introduce latitud `-18.0066`, longitud `-70.2463` y precisión de `35 m`; verifica que los tres valores y el estado localizado se expongan correctamente.
3. **Prueba c — GPS apagado:** simula el fallo y comprueba el estado de elección en el mapa, el motivo mostrado y que la ubicación se solicitó una sola vez.
4. Las pruebas se ejecutaron desde la terminal como parte de la suite del proyecto. El reemplazo `ServicioUbicacionSimulado` controla las lecturas y contabiliza las solicitudes, sin acceder al GPS.

**Resultado:** las tres pruebas solicitadas forman parte de las 49 pruebas de Flutter aprobadas durante la implementación. No requieren ejecutar la app ni disponer de un emulador.

## 5. Avise si el usuario está cerca de un lugar y pruébelo — 4 puntos

**Objetivo:** determinar si la posición del usuario se encuentra dentro de la zona de un lugar de interés del negocio.

**Tareas desarrolladas:**

1. Se incorporó «Clínica La Luz» como lugar de interés, con centro de demostración en `-18.0066, -70.2463` y radio de `150 m`. El mapa muestra el lugar y su zona; debajo se informa «Estás dentro de la zona de Clínica La Luz» o «Estás fuera de la zona de Clínica La Luz».
2. **Prueba a — cercanía:** verifica que `-18.0057, -70.2463`, a aproximadamente 100 m, quede dentro, y que `-18.0039, -70.2463`, a aproximadamente 300 m, quede fuera. La distancia se calcula mediante la fórmula de Haversine.
3. **Prueba b — cancelación:** comprueba que, después de detener el seguimiento, no quede ninguna escucha activa y una lectura posterior no actualice la ubicación. Una prueba adicional de pantalla verifica la liberación al volver desde la ruta del mapa.
4. Las dos pruebas se ejecutaron desde la terminal como parte de la suite del proyecto y finalizaron satisfactoriamente.

**Resultado:** la aplicación clasifica la posición respecto al radio del lugar y verifica mediante pruebas la cercanía y la cancelación del seguimiento.

Las coordenadas del lugar corresponden al ejercicio y no representan una dirección comercial verificada. Los 35 m de precisión se utilizan en las pruebas; la aplicación presenta la precisión que recibe del dispositivo.

## Archivos y líneas afectadas

Las rutas son relativas a la raíz del repositorio. El proyecto móvil se encuentra en **`app/`**. Los rangos corresponden a la numeración actual del código: en archivos nuevos se indica el contenido incorporado; en archivos existentes se señalan los bloques modificados o relevantes para la integración. Los enlaces permiten abrir directamente cada bloque en GitHub.

| Punto del examen | Archivo afectado | Líneas afectadas | Cambio realizado |
|---|---|---|---|
| 1 y 5 | [app/lib/features/ubicacion/domain/ubicacion.dart](app/lib/features/ubicacion/domain/ubicacion.dart#L1-L40) | 1–40, archivo nuevo; entidad 4–8, distancia 10–20, zona 24–39 | Entidad propia, cálculo Haversine, centro del lugar y radio de 150 m. |
| 1 y 3 | [app/lib/features/ubicacion/domain/servicio_ubicacion.dart](app/lib/features/ubicacion/domain/servicio_ubicacion.dart#L1-L13) | 1–13, archivo nuevo | Contrato del servicio de ubicación y error de dominio. |
| 1, 2 y 3 | [app/lib/features/ubicacion/data/servicio_ubicacion_gps.dart](app/lib/features/ubicacion/data/servicio_ubicacion_gps.dart#L1-L113) | 1–113, archivo nuevo; ajustes 58–70, filtros 74–90, cancelación 102–109 | Acceso al GPS, precisión media, intervalo, distancia mínima, errores y log de detención. |
| 1, 2, 3 y 5 | [app/lib/features/ubicacion/presentation/ubicacion_viewmodel.dart](app/lib/features/ubicacion/presentation/ubicacion_viewmodel.dart#L1-L107) | 1–107, archivo nuevo; inyección 22–26, temporizador 41, fallos y selección 64–89, detención 92–105 | Estado de ubicación, servicio inyectado, límite de 10 s, alternativa manual y cierre de la escucha. |
| 1, 2, 3 y 5 | [app/lib/features/ubicacion/presentation/mapa_ubicacion_view.dart](app/lib/features/ubicacion/presentation/mapa_ubicacion_view.dart#L1-L619) | 1–619, archivo nuevo; ciclo de vida 34–114, mapa y círculos 167–214, atribución 292–314, mensajes y coordenadas 448–482 | Pantalla del mapa, coordenadas, precisión, selección por toque y aviso de cercanía. |
| 2 y 5 | [app/lib/core/routes/mapa_route_observer.dart](app/lib/core/routes/mapa_route_observer.dart#L1-L3) | 1–3, archivo nuevo | Observador de rutas para gestionar el ciclo de navegación del mapa. |
| 1 y 2 | [app/lib/core/routes/app_router.dart](app/lib/core/routes/app_router.dart#L71-L77) | 1–3, 23, 71–77 y 120–121 | Imports, ruta `/mapa`, observador, inyección del servicio y acceso público al mapa. |
| 1, 3 y 5 (acceso al mapa) | [app/lib/core/widgets/sitra_app_bar.dart](app/lib/core/widgets/sitra_app_bar.dart#L138-L142) | 138–142 | Botón de acceso al mapa desde los módulos. |
| 1, 3 y 5 (acceso al mapa) | [app/lib/features/auth/presentation/views/login_view.dart](app/lib/features/auth/presentation/views/login_view.dart#L58-L63) | 1 y 58–63 | Import de navegación y botón «Ver mapa de cercanía» en el login. |
| 1 y 2 | [app/android/app/src/main/AndroidManifest.xml](app/android/app/src/main/AndroidManifest.xml#L4-L5) | 4–5 | Permisos de ubicación aproximada y precisa en primer plano. |
| 1, 2 y 3 | [app/pubspec.yaml](app/pubspec.yaml#L54-L62) | 54–62 | Dependencias de mapa, coordenadas y GPS; referencia al plugin Android local. |
| 1, 2 y 3 | [app/pubspec.lock](app/pubspec.lock) | Rangos de resolución generados automáticamente, detallados debajo de la tabla | Versiones resueltas de las dependencias y ruta del plugin Android local. |
| 4 y 5 | [app/test/ubicacion_viewmodel_test.dart](app/test/ubicacion_viewmodel_test.dart#L1-L147) | 1–147, archivo nuevo; simulado 7–34, pruebas del punto 4 en 40–71, pruebas del punto 5 en 73–95 | Servicio simulado, tres pruebas del ViewModel y dos pruebas de cercanía y cancelación, además de casos complementarios. |
| 2, 3 y 5 | [app/test/mapa_ubicacion_view_test.dart](app/test/mapa_ubicacion_view_test.dart#L1-L47) | 1–47, archivo nuevo | Verifica círculo en metros, atribución, aviso de cercanía y liberación al volver desde el mapa. |
| 1 y 2 | [app/test/servicio_ubicacion_gps_test.dart](app/test/servicio_ubicacion_gps_test.dart#L1-L78) | 1–78, archivo nuevo | Configuración de precisión media, 30 s y 50 m, y cancelación durante un permiso pendiente. |
| 1 y 2 | [packages/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java](packages/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java#L78-L112) | 78–112, bloque adaptado del plugin | Selección del proveedor GPS en emuladores para recibir las posiciones de sus controles extendidos. |
| 1 y 2 | [packages/geolocator_android/android/src/test/java/com/baseflow/geolocator/location/EmulatorLocationProviderTest.java](packages/geolocator_android/android/src/test/java/com/baseflow/geolocator/location/EmulatorLocationProviderTest.java#L1-L30) | 1–30, archivo nuevo | Cinco pruebas nativas de selección del proveedor. |
| 1 y 2 | [packages/geolocator_android/SITRA_PATCH.md](packages/geolocator_android/SITRA_PATCH.md#L1-L18) | 1–18, archivo nuevo | Procedencia, alcance y descripción de la corrección local. |
| 1, 2, 3, 4 y 5 | [app/GUIA_MAPA_U2.md](app/GUIA_MAPA_U2.md#L1-L108) | 1–108, archivo nuevo | Documentación técnica del módulo y actualización de Set Location. |
| 1, 2, 3, 4 y 5 | [app/README.md](app/README.md#L1-L21) | 1–21, contenido actualizado | Descripción breve de la aplicación y enlace al README principal. |

**Líneas actualizadas de `app/pubspec.lock`:** 44–59, 80, 83, 132–139, 148–163, 180–187, 276–283, 297–304, 331–393, 418–425, 514–521, 530–537, 590, 593, 598, 601, 606, 609–617, 642–657, 722–729, 754–761, 770–777, 850–857, 939, 942, 951, 953–960, 963, 966, 1023–1030, 1035, 1038, 1071–1086, 1095–1102, 1112–1113. Estos rangos se obtuvieron comparando la entrega actual con el código anterior al examen (`36b90bc`); incluyen dependencias transitivas y versiones resueltas.

La carpeta `packages/geolocator_android/` contiene una copia local de la versión 5.2.1 de Baseflow, con su licencia MIT y archivos de soporte originales. La adaptación funcional se concentra en el bloque de selección de proveedor indicado en la tabla; los demás archivos del paquete permiten que la corrección sea reproducible al clonar el repositorio.

## Compatibilidad y validación realizada

Se corrigió la selección del proveedor para recibir las posiciones GPS enviadas por Set Location en emuladores Android. En dispositivos físicos se conserva la selección original. Se mantienen precisión media, 30 segundos, 50 metros y el límite de 10 segundos; no se fijan coordenadas dentro de la aplicación.

Durante la implementación se verificaron 49 pruebas de Flutter, el análisis estático sin observaciones, cinco pruebas nativas de selección del proveedor Android y la compilación del APK de desarrollo. Esta actualización del README no modifica el código de la aplicación.

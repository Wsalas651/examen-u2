# SITRA-Luz — mapa de cercanía (Examen U2)

## Actualización: Set Location con el proveedor corregido

El repositorio ahora incluye `packages/geolocator_android`, una copia local con licencia MIT que selecciona el proveedor GPS en el emulador. Los controles extendidos envían posiciones GNSS a ese proveedor. La selección en dispositivos físicos y los límites de precisión media, 30 s, 50 m y 10 s no cambian.

1. Detén la ejecución anterior de Flutter con Ctrl+C.
2. Desde la carpeta `app`, ejecuta `flutter pub get` y `flutter run`. Este cambio nativo requiere una reconstrucción; hot reload no basta.
3. Mantén activado Ubicación en Android y Enable GPS signal en Extended controls → Location.
4. Abre el mapa. Pulsa Usar GPS si aparece Tiempo agotado. Envía Set Location durante los siguientes 10 segundos.
5. Para probar dentro, usa -18.0057, -70.2463. Para fuera, usa -18.0039, -70.2463. Después de la primera lectura, espera al menos 30 segundos entre cambios; el movimiento también debe ser de 50 m o más.

Los comandos de proveedor de prueba fused que aparecen más adelante documentan el procedimiento anterior y una alternativa de diagnóstico; no son necesarios para Set Location con la corrección. Si se había activado ese proveedor, debe retirarse con `adb shell cmd location providers remove-test-provider fused` y restaurar el permiso de shell con `adb shell appops set 2000 android:mock_location default`.

## Ejecutar

Desde la carpeta `SITRA-Luz\app`, con un emulador encendido:

```powershell
flutter pub get
flutter run
```

En el login pulsa **Ver mapa de cercanía**. Dentro de los módulos también está disponible el icono de mapa de la barra superior. El mapa es público y no muestra datos de pacientes.

## Verificación automatizada

```powershell
flutter analyze
flutter test --reporter expanded
```

Solo las pruebas nuevas:

```powershell
flutter test --reporter expanded test/ubicacion_viewmodel_test.dart test/mapa_ubicacion_view_test.dart
```

Las pruebas usan un servicio simulado, sin GPS ni emulador. Cubren: construcción sin solicitudes, coordenadas y precisión de 35 m, GPS apagado con una sola solicitud, zona de 150 m, cierre sin escuchas, solicitudes simultáneas, permiso denegado, límite de 10 segundos y cancelación al salir de la pantalla real. La pantalla se comprueba también para radio en metros y atribución.

## Capturas de la app para la evaluación

1. En el emulador abre **⋮ (Extended controls) → Location**. Introduce latitud `-18.0066`, longitud `-70.2463` y envía la posición. Abre el mapa y concede el permiso de ubicación. Captura las coordenadas y **Precisión ± N m**; N es la precisión que reporte Android, no necesariamente 35.
2. Para mostrar **dentro**, fija `-18.0057`, `-70.2463` (aproximadamente 100 m). Para mostrar **fuera**, fija `-18.0039`, `-70.2463` (aproximadamente 300 m). Conserva una captura de cada caso. Durante el seguimiento deben transcurrir al menos 30 segundos entre lecturas aceptadas y existir un desplazamiento de 50 m. Para una primera lectura nueva puedes salir del mapa y volver a entrar.
3. Apaga Ubicación en los ajustes rápidos del emulador. Abre el mapa: debe indicar **GPS apagado**. Toca el mapa para elegir tu punto y captura el resultado. También puedes pulsar **Elegir en mapa** con el GPS disponible.
4. Para comprobar la detención, deja `flutter run` activo y vuelve desde el mapa al login. En la consola aparece **GPS detenido**. Captura la consola inmediatamente después de salir. La app también cancela la escucha al pasar a segundo plano o quedar cubierta por otra pantalla.
5. Si el sistema no entrega ninguna lectura durante 10 segundos, aparece **Tiempo agotado** y se permite elegir en el mapa. Permiso denegado también habilita esta alternativa.

El mapa de OpenStreetMap necesita conexión para descargar sus teselas. El error de GPS mantiene el mapa disponible; la selección manual no solicita ubicación al dispositivo.

## Evidencias de código

| Requisito | Archivo dentro de `app/` |
|---|---|
| Entidad latitud, longitud, precisión y cálculo Haversine | `lib/features/ubicacion/domain/ubicacion.dart` |
| Contrato inyectable y fallo de dominio | `lib/features/ubicacion/domain/servicio_ubicacion.dart` |
| Única clase con import de geolocator; precisión media, 30 s, 50 m, cancelación y log | `lib/features/ubicacion/data/servicio_ubicacion_gps.dart` |
| ViewModel sin import GPS, límite de 10 s y selección manual | `lib/features/ubicacion/presentation/ubicacion_viewmodel.dart` |
| OpenStreetMap, atribución, CircleMarker con useRadiusInMeter y onTap | `lib/features/ubicacion/presentation/mapa_ubicacion_view.dart` |
| Servicio simulado y pruebas de requisitos 4 y 5 | `test/ubicacion_viewmodel_test.dart` |
| Prueba de círculo y liberación al volver desde pantalla | `test/mapa_ubicacion_view_test.dart` |

Para la evidencia de código abre estos archivos y resalta las líneas indicadas por cada requisito. Para la evidencia de terminal ejecuta los comandos anteriores y captura el resultado **All tests passed!**.

## Punto de interés

Se usa **Clínica La Luz** como lugar del negocio, con centro de demostración `-18.0066, -70.2463` y radio de 150 m, según la evaluación. Estas coordenadas no se presentan como dirección comercial verificada. Se cambian en `LugarInteres.clinica`.

No requiere claves de Google Cloud. La ubicación usa permisos de Android en primer plano; no se declara permiso de ubicación en segundo plano.
## Validación realizada y procedencia de capturas

- `flutter analyze --no-pub`: sin observaciones.
- `flutter test --reporter expanded`: 49 pruebas aprobadas; salida completa en `pruebas-flutter.txt`.
- `flutter build apk --debug`: compilación Android verificada.
- `mapa-dentro.png` y `mapa-fuera.png`: capturas reales de la app en el emulador, con lecturas simuladas por el proveedor de prueba de Android (`fused`), precisión de 35 m y puntos a 100 m y 300 m. No son lecturas físicas ni capturas de los controles extendidos. La precisión de 35 m no está fijada en la app.
- `mapa-sin-gps-manual.png`: captura real con ubicación del sistema apagada y selección mediante toque.
- `gps-detenido.txt`: salida real de Logcat al salir del mapa.

**Antes de la corrección del plugin**, el proveedor de precisión media de esta imagen no recibió las posiciones enviadas mediante `geo fix`; la app mostró correctamente **Tiempo agotado**. Para comprobar también la ruta de éxito se inyectaron lecturas en el proveedor de prueba de Android. Al terminar se eliminó ese proveedor de prueba y se restauró Ubicación al estado activado.

Si tus controles extendidos no alimentan el proveedor de precisión media, puedes reproducir la comprobación desde otra terminal (con el mapa abierto). Estos comandos son solo para un emulador de desarrollo:

```powershell
adb shell appops set 2000 android:mock_location allow
adb shell cmd location providers add-test-provider fused
adb shell cmd location providers set-test-provider-enabled fused true
```

Pulsa **Usar GPS**, espera aproximadamente dos segundos y envía:

```powershell
adb shell cmd location providers set-test-provider-location fused --location -18.0057,-70.2463 --accuracy 35
```

Espera al menos 30 segundos y envía el punto exterior:

```powershell
adb shell cmd location providers set-test-provider-location fused --location -18.0039,-70.2463 --accuracy 35
```

Sal del mapa y restaura el emulador:

```powershell
adb shell cmd location providers remove-test-provider fused
adb shell appops set 2000 android:mock_location default
```

La prueba del proveedor y de la cancelación mientras se solicita un permiso está en `test/servicio_ubicacion_gps_test.dart`. Las capturas de código con líneas resaltadas y la captura de la terminal deben tomarse en el editor y terminal para completar el formato de evidencia de la evaluación.

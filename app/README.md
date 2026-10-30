# SITRA-Luz — aplicación móvil del Examen U2

Entrega individual del examen práctico de la Unidad II de Soluciones Móviles II: mapa de ubicación, precisión, consumo moderado, selección manual y zona de cercanía de 150 m.

Consulta el [README principal](../README.md) para el detalle de los cinco apartados, la lista completa de cambios y los archivos móviles afectados. La [guía del examen](GUIA_MAPA_U2.md) describe las evidencias y la simulación de ubicación en Android.

## Ejecutar desde esta carpeta

```powershell
flutter pub get
flutter run
```

Abre **Ver mapa de cercanía** desde el login o el icono de mapa de la barra superior. No se requiere token de Google Cloud. El mapa OpenStreetMap necesita conexión para cargar teselas.

## Verificación

```powershell
flutter analyze --no-pub
flutter test --reporter expanded
flutter build apk --debug --no-pub
```

Solo las pruebas nuevas de ubicación:

```powershell
flutter test --reporter expanded test/ubicacion_viewmodel_test.dart test/mapa_ubicacion_view_test.dart test/servicio_ubicacion_gps_test.dart
```

Las pruebas usan servicios simulados y no necesitan emulador ni GPS. El lugar de interés usa el centro de demostración `-18.0066, -70.2463`; no es una dirección comercial verificada.
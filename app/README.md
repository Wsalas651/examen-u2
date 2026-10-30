# SITRA-Luz — aplicación móvil

Proyecto Flutter del examen práctico individual de la Unidad II de Soluciones Móviles II.

Se implementaron la separación del servicio de ubicación, el seguimiento con precisión media, el mapa OpenStreetMap con radio de precisión, la selección manual, las pruebas del ViewModel y la zona de cercanía de 150 metros.

El [README principal](../README.md) describe los cinco puntos desarrollados y la ubicación de los archivos afectados. El plugin Android utilizado se encuentra en [packages/geolocator_android](../packages/geolocator_android), con una corrección para Set Location en emuladores.

Para ejecutar desde esta carpeta:

```powershell
flutter pub get
flutter run
```

Para verificar el proyecto:

```powershell
flutter analyze --no-pub
flutter test --reporter expanded
```
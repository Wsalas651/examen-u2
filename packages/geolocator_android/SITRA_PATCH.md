# Corrección local para Android Emulator

Base: geolocator_android 5.2.1, de Baseflow (licencia MIT conservada en LICENSE).

Problema: LocationManagerClient selecciona fused antes que gps en Android S o superior. Extended Controls / Set Location entrega posiciones GNSS que el proveedor combinado de algunas imágenes del emulador no retransmite con una petición de precisión media.

Cambio: si Build.HARDWARE identifica un emulador ranchu, goldfish o cutf_cvm y gps está habilitado, se escucha ese proveedor. En dispositivos físicos se conserva la selección original. No se cambian la precisión media (QUALITY_BALANCED_POWER_ACCURACY), los 30 segundos ni los 50 metros; tampoco se amplía el límite de 10 segundos de la app ni se introducen coordenadas simuladas en producción.

Archivos modificados respecto al paquete original:
- android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java
- android/src/test/java/com/baseflow/geolocator/location/EmulatorLocationProviderTest.java (nuevo)

La app utiliza esta copia mediante dependency_overrides en app/pubspec.yaml; no se modifica la caché global de Pub.

Pruebas desde app/android:
```powershell
.\gradlew.bat :geolocator_android:testDebugUnitTest --tests com.baseflow.geolocator.location.EmulatorLocationProviderTest
```
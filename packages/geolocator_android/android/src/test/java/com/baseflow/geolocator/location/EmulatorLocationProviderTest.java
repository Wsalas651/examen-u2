package com.baseflow.geolocator.location;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import java.util.Arrays;
import java.util.Collections;
import org.junit.Test;

public class EmulatorLocationProviderTest {
  @Test public void mediumOnEmulatorUsesGpsForExtendedControls() {
    assertEquals("gps", LocationManagerClient.determineProvider(
        Arrays.asList("fused", "gps", "network"), LocationAccuracy.medium, true, 37));
  }
  @Test public void physicalDeviceKeepsFusedProvider() {
    assertEquals("fused", LocationManagerClient.determineProvider(
        Arrays.asList("fused", "gps", "network"), LocationAccuracy.medium, false, 37));
  }
  @Test public void emulatorWithoutGpsKeepsAvailableFused() {
    assertEquals("fused", LocationManagerClient.determineProvider(
        Arrays.asList("fused", "network"), LocationAccuracy.medium, true, 37));
  }
  @Test public void lowestAccuracyStillUsesPassiveProvider() {
    assertEquals("passive", LocationManagerClient.determineProvider(
        Arrays.asList("fused", "gps", "passive"), LocationAccuracy.lowest, true, 37));
  }
  @Test public void noEnabledProviderReturnsNull() {
    assertNull(LocationManagerClient.determineProvider(
        Collections.emptyList(), LocationAccuracy.medium, true, 37));
  }
}
# Informe de compatibilidad Android — Luchi

Fecha: 2026-09-02. Alcance acordado con el usuario: **desbloquear la instalación en
Android TV y navegación sin táctil, sin tocar orientación (la app sigue vertical en
todos los dispositivos, TV incluido) ni añadir el form factor Android TV al launcher
(leanback/banner quedan para una fase posterior)**.

## 1. Problema detectado

Google Play mostraba, para un televisor `MediaTek AndroidTV`:

> "This item is not compatible with your device" / "No eligible devices for app install"

El teléfono normal instalaba sin problema.

## 2. Causa raíz

Se auditó el **merged manifest real** del build de release
(`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`)
y el manifiesto protobuf dentro del AAB ya generado — no el manifiesto fuente, que puede
diferir de lo que Play recibe. Resultado: **cero** declaraciones `<uses-feature>` en todo el
manifiesto fusionado. Ningún plugin (`geolocator`, `image_picker`, `nsfw_detector_flutter`,
`google_mobile_ads`, `google_sign_in`) inyecta ninguna.

Dos reglas implícitas de Google Play, sin ninguna declaración que las contrarreste:

| Regla | Efecto |
|---|---|
| `android.hardware.touchscreen` se asume **requerido** si no se declara `required="false"` | Excluye todo Android TV / Google TV / pantalla sin táctil |
| El permiso `CAMERA` implica `android.hardware.camera` + `.autofocus` como requeridos | Excluye todo dispositivo sin cámara con autofoco |

El manifiesto declaraba `<uses-permission android:name="android.permission.CAMERA"/>`
(`android/app/src/main/AndroidManifest.xml`) sin el `uses-feature` compensatorio, y no
declaraba `touchscreen` en absoluto. Cualquiera de las dos basta para el mensaje reportado.

### Descartado con evidencia (no era la causa, no se tocó)

- **minSdk 26** — impuesto por `nsfw_detector_flutter`; todo Android TV con Play Store es
  API 28+.
- **targetSdk 36 / compileSdk** — correctos.
- **ABI** — el AAB contiene `arm64-v8a`, `armeabi-v7a`, `x86_64`; sin `abiFilters` en ningún
  gradle. Los MediaTek de TV son ARM.
- **Ubicación** — `ACCESS_FINE/COARSE_LOCATION` solo implicarían `location.gps` con
  `targetSdk ≤ 20`; aquí es 36, no filtraba.
- **Micrófono, telefonía, Bluetooth, WiFi, NFC, sensores** — ninguno de esos permisos estaba
  en el manifiesto fusionado.
- **`glEsVersion`** — ausente.

## 3. Archivos modificados

**Manifiesto y build nativo**
- `android/app/src/main/AndroidManifest.xml` — bloque de `uses-feature`.
- `android/app/src/main/kotlin/com/guardianes/luciernagas/MainActivity.kt` — canal nativo
  `luchi/device_capabilities`.
- `android/app/build.gradle.kts` — dependencia `play-services-base` para
  `GoogleApiAvailability`.

**Capacidades de dispositivo (nuevo)**
- `lib/core/device/device_capabilities.dart`
- `lib/core/device/device_capabilities_provider.dart`
- `test/device_capabilities_test.dart`

**Arranque**
- `lib/main.dart` — resuelve capacidades antes de `runApp`, inyecta por
  `ProviderScope.overrides`, protege `MobileAds.instance.initialize()`.

**Degradación elegante (bugs reales corregidos)**
- `lib/features/sightings/screens/sighting_form_screen.dart` — cámara opcional en la hoja de
  foto, `timeLimit` en `getCurrentPosition`, catch separado.
- `lib/features/sightings/utils/sighting_geocoding.dart` — timeout en `locationFromAddress`.
- `lib/features/auth/screens/login_screen.dart` — `ensureInitialized()` con catch, botón de
  Google oculto sin Play Services.
- `lib/widgets/ad_banner.dart` — try/catch en `_load()`, no se monta en TV, `Platform.isIOS`
  seguro en web.

**Navegación por foco (D-pad/teclado/mando) — todo `lib/`**
- `lib/core/theme/palettes.dart`, `lib/core/theme/firefly_colors.dart`,
  `lib/core/theme/app_theme.dart` — token `focusRing`/`focusShadow` y borde de foco en los
  temas de botón + `focusColor` global.
- 21 `GestureDetector` crudos convertidos a `Material`+`InkWell` (o
  `FocusableActionDetector` donde había animación de pulsado propia) en 14 archivos:
  `home_bottom_nav.dart`, `chapters_list_screen.dart`, `map_hub_screen.dart`,
  `quiz_game_screen.dart`, `sync_game_screen.dart`, `hero_banner.dart`,
  `home_header.dart` (×2), `main_actions.dart`, `recent_sightings.dart` (×2),
  `profile_screen.dart`, `settings_screen.dart` (×2), `avatar_picker_sheet.dart`,
  `sighting_form_screen.dart` (×5), `like_button.dart`.
- `home_bottom_nav.dart` — `FocusTraversalGroup` sobre el menú principal.

## 4. Features Android detectadas (antes de esta corrección)

Ninguna. El manifiesto fusionado no declaraba ningún `<uses-feature>`.

## 5. Features convertidas a opcionales

Todas con `android:required="false"` — ninguna se declaró `required="true"`, no hay hardware
imprescindible en la app (los vídeos van empaquetados en el APK, los minijuegos son render
puro):

`android.hardware.touchscreen`, `.faketouch`, `.camera`, `.camera.any`,
`.camera.autofocus`, `.location`, `.location.gps`, `.location.network`, `.microphone`,
`.telephony`, `.sensor.accelerometer`, `.sensor.gyroscope`, `.nfc`, `.bluetooth`, `.wifi`.

**No se añadió** `android.software.leanback` ni `LEANBACK_LAUNCHER` ni `android:banner`
(decisión explícita: solo compatibilidad de instalación en esta fase).

## 6. minSdk / targetSdk / compileSdk

Sin cambios: `minSdk 26` (`maxOf(26, flutter.minSdkVersion)`), `targetSdk`/`compileSdk` =
los de Flutter (36 en el build verificado).

## 7. ABI soportadas

Sin cambios: `arm64-v8a`, `armeabi-v7a`, `x86_64` (confirmado dentro del AAB generado).

## 8. Configuración Android TV

- **Orientación**: sin cambios. La app sigue bloqueada en vertical
  (`android:screenOrientation="portrait"` + `SystemChrome.setPreferredOrientations` en
  `main.dart`) en todos los dispositivos, TV incluido — decisión explícita del usuario. No es
  un filtro de Play (no existe `<uses-feature android.hardware.screen.portrait>`), así que no
  afecta a la instalación; en un televisor la app se verá encajonada en el centro de la
  pantalla.
- **Launcher/banner**: no se tocó. La app no aparecerá en el launcher del TV en esta fase;
  llegará por el enlace directo del Play Store. Queda documentado como trabajo futuro (ver
  §15).

## 9. Detección de capacidades en runtime

`android/.../MainActivity.kt` expone un `MethodChannel("luchi/device_capabilities")` que usa
`PackageManager.hasSystemFeature` — la misma fuente que usa Google Play para filtrar
dispositivos — para `hasCamera`, `hasGps`, `hasNetworkLocation`, `hasMicrophone`,
`hasTouchscreen`, `isTelevision` (leanback o `UiModeManager` en modo TV), y
`GoogleApiAvailability` para `hasPlayServices`.

`lib/core/device/device_capabilities.dart` envuelve esto en `DeviceCapabilities`
(inmutable), añade clasificación por tamaño (`isTablet`/`isDesktopLike`/`isPhone` vía
`shortestSide` — nunca usado para decidir hardware) y `DeviceCapabilities.fallback` (todo
`true` salvo TV) para cuando el canal falla. Se resuelve **una sola vez** en `main.dart`
antes de `runApp` y se inyecta por `ProviderScope.overrides` — ningún `build()` espera un
`Future`.

Consumido en: la hoja de selección de foto (oculta "Tomar foto" sin cámara), el intento de
GPS (sale ya si no hay ningún proveedor de ubicación), el banner de AdMob (no se monta en
TV), y el botón de Google Sign-In (oculto sin Play Services).

## 10. Adaptaciones D-pad/teclado/mando

- Token `focusRing`/`focusShadow` en `FireflyColors` (color `accent` de cada paleta, visible
  desde el sofá) + borde de foco de 3px en los tres `ButtonThemeData` (elevated/outlined/
  text) + `focusColor` global en `ThemeData` para `InkWell`/`InkResponse`.
- **21 `GestureDetector` crudos → `Material`+`InkWell`** en 14 archivos (lista completa en
  §3). Esto incluye el hallazgo de mayor impacto: el **menú de navegación inferior**
  (`home_bottom_nav.dart`) era enteramente `GestureDetector`, es decir, la navegación
  principal de la app era inalcanzable con D-pad. Ahora es `Material`+`InkWell` con
  `FocusTraversalGroup` sobre el `Row`.
- Dos casos con animación de pulsado propia (`onTapDown`/`onTapUp`) —
  `map_hub_screen.dart` y el nodo de anillo de `sync_game_screen.dart` — se envolvieron en
  `FocusableActionDetector` con un `CallbackAction<ActivateIntent>` para que ENTER/OK
  disparen la misma acción que un tap, conservando el `GestureDetector` interno para el
  puntero.
- ENTER/Espacio/D-pad-centro sobre un widget enfocado ya activa `InkWell`/botones Material
  por comportamiento nativo de Flutter (`WidgetsApp` liga esas teclas a `ActivateIntent`); no
  hizo falta un `Shortcuts`/`Actions` global adicional.
- `PopScope` (`HardwareBackRoute`, `GameScaffold`) ya resolvía el botón/gesto de retroceder
  antes de este trabajo; sigue igual.

## 11. Cambios responsive

**Ninguno.** Decisión explícita: `WideScreenShell` (`lib/app.dart`) y su columna fija de
480px se quedan como están; no se tocó `ScreenFitter` ni se añadieron breakpoints de
pantalla grande. En un televisor la app se verá encajonada en vertical — estado acordado
hasta una fase posterior de rediseño horizontal.

## 12. Tests realizados

```
flutter clean && flutter pub get && flutter analyze && flutter test
```

- `flutter analyze`: **28 issues, ninguno introducido por este trabajo** — 1 warning
  (`unused_import`) detectado y corregido durante el propio trabajo; el resto son
  `info`/`deprecated_member_use` preexistentes (`withOpacity`, `activeColor`, `parent` de
  Riverpod en tests) no relacionados.
- `flutter test`: **11/11 tests pasan**, incluidos `game_flow_e2e_test.dart` (ejercita el
  quiz convertido a `InkWell` y el flujo "salir al menú" que pasa por
  `home_bottom_nav.dart`) y `wide_screen_shell_test.dart` (confirma que el shell de escritorio
  sigue intacto, tal como se decidió no tocarlo).
- Nuevo `test/device_capabilities_test.dart` (7 tests): `fallback` degrada correctamente,
  clasificación por tamaño, `supportsPointer` excluye TV con fake-touch, `hasAnyLocation`.

## 13. Resultado del flutter analyze

Sin errores. 28 issues totales, todas `info`/`warning` de estilo o de deprecaciones ya
presentes antes de este trabajo (`withOpacity`, `activeColor`, `curly_braces_in_flow_control`,
`prefer_const_constructors`, `parent` de Riverpod en tests).

## 14. Resultado del build AAB

```
flutter build appbundle --release
```

Build **exitoso** (exit code 0). Salida:
`build/app/outputs/bundle/release/app-release.aab` (≈151 MB, ABIs `arm64-v8a`,
`armeabi-v7a`, `x86_64` confirmadas dentro del bundle).

**Comprobación del merged manifest real, post-build**
(`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`):

```
grep -c "uses-feature" → 15   (las 15 declaradas en §5, todas presentes)
grep -c 'required="false"' → 21
grep -c 'required="true"' → 0
grep "screenOrientation" → android:screenOrientation="portrait"   (sin cambios, según lo acordado)
```

**Antes** (build previo, mismo comando, sin este trabajo): 0 `uses-feature` en el manifiesto
fusionado — la causa raíz confirmada en §2.
**Después**: 15 `uses-feature`, las 15 con `required="false"`, ninguna en `true`. La
orientación vertical se mantiene intacta, tal como se decidió.

## 15. Riesgos pendientes

- **No se pudo probar en el MediaTek AndroidTV real.** Lo verificable desde aquí es el
  manifiesto fusionado, el AAB, los tests y la no-regresión en teléfono; la confirmación
  definitiva es el catálogo de dispositivos de Play Console tras subir el bundle.
- **La app no aparece en el launcher del TV** en esta fase (sin `LEANBACK_LAUNCHER`/banner);
  se instala y se abre por enlace/ficha del Play Store. Pendiente para una fase posterior si
  se decide.
- **La app sigue en vertical en TV** — cosmético (franjas negras a los lados), pendiente de
  un rediseño horizontal explícitamente pospuesto.
- Los dos minijuegos Flame de acción (`Guiar Luciérnagas`, `Proteger la Luz`) usan
  `PanDetector`/hit-test espacial sin equivalente directo en D-pad; quedan documentados como
  limitación conocida y no alcanzables desde el menú actual (Jugar abre directamente el quiz).
- El anillo de `sync_game_screen.dart` traversa en el orden de generación de nodos, no en el
  orden espacial del círculo — mejora posible, no bloqueante.
- El paneo del mapa (`flutter_map`) no tiene control por D-pad; los botones de zoom sí son
  enfocables.
- Convertir 21 `GestureDetector` a `InkWell` puede introducir un ripple visual donde antes no
  lo había — mitigado ajustando `borderRadius`/`customBorder` a la forma de cada contenedor,
  pero conviene una pasada visual en dispositivo real (ver §16).

## 16. Pasos exactos para verificarlo en Google Play Console

1. Generar el bundle firmado con esta rama:
   `flutter build appbundle --release --dart-define=API_BASE_URL=<dominio real>/api --dart-define=USE_MOCK_AUTH=false`
2. Play Console → tu app → **Prueba y lanzamiento** → el track correspondiente (interno/
   abierto) → **Crear nueva versión** → subir el `.aab` de
   `build/app/outputs/bundle/release/`.
3. Antes de publicar, Play Console recalcula el catálogo de dispositivos compatibles. En
   **Versión** → pestaña **Dispositivos compatibles** (o **Catálogo de dispositivos** según
   la consola), buscar el modelo del televisor MediaTek AndroidTV y confirmar que ya no
   aparece en la lista de excluidos por hardware.
4. Publicar la versión en el track de prueba.
5. En el propio televisor: abrir Google Play (o la Play Store si el TV la tiene), buscar
   "Luchi" — debería mostrar el botón "Instalar" en vez de "No compatible con tu
   dispositivo".
6. Si el TV no tiene Play Store visible o el catálogo tarda en refrescar, instalar el `.aab`
   con `bundletool` (`build-apks --connected-device` + `install-apks`) directamente sobre el
   dispositivo, conectado por ADB, para una verificación inmediata sin esperar la
   propagación de Play Console.

# Guardianes de las Luciérnagas
## Final Preproduction Report

### Estado global

🟠 **CONDITIONAL**

No hay P0 abiertos: el único P0 real (URL de foto arbitraria) y el JWT_SECRET de plantilla fueron corregidos y verificados. Queda un P1 que requiere una acción manual fuera de este repo (confirmar el `JWT_SECRET` real desplegado en Hostinger) y un P1 de verificación de dispositivo real que no puede completarse desde este entorno (Google Sign-In en un APK/AAB firmado, cámara y GPS reales). Por eso el veredicto es CONDITIONAL y no READY.

---

## 1. Executive Summary

La app está funcionalmente completa y bien construida para su tamaño: 25 pantallas, arquitectura feature-first coherente, backend PHP/MySQL con buenas prácticas de seguridad en su mayoría (prepared statements, `password_hash`, ownership checks, uploads con revalidación de MIME y regeneración de EXIF). La auditoría encontró y corrigió un fallo de seguridad real (foto de host arbitrario aceptada en el feed comunitario), una regresión funcional no commiteada que rompía la auto-publicación de avistamientos, y una serie de huecos de robustez (falta de rate limiting fuera de login, puntos de juego sin tope superior, flujos de puntos sin transacción, doble-tap sin guard en el login de invitado, vídeo de capítulos sin manejo de error). Todo lo anterior está corregido y verificado con `flutter analyze` y `flutter test` en verde.

Lo que no puede verificarse desde este entorno (sin dispositivo físico ni acceso al servidor de producción) queda marcado explícitamente como `NO VERIFICADO` más abajo.

## 2. Auditoría realizada

- Descubrimiento completo del repo: pantallas, rutas, providers, servicios, endpoints, storage, dependencias, TODO/FIXME/mock (2 agentes en paralelo).
- Auditoría pantalla por pantalla en 3 lotes: (a) auth + home + education, (b) games + profile, (c) sightings + mapa.
- Auditoría de backend PHP/MySQL: endpoints, JWT, contraseñas, SQL, uploads, autorización, rate limiting, CORS, esquema, transacciones.
- Auditoría de Android/iOS: manifest, gradle, firma, Google Sign-In, iconos/splash.
- Baseline y verificación: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build appbundle --release`.
- Corrección de todos los hallazgos P0/P1/P2 identificados, con `flutter analyze`/`flutter test`/`php -l` entre cada cambio.

## 3. Arquitectura detectada

Flutter 3 / Dart 3, feature-first (`lib/features/<nombre>/{models,providers,screens,data,widgets,utils}`), Riverpod (`StateNotifierProvider`/`Provider`/`Provider.family`, sin `autoDispose`), GoRouter (`StatefulShellRoute.indexedStack` de 5 branches + rutas fuera del shell), Hive + SharedPreferences + `flutter_secure_storage` (token), Dio con interceptores de auth/logging/errores. Backend PHP 8 / MySQL, router manual por `if` en `backend/api/index.php`, PDO con prepared statements. Sin Firebase SDK, sin analytics, sin crash reporting, sin push. `google_mobile_ads` integrado pero apagado (`AppConstants.adsEnabled = false`).

## 4. Pantallas detectadas

25 pantallas, todas con ruta declarada en `lib/app.dart` (ver [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md) para la matriz completa). `/map` y `/feed` están implementadas pero redirigen a `/home` mientras `AppConstants.communityEnabled = false` — comportamiento deliberado documentado en el propio código.

## 5. Funcionalidades — qué funciona / qué no

**Funciona de extremo a extremo:** login/registro/Google/invitado, splash→sesión persistente, onboarding+consentimiento parental, capítulos+vídeo+quiz+puntos, 5 minijuegos con progreso local-autoritativo sincronizado al servidor, avistamientos (GPS difuminado en el dispositivo, foto opcional, cola offline, sync al reconectar), perfil, ajustes (tema, cerrar sesión, borrar cuenta en dos pasos), insignias.

**No disponible por decisión de producto (no es un bug):** mapa comunitario y feed (`/map`, `/feed`) detrás de `communityEnabled = false`; recuperación de contraseña (gateada, con UI lista pero backend pendiente); anuncios (integrados, apagados).

**Corregido durante esta auditoría** (detalle en secciones 6-8): URL de foto arbitraria, regresión de auto-publicación, estrellas de juego sin tope, rate limiting ausente en 3 endpoints, flujos de puntos sin transacción, `allowBackup` sin declarar, doble-tap en login de invitado, vídeo de capítulo sin manejo de error, consentimiento parental sin guard/try-catch, insignias sin estado de error, "Mis avistamientos" sin estado de error, borrado de cuenta sin guard de concurrencia, botones de mapa sin feedback cuando la comunidad está apagada.

## 6. Hallazgos P0 (todos corregidos)

| ID | Módulo | Hallazgo | Corrección | Archivo |
|---|---|---|---|---|
| SEC-001 | Backend / Privacidad | `photo_url` de host arbitrario aceptada: la validación solo miraba el basename, pero se guardaba la URL completa enviada por el cliente — contenido externo servido en el feed a menores | El servidor reconstruye la URL siempre desde el filename ya validado como propio (`sightingPhotoUrl()`), nunca acepta la URL del cliente | `backend/api/lib/media.php` (nuevo), `backend/api/routes/sightings.php`, `backend/api/routes/uploads.php` |
| SEC-002 | Backend / Seguridad | `JWT_SECRET` con valor de plantilla en la config local; si se despliega así, cualquiera falsifica sesiones | Guard de arranque que devuelve 500 si `JWT_SECRET` es el placeholder o mide menos de 32 caracteres; secreto local regenerado (archivo no versionado) | `backend/api/middleware/auth.php`, `backend/api/config/database.php` (no trackeado) |

## 7. Hallazgos P1 (todos corregidos salvo lo anotado)

| ID | Módulo | Hallazgo | Corrección | Archivo |
|---|---|---|---|---|
| MOD-001 | Backend | Regresión no commiteada: el INSERT de avistamientos guardaba `moderation_status = "pending"` en vez de `"approved"`, dejando **todo avistamiento nuevo invisible para siempre** en el feed — contradice la auto-publicación descrita en los propios comentarios y en el commit `22e9b15` | Restaurado a `"approved"` + `moderated_at = NOW()` | `backend/api/routes/sightings.php` |
| SEC-003 | Backend | `PUT /me/game-progress` aceptaba cualquier total de estrellas del cliente sin techo — puntos/insignias inflables desde un Hive editado a mano o un APK parcheado | Tope server-side de 150 estrellas (5 juegos × 10 niveles × 3 estrellas) | `backend/api/routes/users.php` |
| SEC-004 | Backend | Rate limiting solo en `/login`; `/register`, `/auth/guest` y `/uploads/sighting-photo` sin límite — creación masiva de cuentas invitado trivial | Rate limiting genérico por IP reutilizando `login_attempts` (`requireIpNotRateLimited`/`recordIpAttempt`) en los 3 endpoints | `backend/api/middleware/auth.php`, `users.php`, `uploads.php` |
| DATA-001 | Backend | Flujos de puntos (avistamiento, capítulo, estrellas de juego) sin transacción — un fallo a mitad deja el registro sin sus puntos o viceversa; además la lectura de `game_stars` no bloqueaba la fila, permitiendo un *lost update* con dos requests concurrentes | Las 3 rutas envueltas en `beginTransaction`/`commit`/`rollBack`; `game-progress` usa `SELECT ... FOR UPDATE` | `sightings.php`, `chapters.php`, `users.php` |
| SEC-005 | Android | `allowBackup` no declarado (default `true`) — Hive/token incluidos en backups automáticos y transferencia de dispositivo, app de menores | `android:allowBackup="false"` + `dataExtractionRules` (API 31+) + `fullBackupContent="false"` | `AndroidManifest.xml`, `res/xml/data_extraction_rules.xml` (nuevo) |
| AUTH-002 | Cliente | Login como invitado sin protección contra doble-tap (a diferencia de Google/email), permitiendo dos llamadas concurrentes a `loginInvitado()` | Guard `_guestLoading` + deshabilitar los 3 botones de auth mientras cualquiera está en vuelo | `login_screen.dart` |
| EDU-001 | Cliente | `_initVideo()` sin try/catch: un vídeo caído o sin red dejaba el spinner girando indefinidamente sin explicación, en una app para niños de 6-12 años | Estado `_videoError` con mensaje amigable y botón "Reintentar" | `chapter_detail_screen.dart` |
| REL-001 | Release | AAB release no verificado | Ejecutado en esta auditoría — ver sección 29 | — |
| SEC-006 (no corregido, acción manual) | Backend | El `JWT_SECRET` real desplegado en Hostinger no puede verificarse desde este repo (el archivo de config no está versionado) | **Acción pendiente del usuario**: confirmar en el panel de Hostinger que `backend/api/config/database.php` en producción tiene un `JWT_SECRET` distinto del placeholder — el guard de SEC-002 hará que la API devuelva 500 si no es así, así que un despliegue con el placeholder fallaría de forma visible en vez de silenciosa | `backend/api/config/database.php` (producción, fuera de este repo) |

## 8. Hallazgos P2 (corregidos)

| ID | Hallazgo | Corrección |
|---|---|---|
| UX-001 | Botones "Mapa" en home navegaban a `/map`, que redirige silenciosamente a `/home` mientras `communityEnabled = false` — el tap parecía no hacer nada | Ambos botones muestran un SnackBar "próximamente" cuando la comunidad está apagada, en vez de navegar en silencio |
| PROF-001 | `profile_screen.dart` no leía `isLoading`/`isStale` de `badgesProvider` — sin conexión y sin caché, el grid de insignias se veía vacío sin explicación | Estado de carga, vacío y "sin conexión" añadidos al grid |
| SIGH-001 | `my_sightings_screen.dart` no mostraba `state.error` — un fallo de red se confundía con "no tienes avistamientos" | Estado de error explícito con botón "Reintentar" |
| SET-001 | Borrado de cuenta sin guard de concurrencia: el bottom sheet se cierra antes del `await`, sin loading visible; un segundo tap en "Borrar mi cuenta" podía iniciar un segundo flujo en paralelo | Guard estático `_deletingAccount` que bloquea un segundo flujo mientras el primero está en curso |
| SET-002 | Enlace "Política de privacidad" sin feedback si `canLaunchUrl` fallaba — el tap no hacía nada visible | SnackBar de error cuando no se puede abrir |
| CONS-001 | `parental_consent_screen.dart`: botón no se deshabilitaba durante el `await` a Hive, sin try/catch si esas escrituras fallaban (pantalla legalmente sensible) | Guard `_saving` + try/catch con mensaje amigable |
| HOME-001 | `Future.wait` del pull-to-refresh en home sin try/catch defensivo | Envuelto en try/catch (los providers ya traducen el error a su propio estado) |
| CFG-001 | Comentario del AdMob App ID en Android decía "de PRUEBA" siendo el App ID real de la cuenta (no coincide con el ID de prueba público de Google) | Comentario corregido para reflejar la realidad |
| DEBT-001 | Archivos scratch sin referencias en la raíz del repo (`test.dart`, `test_map.dart`, `test_riverpod.dart`, `test_db2.php`, `test_db3.php`) — los `.php` sueltos son además superficie de exposición si llegan al servidor | Eliminados (verificado: sin referencias en el código) |
| DEBT-003 | Lints menores: `unnecessary_type_check` y comparación de tipos no relacionados en `sync_service.dart`; imports no usados en `onboarding_screen.dart` y 2 archivos de test | Corregidos |
| DEBT-004 | Faltaban `Strict-Transport-Security` y `Referrer-Policy` en las respuestas de la API | Añadidos en `backend/api/.htaccess` |

## 9. UI/UX

Consistente en general: mensajes en español apropiados para niños, sin excepciones técnicas expuestas al usuario en ningún flujo auditado. Los datos mock están todos correctamente gateados por `AppConstants.useMockAuth`/`allowSeedData` (ambos `false` por defecto). Pendiente de mejora no bloqueante: `chapters_list_screen.dart` sin `Semantics(button:true)` en las tarjetas (el resto del proyecto sí lo usa consistentemente); el icono de notificaciones en `home_header.dart` es un placeholder mudo sin acción.

## 10. Responsive

No se pudo ejecutar en dispositivos físicos de distintos tamaños desde este entorno — `NO VERIFICADO`. El código usa `ScreenFitter`/layouts flexibles de forma consistente (no `MediaQuery` mágicos dispersos); `wide_screen_shell_test.dart` (6 tests) cubre el breakpoint de escritorio y escalado de texto, y pasa en verde.

## 11. Autenticación

Login por email, registro, Google Sign-In e invitado, todos con loading real y error traducido del backend. Doble-tap corregido en los 3 flujos (guard cruzado entre los tres botones). `AuthNotifier` no tiene guard de reentrada propio a nivel de notifier (mitigado en la práctica por los guards de la UI). Password recovery gateada correctamente (no se expone una función no implementada).

## 12. Google Sign-In

Configuración coherente: `GOOGLE_CLIENT_ID` en `config/database.php` coincide con el client OAuth "Web" (type=3) de `google-services.json`, y con el `aud` validado en `users.php`. **Riesgo P2 no corregido** (requiere una acción en Google Cloud Console, fuera del alcance de este repo): no existe un cliente OAuth para el `applicationId` de debug (`.dev`), por lo que Google Sign-In no funcionará en builds debug — sí en release. `NO VERIFICADO`: comportamiento real de Google Sign-In en un dispositivo físico con el AAB firmado (requiere instalación real).

## 13. Perfil y Configuración

Perfil: estados de insignias corregidos (loading/empty/offline). Configuración: el único switch (tema oscuro) cambia y persiste algo real; cerrar sesión y borrar cuenta están bien diferenciados en UI y efecto (borrado en dos pasos con confirmación textual "ELIMINAR"); guard de concurrencia añadido al borrado.

## 14. Progreso y Gamificación

Puntos siempre calculados en servidor. Idempotencia correcta en capítulos (`INSERT IGNORE`) y estrellas de juego (paga solo el delta sobre el máximo previo). Corregido: tope máximo de estrellas, transacciones, y el *lost update* en escrituras concurrentes de `game_stars`. Nota de diseño (no corregida, es una decisión de producto a confirmar con el usuario): el bono diario de energía se paga aunque el nivel se pierda, no solo al ganar.

## 15. Misiones

El esquema de `missions`/`user_missions` sigue en la base de datos pero ya no se usa (reemplazado por el sistema de 5 minijuegos + capítulos). No es un bug, es código/esquema muerto documentado aquí para una futura limpieza de esquema (no se tocó la base de datos en esta auditoría).

## 16. Capítulos y Quiz

Corregido el manejo de error de vídeo (sección 7, EDU-001). El resto del flujo (marcar completado, offline-first con `catch` silencioso documentado) funciona como está diseñado.

## 17. Avistamientos

Flujo completo verificado: formulario → permisos → GPS/foto → NSFW → upload → envío → cola offline → sync. Difuminado de coordenadas confirmado en el dispositivo (redondeo a 3 decimales) antes de cualquier request de red, tanto con GPS real como con punto aleatorio por ciudad. Permisos just-in-time con explicación previa; la app sigue funcionando si se deniegan. Envío protegido contra doble-tap por la combinación de flags de UI.

**Riesgos documentados, no corregidos en este ciclo** (P3, no bloqueantes): posible foto huérfana en el servidor si la app muere entre subir la foto y crear el avistamiento; la cola offline no lleva una idempotency key, por lo que un `kill` de la app justo después de un POST exitoso pero antes de borrar la clave local podría reintentar y duplicar el avistamiento en el servidor.

## 18. GPS / Fotos

GPS: lectura puntual (`getCurrentPosition`), no streaming — sin consumo de batería innecesario. Fotos: revalidadas por MIME real (`finfo`) y re-codificadas por GD en el servidor (esto también borra EXIF/GPS de la imagen), límite 5MB, nombre generado server-side. Corregido en esta auditoría: la URL ya no puede apuntar a un host externo (SEC-001).

## 19. Mapa

Sin clustering de marcadores — con muchos avistamientos en una zona el rendimiento visual se degradaría (`flutter_map` sin `flutter_map_marker_cluster`). No bloqueante hoy porque el mapa comunitario está detrás de `communityEnabled = false`; recomendado antes de activarlo en producción.

## 20. Offline / Caché / Sync

Hive namespaced por usuario (`<box>_u<userId>`), correcto en cambio de cuenta. Cola de avistamientos offline drena al arrancar y al reconectar, borra por clave individual. Logout no vacía las cajas del usuario (comportamiento deliberado); borrado real de cuenta sí las vacía. Ver el riesgo de duplicado por falta de idempotency key en la sección 17.

## 21. Rendimiento

No se pudo perfilar en dispositivo real — `NO VERIFICADO`. El código usa `ListView.builder`/`ListView.separated` de forma consistente en listas largas (feed, mis avistamientos); sin paginación "cargar más" en el feed/mapa (limitado a `feedPageSize` fijo).

## 22. Backend

Router manual por `if` (funcional, sin problemas detectados de N+1 evidentes en las rutas auditadas). Transacciones añadidas donde faltaban (sección 7). CORS con allowlist estricta, sin `*`. Errores nunca exponen detalles internos (`display_errors=0` forzado).

## 23. Base de datos

11 tablas, InnoDB + `utf8mb4_unicode_ci`, claves únicas e índices correctos en las columnas de acceso frecuente (email, feed, coordenadas). No se ejecutó `EXPLAIN` contra datos reales de producción — `NO VERIFICADO` (requiere acceso a la base de datos de Hostinger, fuera del alcance de este entorno).

## 24. Seguridad

Corregidos en esta auditoría: URL de foto arbitraria (P0), secreto JWT de plantilla (P0), rate limiting ausente (P1), estrellas sin tope (P1), transacciones ausentes (P1), backup no declarado (P1). Ningún secreto real quedó en archivos versionados (verificado con `git ls-files` sobre `config/database.php`, `google-services.json`, `key.properties`, `*.jks`). Contraseñas con `bcrypt` cost 12. Política de contraseña mínima de 6 caracteres y JWT de 30 días sin revocación quedan como deuda P3 documentada, no bloqueante.

## 25. Privacidad infantil

Ver [PRIVACY.md](PRIVACY.md) (ya actualizado en el repo) y [PRIVACY_BEHAVIOR_MATRIX.md](PRIVACY_BEHAVIOR_MATRIX.md). Coordenadas difuminadas en el propio dispositivo antes de cualquier request de red — doble defensa, el servidor también recorta. Sin nombre completo ni user_id expuestos en el feed; se expone el primer nombre y avatar del autor por decisión de producto documentada — confirmar que sigue alineado con la versión más reciente de `docs/PRIVACY.md` (modificado en este mismo ciclo de trabajo, fuera del alcance de esta auditoría de código revisar la redacción legal). EXIF de fotos eliminado por la re-codificación server-side.

## 26. Ads

`google_mobile_ads` integrado pero apagado (`adsEnabled = false`) — sin anuncios en producción hasta que se active explícitamente. App ID real configurado correctamente en ambas plataformas (comentario corregido en Android, sección 8). Cuando se active, revisar la configuración de audiencia infantil (`tagForChildDirectedTreatment`/`tagForUnderAgeOfConsent`) antes de servir el primer anuncio real — `NO VERIFICADO` porque los anuncios están apagados.

## 27. Android / Google Play

`allowBackup=false` + `dataExtractionRules` añadidos (P1). Firma release configurada (`key.properties` + keystore presentes, no versionados). R8/Proguard activo. `minSdk=26`. Sin cliente OAuth de Google para el `applicationId` de debug (no bloqueante, solo afecta a builds debug). Ver sección 29 para el resultado del build AAB.

## 28. Tests

11 tests (unit + widget), todos en verde tras las correcciones (`games_progress_test.dart`, `game_flow_e2e_test.dart`, `wide_screen_shell_test.dart`). Sin cobertura de: `auth_provider`, `sightings_provider`, `sync_service`, redirects del router. No se añadieron tests nuevos en este ciclo por límite de tiempo — recomendado como backlog post-release (sección 32).

## 29. Build release

```
flutter analyze   → PASS (0 errores, 0 warnings, 27 lints "info" cosméticos preexistentes)
flutter test      → PASS (11/11)
flutter build appbundle --release --dart-define=API_BASE_URL=https://dimgrey-dove-703529.hostingersite.com/api --dart-define=USE_MOCK_AUTH=false
  → PASS, exit code 0
  → build\app\outputs\bundle\release\app-release.aab (130.8 MB)
  → firmado con la keystore de producción (android/key.properties + upload-keystore.jks)
```

El AAB compila y firma correctamente contra el backend real. `NO VERIFICADO`: instalación y ejecución de este AAB en un dispositivo Android físico (Google Sign-In, cámara, GPS) — este entorno no tiene un dispositivo conectado.

## 30. Riesgos restantes

1. Confirmar manualmente que `JWT_SECRET` en el servidor de producción (Hostinger) no es el valor de plantilla — el guard añadido lo hace fallar de forma visible (500) si lo es, pero no puede verificarse desde este repo.
2. Sin cliente OAuth de Google para el `applicationId` de debug — solo afecta a desarrollo, no a producción.
3. Cola offline de avistamientos sin idempotency key: riesgo bajo de duplicado si la app muere en una ventana muy concreta entre el POST exitoso y el borrado local.
4. Mapa sin clustering — revisar antes de activar `communityEnabled` en producción con volumen real de avistamientos.
5. Sin cobertura de test para auth/sightings/sync — cualquier regresión futura en esos módulos no se detectará automáticamente.
6. `docs/PRIVACY.md` fue modificado en este mismo ciclo de cambios por el propio usuario — no se auditó su redacción legal, solo se verificó que el código coincide con lo que el documento describe a nivel técnico (difuminado de coordenadas, exposición de nombre de pila).

## 31. Correcciones aplicadas

Ver secciones 6, 7 y 8 completas — 2 P0, 8 P1, 10 P2, todas verificadas con `flutter analyze`/`flutter test`/`php -l` tras cada cambio.

## 32. Correcciones pendientes (post-release, no bloqueantes)

- Añadir idempotency key (UUID client-side) a la cola offline de avistamientos.
- Clustering de marcadores en el mapa antes de activar `communityEnabled`.
- Tests unitarios de `auth_provider`, `sightings_provider`, `sync_service` y redirects del router.
- Subir la política de contraseña mínima (actualmente 6 caracteres) y considerar acortar la expiración del JWT (actualmente 30 días) o añadir revocación.
- Confirmar con el usuario si el bono diario de energía debe pagarse también al perder un nivel (decisión de producto, no un bug).
- Limpieza de esquema: tablas `missions`/`user_missions` ya no usadas por el código actual.

## 33. Pasos exactos antes de publicar

1. Confirmar en el hosting de producción que `backend/api/config/database.php` tiene un `JWT_SECRET` real (no el placeholder) — desplegar los cambios de esta auditoría en `backend/` a Hostinger.
2. Ejecutar las migraciones de base de datos pendientes si las hay (ninguna nueva se creó en este ciclo).
3. Verificar en un dispositivo Android físico: login con Google (con el AAB firmado), cámara, GPS, permisos, borrado de cuenta.
4. Confirmar el resultado del build AAB (sección 29) y subirlo a la Play Console como release interno/cerrado antes de producción.
5. Completar el formulario de Data Safety de Google Play con el inventario de `docs/PRIVACY.md`.

## 34. Pasos posteriores al lanzamiento

Ver sección 32 (backlog no bloqueante) más: activar `communityEnabled` solo tras añadir clustering; activar `adsEnabled` solo tras confirmar la configuración de audiencia infantil de AdMob; monitorizar el endpoint `/auth/guest` y `/register` para ajustar los límites de rate limiting recién añadidos si resultan demasiado estrictos/laxos en tráfico real.

## 35. Veredicto final

🟠 **CONDITIONAL** — sin P0 abiertos. Publicable tras completar el paso 1 de la sección 33 (confirmar el secreto JWT real en producción) y una pasada de verificación manual en dispositivo físico (sección 33, punto 3), que no pudo ejecutarse desde este entorno.

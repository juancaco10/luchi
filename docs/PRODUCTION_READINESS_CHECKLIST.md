# Production Readiness Checklist — Guardianes de las Luciérnagas

Ver [FINAL_PREPRODUCTION_REPORT.md](FINAL_PREPRODUCTION_REPORT.md) para el detalle de cada hallazgo.

## Build

- [x] `flutter analyze` limpio (0 errores, 0 warnings)
- [x] tests críticos pasan (11/11)
- [x] AAB release compila y firma (`app-release.aab`, 130.8 MB, exit code 0)
- [ ] versión (`pubspec.yaml: version:`) revisada antes de subir a Play Console
- [x] firma release configurada (`key.properties` + keystore presentes, no versionados)

## Backend / Seguridad

- [x] `photo_url` reconstruida server-side, nunca confía en la URL del cliente
- [ ] `JWT_SECRET` real confirmado en el servidor de producción (Hostinger) — **acción manual pendiente, fuera de este repo**
- [x] Rate limiting en `/login`, `/register`, `/auth/guest`, `/uploads/sighting-photo`
- [x] Tope máximo de estrellas de juego en el servidor
- [x] Flujos de puntos (avistamiento, capítulo, estrellas) en transacción
- [x] `SELECT ... FOR UPDATE` en `game_stars` para evitar lost updates
- [x] Headers HSTS y Referrer-Policy añadidos
- [x] Auto-publicación de avistamientos restaurada (`moderation_status = "approved"`)
- [x] Sin secretos en archivos versionados (verificado con `git ls-files`)

## Autenticación

- [x] login por email
- [x] registro
- [x] Google Sign-In (configuración cliente/servidor coherente)
- [x] login como invitado (con guard de doble-tap añadido)
- [x] logout
- [x] sesión persistente
- [x] cambio de usuario (Hive namespaced por userId)
- [x] eliminación de cuenta (con guard de concurrencia añadido)
- [ ] Google Sign-In verificado en dispositivo físico con AAB firmado — **NO VERIFICADO**, requiere instalación real

## Perfil y Configuración

- [x] switch de tema persiste y cambia algo real
- [x] estados loading/empty/offline de insignias
- [x] cerrar sesión vs borrar cuenta bien diferenciados
- [x] enlace de política de privacidad con feedback si falla

## Progreso y Gamificación

- [x] puntos calculados en servidor
- [x] idempotencia en capítulos y estrellas de juego
- [x] tope máximo de estrellas (anti-manipulación de cliente)
- [ ] confirmar con el usuario si el bono diario de energía debe requerir ganar el nivel (decisión de producto)

## Capítulos y Quiz

- [x] manejo de error de vídeo (spinner infinito corregido)
- [x] marcar capítulo completado, offline-first

## Avistamientos

- [x] flujo completo formulario → GPS/foto → NSFW → upload → envío → cola offline → sync
- [x] difuminado de coordenadas en el dispositivo antes de cualquier request
- [x] permisos just-in-time, la app funciona si se deniegan
- [x] protegido contra doble-tap/doble envío
- [ ] idempotency key en la cola offline (riesgo bajo de duplicado) — backlog post-release
- [x] estado de error visible en "Mis avistamientos"

## Mapa

- [x] implementado, detrás de `AppConstants.communityEnabled = false`
- [ ] clustering de marcadores — recomendado antes de activar la comunidad en producción
- [x] botones que apuntan a `/map` avisan en vez de navegar en silencio

## Offline / Caché / Sync

- [x] Hive namespaced por usuario
- [x] cola offline drena al arrancar y al reconectar
- [x] logout no destruye datos offline que deban preservarse; borrado de cuenta sí purga todo

## Privacidad infantil

- [x] coordenadas difuminadas en cliente y servidor (doble defensa)
- [x] sin nombre completo ni user_id expuestos en el feed
- [x] EXIF eliminado por re-codificación server-side de fotos
- [x] `allowBackup=false` + `dataExtractionRules`

## Ads

- [x] integrado pero apagado (`adsEnabled = false`)
- [x] App ID real correcto en Android e iOS (comentario corregido)
- [ ] configuración de audiencia infantil de AdMob — pendiente de revisar antes de activar anuncios

## Android / Google Play

- [x] `allowBackup=false`, `dataExtractionRules`
- [x] permisos declarados con `tools:node="remove"` de los innecesarios
- [x] firma release configurada
- [ ] Google Sign-In en build debug (`.dev`) — sin cliente OAuth, no bloquea producción

## Tests

- [x] 11 tests en verde
- [ ] cobertura de `auth_provider`, `sightings_provider`, `sync_service`, router — backlog post-release

## Deuda técnica limpiada

- [x] archivos scratch sueltos en la raíz eliminados (`test.dart`, `test_map.dart`, `test_riverpod.dart`, `test_db2.php`, `test_db3.php`)
- [x] lints menores corregidos (`sync_service.dart`, imports no usados)

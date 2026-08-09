# Privacidad de menores — Guardianes de las Luciérnagas

Público objetivo: niños de 6–12 años. La app recoge **país/ciudad del perfil**, opcionalmente **GPS** (solo si el usuario lo comparte al registrar un avistamiento) y **fotos**, y datos de progreso (puntos, capítulos completados). Este documento define qué se recoge, cómo se minimiza, y qué debe cumplir el cliente y (cuando se retome) el backend. Sirve de referencia obligatoria para cualquier cambio en `lib/features/sightings/` o `lib/features/auth/`.

Este documento describe el diseño objetivo; el código actual **no** lo cumple todavía en varios puntos (marcados abajo como "Estado actual"). No sustituye asesoría legal formal (COPPA en EE. UU., GDPR-K en la UE, LOPDGDD/RGPD en España) antes de un lanzamiento público real.

## Principios

1. **Minimización**: no se recoge ni se envía al servidor nada que la funcionalidad no necesite explícitamente.
2. **GPS opt-in con alternativa real, nunca de memoria**: al registrar un avistamiento, el usuario elige si comparte su ubicación exacta o no. Si no la comparte —o el permiso se deniega, o el dispositivo falla al obtenerla— se usa un punto al azar dentro de la ciudad de su perfil, nunca un error ni un bloqueo. Un punto real (difuminado a 3 decimales) y uno aleatorio son indistinguibles en el mapa: nadie puede saber, mirando un marcador, si corresponde a la posición real de un niño.
3. **Anonimato en lo público**: nada visible para otros usuarios identifica a un niño concreto por nombre real ni por ubicación precisa.
4. **Consentimiento antes de permisos**: nunca se dispara un diálogo nativo de permiso (ubicación/cámara) sin una pantalla previa que explique para qué, en lenguaje apto para familias/menores.
5. **Control y borrado**: el usuario (o su tutor) puede ver y borrar sus datos.

## Datos recogidos y tratamiento

| Dato | Para qué | Dónde vive | Tratamiento |
|---|---|---|---|
| Nombre de usuario | Perfil, "mis avistamientos" | SharedPreferences + backend | Nunca se muestra en el mapa comunitario ni a otros usuarios |
| País/ciudad del perfil | Requisito único antes de publicar; base del punto aleatorio cuando no se comparte GPS | SharedPreferences + backend (`users.country`/`users.city`) | Se pide una sola vez, con explicación previa (`location_setup_screen.dart`); para Uruguay sale de una lista fija sin tocar la red, para otros países se geocodifica |
| Ubicación del avistamiento | Ubicar la especie en el mapa | Hive (cola local) + backend | **Opt-in por avistamiento.** Con GPS compartido: posición real difuminada a 3 decimales (~100 m). Sin compartir (o denegado/falla): punto al azar dentro de un radio de ~3 km del centro de la ciudad del perfil — nunca la posición real sin permiso explícito |
| Foto del avistamiento | Evidencia visual | dispositivo → backend | Se recortan metadatos EXIF (que pueden incluir GPS de precisión completa y datos del dispositivo) antes de subir; además se filtra on-device (`nsfw_detector_flutter`) antes de aceptarla |
| Puntos / nivel / capítulos completados | Gamificación | SharedPreferences + backend | No es dato sensible; se conserva mientras la cuenta exista |
| Token de sesión | Autenticación | **Debe** vivir en almacenamiento seguro (`flutter_secure_storage`), no en SharedPreferences en texto plano | — |

**Estado actual (a corregir, ver plan de mejoras Fase 1 y 2):**
- El token se guarda hoy en SharedPreferences en texto plano.
- No existe pantalla de consentimiento parental en el onboarding.
- La revisión legal formal (COPPA/GDPR-K/RGPD) sigue pendiente — ver checklist.

**Resuelto:**
- El recorte de EXIF de las fotos ya está implementado en dos capas — `sighting_form_screen.dart` re-codifica la imagen al elegirla (`imageQuality: 85`, `maxWidth: 1600`), y `backend/api/routes/uploads.php` la vuelve a decodificar y re-codificar con GD antes de guardarla, lo que descarta cualquier metadato EXIF (ubicación GPS de precisión completa, datos del dispositivo) que hubiera sobrevivido a la primera capa.
- El GPS es opt-in explícito por avistamiento, con una explicación siempre visible en pantalla (`_LocationCard` en `sighting_form_screen.dart`) antes de que el interruptor "Compartir mi ubicación exacta" pueda disparar el permiso nativo. La alternativa (punto al azar dentro de la ciudad del perfil, `randomPointNear` en `sighting_geocoding.dart`) es funcionalmente equivalente para el mapa, así que negarse no degrada la experiencia ni bloquea el envío.
- **El mapa/feed comunitario ya no está deshabilitado.** `GET /sightings` (antes `410` a propósito) ahora devuelve avistamientos reales, pero solo bajo las tres condiciones que este documento exigía para poder abrirlo — ver `backend/api/routes/sightings.php`:
  1. **Moderación previa**: todo avistamiento nace con `moderation_status = 'pending'` y no aparece en el feed hasta que un moderador humano lo aprueba en `backend/admin/moderation.php` (acceso restringido a cuentas con `is_moderator = 1`, activado a mano en la base — no hay forma de auto-concedérselo desde la app). Editar un avistamiento ya aprobado lo devuelve a `pending` automáticamente.
  2. **Sin nombre de usuario**: la respuesta de `GET /sightings` nunca incluye `user_id` ni `user_name`. Solo `is_mine` (booleano, calculado en el servidor) distingue lo propio de lo ajeno, y solo sobre uno mismo.
  3. **Coordenadas redondeadas en el servidor**: `blurCoord()` recorta `lat`/`lng` a 3 decimales antes de responder, como segunda capa de defensa además del difuminado del cliente. `location_name` se recorta a nivel ciudad (`cityLevelLocation()`).
  - Corazones (`sighting_likes`) siguen la misma regla: solo se puede dar corazón a algo `approved`, y un corazón por persona (`UNIQUE KEY`), sin que quede expuesto quién lo dio a nadie más que al propio autor del corazón.
  - Migración: `backend/database/migrations/04_2026_sightings_social.sql`.

## Requisitos de cliente

- **Consentimiento parental** en el onboarding (`lib/features/auth/screens/onboarding_screen.dart`), antes de cualquier pantalla que vaya a pedir ubicación o cámara. Debe enlazar a este documento (o a una versión pública del mismo) y explicar en lenguaje simple qué se recoge y por qué.
- **Permisos just-in-time**: la explicación de ubicación (`_LocationCard`) y la de foto (hoja previa en `_choosePhotoSource`) están siempre visibles en pantalla antes de que su interruptor/botón dispare el diálogo nativo correspondiente. Si se deniega cualquiera de los dos, la app sigue funcionando (punto aleatorio; avistamiento sin foto).
- **Difuminado de coordenadas**: redondear a 3 decimales tanto la posición GPS real como el punto aleatorio, antes de construir el payload de envío. Esto pasa en el cliente, no se confía en que el backend lo haga.
- **Sin nombre en el mapa público**: `map_screen.dart` no debe pintar `user_name` en los marcadores de la comunidad; solo la pantalla de "mis avistamientos" (propios) puede mostrar el nombre del propio usuario.
- **Sin histórico de posición**: no guardar ningún log de posiciones GPS del dispositivo más allá del momento puntual en que el usuario decide compartirla para un avistamiento — nunca en segundo plano, nunca fuera de ese envío.
- **Borrado de cuenta**: la pantalla de ajustes (`settings_screen.dart`) debe ofrecer una vía para solicitar borrado de cuenta y datos asociados (aunque hoy dependa de un backend que todavía no lo implementa).

## Requisitos de backend

- ~~`GET /sightings` no debe devolver coordenadas de precisión completa ni `user_name` real~~ — hecho, ver "Resuelto" arriba.
- ~~Implementar moderación real antes de publicar un avistamiento en el mapa comunitario~~ — hecho (`moderation_status`, `backend/admin/moderation.php`).
- Endpoint de borrado de cuenta que elimine o anonimice avistamientos y datos personales asociados. **Sigue pendiente**: con el feed comunitario abierto, esto pasa de ser una mejora a ser más urgente — hoy borrar una cuenta no retira sus avistamientos ya aprobados del feed.
- Retención mínima: definir un plazo de expiración de datos de cuentas inactivas.
- La cola de moderación no tiene límite de tiempo: un avistamiento puede quedarse en `pending` indefinidamente si nadie lo revisa. Antes de un lanzamiento real hace falta un proceso (aunque sea manual) que garantice que se revisa en un plazo razonable, o el feed comunitario se queda vacío en la práctica.

## Checklist antes de cualquier release pública

- [ ] Pantalla de consentimiento parental implementada y enlazada desde onboarding — **bloqueante**: el feed comunitario ya publica contenido entre usuarios sin que esto exista todavía.
- [x] Coordenadas difuminadas en el cliente antes de cualquier envío
- [x] Mapa/feed comunitario sin nombres de usuario
- [x] EXIF recortado de las fotos antes de subir
- [x] Moderación previa a la publicación en el feed comunitario
- [ ] Proceso que garantice que la cola de moderación se revisa en un plazo razonable (hoy es manual y sin SLA)
- [ ] Token en almacenamiento seguro
- [ ] Endpoint de borrado de cuenta que retire también sus avistamientos del feed
- [ ] Política de privacidad pública redactada y enlazada en la tienda de apps
- [ ] Revisión legal formal (COPPA/GDPR-K/RGPD según mercado de lanzamiento)

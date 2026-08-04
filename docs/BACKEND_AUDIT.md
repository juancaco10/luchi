# Auditoría del backend (`backend/`)

**Estado**: este documento es solo lectura/diagnóstico. Por decisión de proyecto, el código de `backend/` no se modifica desde este repo Flutter salvo instrucción explícita. Sirve como lista de trabajo — ver el plan de corrección global vigente (Fase 1 toca lo mínimo del backend: contrato de errores y `awardBadgesIfEarned()`).

**Nota (revisión posterior):** la versión anterior de este documento describía un backend que no arrancaba. Eso ya no es así — ver "Corregido desde la auditoría original" más abajo. El resto de hallazgos de seguridad/escalabilidad sigue vigente salvo que se indique lo contrario.

PHP 8 puro (sin framework, sin Composer) + PDO + MySQL, pensado para hosting compartido tipo Hostinger. Desplegado y respondiendo en `dimgrey-dove-703529.hostingersite.com`.

```
backend/api/index.php
backend/api/.htaccess
backend/api/config/database.php
backend/api/lib/gamification.php
backend/api/middleware/auth.php
backend/api/routes/users.php
backend/api/routes/chapters.php
backend/api/routes/missions.php
backend/api/routes/sightings.php
backend/database/schema.sql
```

## Corregido desde la auditoría original

- **El fatal de arranque ya no existe.** `php -l backend/api/index.php` no reporta errores de sintaxis.
- **`updateUserLevel()` ya no está duplicada** — vive en `backend/api/lib/gamification.php` e importada desde ambos routers.
- **Rate limiting de login implementado** (`middleware/auth.php`, tabla `login_attempts`): throttle por par (email, IP).
- **`DELETE /me` implementado** (`routes/users.php`) — el cliente Flutter ya lo invoca desde `deleteAccount()`.
- **`GET /sightings` (mapa comunitario) deshabilitado a propósito**: devuelve `410` con el mensaje "El mapa comunitario está deshabilitado en esta versión" — decisión explícita de privacidad documentada en el propio código (ver `routes/sightings.php`), no un descuido. `GET /my-sightings` sigue disponible y correctamente acotado al usuario autenticado.
- **CORS ya no es `*`**: `index.php` refleja el `Origin` de la petición (`header('Access-Control-Allow-Origin: ' . $origin)`) — sigue sin ser una allowlist explícita, ver más abajo.
- **`backend/api/config/database.php` está en `.gitignore`** (confirmado, línea con ese path exacto).

## Seguridad — sigue pendiente

- CORS refleja cualquier `Origin` en vez de comprobarlo contra una allowlist de orígenes conocidos (app/web reales). Mejor que `*`, pero equivalente en la práctica si no hay validación.
- JWT HS256 hecho a mano (`middleware/auth.php`): usa `hash_equals` en la verificación de firma (correcto), pero no valida el campo `alg` del header contra un valor esperado. Sin refresh tokens ni revocación — un token robado es válido 30 días completos.
- `is_pending` en la respuesta de `/my-sightings` está **hardcodeado a `false`**, aunque README y RESUMEN_PROYECTO describen un flujo de moderación. Hoy no existe moderación real.
- `routes/missions.php` (~línea 74) contiene la única consulta no parametrizada del código, con un patrón confuso (ternario sobre el booleano que devuelve `execute()`, no sobre el resultado):
  ```php
  $pts = (int) $db->prepare('SELECT points FROM users WHERE id = ?')->execute([$user['id']])
       ? $db->query("SELECT points FROM users WHERE id = {$user['id']}")->fetchColumn() : 0;
  ```
  El valor interpolado es un id entero ya autenticado, no input de usuario, así que no es explotable directamente — pero contradice la afirmación del README de que todo el backend usa consultas parametrizadas.
- `backend/api/.htaccess` hace bien varias cosas: cabeceras `X-Content-Type-Options`, `X-Frame-Options: DENY`, `X-XSS-Protection`, `Options -Indexes`, y bloquea acceso directo a `.env/.sql/.md`. No bloquea explícitamente `config/database.php`, aunque ese archivo no imprime nada si se accede directo.

## Lógica de negocio incompleta

- `awardBadgesIfEarned()` solo evalúa `condition_type === 'points'`. Las insignias seedeadas de tipo misiones/avistamientos/capítulos en `schema.sql` **nunca pueden desbloquearse**. (Fase 1 del plan de corrección global lo toca.)
- `POST /sightings` suma +20 puntos pero no llama a la recalculación de nivel ni de insignias (a diferencia de `/complete-chapter`, que sí lo hace) → un usuario puede subir de nivel por avistamientos sin que el backend lo refleje hasta la siguiente acción que sí recalcule.
- Los mensajes de error no tienen un formato 100% consistente entre routers — el cliente Flutter (Fase 1 del plan) empezará a mostrar `error` del backend directamente, así que cualquier endpoint que no devuelva `{"error": "..."}` en fallo se verá como un mensaje crudo en la UI.

## Rendimiento / escalabilidad

- Sin ninguna capa de caché (APCu, Redis, ni cabeceras `Cache-Control`/`ETag`) — cada `GET /chapters` o `/missions` golpea MySQL aunque el contenido cambia con muy poca frecuencia.
- Sin índice en `chapters.order_index`/`is_active` ni en `missions.type`/`is_active` — impacto bajo hoy por el tamaño de las tablas semilla, pero a vigilar si el catálogo crece.
- `schema.sql` abre con `DROP TABLE IF EXISTS` de las 8 tablas — reimportar el esquema en un entorno con datos reales los destruye. Tratar como "solo para bootstrap", nunca ejecutarlo contra producción sin backup previo.
- Contenido (capítulos, misiones, insignias) vive únicamente como `INSERT` semilla en `schema.sql` — no hay forma de editarlo sin tocar SQL directo ni panel de administración.
- Vídeos sembrados (`video_url`) apuntan a los samples públicos de Google (`BigBuckBunny.mp4`, `ElephantsDream.mp4`) — son placeholders, no contenido del producto.

## Resumen de correcciones pendientes

1. Allowlist real de CORS en vez de reflejar cualquier `Origin`.
2. Moderación real de avistamientos (`is_pending` de verdad) y las reglas de `awardBadgesIfEarned()` que faltan.
3. Cachear `/chapters` y `/missions` (APCu o `Cache-Control`/`ETag`).
4. Sustituir los `video_url` placeholder por contenido propio antes de cualquier lanzamiento.
5. Formato de error consistente `{"error": "..."}` en todos los endpoints — bloqueante para que el interceptor del cliente (Fase 1 del plan) muestre siempre un mensaje útil.

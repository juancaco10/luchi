# Auditoría del backend (`backend/`)

**Estado**: este documento es solo lectura/diagnóstico. Por decisión de proyecto, el código de `backend/` no se modifica desde este repo Flutter salvo instrucción explícita. Sirve como lista de trabajo para cuando se aborde el backend (ver "Plan de ampliación y escalabilidad", fases F1–F3, en el histórico de planes del proyecto).

PHP 8 puro (sin framework, sin Composer) + PDO + MySQL, pensado para hosting compartido tipo Hostinger.

```
backend/api/index.php
backend/api/.htaccess
backend/api/config/database.php
backend/api/middleware/auth.php
backend/api/routes/users.php
backend/api/routes/chapters.php
backend/api/routes/missions.php
backend/api/routes/sightings.php
backend/database/schema.sql
```

## Bloqueante: la API no arranca

- `backend/api/index.php:36` — `global $method as $reqMethod, $path as $reqPath;`. `global` no admite `as` en PHP → **error fatal de parseo**. Ninguna petición puede procesarse mientras esto exista. El helper `route()` que contiene esta línea es además código muerto: ninguna ruta se registra a través de él, todas las rutas usan bloques `if ($method === ... && $path === ...)` directos en cada `routes/*.php`.
- `updateUserLevel()` está **declarada dos veces** (`routes/users.php` y `routes/chapters.php`), y `index.php` hace `require_once` de ambos → fatal "cannot redeclare function".

**Corrección propuesta** (no aplicada): eliminar el helper `route()` muerto; mover `updateUserLevel()` a un único sitio (p. ej. `config/` o un `lib/gamification.php`) e importarlo desde ambos routers.

## Seguridad

- `Access-Control-Allow-Origin: *` en `index.php:9` sobre una API que requiere Bearer token — permite que cualquier origen web lea respuestas autenticadas vía JS si alguna vez se filtra un token por otro medio (XSS en un tercero, etc.). Restringir a los orígenes reales de la app/web.
- Sin **rate limiting** en `/login` ni `/register` → fuerza bruta de contraseñas sin fricción.
- JWT HS256 hecho a mano (`middleware/auth.php`): usa `hash_equals` en la verificación de firma (correcto), pero no valida el campo `alg` del header contra un valor esperado (no explotable hoy porque siempre se recalcula HS256, pero es una práctica frágil si se toca el código). Sin refresh tokens ni revocación — un token robado es válido 30 días completos.
- `GET /sightings` devuelve **coordenadas exactas + `user_name`** de cualquier niño a cualquier usuario autenticado, con `LIMIT 500` y sin paginación real. Para una app de menores esto es el hallazgo más serio del backend — ver `docs/PRIVACY.md`.
- `is_pending` en la respuesta de avistamientos está **hardcodeado a `false`**, aunque README y RESUMEN_PROYECTO describen un flujo de moderación. Hoy no existe moderación real: todo avistamiento es público de inmediato.
- `routes/missions.php` (~línea 74) contiene la única consulta no parametrizada del código, con un patrón confuso (ternario sobre el booleano que devuelve `execute()`, no sobre el resultado):
  ```php
  $pts = (int) $db->prepare('SELECT points FROM users WHERE id = ?')->execute([$user['id']])
       ? $db->query("SELECT points FROM users WHERE id = {$user['id']}")->fetchColumn() : 0;
  ```
  El valor interpolado es un id entero ya autenticado, no viene de input de usuario, así que no es explotable directamente — pero contradice la afirmación del README de que todo el backend usa consultas parametrizadas, y es un patrón a no replicar.
- `backend/api/.htaccess` sí hace bien varias cosas: cabeceras `X-Content-Type-Options`, `X-Frame-Options: DENY`, `X-XSS-Protection`, `Options -Indexes`, y bloquea acceso directo a `.env/.sql/.md`. No bloquea explícitamente `config/database.php`, aunque ese archivo no imprime nada si se accede directo.
- `backend/api/config/database.php` contiene hoy solo placeholders (`your_database_name`, `JWT_SECRET => 'CHANGE_THIS_TO_A_STRONG_RANDOM_SECRET_64_CHARS'`), pero el archivo **no está en `.gitignore`** — en cuanto se rellenen credenciales reales, quedarían listas para commitearse por accidente.

## Lógica de negocio incompleta

- `awardBadgesIfEarned()` solo evalúa `condition_type === 'points'`. Las insignias seedeadas de tipo misiones/avistamientos/capítulos en `schema.sql` **nunca pueden desbloquearse**.
- `POST /sightings` suma +20 puntos pero no llama a la recalculación de nivel ni de insignias (a diferencia de `/complete-chapter`, que sí lo hace) → un usuario puede subir de nivel por avistamientos sin que el backend lo refleje hasta la siguiente acción que sí recalcule.

## Rendimiento / escalabilidad

- Sin ninguna capa de caché (APCu, Redis, ni siquiera cabeceras `Cache-Control`/`ETag`) — cada `GET /chapters` o `/missions` golpea MySQL aunque el contenido cambia con muy poca frecuencia.
- Sin índice en `chapters.order_index`/`is_active` ni en `missions.type`/`is_active` — impacto bajo hoy por el tamaño de las tablas semilla, pero a vigilar si el catálogo crece.
- `schema.sql` abre con `DROP TABLE IF EXISTS` de las 8 tablas — reimportar el esquema en un entorno con datos reales los destruye. Cualquier script de despliegue debe tratarlo como "solo para bootstrap", nunca ejecutarlo contra producción sin backup previo.
- Contenido (capítulos, misiones, insignias) vive únicamente como `INSERT` semilla en `schema.sql` — no hay forma de editarlo sin tocar SQL directo ni panel de administración.
- Vídeos sembrados (`video_url`) apuntan a los samples públicos de Google (`BigBuckBunny.mp4`, `ElephantsDream.mp4`) — son placeholders, no contenido del producto.

## Resumen de correcciones pendientes (por si se retoma el backend)

1. Arreglar el fatal de `index.php` y la doble declaración de `updateUserLevel()` — bloqueante, nada funciona sin esto.
2. Restringir CORS a orígenes conocidos.
3. Rate limiting en `/login` y `/register`.
4. `GET /sightings`: quitar coordenadas exactas y `user_name` de la respuesta pública, o exigir moderación antes de exponerlas (ver `docs/PRIVACY.md`).
5. Implementar moderación real (`is_pending` de verdad) y las reglas de `awardBadgesIfEarned()` que faltan.
6. Cachear `/chapters` y `/missions` (APCu o `Cache-Control`/`ETag`).
7. `.gitignore` para `backend/api/config/database.php`.
8. Sustituir los `video_url` placeholder por contenido propio antes de cualquier lanzamiento.

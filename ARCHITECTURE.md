# ARCHITECTURE.md

## Capas

```
lib/
├── main.dart                 # bootstrap: portrait lock, LocalStorage.init(), ProviderScope
├── app.dart                  # MaterialApp.router + GoRouter (todas las rutas y transiciones)
├── core/
│   ├── network/
│   │   ├── api_client.dart       # Dio singleton + interceptores (auth/logging/errores)
│   │   └── api_endpoints.dart    # paths de la API PHP
│   ├── storage/
│   │   └── local_storage.dart    # SharedPreferences (sesión) + Hive (caché/cola offline)
│   ├── theme/                    # app_colors.dart, app_theme.dart (Material3 oscuro)
│   └── utils/
│       └── constants.dart        # baseUrl, timeouts, keys, gamificación, UI tokens
├── features/
│   ├── auth/          {models, providers, screens}  # splash, onboarding, login, register
│   ├── home/           screens                       # dashboard
│   ├── education/      {models, providers, screens}  # capítulos, detalle, quiz (level_one)
│   ├── missions/       {models, providers, screens}  # misiones diarias/semanales
│   ├── profile/        {providers, screens}          # perfil, insignias, ajustes
│   └── sightings/      {models, providers, screens}  # avistamientos GPS+foto, mapa
└── widgets/            # componentes compartidos entre features
```

Fuera de `lib/`: `backend/` (API PHP/MySQL, ver `docs/BACKEND_AUDIT.md`), `assets/images/`.

## Flujo de datos: patrón de tres niveles (API → caché → mock)

`chapters_provider.dart` y `missions_provider.dart` implementan el mismo patrón (hoy duplicado, candidato a extraerse — ver plan de mejoras Fase 4):

1. Intentar `GET` vía `ApiClient` contra `AppConstants.baseUrl` (endpoint de `api_endpoints.dart`).
2. Si responde bien → parsear y **cachear en Hive** (`chapters_box` / `missions_box`).
3. Si la llamada falla (hoy siempre falla: `baseUrl` es un placeholder) → leer la última caché de Hive.
4. Si la caché está vacía (primer arranque) → `ChapterModel.getMockChapters()` / `MissionModel.getMockMissions()`.

`sightings_provider.dart` solo tiene escritura: `LocalStorage.queueSighting()` guarda en `sightings_box` como cola offline, pero **nada la drena** hoy (gap conocido, ver plan Fase 5).

## Estado y navegación

- **Riverpod**, sin codegen: `StateNotifierProvider` por feature (`authProvider`, `chaptersProvider`, `missionsProvider`, `sightingsProvider`), más `Provider.family` para lookup por id (`chapterByIdProvider`, `missionByIdProvider`) y `Provider`s derivados (`currentUserProvider`, `profileProvider`).
- **GoRouter** declarativo en `lib/app.dart`. Guard global (`redirect`) lee `LocalStorage.instance.isLoggedIn` / `.onboardingDone` de forma síncrona. Rutas protegidas: `/home /chapters /missions /profile /sightings /map`. El router es un `final` de nivel superior sin `refreshListenable`, por lo que **no reacciona a cambios de sesión en caliente** (logout no fuerza redirect hasta la siguiente navegación) — ver plan Fase 1.

### Rutas

| path | name | pantalla | protegida |
|---|---|---|---|
| `/splash` | splash | SplashScreen | no |
| `/onboarding` | onboarding | OnboardingScreen | no |
| `/login` | login | LoginScreen | no |
| `/register` | register | RegisterScreen | no |
| `/home` | home | HomeScreen | sí |
| `/chapters` | chapters | ChaptersListScreen | sí |
| `/chapters/:id` | chapter-detail | ChapterDetailScreen | sí |
| `/game/level-1` | game-level-1 | LevelOneScreen (quiz) | no* |
| `/missions` | missions | MissionsScreen | sí |
| `/missions/:id` | mission-detail | MissionDetailScreen | sí |
| `/profile` | profile | ProfileScreen | sí |
| `/settings` | settings | SettingsScreen | no* |
| `/sightings/new` | sighting-form | SightingFormScreen | sí (prefijo `/sightings`) |
| `/map` | map | MapScreen | sí |

\* `game-level-1` y `settings` no están en `protectedRoutes` de `app.dart` pese a requerir sesión en la práctica — inconsistencia a revisar.

## Persistencia

- **SharedPreferences**: `auth_token` (texto plano — mover a `flutter_secure_storage`, plan Fase 1), `current_user` (JSON), `onboarding_done`.
- **Hive** (boxes sin tipar, JSON crudo): `chapters_box`, `missions_box`, `sightings_box` (esta última también como cola offline de escritura).
- **No hay SQLite.**

## Backend (documentado, no gestionado desde este repo)

PHP 8 + PDO + MySQL, sin framework. Ver auditoría completa y estado real (no arranca hoy) en [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md).

### Endpoints

| método | path | requiere auth |
|---|---|---|
| POST | `/register` | no |
| POST | `/login` | no |
| GET | `/me` | sí |
| GET | `/chapters` | sí |
| POST | `/complete-chapter` | sí |
| GET | `/missions` | sí |
| POST | `/complete-mission` | sí |
| POST | `/sightings` | sí |
| GET | `/sightings` | sí |
| GET | `/my-sightings` | sí |

Auth: JWT HS256 hecho a mano (`backend/api/middleware/auth.php`), `password_hash` bcrypt costo 12, expiry 30 días, sin refresh/revocación.

### Esquema (`backend/database/schema.sql`)

8 tablas InnoDB/utf8mb4: `users, chapters, user_chapters, missions, user_missions, sightings, badges, user_badges`. Índices: `users.email` (único), `uq_user_chapter`, `uq_user_mission`, `uq_user_badge` (compuestos únicos), `sightings.idx_user`, `sightings.idx_coords(lat,lng)`. El script empieza con `DROP TABLE IF EXISTS` de las 8 tablas — reimportar borra datos existentes.

## Gamificación

Fuente de verdad: `lib/core/utils/constants.dart`.

- Puntos: misión diaria **+10**, misión semanal **+30**, capítulo completado **+15**, avistamiento **+20**.
- Niveles por puntos acumulados: **Observador** (0) → **Explorador** (100) → **Guardián** (200) → **Maestro Guardián** (400).
- `getLevelForPoints(points)` y `getLevelProgress(points)` son las únicas funciones que deben calcular esto; no reimplementar el umbral en una pantalla.

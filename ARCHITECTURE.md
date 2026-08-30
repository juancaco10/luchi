# ARCHITECTURE.md

Mapa de capas y flujo de datos del cliente Flutter y su backend PHP/MySQL.
Fuente de verdad de la estructura del código; la lista de pantallas y su
estado está en [docs/SCREEN_INVENTORY.md](docs/SCREEN_INVENTORY.md).

## Capas

```
lib/
├── main.dart                  # bootstrap: portrait lock, LocalStorage.init(), ProviderScope
├── app.dart                   # MaterialApp.router + GoRouter (todas las rutas y transiciones)
│
├── core/                      # código transversal, sin dependencia de features
│   ├── data/
│   │   └── cached_list_repository.dart   # patrón "API → caché → seed" reutilizable
│   ├── network/
│   │   ├── api_client.dart    # Dio singleton + interceptores (auth/logging/errores)
│   │   ├── api_endpoints.dart # paths de la API PHP
│   │   └── sync_service.dart  # drena la cola offline de avistamientos (arranque + reconexión)
│   ├── session/
│   │   └── user_scoped_providers.dart   # providers namespaced por usuario activo
│   ├── storage/
│   │   └── local_storage.dart # SharedPreferences (sesión) + Hive (caché/cola offline)
│   ├── theme/
│   │   ├── app_theme.dart     # ThemeData claro/oscuro con Nunito
│   │   ├── firefly_colors.dart # extensiones ThemeExtension (context.colors/text/firefly)
│   │   ├── palettes.dart      # DarkPalette / LightPalette (tokens por tema)
│   │   └── theme_provider.dart # switch de tema persistente
│   └── utils/
│       └── constants.dart     # baseUrl, timeouts, keys, gamificación, UI tokens, assets
│
├── features/                  # feature-first; cada una con models/providers/screens/widgets
│   ├── auth/         # splash, onboarding, consentimiento parental, login, register, nickname
│   ├── education/    # Aprender: capítulos + detalle (video local) — 8 capítulos empaquetados
│   ├── games/        # minijuegos (quiz + 4 ocultos de la navegación tras decisión de producto)
│   ├── home/         # dashboard (Jugar / Aprender / Mapa, progreso, avistamientos recientes)
│   ├── profile/      # perfil, ajustes, avatares
│   └── sightings/    # formulario GPS+foto, mapa, feed, mis avistamientos
│
└── widgets/                  # componentes compartidos entre features
    ├── ad_banner.dart         # banner de anuncios (apagado, adsEnabled=false)
    ├── custom_button.dart
    ├── firefly_background.dart # partículas de luciérnaga
    ├── hardware_back_route.dart
    ├── level_progress_bar.dart
    ├── points_display.dart
    ├── reward_overlay.dart
    └── screen_fitter.dart     # escala para pantallas bajas
```

Fuera de `lib/`: `backend/` (API PHP/MySQL desplegada en Hostinger, ver
[docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md)), `assets/images/`, `assets/videos/`
(videos de los 8 capítulos, empaquetados en el APK), `landing_page/`.

## Temas (desde Fase 2)

No existe `AppColors` ni `Color(0x...)` sueltos en pantallas: todo pasa por
`Theme.of(context)` vía las extensiones de `lib/core/theme/firefly_colors.dart`:
`context.colors` (ColorScheme), `context.text` (TextTheme), `context.firefly`
(tokens de marca: glow, gradientes, cardShadow). Los valores por tema viven en
`lib/core/theme/palettes.dart` (`DarkPalette` / `LightPalette`).

## Estado de aplicación vs. estado efímero

- **Estado que sobrevive a un `pop()` o lo usa otra pantalla → Riverpod**
  (`StateNotifierProvider`, `Provider`, `Provider.family`).
- **Estado efímero de UI** (animaciones locales, formularios, temporizador del
  quiz) → `setState` dentro del widget. No mezclar.

## Flujo de datos: patrones

- **Capítulos (Aprender)**: los 8 capítulos y sus videos viven empaquetados en
  el APK (`ChapterModel.getMockChapters()` → `assets/videos/{id}.mp4`), así
  Aprender funciona sin conexión. El progreso del niño (completado/desbloqueado)
  se conserva en la caché local de Hive y se aplica sobre la lista fija.
  `chapters_provider.dart` ya **no** depende del backend para la lista.
- **Avistamientos**: `sightings_provider.dart` escribe en `sightings_box` como
  cola offline; `lib/core/network/sync_service.dart` la drena al arrancar y al
  reconectar. Borra por clave individual (`removePendingSighting`).
- **Juegos**: el progreso (estrellas por nivel) vive en `games_box` de Hive,
  es local del jugador y nunca se limpia salvo al cerrar sesión.

## Rutas

Todas centralizadas en [lib/app.dart](lib/app.dart) con GoRouter
(`routerProvider`). Sin `Navigator.push` directo salvo diálogos/bottom sheets.
Tras decisión de producto, la pestaña **Jugar** abre la selección de nivel del
**quiz** directamente (`/game` → `LevelSelectScreen(explorar)`); los otros 4
minijuegos quedan vivos en el código bajo `/game/:gameId` pero sin exposición
en la navegación.

## Backend

Ver [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md) para el estado real. El
backend PHP **sí arranca** (`php -l backend/api/index.php` limpio), tiene rate
limiting de login, `DELETE /me`, y responde en Hostinger. No se toca desde este
repo Flutter salvo instrucción explícita.

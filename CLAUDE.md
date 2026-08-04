# CLAUDE.md — contrato de trabajo del repo

Este archivo orienta a cualquier agente o colaborador que edite este repo. Léelo antes de tocar código.

## Qué es esto

Juego educativo Flutter para niños de 6–12 años sobre conservación de luciérnagas: capítulos (vídeo + quiz), misiones diarias/semanales, avistamientos con GPS + foto, mapa comunitario, perfil con puntos y niveles. Cliente Flutter 3 / Dart 3 (Riverpod + GoRouter + Hive/SharedPreferences + Dio) más una API PHP/MySQL en `backend/` pensada para Hostinger.

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para el mapa de capas y flujo de datos, [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md) para el estado real del backend, y [docs/PRIVACY.md](docs/PRIVACY.md) para las reglas de datos de menores.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release --analyze-size
```

No hay CI configurado todavía (ver Fase 7 del plan de mejoras). No hay tests todavía — al añadir código nuevo, añade test si el patrón ya existe en el repo; si no existe, no bloquees por eso pero no reduzcas cobertura existente.

## Convenciones de estructura

Feature-first: cada feature vive en `lib/features/<nombre>/` con subcarpetas `models/`, `providers/`, `screens/` (y a partir de la Fase 4 del plan, `widgets/` y `data/` por feature). Código transversal en `lib/core/{network,storage,theme,utils}/`. Widgets compartidos entre features en `lib/widgets/`, no dentro de una feature.

- **Estado de aplicación → Riverpod** (`StateNotifierProvider`, `Provider`, `Provider.family`). **Estado efímero de UI** (animaciones locales, formularios, temporizador del quiz) → `setState` dentro del propio widget. No mezclar: si el dato sobrevive a un `pop()` o lo necesita otra pantalla, va a un provider.
- **Rutas**: todas centralizadas en [lib/app.dart](lib/app.dart) (GoRouter). No uses `Navigator.push` directo salvo diálogos/bottom sheets locales.
- **Assets**: referencia siempre vía `AppConstants.assetsImages` / futuras constantes de `AppAssets`, nunca literales `'assets/images/...'` sueltos en las pantallas (hoy hay excepciones en `home_screen.dart` y `splash_screen.dart` pendientes de limpiar — no añadas más).
- **Constantes de negocio** (puntos, niveles, timeouts, radios, paddings) van en [lib/core/utils/constants.dart](lib/core/utils/constants.dart), no hardcodeadas en pantallas.
- **Endpoints** centralizados en `lib/core/network/api_endpoints.dart`; las llamadas HTTP pasan siempre por `ApiClient` (Dio con interceptores de auth/logging/errores), nunca `http`/`Dio` instanciado ad hoc en una pantalla.

## Zonas frágiles — leer antes de tocar

- **Auth es un mock.** `lib/features/auth/providers/auth_provider.dart` no llama a la API: genera un usuario fijo y guarda `'mock_token_123'`. No asumas que el login real funciona hasta que se implemente la Fase 1 del plan de mejoras.
- **El backend PHP no arranca tal cual está** (error de sintaxis fatal en `backend/api/index.php` + función duplicada). Por decisión de proyecto, el backend **no se toca desde este repo Flutter** salvo que se indique explícitamente; ver auditoría completa en `docs/BACKEND_AUDIT.md`.
- **`AppConstants.baseUrl` es un placeholder** (`https://yourdomain.com/api`). Todas las llamadas de red fallan hoy y el cliente cae a caché Hive o a datos mock (`getMockChapters()`, `getMockMissions()`).
- **`.env` se empaqueta como asset de Flutter** (`pubspec.yaml` → `assets:`). Hoy solo tiene placeholders, pero **nunca pongas un secreto real ahí** — cualquier cosa en `assets/` viaja dentro del APK/bundle web y es extraíble.
- **La cola offline de avistamientos no se drena.** `LocalStorage.queueSighting()` escribe en Hive pero no hay ningún lugar que llame a `getPendingSightings()`/`clearPendingSightings()` — ver Fase 5 del plan.
- **Dependencias declaradas sin usar**: `lottie`, `cached_network_image`, `flutter_svg`, `shimmer`, `flutter_dotenv`, `connectivity_plus`. Antes de añadir una función que "ya debería estar cubierta por X", comprueba si X se usa de verdad.
- El proyecto **no es un repositorio git todavía** (`git init` pendiente).

## Gamificación (fuente de verdad: `constants.dart`)

Puntos: misión diaria +10, semanal +30, capítulo +15, avistamiento +20. Niveles por puntos acumulados: Observador (0), Explorador (100), Guardián (200), Maestro Guardián (400). Usa siempre `AppConstants.getLevelForPoints`/`getLevelProgress`, no reimplementes el umbral en una pantalla.

## Privacidad (obligatorio en cualquier feature de avistamientos/mapa)

Este producto es para menores. Cualquier cambio que toque ubicación, fotos o nombre de usuario debe respetar `docs/PRIVACY.md`: coordenadas difuminadas antes de salir del dispositivo, sin nombre de usuario en el mapa comunitario, permisos pedidos con explicación previa.

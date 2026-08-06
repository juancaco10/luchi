# CLAUDE.md — contrato de trabajo del repo

Este archivo orienta a cualquier agente o colaborador que edite este repo. Léelo antes de tocar código.

## Qué es esto

Juego educativo Flutter para niños de 6–12 años sobre conservación de luciérnagas: capítulos (vídeo + quiz), misiones diarias/semanales, avistamientos con país/ciudad de perfil + GPS opcional (si no se comparte, punto al azar dentro de la ciudad) + foto, mapa comunitario, perfil con puntos y niveles. Cliente Flutter 3 / Dart 3 (Riverpod + GoRouter + Hive/SharedPreferences + Dio) más una API PHP/MySQL en `backend/` pensada para Hostinger.

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para el mapa de capas y flujo de datos, [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md) para el estado real del backend, y [docs/PRIVACY.md](docs/PRIVACY.md) para las reglas de datos de menores.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release --analyze-size
```

Build contra el backend real: `flutter build apk --dart-define=API_BASE_URL=<dominio real>/api --dart-define=USE_MOCK_AUTH=false` (o `scripts/run_prod.sh`, local y gitignorado — copiar desde `scripts/run_prod.sh.example`). Sin esos `--dart-define` la app usa el placeholder `https://yourdomain.com/api` y falla toda llamada de red.

No hay CI configurado todavía (ver Fase 4 del plan de corrección global). No hay tests todavía — al añadir código nuevo, añade test si el patrón ya existe en el repo; si no existe, no bloquees por eso pero no reduzcas cobertura existente.

## Convenciones de estructura

Feature-first: cada feature vive en `lib/features/<nombre>/` con subcarpetas `models/`, `providers/`, `screens/` (y a partir de la Fase 4 del plan, `widgets/` y `data/` por feature). Código transversal en `lib/core/{network,storage,theme,utils}/`. Widgets compartidos entre features en `lib/widgets/`, no dentro de una feature.

- **Estado de aplicación → Riverpod** (`StateNotifierProvider`, `Provider`, `Provider.family`). **Estado efímero de UI** (animaciones locales, formularios, temporizador del quiz) → `setState` dentro del propio widget. No mezclar: si el dato sobrevive a un `pop()` o lo necesita otra pantalla, va a un provider.
- **Rutas**: todas centralizadas en [lib/app.dart](lib/app.dart) (GoRouter). No uses `Navigator.push` directo salvo diálogos/bottom sheets locales.
- **Assets**: referencia siempre vía `AppConstants.assetsImages` / futuras constantes de `AppAssets`, nunca literales `'assets/images/...'` sueltos en las pantallas (hoy hay excepciones en `home_screen.dart` y `splash_screen.dart` pendientes de limpiar — no añadas más).
- **Constantes de negocio** (puntos, niveles, timeouts, radios, paddings) van en [lib/core/utils/constants.dart](lib/core/utils/constants.dart), no hardcodeadas en pantallas.
- **Endpoints** centralizados en `lib/core/network/api_endpoints.dart`; las llamadas HTTP pasan siempre por `ApiClient` (Dio con interceptores de auth/logging/errores), nunca `http`/`Dio` instanciado ad hoc en una pantalla.

## Zonas frágiles — leer antes de tocar

- **Auth ya no es mock por defecto.** `AppConstants.useMockAuth` es `false` de forma predeterminada: `lib/features/auth/providers/auth_provider.dart` llama a la API real salvo que se pase `--dart-define=USE_MOCK_AUTH=true`. El backend en Hostinger responde (verificado con `curl` y en dispositivo real).
- **El interceptor de errores ya NO cierra sesión en un 401 cualquiera** (arreglado en Fase 1). `lib/core/network/api_client.dart`, `_ErrorInterceptor` solo traduce el error y propaga `err.response.data['error']` del backend; cerrar sesión es responsabilidad del call site que depende de auth (login/register, `deleteAccount()`). No repitas el patrón "401 ⇒ clearToken() global" en código nuevo.
- **El backend PHP sí arranca** (`php -l backend/api/index.php` limpio) y tiene rate limiting de login, `DELETE /me`, y el mapa comunitario deshabilitado (`410`) por privacidad — `docs/BACKEND_AUDIT.md` estaba desactualizado y ya no describe el estado real. Sigue siendo cierto que el backend **no se toca desde este repo Flutter** salvo instrucción explícita.
- **`AppConstants.baseUrl` es un placeholder** (`https://yourdomain.com/api`) otra vez — nunca hardcodear el dominio real aquí; se inyecta por `--dart-define=API_BASE_URL=...` (ver sección Comandos).
- **La cola offline de avistamientos se drena al arrancar y al reconectar** (arreglado en Fase 1). `lib/core/network/sync_service.dart` llama a `_syncPending()` tanto en `start()` como al detectar conectividad; borra por clave individual (`removePendingSighting`), no con `clear()+reinsert`.
- **El sistema de temas es real desde Fase 2.** `AppColors` (clase estática de colores fijos) se borró; todo pasa por `Theme.of(context)` vía las extensiones de `lib/core/theme/firefly_colors.dart`: `context.colors` (ColorScheme), `context.text` (TextTheme), `context.firefly` (tokens de marca sin equivalente en Material — glow, gradientes, cardShadow). Los valores por tema viven en `lib/core/theme/palettes.dart` (`DarkPalette`/`LightPalette`). No reintroduzcas colores `Color(0x...)` sueltos en una pantalla ni un `AppColors` nuevo.
- El proyecto **ya es un repositorio git** (`main`, remoto `github.com/juancaco10/luchi`).

## Gamificación (fuente de verdad: `constants.dart`)

Puntos: misión diaria +10, semanal +30, capítulo +15, avistamiento +20. Niveles por puntos acumulados: Observador (0), Explorador (100), Guardián (200), Maestro Guardián (400). Usa siempre `AppConstants.getLevelForPoints`/`getLevelProgress`, no reimplementes el umbral en una pantalla.

## Privacidad (obligatorio en cualquier feature de avistamientos/mapa)

Este producto es para menores. Cualquier cambio que toque ubicación, fotos o nombre de usuario debe respetar `docs/PRIVACY.md`: coordenadas difuminadas antes de salir del dispositivo, sin nombre de usuario en el mapa comunitario, permisos pedidos con explicación previa.

# 🪲 Luchi — Guardianes de las Luciérnagas

> Aplicación educativa y gamificada para niños (6–12 años) sobre la conservación de luciérnagas y el cuidado del ecosistema nocturno.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![PHP](https://img.shields.io/badge/PHP-8.x-777BB4?logo=php)
![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?logo=mysql)

Cliente Flutter (Riverpod + GoRouter + Hive/SharedPreferences + Dio) y API
PHP/MySQL en `backend/` para Hostinger.

---

## 📚 Documentación

Índice completo en [docs/README.md](docs/README.md). Lo esencial:

- **[docs/SCREEN_INVENTORY.md](docs/SCREEN_INVENTORY.md)** — pantallas, estado y flujo.
- **[docs/PRODUCTION_READINESS_CHECKLIST.md](docs/PRODUCTION_READINESS_CHECKLIST.md)** — qué falta para producción.
- **[docs/PRIVACY.md](docs/PRIVACY.md)** — reglas de datos de menores (obligatorio en avistamientos/mapa).
- **[docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md)** — estado real del backend.

---

## 🏗️ Arquitectura Flutter

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para el detalle. Resumen:

```
lib/
├── main.dart                 ← Entry point + orientación + ProviderScope
├── app.dart                  ← GoRouter + ThemeData + MaterialApp
├── core/                     ← network, storage, session, theme, utils
├── features/                 ← auth, education, games, home, profile, sightings
└── widgets/                  ← componentes compartidos
```

- **Estado de app** → Riverpod. **Estado efímero de UI** → `setState`.
- **Temas** → extensiones de `firefly_colors.dart` (`context.colors/text/firefly`), nunca `Color(0x...)` sueltos.
- **Rutas** → centralizadas en `lib/app.dart` (GoRouter).

---

## 🚀 Setup Flutter

### Requisitos
- Flutter SDK 3.x / Dart 3.x
- Android Studio / VS Code con extensión Flutter

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Configurar la URL del backend (opcional)

`AppConstants.baseUrl` en `lib/core/utils/constants.dart` apunta al backend real
de Hostinger por defecto. Se inyecta en build:

```bash
flutter build apk --dart-define=API_BASE_URL=<dominio real>/api
```

`USE_MOCK_AUTH=true` usa el mock local de auth (útil sin backend). Ver
[CLAUDE.md](CLAUDE.md).

### 3. Ejecutar

```bash
flutter run
```

> **Auth real**: `AppConstants.useMockAuth` es `false` por defecto. La app
> llama a la API real salvo que se pase `--dart-define=USE_MOCK_AUTH=true`.

---

## 🔌 Backend PHP

> El backend **sí arranca** y está desplegado en Hostinger. Ver
> [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md). No se toca desde este repo
> Flutter salvo instrucción explícita.

### Despliegue

1. Sube `backend/api/` al directorio `public_html/api/` del hosting.
2. Aplica las migraciones de `backend/database/migrations/` en orden.
3. Configura `backend/api/config/database.php` (credenciales + `JWT_SECRET`).

### Verificar

```bash
curl https://tu_dominio.com/api/login -H "Content-Type: application/json" -d '{}'
```

---

## 📡 API Reference

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/register` | ❌ | Registrar nuevo usuario |
| POST | `/login` | ❌ | Iniciar sesión (con rate limiting) |
| GET | `/me` | ✅ | Obtener perfil actual |
| PUT | `/me` | ✅ | Actualizar perfil (nickname, país/ciudad, avatar) |
| DELETE | `/me` | ✅ | Eliminar cuenta |
| GET | `/chapters` | ✅ | Capítulos con progreso |
| POST | `/complete-chapter` | ✅ | Marcar capítulo completado (+puntos) |
| POST | `/sightings` | ✅ | Registrar avistamiento (+20 pts) |
| GET | `/sightings` | ✅ | Feed comunitario (mapa) |
| GET | `/my-sightings` | ✅ | Mis avistamientos |

---

## 🎮 Sistema de Gamificación

| Acción | Puntos |
|--------|--------|
| Capítulo completado | +15 |
| Avistamiento registrado | +20 |
| Estrella de minijuego | +5 |

**Niveles:**
| Nivel | Nombre | Puntos requeridos |
|-------|--------|------------------|
| 1 | Observador | 0 |
| 2 | Explorador | 100 |
| 3 | Guardián | 200 |
| 4 | Maestro Guardián | 400 |

---

## 📦 Dependencias Flutter principales

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` | State management |
| `go_router` | Navegación declarativa |
| `dio` | HTTP client |
| `hive_flutter` | Cache offline |
| `flutter_animate` | Micro-animaciones |
| `flutter_map` | Mapa OSM (sin API key) |
| `geolocator` + `geocoding` | GPS + geocodificación |
| `video_player` + `chewie` | Reproductor de videos |
| `image_picker` + `nsfw_detector_flutter` | Fotos + filtro NSFW on-device |
| `google_mobile_ads` | Anuncios (apagados, `adsEnabled=false`) |

---

## 🔒 Privacidad infantil

Obligatorio en cualquier cambio de avistamientos/mapa — ver [docs/PRIVACY.md](docs/PRIVACY.md):

- Coordenadas difuminadas a 3 decimales antes de salir del dispositivo.
- Sin nombre completo ni `user_id` en el feed comunitario.
- EXIF eliminado por re-codificación server-side de fotos.
- `allowBackup=false` + `dataExtractionRules`.

---

## 📄 Licencia

MIT — Úsalo libremente para proyectos educativos.

---

*Hecho con ❤️ para proteger la magia de las noches de verano 🌙✨*

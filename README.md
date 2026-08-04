# 🪲 Guardianes de las Luciérnagas

> Aplicación educativa y gamificada para niños (6–12 años) sobre la conservación de luciérnagas y el cuidado del ecosistema nocturno.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![PHP](https://img.shields.io/badge/PHP-8.x-777BB4?logo=php)
![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?logo=mysql)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📱 Pantallas

| Splash | Onboarding | Home | Capítulos |
|--------|-----------|------|-----------|
| Partículas de luciérnagas animadas | 4 slides con gradientes | Dashboard con puntos y misiones | Lista con progreso por capítulo |

| Misiones | Perfil | Avistamiento | Mapa |
|---------|--------|-------------|------|
| Diarias + semanales | Nivel, puntos e insignias | GPS + foto + cantidad | flutter_map con marcadores |

---

## 🏗️ Arquitectura Flutter

```
lib/
├── main.dart                 ← Entry point + orientación + sistema UI
├── app.dart                  ← GoRouter + ThemeData + MaterialApp
├── core/
│   ├── theme/
│   │   ├── app_colors.dart   ← Paleta completa (noche + luciérnaga)
│   │   └── app_theme.dart    ← ThemeData oscuro con Nunito
│   ├── network/
│   │   ├── api_client.dart   ← Dio singleton + interceptores
│   │   └── api_endpoints.dart
│   ├── storage/
│   │   └── local_storage.dart ← SharedPrefs + Hive (offline-first)
│   └── utils/
│       └── constants.dart    ← Gamification + assets + UI constants
├── features/
│   ├── auth/                 ← Splash, Onboarding, Login, Register
│   ├── home/                 ← Home Dashboard
│   ├── education/            ← Capítulos (lista + detalle + quiz)
│   ├── missions/             ← Misiones (lista + detalle)
│   ├── sightings/            ← Formulario + Mapa
│   └── profile/              ← Perfil + Configuración
└── widgets/                  ← Componentes reutilizables
    ├── firefly_background.dart ← Partículas de luciérnaga
    ├── custom_button.dart
    ├── level_progress_bar.dart
    ├── reward_overlay.dart
    └── points_display.dart
```

---

## 🚀 Setup Flutter

### Requisitos
- Flutter SDK 3.x
- Dart 3.x
- Android Studio / VS Code con extensión Flutter

### 1. Instalar dependencias

```bash
cd luciernagas_game
flutter pub get
```

### 2. Crear directorios de assets

```bash
mkdir -p assets/images assets/animations assets/fonts
```

> **Fuente Nunito**: hoy la app usa el paquete `google_fonts`, que descarga la tipografía por red en el primer arranque (no funciona 100% offline). Si prefieres empaquetarla localmente, descarga los `.ttf` de [Google Fonts](https://fonts.google.com/specimen/Nunito) en `assets/fonts/` (`Nunito-Regular.ttf`, `Nunito-SemiBold.ttf`, `Nunito-Bold.ttf`, `Nunito-ExtraBold.ttf`) y declara una sección `fonts:` en `pubspec.yaml`.

### 3. Configurar URL del backend

Edita `lib/core/utils/constants.dart`:
```dart
static const String baseUrl = 'https://TU_DOMINIO.com/api';
```

### 4. Ejecutar

```bash
flutter run
```

> **Estado actual del login**: `auth_provider.dart` todavía no llama a la API — genera un usuario simulado en local para poder probar el resto de la app sin backend. Ver [CLAUDE.md](CLAUDE.md) y [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md).

---

## 🔌 Setup Backend PHP

> ⚠️ **El backend, tal como está en este repo, no arranca** (error de sintaxis fatal en `backend/api/index.php` + una función declarada dos veces). Antes de desplegarlo hace falta aplicar las correcciones listadas en [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md). Los pasos de esta sección describen el despliegue una vez corregido.

### Requisitos
- PHP 8.0+
- MySQL 5.7+ / MariaDB 10.3+
- Apache con mod_rewrite (Hostinger shared hosting ✅)

### 1. Base de datos

1. Crea una base de datos MySQL en tu panel de Hostinger
2. Importa el esquema:
```bash
mysql -u usuario -p nombre_db < backend/database/schema.sql
```

### 2. Configuración

Edita `backend/api/config/database.php`:
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'tu_base_de_datos');
define('DB_USER', 'tu_usuario');
define('DB_PASS', 'tu_contraseña');
define('JWT_SECRET', 'clave_secreta_aleatoria_muy_larga_64_caracteres');
```

### 3. Deploy a Hostinger

1. Sube el contenido de `backend/api/` al directorio `public_html/api/` de tu hosting
2. Verifica que el `.htaccess` esté habilitado (Panel → Hosting → Configuración de Apache)

### 4. Verificar

```bash
curl https://tu_dominio.com/api/chapters -H "Authorization: Bearer TU_TOKEN"
```

---

## 📡 API Reference

### Autenticación

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/register` | Registrar nuevo usuario |
| POST | `/login` | Iniciar sesión |
| GET | `/me` | Obtener perfil actual |

**Ejemplo registro:**
```json
POST /register
{
  "name": "María",
  "email": "maria@ejemplo.com",
  "password": "mi_contraseña"
}
```

**Respuesta:**
```json
{
  "token": "eyJ...",
  "user": {
    "id": 1,
    "name": "María",
    "email": "maria@ejemplo.com",
    "points": 0,
    "level": 1,
    "levelName": "Observador"
  }
}
```

### Capítulos

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/chapters` | ✅ | Lista con progreso del usuario |
| POST | `/complete-chapter` | ✅ | Marcar capítulo como completado |

### Misiones

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/missions` | ✅ | Lista diarias + semanales |
| POST | `/complete-mission` | ✅ | Completar misión (+puntos) |

### Avistamientos

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/sightings` | ✅ | Registrar avistamiento (+20 pts) |
| GET | `/sightings` | ✅ | Todos los avistamientos (mapa) |
| GET | `/my-sightings` | ✅ | Mis avistamientos |

---

## 🎮 Sistema de Gamificación

| Acción | Puntos |
|--------|--------|
| Misión diaria | +10 |
| Misión semanal | +30 |
| Completar capítulo | +15 |
| Registrar avistamiento | +20 |

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
| `geolocator` | GPS |
| `video_player` + `chewie` | Reproductor de videos |
| `image_picker` | Cámara para fotos |


---

## 🔒 Seguridad Backend

- ✅ Consultas PDO con parámetros preparados en casi todas las rutas (una excepción documentada en la auditoría)
- ✅ Contraseñas hasheadas con `password_hash()` (bcrypt, cost=12)
- ✅ JWT HS256 con expiración 30 días
- ✅ `.htaccess` bloquea archivos `.env`, `.sql`, `.md`
- ❌ El backend no arranca hoy (error fatal de sintaxis) — ver `docs/BACKEND_AUDIT.md`
- ❌ Sin rate limiting en `/login` ni `/register`
- ❌ CORS abierto a cualquier origen (`Access-Control-Allow-Origin: *`) sobre endpoints autenticados
- ❌ `GET /sightings` expone coordenadas exactas y nombre de usuario de menores a cualquier cuenta autenticada — ver `docs/PRIVACY.md`
- ❌ Sin caché de servidor (APCu/Redis/ETag)

Lista completa de hallazgos y correcciones propuestas: [docs/BACKEND_AUDIT.md](docs/BACKEND_AUDIT.md).

---

## ✅ Implementado vs. 🌱 Planificado

**Implementado en el cliente Flutter**: onboarding, dashboard, lista/detalle de capítulos con quiz, misiones (UI), formulario de avistamiento con GPS/foto, mapa con `flutter_map`, perfil e insignias por puntos, caché offline de capítulos/misiones vía Hive.

**No implementado todavía** (aunque se mencione en otros documentos del proyecto o en versiones anteriores de este README):
- Login/registro reales contra el backend (hoy es un mock local)
- Moderación de avistamientos antes de aparecer en el mapa comunitario
- Insignias por misiones/avistamientos/capítulos (el backend solo evalúa insignias por puntos)
- Sincronización de la cola de avistamientos offline (se guardan en local pero nada los sube todavía)
- Difuminado de ubicación y ocultación de nombre en el mapa comunitario (ver `docs/PRIVACY.md`)

## 🌱 Roadmap futuro

- [ ] Push notifications (misiones diarias)
- [ ] Modo multijugador por clase/grupo
- [ ] Mapa de calor de avistamientos
- [ ] Integración con iNaturalist API
- [ ] Panel de administración web
- [ ] Modo offline completo con sync automático (hoy la cola local no se drena)
- [ ] Soporte multiidioma (ES/EN/PT)
- [ ] Backend funcional en producción (ver checklist en `docs/BACKEND_AUDIT.md`)
- [ ] Consentimiento parental y controles de privacidad para menores (ver `docs/PRIVACY.md`)

---

## 📄 Licencia

MIT — Úsalo libremente para proyectos educativos.

---

*Hecho con ❤️ para proteger la magia de las noches de verano 🌙✨*

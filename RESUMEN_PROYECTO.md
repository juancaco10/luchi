# Resumen de "Guardianes de las Luciérnagas" (Luchi)

**"Guardianes de las Luciérnagas"** es una aplicación móvil multiplataforma (Android, iOS, Web, Windows) diseñada específicamente para niños de entre 6 y 12 años. Su objetivo principal es educar sobre la conservación de las luciérnagas y su ecosistema nocturno, motivando a los usuarios a salir a la naturaleza y apagar las luces, todo mediante una experiencia gamificada y mágica.

A continuación, se detalla todo lo que **tiene** y **hace** la aplicación actual (estructura de navegación vigente 2026-08-30):

---

## 📱 Módulos y Funcionalidades (Frontend - Flutter)

### 1. Autenticación y Onboarding (Inicio)
*   **Onboarding Mágico:** Pantallas introductorias con animaciones y gradientes nocturnos que explican el propósito de la app a los niños.
*   **Consentimiento parental:** Pantalla previa de consentimiento (política + versión de política persistida).
*   **Registro e Inicio de Sesión:** Sistema para crear una cuenta (Correo, Contraseña, Google o invitado) y guardar el progreso usando tokens JWT contra el backend real. **No es mock por defecto.**
*   **Nickname setup:** Tras el primer login se pide el apodo que saldrá en el feed.
*   **Splash Screen:** Pantalla de carga con partículas flotantes de luciérnagas animadas.

### 2. Dashboard (Pantalla Principal)
*   **Resumen del Jugador:** Muestra el nombre del niño, su Nivel (ej. "Observador", "Explorador") y sus "Puntos de Luz", con barra de progreso hacia el siguiente nivel.
*   **Accesos Rápidos:** Tarjetas **Jugar** (→ quiz), **Aprender** (→ capítulos/videos) y **Mapa** (→ explorar).
*   **Progreso educativo y avistamientos recientes:** tarjetas que leen datos reales de los providers.

### 3. Educación — Aprender (Capítulos y Videos)
*   **8 capítulos** empaquetados con sus videos locales (`assets/videos/{id}.mp4`), funcionan **sin conexión**.
*   **Estructura de Desbloqueo:** Los capítulos están bloqueados; el jugador debe terminar uno para abrir el siguiente.
*   **Progreso offline-first:** qué capítulos completó el usuario se conserva en caché local.
*   **Datos curiosos y puntos** por cada capítulo completado.

### 4. Jugar — Quiz (Exploración Nocturna)
*   **Preguntas y respuestas** con temporizador, racha, feedback y explicación.
*   **10 niveles** con desbloqueo secuencial y sistema de estrellas.
*   **Preguntas obligatorias del cliente** (qué son, dónde viven, por qué están en peligro, cómo protegerlas/ayudarlas, matar/atrapar, desde el hogar, alimentación/reproducción) están en el banco.
*   Otros 4 minijuegos (Guiar, Sincronizar, Proteger, Restaurar) quedan en el código pero **ocultos de la navegación** (decisión de producto).

### 5. Avistamientos (Trabajo de Campo)
*   **Formulario Interactivo:** Si el niño ve luciérnagas en su jardín o parque, puede registrar el "Avistamiento".
*   **Geolocalización (GPS):** opcional; si no se comparte, se usa un punto al azar dentro de la ciudad. Las coordenadas se **difuminan a 3 decimales** antes de salir del dispositivo.
*   **Adjuntar Foto:** cámara + filtro **NSFW on-device** (nunca sale del teléfono para esa comprobación).
*   **Cola offline + sync:** los avistamientos sin conexión se guardan y se suben al arrancar/reconectar.
*   **Recompensa:** +20 puntos por avistamiento.

### 6. Mapa Interactivo — Explorar
*   **OpenStreetMap** vía `flutter_map` (sin API key; sustituye a CartoDB que exigía key).
*   Muestra avistamientos propios (aprobados/pendientes) y del feed comunitario.
*   Zoom por botones + detalle de avistamientos.

### 7. Feed Comunitario (Publicaciones)
*   Sin nombre completo ni `user_id` (privacidad infantil).
*   Fotos, me gusta, cantidad y filtro por fecha.

### 8. Perfil y Ajustes
*   **Perfil de Guardián:** avatar (18 seleccionables), nivel, puntos, estadísticas.
*   **Configuración:** tema claro/oscuro (real y persistente), nickname, ubicación, cerrar sesión, eliminar cuenta, enlace de privacidad.

---

## ⚙️ Características Técnicas (El Motor)

*   **Motor Frontend (App):** Flutter 3.x / Dart 3. `Riverpod` (estado), `GoRouter` (navegación centralizada en `lib/app.dart`).
*   **Temas:** sistema real por tema vía extensiones de `firefly_colors.dart` (`context.colors/text/firefly`); valores en `palettes.dart`. Sin `AppColors` ni colores sueltos.
*   **Funcionamiento Offline-First:** `Hive` + `SharedPreferences` para capítulos, avistamientos y sesión.
*   **Arquitectura feature-first:** `lib/core` (transversal) + `lib/features/{auth,education,games,home,profile,sightings}` + `lib/widgets` (compartidos).
*   **Backend y Base de Datos:**
    *   API RESTful en **PHP 8.x**, MySQL, JWT, bcrypt, rate limiting en login.
    *   Desplegado y respondiendo en Hostinger; ver `docs/BACKEND_AUDIT.md`.
    *   Endpoints centralizados en `lib/core/network/api_endpoints.dart`; HTTP solo vía `ApiClient`.

---

## 💡 Resumen Final
"Guardianes de las Luciérnagas" no es solo una app informativa, es un **juego ecológico de la vida real**. Convierte el teléfono móvil en una herramienta de exploración donde el objetivo final no está en la pantalla, sino en cuidar el jardín y apagar las luces en casa.

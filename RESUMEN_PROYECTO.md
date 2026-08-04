# Resumen de "Guardianes de las Luciérnagas"

**"Guardianes de las Luciérnagas"** es una aplicación móvil multiplataforma (Android, iOS, Web, Windows) diseñada específicamente para niños de entre 6 y 12 años. Su objetivo principal es educar sobre la conservación de las luciérnagas y su ecosistema nocturno, motivando a los usuarios a salir a la naturaleza y apagar las luces, todo mediante una experiencia gamificada y mágica.

A continuación, se detalla todo lo que **tiene** y **hace** la aplicación actual:

---

## 📱 Módulos y Funcionalidades (Frontend - Flutter)

### 1. Autenticación y Onboarding (Inicio)
*   **Onboarding Mágico:** Pantallas introductorias con animaciones y gradientes nocturnos que explican el propósito de la app a los niños.
*   **Registro e Inicio de Sesión:** Sistema para crear una cuenta (Nombre, Correo, Contraseña) y guardar el progreso de forma segura usando tokens JWT.
*   **Splash Screen:** Pantalla de carga con partículas flotantes de luciérnagas animadas.

### 2. Dashboard (Pantalla Principal)
*   **Resumen del Jugador:** Muestra el nombre del niño, su Nivel actual (ej. "Observador", "Explorador"), y sus "Puntos de Luz" totales, con una barra circular de progreso hacia el siguiente nivel.
*   **Accesos Rápidos:** Botones grandes y redondeados para acceder a Capítulos, Misiones y el Mapa.
*   **Diseño Animado:** Fondo dinámico (opcional) o gradiente nocturno suave.

### 3. Educación (Capítulos y Quiz)
*   **Módulo de Aprendizaje:** Lecciones cortas y amigables sobre ecología, biología de luciérnagas y contaminación lumínica.
*   **Estructura de Desbloqueo:** Los capítulos están bloqueados; el jugador debe terminar el Capítulo 1 para abrir el Capítulo 2.
*   **Multimedia:** Soporte para textos con tipografía grande y fácil de leer, y videos incrustados.

### 4. Gamificación (Misiones y Recompensas)
*   **Misiones Diarias y Semanales:** Tareas del mundo real, como "Apaga las luces exteriores hoy" o "Lee un capítulo de la academia".
*   **Economía de Puntos:** Completar misiones otorga "Puntos de Luz". Al sumar puntos, el usuario sube de nivel y desbloquea insignias (badges).
*   **Overlay de Recompensa:** Al completar una tarea o subir de nivel, aparece una animación emergente en toda la pantalla para celebrar el logro.

### 5. Avistamientos (Trabajo de Campo)
*   **Formulario Interactivo:** Si el niño ve luciérnagas en su jardín o parque, puede registrar el "Avistamiento".
*   **Geolocalización (GPS):** La app toma las coordenadas actuales de forma automática.
*   **Adjuntar Foto:** Permite usar la cámara para capturar la evidencia.
*   **Registro de Cantidad:** El niño indica cuántas luciérnagas vio (1, un grupito, o muchas).
*   **Recompensa Extra:** Cada avistamiento válido otorga +20 puntos.

### 6. Mapa Interactivo
*   **Ubicación de Avistamientos:** Usa OpenStreetMap (vía `flutter_map` - no requiere clave de Google Maps) para mostrar en un mapa con un estilo oscuro/nocturno todos los lugares donde se han visto luciérnagas.
*   **Comunidad (Futuro):** Muestra tanto los avistamientos del usuario como los de la comunidad (sujetos a aprobación).

### 7. Perfil y Ajustes
*   **Perfil de Guardián:** Muestra el avatar, estadísticas totales (misiones completadas, avistamientos).
*   **Configuración:** Modo oscuro/claro (actualmente optimizado para modo nocturno forzado), notificaciones y cierre de sesión.

---

## ⚙️ Características Técnicas (El Motor)

*   **Motor Frontend (App):** Construida con Flutter 3.x y Dart 3. Utiliza `Riverpod` para la gestión de estado de alto rendimiento, y `GoRouter` para una navegación moderna.
*   **Funcionamiento Offline-First:** Usa almacenamiento local (`Hive` y `SharedPreferences`) para guardar misiones, capítulos y estado de inicio de sesión. Si no hay internet, la app sigue funcionando con los últimos datos sincronizados.
*   **Arquitectura Limpia (Clean Architecture):** Código completamente modular (dividido en 'core' y 'features'), sin generación automática de código, garantizando compilaciones instantáneas y sin conflictos en el futuro.
*   **Backend y Base de Datos:**
    *   API RESTful programada en **PHP 8.x**.
    *   Base de datos relacional **MySQL**.
    *   Seguridad integrada con Tokens JWT, contraseñas encriptadas (Bcrypt) y prevención contra inyección SQL.

---

## 💡 Resumen Final
"Guardianes de las Luciérnagas" no es solo una app informativa, es un **juego ecológico de la vida real**. Convierte el teléfono móvil en una herramienta de exploración (pokedex de la naturaleza) donde el objetivo final no está en la pantalla, sino en cuidar el jardín y apagar las luces en casa.

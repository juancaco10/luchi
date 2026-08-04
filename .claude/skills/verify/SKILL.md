---
name: verify
description: Build, install and drive the Luchi Flutter app on a connected Android device to observe a change at runtime.
---

# Verificar la app en un dispositivo Android

## Handle

No hay emulador configurado; se usa el dispositivo físico conectado.

```bash
flutter devices                      # anota el serial (p.ej. RFCW31BZ6XY)
flutter build apk --debug
adb -s <serial> install -r build/app/outputs/flutter-apk/app-debug.apk
```

`flutter run` no hace falta: build + install + `monkey` para lanzar es más
rápido y no deja un proceso attached bloqueando el shell.

### Dart-defines que importan

`lib/core/utils/constants.dart` lee dos:

- `API_BASE_URL` — por defecto apunta al backend real en Hostinger.
- `USE_MOCK_AUTH` — por defecto **false**, o sea la app llama a la API real.

Para verificar UI (home, tema, educación) sin credenciales reales:

```bash
flutter build apk --debug --dart-define=USE_MOCK_AUTH=true
```

Ojo: con mock auth el token es falso, así que cualquier pantalla que
llame a la API recibe 401 y el interceptor de errores borra el token →
la app te devuelve al login. Ver "Gotchas".

## Conducir

```bash
A="adb -s <serial> shell"
$A pm clear com.guardianes.luciernagas          # estado limpio: fuerza onboarding
$A monkey -p com.guardianes.luciernagas -c android.intent.category.LAUNCHER 1
$A "sleep 9"                                     # splash + onboarding tardan
adb -s <serial> exec-out screencap -p > shot.png
```

`exec-out` va en el `adb`, **no** dentro de `adb shell` (si lo metes en la
variable `$A` falla con "inaccessible or not found").

Coordenadas útiles en 1080x2340 (tema oscuro, tras `pm clear`):

| Elemento | tap |
|---|---|
| "Saltar" onboarding | `540 2135` |
| Campo correo (login) | `540 665` |
| Campo contraseña | `540 878` |
| Botón "Iniciar sesión" | `540 1131` |
| Toggle de tema (home) | `691 193` |
| Tarjeta "Capítulos" (home) | `540 1455` |

Para escribir en los campos: `input tap` → `input text "..."` → `input
keyevent 4` para cerrar el teclado. **No uses `keyevent 111`** (abre el
portapapeles de Samsung). Un segundo `keyevent 4` en el login cierra la app.

## Backend real

Responde. Se puede sondear sin la app:

```bash
curl -s -X POST https://dimgrey-dove-703529.hostingersite.com/api/login \
  -H "Content-Type: application/json" -d '{}'
```

Las rutas **no** llevan prefijo `/auth` (`/login`, no `/auth/login`).

## Gotchas observadas

- `_ErrorInterceptor` en `lib/core/network/api_client.dart` descarta el
  campo `error` que devuelve el backend y llama a `clearToken()` en
  **cualquier** 401. Efecto: un 401 en una pantalla cualquiera cierra la
  sesión y te manda al login sin avisar.
- `ProgressCard` en `home_screen.dart` está hardcodeada a 2/5 capítulos;
  la lista real tiene 4 niveles. No lo tomes como dato real.
- El widget de avistamientos recientes desborda 1px por abajo
  (raya amarilla/negra en debug).

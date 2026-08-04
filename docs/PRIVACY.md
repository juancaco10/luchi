# Privacidad de menores — Guardianes de las Luciérnagas

Público objetivo: niños de 6–12 años. La app recoge **ubicación GPS** y **fotos** para los avistamientos, y datos de progreso (puntos, capítulos completados). Este documento define qué se recoge, cómo se minimiza, y qué debe cumplir el cliente y (cuando se retome) el backend. Sirve de referencia obligatoria para cualquier cambio en `lib/features/sightings/` o `lib/features/auth/`.

Este documento describe el diseño objetivo; el código actual **no** lo cumple todavía en varios puntos (marcados abajo como "Estado actual"). No sustituye asesoría legal formal (COPPA en EE. UU., GDPR-K en la UE, LOPDGDD/RGPD en España) antes de un lanzamiento público real.

## Principios

1. **Minimización**: no se recoge ni se envía al servidor nada que la funcionalidad no necesite explícitamente.
2. **Difuminado por defecto**: ninguna ubicación exacta sale nunca del dispositivo salvo para el propio registro privado del usuario.
3. **Anonimato en lo público**: nada visible para otros usuarios identifica a un niño concreto por nombre real ni por ubicación precisa.
4. **Consentimiento antes de permisos**: nunca se dispara un diálogo nativo de permiso (GPS/cámara) sin una pantalla previa que explique para qué, en lenguaje apto para familias/menores.
5. **Control y borrado**: el usuario (o su tutor) puede ver y borrar sus datos.

## Datos recogidos y tratamiento

| Dato | Para qué | Dónde vive | Tratamiento |
|---|---|---|---|
| Nombre de usuario | Perfil, "mis avistamientos" | SharedPreferences + backend | Nunca se muestra en el mapa comunitario ni a otros usuarios |
| Coordenadas GPS del avistamiento | Ubicar la especie en el mapa | Hive (cola local) + backend | **Difuminadas a ~3 decimales (~100 m) antes de salir del dispositivo** — la app nunca envía ni guarda la coordenada de precisión completa |
| Foto del avistamiento | Evidencia visual | dispositivo → backend | Se recortan metadatos EXIF (que pueden incluir GPS de precisión completa y datos del dispositivo) antes de subir |
| Puntos / nivel / capítulos completados | Gamificación | SharedPreferences + backend | No es dato sensible; se conserva mientras la cuenta exista |
| Token de sesión | Autenticación | **Debe** vivir en almacenamiento seguro (`flutter_secure_storage`), no en SharedPreferences en texto plano | — |

**Estado actual (a corregir, ver plan de mejoras Fase 1 y 2):**
- El token se guarda hoy en SharedPreferences en texto plano.
- Las coordenadas se envían hoy sin difuminar; el backend (`GET /sightings`, auditado en `docs/BACKEND_AUDIT.md`) las devuelve exactas junto con el nombre de usuario a cualquier cuenta autenticada.
- No existe pantalla de consentimiento parental en el onboarding.
- No se recortan metadatos EXIF de las fotos antes de subir.

## Requisitos de cliente

- **Consentimiento parental** en el onboarding (`lib/features/auth/screens/onboarding_screen.dart`), antes de cualquier pantalla que vaya a pedir GPS o cámara. Debe enlazar a este documento (o a una versión pública del mismo) y explicar en lenguaje simple qué se recoge y por qué.
- **Permisos just-in-time**: al llegar a `sighting_form_screen.dart`, mostrar primero una explicación en pantalla ("necesitamos tu ubicación para marcar dónde viste la luciérnaga") y solo entonces disparar el diálogo nativo. Si se deniega, ofrecer introducir una ubicación aproximada a mano en vez de bloquear la función.
- **Difuminado de coordenadas**: redondear lat/lng a 3 decimales antes de construir el payload de envío. Esto debe pasar en el cliente, no confiar en que el backend lo haga.
- **Sin nombre en el mapa público**: `map_screen.dart` no debe pintar `user_name` en los marcadores de la comunidad; solo la pantalla de "mis avistamientos" (propios) puede mostrar el nombre del propio usuario.
- **Sin histórico de posición**: no guardar un log de ubicaciones del dispositivo más allá del avistamiento puntual que el usuario decide enviar.
- **Borrado de cuenta**: la pantalla de ajustes (`settings_screen.dart`) debe ofrecer una vía para solicitar borrado de cuenta y datos asociados (aunque hoy dependa de un backend que todavía no lo implementa).

## Requisitos de backend (cuando se retome, ver `docs/BACKEND_AUDIT.md`)

- `GET /sightings` no debe devolver coordenadas de precisión completa ni `user_name` real; devolver un alias o nada, y coordenadas ya redondeadas server-side como segunda capa de defensa (defensa en profundidad, no confiar solo en el cliente).
- Implementar moderación real (`is_pending`) antes de publicar un avistamiento en el mapa comunitario.
- Endpoint de borrado de cuenta que elimine o anonimice avistamientos y datos personales asociados.
- Retención mínima: definir un plazo de expiración de datos de cuentas inactivas.

## Checklist antes de cualquier release pública

- [ ] Pantalla de consentimiento parental implementada y enlazada desde onboarding
- [ ] Coordenadas difuminadas en el cliente antes de cualquier envío
- [ ] Mapa comunitario sin nombres de usuario
- [ ] EXIF recortado de las fotos antes de subir
- [ ] Token en almacenamiento seguro
- [ ] Política de privacidad pública redactada y enlazada en la tienda de apps
- [ ] Revisión legal formal (COPPA/GDPR-K/RGPD según mercado de lanzamiento)

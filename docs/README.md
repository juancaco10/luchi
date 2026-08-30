# 📚 Documentación — Luchi: Guardianes de las Luciérnagas

Índice central de toda la documentación del repo. Las rutas se actualizan con
cada cambio relevante; consulta este índice para orientarte antes de tocar código.

---

## 1. Visión general y arquitectura

| Documento | Contenido |
| --- | --- |
| [../ARCHITECTURE.md](../ARCHITECTURE.md) | Mapa de capas (`lib/`), temas, patrones de estado y flujo de datos |
| [../CLAUDE.md](../CLAUDE.md) | **Contrato de trabajo del repo** — leelo antes de editar |
| [../README.md](../README.md) | Presentación del proyecto, setup Flutter y backend |
| [../RESUMEN_PROYECTO.md](../RESUMEN_PROYECTO.md) | Resumen general de producto |

## 2. Inventario y estado del código

| Documento | Contenido |
| --- | --- |
| [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md) | Todas las pantallas, rutas, tabs y superficies de UI |
| [BACKEND_AUDIT.md](BACKEND_AUDIT.md) | Estado real del backend PHP/MySQL |
| [PRIVACY_BEHAVIOR_MATRIX.md](PRIVACY_BEHAVIOR_MATRIX.md) | Matriz de comportamiento frente a privacidad |

## 3. Producción y lanzamiento

| Documento | Contenido |
| --- | --- |
| [PRODUCTION_READINESS_CHECKLIST.md](PRODUCTION_READINESS_CHECKLIST.md) | **Qué falta para producción** — la lista de referencia |
| [GOOGLE_PLAY_RELEASE_AUDIT.md](GOOGLE_PLAY_RELEASE_AUDIT.md) | Auditoría para Google Play (Familias, data safety) |
| [GOOGLE_PLAY_CHILD_LOCATION_REVIEW.md](GOOGLE_PLAY_CHILD_LOCATION_REVIEW.md) | Revisión de ubicación en apps para menores |
| [FINAL_PREPRODUCTION_REPORT.md](FINAL_PREPRODUCTION_REPORT.md) | Detalle de cada hallazgo preproducción |
| [PREPRODUCTION_AUDIT.md](PREPRODUCTION_AUDIT.md) | Auditoría preproducción amplia |
| [PREPRODUCTION_FIX_LOG.md](PREPRODUCTION_FIX_LOG.md) | Registro de correcciones aplicadas |
| [REAL_DEVICE_TEST_CHECKLIST.md](REAL_DEVICE_TEST_CHECKLIST.md) | Checklist de pruebas en dispositivo físico |

## 4. Privacidad infantil (obligatorio)

| Documento | Contenido |
| --- | --- |
| [PRIVACY.md](PRIVACY.md) | **Reglas de datos de menores** — leer antes de tocar avistamientos/mapa |

---

## Cómo mantener este índice

- Al añadir/renombrar/eliminar un `.md`, actualiza la tabla correspondiente.
- Marca con `- [x]`/`- [ ]` el estado real en `PRODUCTION_READINESS_CHECKLIST.md`.
- Actualiza `SCREEN_INVENTORY.md` al añadir o cambiar rutas/pantallas.

-- ============================================================
-- Corrige las URLs de vídeo de los 4 capítulos.
--
-- Ejecutar UNA vez en phpMyAdmin (u otro cliente MySQL) contra la base de
-- producción. Seguro de re-ejecutar: el WHERE solo afecta filas que
-- todavía tengan la URL vieja, así que correrlo dos veces no hace nada la
-- segunda vez.
--
-- ── Por qué ──────────────────────────────────────────────────────
-- Los 4 vídeos apuntaban a commondatastorage.googleapis.com/gtv-videos-
-- bucket/sample/*.mp4 — un bucket público de Google que ahora devuelve
-- 403 Forbidden (confirmado con curl y en dispositivo real, 2026-08-07).
-- El capítulo abría con normalidad (título, descripción, datos curiosos),
-- pero el reproductor de vídeo se quedaba esperando para siempre un
-- archivo que nunca iba a llegar — así que en la práctica ningún
-- capítulo se podía completar.
--
-- Los reemplazos son vídeos de ejemplo genéricos (flores, abeja,
-- mariposa) solo para que el reproductor funcione — no son contenido
-- real sobre luciérnagas. Cuando haya vídeos propios grabados, esta
-- misma tabla es la que hay que actualizar.
-- ============================================================

UPDATE chapters SET video_url = 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4'
  WHERE video_url LIKE '%BigBuckBunny.mp4';

UPDATE chapters SET video_url = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'
  WHERE video_url LIKE '%ElephantsDream.mp4';

UPDATE chapters SET video_url = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'
  WHERE video_url LIKE '%ForBiggerBlazes.mp4';

UPDATE chapters SET video_url = 'https://download.samplelib.com/mp4/sample-15s.mp4'
  WHERE video_url LIKE '%SubaruOutbackOnStreetAndDirt.mp4';

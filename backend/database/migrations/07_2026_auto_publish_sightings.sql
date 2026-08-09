-- ============================================================
-- Auto-publicación de avistamientos (decisión de producto).
--
-- Sustituye la cola de moderación manual por publicación inmediata:
-- el código de `POST /sightings` ya inserta con `approved`, así que
-- esto solo hay que ejecutarlo UNA vez para aprobar lo que quedó
-- pendiente de la época de moderación.
--
-- Re-ejecutar es inofensivo (solo actualiza moderated_at de lo ya
-- aprobado), pero no hace falta.
-- ============================================================

UPDATE sightings
   SET moderation_status = 'approved', moderated_at = NOW()
 WHERE moderation_status = 'pending';

-- Verificación rápida: debe mostrar solo 'approved'.
-- SELECT moderation_status, COUNT(*) FROM sightings GROUP BY moderation_status;

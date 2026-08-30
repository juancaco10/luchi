<?php
/**
 * Construye la URL pública de una foto de avistamiento a partir de un
 * filename ya validado server-side. Nunca aceptar la URL que manda el
 * cliente: solo el servidor decide el host/esquema/ruta.
 */
function sightingPhotoUrl(string $filename): string
{
    $scheme    = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host      = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
    return "{$scheme}://{$host}{$scriptDir}/uploads/sightings/{$filename}";
}

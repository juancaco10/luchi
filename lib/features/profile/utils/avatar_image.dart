import 'package:flutter/material.dart';

/// Los 18 avatares seleccionables, en el orden en que se muestran en
/// `AvatarPickerSheet`. Única fuente de verdad del lado cliente — el
/// backend valida contra el mismo patrón (`avatar01.png`…`avatar18.png`)
/// en `PUT /me`, así que esta lista y esa regex deben crecer juntas.
const kAvatarFileNames = [
  'avatar01.png', 'avatar02.png', 'avatar03.png', 'avatar04.png',
  'avatar05.png', 'avatar06.png', 'avatar07.png', 'avatar08.png',
  'avatar09.png', 'avatar10.png', 'avatar11.png', 'avatar12.png',
  'avatar13.png', 'avatar14.png', 'avatar15.png', 'avatar16.png',
  'avatar17.png', 'avatar18.png',
];

const _avatarsPath = 'assets/images/avatars/';

/// Resuelve el `avatarUrl` guardado en `UserModel` a algo pintable.
///
/// `avatarUrl` tiene tres formas posibles en la práctica:
/// - `null` — nadie eligió avatar todavía: se devuelve `null` y quien
///   llama debe caer al círculo con la inicial del nombre.
/// - Empieza por `http` — foto de perfil de Google (`picture` del claim
///   OIDC), escrita directo por el backend al iniciar sesión con Google.
/// - Cualquier otra cosa — se asume uno de los 18 nombres de archivo
///   fijos y se resuelve al asset local. No hace falta volver a validar
///   aquí: si no es uno de los 18, el asset simplemente no existirá y
///   `Image.asset`/`errorBuilder` en quien lo use debe cubrir ese caso.
ImageProvider? avatarImageFor(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  if (avatarUrl.startsWith('http')) return NetworkImage(avatarUrl);
  return AssetImage('$_avatarsPath$avatarUrl');
}

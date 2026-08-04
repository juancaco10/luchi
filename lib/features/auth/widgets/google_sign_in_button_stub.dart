import 'package:flutter/widgets.dart';

/// Reemplazado por `google_sign_in_button_web.dart` en compilaciones web
/// (ver `google_sign_in_button.dart`). En Android/iOS/desktop el botón de
/// Google es el `_OutlinedAction` propio de `login_screen.dart`, así que
/// esta variante nunca debería llegar a renderizarse; el `SizedBox.shrink`
/// es un fallback inofensivo, no la ruta esperada.
Widget buildWebGoogleButton() => const SizedBox.shrink();

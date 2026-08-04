// Importación condicional: `google_sign_in_button_web.dart` usa
// `package:google_sign_in_web`, que importa `dart:ui_web` y no compila
// para Android/iOS. `dart.library.ui_web` solo existe en compilaciones
// web, así que ahí (y solo ahí) se sustituye el stub por la versión real.
export 'google_sign_in_button_stub.dart'
    if (dart.library.ui_web) 'google_sign_in_button_web.dart';

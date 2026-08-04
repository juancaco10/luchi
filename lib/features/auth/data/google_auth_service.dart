import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/utils/constants.dart';

/// Aísla el SDK de `google_sign_in` del resto de la app: `AuthNotifier`
/// solo ve `Future<String?> signInInteractive()` (Android/iOS/desktop) o el
/// stream de `idTokenOnWebSignIn` (web), nunca los tipos del paquete.
///
/// google_sign_in 7.x tiene dos flujos irreconciliables por diseño:
/// - Android/iOS/desktop: `authenticate()` es una llamada directa que
///   devuelve la cuenta o lanza si el usuario cancela.
/// - Web: Google exige su propio botón por política de marca —
///   `supportsAuthenticate()` es `false` ahí y `authenticate()` lanzaría
///   `UnsupportedError`—, así que el resultado llega por
///   `authenticationEvents` cuando el usuario interactúa con el botón que
///   el propio SDK renderiza (ver `google_sign_in_button.dart`).
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      // En web no hay equivalente a google-services.json: el clientId hay
      // que pasarlo explícito. En Android sale sobrando (lo toma del
      // google-services.json) y pasar el de tipo Web ahí sería el cliente
      // equivocado, así que solo se manda en web.
      clientId: kIsWeb ? AppConstants.googleWebClientId : null,
      // serverClientId sí es el mismo en las dos plataformas: es lo que
      // hace que el idToken resultante tenga aud=<client web>, que es
      // justo lo que el backend exige en GOOGLE_CLIENT_ID.
      serverClientId: AppConstants.googleWebClientId,
    );
    _initialized = true;
  }

  /// Android/iOS/desktop. Devuelve `null` si el usuario cancela el
  /// selector de cuenta (no es un error, solo "no hizo nada").
  Future<String?> signInInteractive() async {
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Web. El idToken llega aquí cuando el usuario completa el flujo en el
  /// botón renderizado por Google, no como resultado de una llamada.
  Stream<String> get idTokenOnWebSignIn {
    return GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .cast<GoogleSignInAuthenticationEventSignIn>()
        .map((event) => event.user.authentication.idToken)
        .where((idToken) => idToken != null)
        .cast<String>();
  }
}

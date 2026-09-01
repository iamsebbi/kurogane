import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/api_constants.dart';
import '../core/firebase/firebase_options.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final Dio _dio;
  static const MethodChannel _nativeGoogleChannel = MethodChannel('com.kurogane.mobile/google_identity');

  AuthService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges async* {
    if (Firebase.apps.isEmpty) {
      try {
        await _ensureFirebase();
      } catch (e) {
        debugPrint('Firebase init stream fallback: $e');
      }
    }
    if (Firebase.apps.isNotEmpty) {
      yield* FirebaseAuth.instance.authStateChanges();
    } else {
      yield null;
    }
  }

  /// Validare email conform RFC 5322 regex simplificat
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Validare username (2-24 caractere, litere, cifre, _, -, .)
  static bool isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.-]{2,24}$');
    return usernameRegex.hasMatch(username.trim());
  }

  /// Extrage o sugestie curata de username pe baza contului Google
  static String deriveSuggestedUsername(User? user) {
    if (user == null) return 'otaku';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      final clean = user.displayName!
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
      if (clean.length >= 2) return clean.length > 24 ? clean.substring(0, 24) : clean;
    }
    if (user.email != null && user.email!.contains('@')) {
      final prefix = user.email!.split('@')[0]
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
      if (prefix.length >= 2) return prefix.length > 24 ? prefix.substring(0, 24) : prefix;
    }
    return 'otaku_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<Response<dynamic>?> _postWithFallback(String path, {dynamic data}) async {
    // 1. Incearca mai intai baseUrl curent
    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return response;
      }
    } catch (e) {
      debugPrint('[AuthService] POST failed on ${_dio.options.baseUrl}$path: $e');
    }

    // 2. Incearca fallback-urile din candidateBaseUrls
    final currentBase = _dio.options.baseUrl;
    final candidates = ApiConstants.candidateBaseUrls.where((u) => u != currentBase);

    for (final candidateUrl in candidates) {
      try {
        final fallbackDio = Dio(
          BaseOptions(
            baseUrl: candidateUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 8),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        final response = await fallbackDio.post(path, data: data);
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          _dio.options.baseUrl = candidateUrl;
          debugPrint('[AuthService] Switched working baseUrl to $candidateUrl for $path');
          return response;
        }
      } catch (e) {
        debugPrint('[AuthService] Candidate $candidateUrl failed for $path: $e');
      }
    }

    return null;
  }

  /// Verifică în timp real dacă un username este disponibil
  Future<({bool available, String? error})> checkUsernameAvailable(
    String username, {
    String? excludeUserId,
    String? email,
  }) async {
    final clean = username.trim();
    if (clean.isEmpty) {
      return (available: false, error: 'Introdu un nume de utilizator.');
    }
    if (!isValidUsername(clean)) {
      return (available: false, error: 'Folosește 2-24 caractere (litere, cifre, _, -, .)');
    }

    try {
      final response = await _dio.get(
        ApiConstants.checkUsername,
        queryParameters: {
          'username': clean,
          if (excludeUserId != null) 'excludeUserId': excludeUserId,
          if (email != null) 'email': email,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final available = response.data['available'] == true;
        final error = response.data['error'] as String?;
        return (available: available, error: error);
      }
    } catch (e) {
      debugPrint('[AuthService] checkUsernameAvailable error: $e');
    }

    return (available: true, error: null);
  }

  /// Rezolvă username -> email prin backend dacă identifier-ul nu conține @
  Future<String> resolveIdentifier(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    if (clean.isEmpty) {
      throw const AuthException('Introdu un nume de utilizator sau o adresă de email.');
    }

    if (clean.contains('@')) {
      if (!isValidEmail(clean)) {
        throw const AuthException('Adresa de email introdusă nu are un format valid.');
      }
      return clean;
    }

    // Rezolvare prin backend API cu fallback
    try {
      final response = await _postWithFallback(
        ApiConstants.resolveIdentifier,
        data: {'identifier': clean},
      );

      if (response != null && response.statusCode == 200 && response.data != null && response.data['email'] != null) {
        return response.data['email'] as String;
      }
      throw const AuthException('Nu am găsit niciun cont asociat cu acest username.');
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        throw const AuthException('Numele de utilizator nu există în sistem.');
      }
      throw const AuthException('Eroare de conexiune la verificarea username-ului.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('A apărut o problemă la căutarea contului.');
    }
  }

  /// Conectare cu Email / Username + Parolă
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
  }) async {
    await _ensureFirebase();

    final email = await resolveIdentifier(identifier);

    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth sign in error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          throw const AuthException('Emailul sau parola sunt incorecte.');
        case 'user-disabled':
          throw const AuthException('Acest cont a fost dezactivat de administrator.');
        case 'invalid-email':
          throw const AuthException('Formatul adresei de email este invalid.');
        case 'network-request-failed':
          throw const AuthException('Eroare de rețea. Verifică conexiunea la internet.');
        default:
          throw AuthException(e.message ?? 'Autentificarea a eșuat.');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('A apărut o eroare neașteptată la autentificare.');
    }
  }

  /// Alias pentru compatibilitate
  Future<UserCredential> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) => signIn(identifier: identifier, password: password);

  /// Înregistrare Cont Nou (Username + Email + Parolă)
  Future<UserCredential> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (!isValidUsername(cleanUsername)) {
      throw const AuthException('Numele de utilizator trebuie să aibă între 2 și 24 caractere.');
    }
    if (!isValidEmail(cleanEmail)) {
      throw const AuthException('Introdu o adresă de email validă.');
    }
    if (password.length < 8) {
      throw const AuthException('Parola trebuie să aibă cel puțin 8 caractere.');
    }

    await _ensureFirebase();

    // Creare cont în Firebase Authentication
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(cleanUsername);
        await credential.user!.reload();
      }

      // Sincronizare profil utilizator în backend-ul Kurogane
      try {
        await _postWithFallback(
          ApiConstants.registerUser,
          data: {
            'id': credential.user?.uid ?? '',
            'email': cleanEmail,
            'username': cleanUsername,
            'password': '',
          },
        );
      } catch (backendError) {
        debugPrint('Backend sync user profile error: $backendError');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth sign up error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthException('Această adresă de email este deja asociată unui cont.');
        case 'invalid-email':
          throw const AuthException('Adresa de email introdusă nu este validă.');
        case 'weak-password':
          throw const AuthException('Parola aleasă este prea slabă. Folosește o combinație mai complexă.');
        case 'network-request-failed':
          throw const AuthException('Eroare de rețea. Verifică conexiunea la internet.');
        default:
          throw AuthException(e.message ?? 'Nu s-a putut crea contul.');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('A apărut o eroare neașteptată la înregistrare.');
    }
  }

  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignIn() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiConstants.googleServerClientId,
      );
      _googleSignInInitialized = true;
    }
  }

  /// Autentificare Nativă Google Sign-In (cu Android Credential Manager Bottom Sheet)
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureFirebase();
    try {
      String? idToken;

      // 1. Încearcă direct canalul nativ Android Credential Manager (Bottom Sheet nativ)
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final result = await _nativeGoogleChannel.invokeMapMethod<String, dynamic>('signInWithGoogle', {
            'serverClientId': ApiConstants.googleServerClientId,
            'filterByAuthorizedAccounts': false,
          });

          if (result != null && result['idToken'] != null) {
            idToken = result['idToken'] as String;
          }
        } on PlatformException catch (pe) {
          if (pe.code == 'CANCELED') {
            return null; // User cancelled bottom sheet
          }
          debugPrint('Native Credential Manager fallback note: ${pe.code} - ${pe.message}');
        }
      }

      // 2. Fallback plugin standard dacă idToken nu a fost obținut încă
      if (idToken == null) {
        await _ensureGoogleSignIn();
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        idToken = googleAuth.idToken;
      }

      if (idToken == null) {
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);

      // Sincronizare profil în backend (pentru rezolvare username -> email)
      if (userCredential.user != null) {
        final email = userCredential.user!.email ?? '';
        final username = deriveSuggestedUsername(userCredential.user);
        try {
          await _dio.post(
            ApiConstants.registerUser,
            data: {
              'id': userCredential.user!.uid,
              'email': email,
              'username': username,
              'password': '',
            },
          );
        } catch (backendErr) {
          debugPrint('Google Sign-In backend sync note: $backendErr');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Firebase error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw const AuthException('Există deja un cont cu această adresă de email.');
        case 'invalid-credential':
          throw const AuthException('Credențialele Google sunt invalide.');
        case 'network-request-failed':
          throw const AuthException('Nu s-a putut stabili conexiunea la server. Verifică conexiunea.');
        default:
          throw const AuthException('A apărut o problemă la conectarea cu Google.');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('Google Sign-In generic error: $e');
      throw const AuthException('A apărut o eroare la autentificarea cu Google.');
    }
  }

  /// Resetare Parolă (Forgot Password)
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!isValidEmail(cleanEmail)) {
      throw const AuthException('Introdu o adresă de email validă pentru resetarea parolei.');
    }

    await _ensureFirebase();

    try {
      await firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth reset password error: ${e.code}');
      // Nu expunem erori detaliate care ar permite enumerarea conturilor
    } catch (e) {
      debugPrint('Reset password error: $e');
    }
  }

  /// Deconectare (Sign Out)
  Future<void> signOut() async {
    await _ensureFirebase();
    try {
      await firebaseAuth.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw const AuthException('A apărut o eroare la deconectare.');
    }
  }
}

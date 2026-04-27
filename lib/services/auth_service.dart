import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign up
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    String langCode = 'en',
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));

      String uid = userCredential.user!.uid;

      UserModel user = UserModel.newUser(
        id: uid,
        fullName: fullName,
        email: email,
      );

      // Add isUserRegistrationComplete field directly here
      await _firestore
          .collection('users')
          .doc(uid)
          .set({...user.toMap(), 'isUserRegistrationComplete': false})
          .timeout(const Duration(seconds: 20));

      return null; // success
    } on TimeoutException {
      return langCode == 'si'
          ? 'සම්බන්ධතාවය ප්‍රමාද වී ඇත. කරුණාකර නැවත උත්සාහ කරන්න.'
          : 'Connection timed out. Please try again.';
    } on FirebaseAuthException catch (e) {
      return _localizeAuthError(e, langCode);
    } catch (e) {
      return _localizeGenericError(langCode);
    }
  }

  /// Login
  Future<String?> login({
    required String email,
    required String password,
    String langCode = 'en',
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _localizeAuthError(e, langCode);
    } catch (e) {
      return _localizeGenericError(langCode);
    }
  }

  /// Google login
  Future<String?> loginWithGoogle({String langCode = 'en'}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return langCode == 'si'
            ? 'ගූගල් ඇතුළුවීම අවලංගු කරන ලදී.'
            : 'Google sign in was cancelled.';
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return _localizeGenericError(langCode);
      }

      await _ensureUserDocument(firebaseUser);
      return null;
    } on TimeoutException {
      return langCode == 'si'
          ? 'සම්බන්ධතාවය ප්‍රමාද වී ඇත. කරුණාකර නැවත උත්සාහ කරන්න.'
          : 'Connection timed out. Please try again.';
    } on FirebaseAuthException catch (e) {
      return _localizeAuthError(e, langCode);
    } catch (_) {
      return _localizeGenericError(langCode);
    }
  }

  /// Reset password
  Future<String?> resetPassword({
    required String email,
    String langCode = 'en',
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _localizeAuthError(e, langCode);
    } catch (e) {
      return _localizeGenericError(langCode);
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _ensureUserDocument(User firebaseUser) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      await userDocRef.set({
        'email': firebaseUser.email ?? '',
        'fullName':
            (firebaseUser.displayName != null &&
                firebaseUser.displayName!.trim().isNotEmpty)
            ? firebaseUser.displayName!.trim()
            : (userDoc.data()?['fullName'] ?? ''),
      }, SetOptions(merge: true));
      return;
    }

    final user = UserModel.newUser(
      id: firebaseUser.uid,
      fullName:
          (firebaseUser.displayName != null &&
              firebaseUser.displayName!.trim().isNotEmpty)
          ? firebaseUser.displayName!.trim()
          : 'New User',
      email: firebaseUser.email ?? '',
    );

    await userDocRef.set({
      ...user.toMap(),
      'isUserRegistrationComplete': false,
    });
  }

  String _localizeGenericError(String langCode) {
    if (langCode == 'si') {
      return 'සත්‍යාපනය අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.';
    }
    return 'Authentication failed. Please try again.';
  }

  String _localizeAuthError(FirebaseAuthException e, String langCode) {
    final isSinhala = langCode == 'si';

    switch (e.code) {
      case 'email-already-in-use':
        return isSinhala
            ? 'මෙම ඊමේල් එක දැනටමත් භාවිතා වේ.'
            : 'Email already exists.';
      case 'invalid-email':
        return isSinhala
            ? 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න.'
            : 'Enter a valid email address.';
      case 'user-not-found':
        return isSinhala
            ? 'මෙම ඊමේල් සඳහා ගිණුමක් හමු නොවීය.'
            : 'No user found for this email.';
      case 'wrong-password':
        return isSinhala ? 'මුරපදය වැරදියි.' : 'Incorrect password.';
      case 'weak-password':
        return isSinhala ? 'මුරපදය ඉතා දුර්වලයි.' : 'Password is too weak.';
      case 'user-disabled':
        return isSinhala
            ? 'මෙම ගිණුම අක්‍රිය කර ඇත.'
            : 'This account has been disabled.';
      case 'operation-not-allowed':
        return isSinhala
            ? 'මෙම ක්‍රියාව අනුමත නොවේ.'
            : 'This operation is not allowed.';
      case 'too-many-requests':
        return isSinhala
            ? 'බොහෝ උත්සාහයන්. ටික වේලාවකට පසුව නැවත උත්සාහ කරන්න.'
            : 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return isSinhala
            ? 'ජාල සම්බන්ධතාවය අසාර්ථකයි.'
            : 'Network connection failed.';
      case 'sign_in_canceled':
        return isSinhala
            ? 'ගූගල් ඇතුළුවීම අවලංගු කරන ලදී.'
            : 'Google sign in was cancelled.';
      default:
        return _localizeGenericError(langCode);
    }
  }
}

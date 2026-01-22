import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/firebase_auth_service.dart';

class AuthRepository {

  final AuthService _authService;
  AuthRepository(this._authService);
  User? get currentUser => _authService.currentUser;

  Future<User?> login(String email, String password) async {
    final credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password
    );
    return credential?.user;
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future <User?> register(String email, String password) async {

    try {
      final credential = await _authService.createUserWithEmailPassword(
        email: email,
        password: password,
      );

      // Ensure we have a valid UID before proceeding
      if (credential?.user == null) {
        throw Exception("Auth failed: No user returned");
      }

      String? uid = credential?.user!.uid;

      // Create staff in Firestore
      if (uid != null) {
        await FirebaseFirestore.instance.collection('staff').doc(uid).set({
          'email': email,
          'staffId': uid,
          'staffName': '',
          'profilePicUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential?.user;

    } catch (e) {
      print("Error registering user: $e");
      rethrow;
    }
  }
}
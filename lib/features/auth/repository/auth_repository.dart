import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider taake hum isay Controller mein use kar saken
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  // --- SIGN UP FUNCTION ---
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save Extra Data (Name, Phone, Role) to Firestore
      if (credential.user != null) {
        await _saveUserData(
          uid: credential.user!.uid,
          email: email,
          name: name,
          phone: phone,
        );
        return credential.user;
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Something went wrong!";
    } catch (e) {
      throw e.toString();
    }
    return null;
  }

  // --- LOGIN FUNCTION ---
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed!";
    } catch (e) {
      throw e.toString();
    }
  }

  // --- SAVE DATA TO FIRESTORE ---
  Future<void> _saveUserData({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'admin', // Important: Hum mark kar rahe hain k ye Admin hai
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

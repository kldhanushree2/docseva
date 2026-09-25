import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> register(
    String name,
    String email,
    String phone,
    String password, {
    String dateOfBirth = '',
    String gender = '',
    String address = '',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          dateOfBirth: dateOfBirth,
          gender: gender,
          address: address,
        );
        try {
          await _db.collection('Users').doc(user.uid).set(userModel.toMap());
        } catch (e) {
          debugPrint('Warning: Could not save user profile to Firestore: $e');
        }
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }
}

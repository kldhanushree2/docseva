import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gov_service_model.dart';
import '../models/application_model.dart';
import '../models/vault_model.dart';
import '../models/reminder_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Government Services
  Stream<List<GovServiceModel>> getGovServices() {
    return _db.collection('documents').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GovServiceModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Applications
  Stream<List<ApplicationModel>> getApplications(String userId) {
    return _db.collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ApplicationModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addApplication(ApplicationModel app) async {
    try {
      // Use applicationNumber as document ID if set, otherwise doc.id
      final docRef = app.id.isNotEmpty
          ? _db.collection('applications').doc(app.id)
          : _db.collection('applications').doc(app.applicationNumber);
      await docRef.set(app.toMap());
    } catch (e) {
      debugPrint('Firestore Error adding application: $e');
      rethrow;
    }
  }

  Future<void> deleteApplication(String id) async {
    try {
      await _db.collection('applications').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore Error deleting application: $e');
      rethrow;
    }
  }

  // Vault
  Stream<List<VaultModel>> getVaultDocuments(String userId) {
    return _db.collection('vault')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VaultModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addVaultDocument(VaultModel doc) async {
    try {
      await _db.collection('vault').add(doc.toMap());
    } catch (e) {
      debugPrint('Firestore Error adding vault document: $e');
      rethrow;
    }
  }

  Future<void> deleteVaultDocument(String id) async {
    try {
      await _db.collection('vault').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore Error deleting vault document: $e');
      rethrow;
    }
  }

  // Reminders
  Stream<List<ReminderModel>> getReminders(String userId) {
    return _db.collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReminderModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<String> addReminder(ReminderModel reminder) async {
    try {
      final docRef = await _db.collection('reminders').add(reminder.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore Error adding reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _db.collection('reminders').doc(reminder.id).update(reminder.toMap());
    } catch (e) {
      debugPrint('Firestore Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _db.collection('reminders').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore Error deleting reminder: $e');
      rethrow;
    }
  }
}

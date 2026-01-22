import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../service/firebase_auth_service.dart';
import '../model/staff.dart';
import '../../service/firebase_firestore_service.dart';

class StaffRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _auth = AuthService();
  static const String collectionName = 'staff';

  // Get Staff By ID
  Future<Staff?> getStaffById(String staffId) async {
    try{
      return await _firestoreService.getModel<Staff>(
        collection: collectionName,
        docId: staffId,
        fromMap: (map) {
          final enrichedMap = {
            'staffId': staffId,
            ...map,
          };
          return Staff.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future <void> updateStaffName(String newName) async {
    User? staff = _auth.currentUser;

    if (staff == null) throw Exception("No staff logged in");

    try {
      await staff.updateDisplayName(newName);
      await staff.reload();

      await FirebaseFirestore.instance.collection('staff').doc(staff.uid).update({
        'staffName': newName,
      });

    } catch (e) {
      throw Exception("Failed to update name: $e");
    }
  }
}
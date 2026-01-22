import '../model/staff.dart';
import '../../service/firebase_firestore_service.dart';

class StaffRepository {
  final FirestoreService _firestoreService = FirestoreService();
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
}
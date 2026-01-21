import '../model/user.dart';
import '../../service/firebase_firestore_service.dart';

class UserRepository {
  final FirestoreService _firestoreService = FirestoreService();
  static const String collectionName = 'user';


  // Get User By ID
  Future<User?> getUserById(String userId) async{
    try{
      return await _firestoreService.getModel<User>(
        collection: collectionName,
        docId: userId,
        fromMap: (map) {
          final enrichedMap = {
            'userId': userId,
            ...map,
          };
          return User.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
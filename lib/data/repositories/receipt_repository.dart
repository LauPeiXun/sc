import '../../service/firebase_firestore_service.dart';
import '../model/receipt.dart';

class ScannerRepository {
  final FirestoreService _firestoreService = FirestoreService();
  static const String collectionName = 'scannedReceipt';

  // Get ScannedReceipt By ID
  Future<ScannedReceipt?> getReceiptById(String fileId) async {
    try{
      return await _firestoreService.getModel<ScannedReceipt>(
        collection: collectionName,
        docId: fileId,
        fromMap: (map) {
          final enrichedMap = {
            'fileId': fileId,
            ...map,
          };
          return ScannedReceipt.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

}
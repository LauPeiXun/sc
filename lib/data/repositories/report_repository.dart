import '../../service/firebase_firestore_service.dart';
import '../model/report.dart';

class ReportRepository {
  final FirestoreService _firestoreService = FirestoreService();
  static const String collectionName = 'report';

  // Get Report By ID
  Future<Report?> getReportById(String reportId) async {
    try{
      return await _firestoreService.getModel<Report>(
        collection: collectionName,
        docId: reportId,
        fromMap: (map) {
          final enrichedMap = {
            'reportId': reportId,
            ...map,
          };
          return Report.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
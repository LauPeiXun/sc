import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'firebase_auth_service.dart';
import 'firebase_storage_service.dart';
import 'firebase_firestore_service.dart';
import '../data/model/receipt.dart';

class ScannerService {
  final AuthService _authService = AuthService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> scanDocument() async {
    try {
      // 1. 调用扫描器
      // getScanDocuments 返回 Map?，包含 'pdf' 和 'images' 键
      final dynamic result = await FlutterDocScanner().getScanDocuments(page: 3);
      
      if (result == null) {
        print("User cancelled scanning");
        return;
      }

      String? filePath;
      if (result is Map && result.containsKey('pdf')) {
        filePath = result['pdf'];
      } else if (result is List && result.isNotEmpty) {
        filePath = result[0];
      }

      if (filePath == null) {
        print("No document path found");
        return;
      }

      // 2. 获取当前用户
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print("Error: No user logged in");
        return;
      }

      // 3. 上传到 Firebase Storage
      final xFile = XFile(filePath);
      print("Uploading document...");
      final downloadUrl = await _storageService.uploadPdf(
        userId: currentUser.uid,
        xfile: xFile,
      );

      // 4. 保存到 Firestore
      final receiptId = _firestoreService.generateDocId('receipts');
      final receipt = Receipt(
        receiptId: receiptId,
        receiptName: 'Scan_${DateTime.now().millisecondsSinceEpoch}',
        pdfBase64: downloadUrl,
        staffId: currentUser.uid,
        description: 'Scanned via App',
        createdAt: DateTime.now(),
      );

      await _firestoreService.setModel<Receipt>(
        collection: 'receipts',
        docId: receiptId,
        model: receipt,
        toMap: (r) => r.toJson(),
      );

      print("Document successfully scanned and saved to Firebase!");

    } on PlatformException catch (e) {
      print('Platform Error: ${e.message}');
    } catch (e) {
      print('Error: $e');
    }
  }
}

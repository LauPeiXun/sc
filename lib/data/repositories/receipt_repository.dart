import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:convert';
import '../model/receipt.dart';
import '../../service/firebase_firestore_service.dart';

class ReceiptRepository {
  final FirestoreService _firestoreService = FirestoreService();
  static const String collectionName = 'receipt';

  Future<Receipt?> getReceiptById(String receiptId) async {
    try {
      return await _firestoreService.getModel<Receipt>(
        collection: collectionName,
        docId: receiptId,
        fromMap: (map) {
          final enrichedMap = {
            'receiptId': receiptId,
            ...map,
          };
          return Receipt.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

Future<Receipt> uploadReceipt(String staffId, XFile file) async {
  try {
    print("📤 Starting upload for user: $staffId, file: ${file.name}");
    
    final bytes = await file.readAsBytes();
    print("📊 File size: ${bytes.lengthInBytes} bytes");
    
    const int maxSafeSize = 750 * 1024; // 768,000 bytes
    
    if (bytes.lengthInBytes > maxSafeSize) {
      throw Exception('File is too large for database storage. Max size is 750KB.');
    }

    final pdfBase64 = base64Encode(bytes);
    print("File encoded to Base64");

    final uid = _firestoreService.generateDocId(collectionName);
    print("Generated docId: $uid");

    print("Writing to Firestore...");
    await FirebaseFirestore.instance.collection('receipt').doc(uid).set({
      'receiptId': uid,
      'receiptName': file.name,
      'pdfBase64': pdfBase64,
      'staffId': staffId,
      'description': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('report').doc(uid).set({
      'reportId': uid,
      'receiptName': file.name,
      'creteBy': staffId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("Upload successful!");

    return Receipt(
      receiptId: uid,
      receiptName: file.name,
      pdfBase64: pdfBase64,
      staffId: staffId,
      description: '',
      createdAt: DateTime.now(),
    );
  } catch (e) {
    print("Upload Failed: $e");
    rethrow;
  }
}}

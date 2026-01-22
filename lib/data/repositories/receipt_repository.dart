import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:convert';
import 'dart:io';
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
    
    var bytes = await file.readAsBytes();
    print("📊 Original file size: ${bytes.lengthInBytes} bytes (${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB)");
    
    // 如果文件太大，需要压缩
    const int maxSafeSize = 750 * 1024; // 750KB limit
    
    if (bytes.lengthInBytes > maxSafeSize) {
      print("⚠️ File is too large! Attempting to compress...");
      
      // 尝试压缩（如果是PDF可能无法压缩，但值得一试）
      if (file.name.toLowerCase().endsWith('.pdf')) {
        throw Exception('PDF file is too large (${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB). Maximum allowed: 750KB.\n\nTip: Try using fewer pages or lower resolution when scanning.');
      }
      
      throw Exception('File is too large (${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB). Maximum allowed: 750KB.');
    }

    final pdfBase64 = base64Encode(bytes);
    print("✅ File encoded to Base64");

    final uid = _firestoreService.generateDocId(collectionName);
    print("🆔 Generated docId: $uid");

    print("🚀 Writing to Firestore...");
    await FirebaseFirestore.instance.collection('receipt').doc(uid).set({
      'receiptId': uid,
      'receiptName': file.name,
      'pdfBase64': pdfBase64,
      'staffId': staffId,
      'staffName': 'Unknown',
      'description': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('report').doc(uid).set({
      'reportId': uid,
      'receiptName': file.name,
      'creteBy': staffId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("✨ Upload successful!");

    return Receipt(
      receiptId: uid,
      receiptName: file.name,
      pdfBase64: pdfBase64,
      staffId: staffId,
      staffName: 'Unknown',
      description: '',
      createdAt: DateTime.now(),
    );
  } catch (e) {
    print("Upload Failed: $e");
    rethrow;
  }
}}

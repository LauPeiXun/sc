import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sc/service/gemini_ai_service.dart';
import 'dart:convert';
import '../model/receipt.dart';
import '../../service/firebase_firestore_service.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class ReceiptRepository {

  final FirestoreService _firestoreService = FirestoreService();
  final GeminiAiService _geminiAiService = GeminiAiService();
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

  Future<Map<String, dynamic>?> recognizeReceipt(Uint8List imageBytes) async {
    try {
      final String? jsonString = await _geminiAiService.processImage(imageBytes);
      if (jsonString == null) return null;

      final dynamic decoded = jsonDecode(jsonString);

      Map<String, dynamic> responseMap;
      if (decoded is List) {
        if (decoded.isNotEmpty) {
          responseMap = decoded.first as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        responseMap = decoded as Map<String, dynamic>;
      }
      final Map<String, dynamic> data = responseMap['data'] ?? {};
      final String status = data['status'] ?? 'unclear';

      if (status == 'clear' || status == 'multiple_detected' || status == 'invalid' || status == 'unclear') {
        return data;
      }

      return null;
    } catch (e) {
      print("❌ OCR Error: $e");
      return null;
    }
  }


  Future<Receipt> uploadReceipt({
    required String staffId,
    required String staffName,
    required XFile file,
    required Map<String, dynamic> ocrData,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        quality: 50,
        format: CompressFormat.jpeg,
      );
      final String base64Image = base64Encode(compressedBytes);
      final uid = _firestoreService.generateDocId(collectionName);
      String fileName = p.basenameWithoutExtension(file.name);

      final Map<String, dynamic> receiptData = {
        'receiptId': uid,
        'receiptName': fileName,
        'receiptImg': base64Image,
        'staffId': staffId,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
        'bank': ocrData['bankName'] ?? '',
        'bankAcc': ocrData['bankAcc'] ?? '',
        'totalAmount': _parseDouble(ocrData['totalAmount']),
        'printedDate': ocrData['printedDate'] ?? '',
        'handwrittenDate': ocrData['handwrittenDate'] ?? '',
        'location': ocrData['location'] ?? '',
        'status': ocrData['status'] ?? 'unknown',
      };

      await FirebaseFirestore.instance.collection(collectionName).doc(uid).set(receiptData);

      return Receipt.fromJson({
        ...receiptData,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("❌ uploadReceipt Error: $e");
      rethrow;
    }
  }
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      // Delete from both collections
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(FirebaseFirestore.instance.collection('receipt').doc(receiptId));
      await batch.commit();
      print("✅ Successfully deleted receipt: $receiptId");
    } catch (e) {
      print("❌ Error deleting receipt: $e");
      rethrow;
    }
  }
}
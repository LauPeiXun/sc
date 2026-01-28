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

  Future<Map<String, dynamic>> recognizeReceipt(List<Uint8List> imageBytes) async {
    try {
      final String? jsonString = await _geminiAiService.processImages(imageBytes);
      if (jsonString == null) throw Exception("AI no response");

      final Map<String, dynamic> responseMap = jsonDecode(jsonString);
      final Map<String, dynamic> data = responseMap['data'] ?? {};

      if (responseMap['status'] == 'unclear') {
        throw Exception("Blurred image: ${responseMap['reason']}");
      }
      if (responseMap['status'] == 'multiple_detected') {
        throw Exception("Detected multiple receipts: ${responseMap['reason']}");
      }
      return data;
    } catch (e) {
      print("❌ OCR Error: $e");
      rethrow;
    }
  }

  Future<Receipt> uploadReceipt({
    required String staffId,
    required String staffName,
    required List<XFile> files,
    required Map<String, dynamic> ocrData,
  }) async {
    try {
      List<String> base64List = [];
      int totalSize = 0;

      for (var file in files) {
        final bytes = await file.readAsBytes();

        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          quality: 50,
          format: CompressFormat.jpeg,
        );

        totalSize += compressedBytes.length;
        base64List.add(base64Encode(compressedBytes));
      }

      if (totalSize > 950000) {
        throw Exception("图片太大，Firestore 塞不下了！请减少页数或降低质量。");
      }

      final uid = _firestoreService.generateDocId(collectionName);

      // 3. 构造存入 Firestore 的 Map (字段必须和你的 toJson/fromJson 一一对应)
      final Map<String, dynamic> receiptData = {
        'receiptId': uid,
        'receiptName': files.isNotEmpty ? fileName : "Unknown_Scan",
        'receiptImg': base64List,
        'staffId': staffId,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
        'bank': ocrData['bankName'] ?? '',
        'bankAcc': ocrData['bankAcc'] ?? '',
        'totalAmount': (ocrData['totalAmount'] ?? 0.0).toDouble(),
        'transferDate': ocrData['transferDate'] ?? '',
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
  Future<void> deleteReceipt(String receiptId) async {
    try {
      // Delete from both collections
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(FirebaseFirestore.instance.collection('receipt').doc(receiptId));
      batch.delete(FirebaseFirestore.instance.collection('report').doc(receiptId));
      await batch.commit();
      print("✅ Successfully deleted receipt: $receiptId");
    } catch (e) {
      print("❌ Error deleting receipt: $e");
      rethrow;
    }
  }

}
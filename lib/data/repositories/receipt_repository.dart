import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import '../model/receipt.dart';
import '../../service/firebase_firestore_service.dart';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

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

  Future<Receipt> uploadReceipt(String staffId, String staffName, List<XFile> files) async {
    try {
      print("📤 Processing ${files.length} images for user: $staffName");

      List<String> base64List = [];
      int totalSize = 0;

      // 1. 循环处理每一张图
      for (var file in files) {
        final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: 800,  // 缩小一点，为了能放多张
          minHeight: 800,
          quality: 50,    // 质量调低一点
          format: CompressFormat.jpeg,
        );

        if (compressedBytes == null) continue;

        // 累加大小，防止爆库
        totalSize += compressedBytes.lengthInBytes;

        // 编码并加入列表
        base64List.add(base64Encode(compressedBytes));
      }

      // 2. 检查总大小 (Firestore 限制 1MB = 1,048,576 bytes)
      print("📊 Total Size: ${(totalSize / 1024).toStringAsFixed(2)} KB");
      if (totalSize > 950000) { // 950KB 安全线
        throw Exception("Total size too big for Firestore! Try fewer pages.");
      }

      if (base64List.isEmpty) throw Exception("No images processed successfully");

      final uid = _firestoreService.generateDocId(collectionName);
      final fileName = "Scan_${DateTime.now().millisecondsSinceEpoch} (${base64List.length} pgs).jpg";

      await FirebaseFirestore.instance.collection('receipt').doc(uid).set({
        'receiptId': uid,
        'receiptName': fileName,
        'receiptImg': base64List, // ✅ 存入整个数组
        'staffId': staffId,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Report Collection (轻量级)
      await FirebaseFirestore.instance.collection('report').doc(uid).set({
        'reportId': uid,
        'receiptName': fileName,
        'pageCount': base64List.length, // 记录一下有多少页
        'staffId': staffId,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending'
      });

      return Receipt(
        receiptId: uid,
        receiptName: fileName,
        receiptImg: base64List, // ✅
        staffId: staffId,
        staffName: staffName,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }}

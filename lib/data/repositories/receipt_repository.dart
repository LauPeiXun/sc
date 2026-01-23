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

  Future<Receipt> uploadReceipt(String staffId, String staffName, List<XFile> files, {String extractedText = ''}) async {
    try {
      print("📤 Processing ${files.length} images for user: $staffName");

      List<String> base64List = [];
      int totalSize = 0;

      // 1. 循环处理每一张图
      for (var file in files) {
        try {
          print("🖼️ Reading image: ${file.name}");
          
          // 直接读取文件的二进制数据
          final bytes = await file.readAsBytes();
          
          if (bytes.isEmpty) {
            print("⚠️ File is empty: ${file.name}, skipping");
            continue;
          }

          print("✅ Read file ${file.name}: ${(bytes.length / 1024).toStringAsFixed(2)} KB");

          // 尝试压缩
          Uint8List? compressedBytes;
          try {
            compressedBytes = await FlutterImageCompress.compressWithList(
              bytes,
              minWidth: 800,
              minHeight: 800,
              quality: 50,
              format: CompressFormat.jpeg,
            );
          } catch (e) {
            print("⚠️ Compression failed for ${file.name}, using original: $e");
            compressedBytes = bytes;
          }

          if (compressedBytes == null || compressedBytes.isEmpty) {
            print("⚠️ Compression returned empty for ${file.name}, using original");
            compressedBytes = bytes;
          }

          print("✅ Compressed ${file.name}: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB");

          // 累加大小
          totalSize += compressedBytes.length;

          // 编码并加入列表
          final encoded = base64Encode(compressedBytes);
          if (encoded.isEmpty) {
            print("⚠️ Base64 encoding failed for ${file.name}, skipping");
            continue;
          }
          
          print("✅ Base64 encoded ${file.name}");
          base64List.add(encoded);
        } catch (e) {
          print("❌ Error processing ${file.name}: $e");
          continue;
        }
      }

      // 2. 检查总大小
      if (base64List.isNotEmpty) {
        print("📊 Total Size: ${(totalSize / 1024).toStringAsFixed(2)} KB");
        if (totalSize > 950000) { // 950KB 安全线
          throw Exception("Total size too big for Firestore! Try fewer pages.");
        }
      }

      // 允许只保存文本而不需要图片
      if (base64List.isEmpty && extractedText.isEmpty) {
        throw Exception("No images or text to save");
      }

      final uid = _firestoreService.generateDocId(collectionName);
      final pageCount = base64List.length;
      final fileName = pageCount > 0
          ? "Scan_${DateTime.now().millisecondsSinceEpoch} (${pageCount} pgs).jpg"
          : "OCR_${DateTime.now().millisecondsSinceEpoch}.txt";

      print("💾 Saving to Firestore - ID: $uid, Images: ${base64List.length}, Text length: ${extractedText.length}");

      await FirebaseFirestore.instance.collection('receipt').doc(uid).set({
        'receiptId': uid,
        'receiptName': fileName,
        'receiptImg': base64List.isEmpty ? [] : base64List,
        'staffId': staffId,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
        'extractedText': extractedText,
      });

      print("✅ Successfully saved receipt: $uid");

      // Report Collection (轻量级) - 添加错误处理
      try {
        await FirebaseFirestore.instance.collection('report').doc(uid).set({
          'reportId': uid,
          'receiptName': fileName,
          'pageCount': pageCount,
          'staffId': staffId,
          'staffName': staffName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Pending'
        });
        print("✅ Successfully saved report: $uid");
      } catch (e) {
        print("⚠️ Failed to save report (non-critical): $e");
        // 不中断主流程，receipt已保存成功
      }

      return Receipt(
        receiptId: uid,
        receiptName: fileName,
        receiptImg: base64List,
        staffId: staffId,
        staffName: staffName,
        createdAt: DateTime.now(),
        extractedText: extractedText
      );
    } catch (e) {
      print("❌ Error in uploadReceipt: $e");
      rethrow;
    }
  }}

import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'dart:io';

class DocumentScannerService {
  /// Scans document and returns list of image paths
  Future<List<String>> scanDocument() async {
    dynamic result;

    try {
      result = await FlutterDocScanner().getScannedDocumentAsImages(page: 4);
    } on PlatformException catch (e) {
      throw Exception('Scanner Error: $e');
    }

    if (result == null) {
      throw Exception('User cancelled scanning');
    }

    // Parse image paths
    List<String> imagePaths = [];

    if (result is List && result.isNotEmpty) {
      for (var item in result) {
        imagePaths.add(item.toString());
      }
    } else if (result is Map) {
      if (result.containsKey('images') && result['images'] is List) {
        for (var item in result['images']) {
          imagePaths.add(item.toString());
        }
      } else if (result.containsKey('imageUri')) {
        imagePaths.add(result['imageUri'].toString());
      }
    }

    if (imagePaths.isEmpty) {
      throw Exception('No images captured');
    }

    // Clean paths and validate
    List<String> validPaths = [];
    for (var path in imagePaths) {
      String cleanPath = path;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.replaceFirst('file://', '');
      }
      
      // Validate file exists
      final file = File(cleanPath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print("✅ Image found: $cleanPath (${(fileSize / 1024).toStringAsFixed(2)} KB)");
        validPaths.add(cleanPath);
      } else {
        print("❌ Image not found: $cleanPath");
      }
    }

    if (validPaths.isEmpty) {
      throw Exception('No valid images found');
    }

    return validPaths;
  }
}

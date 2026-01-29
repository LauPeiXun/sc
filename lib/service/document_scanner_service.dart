import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'dart:io';

class DocumentScannerService {
  Future<String> scanDocument() async {
    dynamic result;

    try {
      result = await FlutterDocScanner().getScannedDocumentAsImages(page: 1);
    } on PlatformException catch (e) {
      throw Exception('Scanner Error: $e');
    }

    if (result == null) {
      throw Exception('No image captured');
    }

    String imagePath = '';

    if (result is List && result.isNotEmpty) {
      imagePath = result.first.toString();
    } else if (result is Map) {
      if (result.containsKey('images') && result['images'] is List && (result['images'] as List).isNotEmpty) {
        imagePath = (result['images'] as List).first.toString();
      } else if (result.containsKey('imageUri')) {
        imagePath = result['imageUri'].toString();
      }
    } else if (result is String) {
      imagePath = result;
    }

    if (imagePath.isEmpty) {
      throw Exception('No valid image path');
    }

    String cleanPath = imagePath;
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }
    
    final file = File(cleanPath);
    if (await file.exists()) {
      final fileSize = await file.length();
      print("Image found: $cleanPath (${(fileSize / 1024).toStringAsFixed(2)} KB)");
      return cleanPath;
    } else {
      throw Exception('Image not found: $cleanPath');
    }
  }
}
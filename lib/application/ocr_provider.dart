import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:sc/service/ocr_service.dart';

class OCRProvider extends ChangeNotifier {
  final OCRService _ocrService = OCRService();
  
  String _extractedText = '';
  bool _isProcessing = false;
  String _errorMessage = '';
  List<XFile> _scannedImages = []; // 保存扫描的图片

  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;
  bool get isSaving => false;
  String get errorMessage => _errorMessage;
  List<XFile> get scannedImages => _scannedImages;

  Future<void> extractTextFromImage(String imagePath) async {
    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _extractedText = await _ocrService.recognizeTextFromImage(imagePath);
      // 添加图片到列表
      _scannedImages.add(XFile(imagePath));
    } catch (e) {
      _errorMessage = e.toString();
      _extractedText = '';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> appendTextFromImage(String imagePath) async {
    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newText = await _ocrService.recognizeTextFromImage(imagePath);
      _extractedText = _extractedText.isEmpty
          ? newText 
          : '$_extractedText\n\n---\n\n$newText';
      // 添加图片到列表
      _scannedImages.add(XFile(imagePath));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearText() {
    _extractedText = '';
    _errorMessage = '';
    _scannedImages.clear(); // 清除图片列表
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
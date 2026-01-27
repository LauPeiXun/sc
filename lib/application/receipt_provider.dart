import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../data/repositories/receipt_repository.dart';
import '../data/model/receipt.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptRepository _receiptRepository = ReceiptRepository();

  Receipt? _currentReceipt;
  bool _isLoading = false;
  String? _error;

  Receipt? get currentReceipt => _currentReceipt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setError(String? error) => _setError(error);

  Future<void> getReceiptById(String receiptId) async {
    _setLoading(true);
    _setError(null);
    try {
      final receipt = await _receiptRepository.getReceiptById(receiptId);
      _currentReceipt = receipt;
    } catch (e) {
      _setError('Failed to get receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> processScanAndUpload({
    required String staffId,
    required String staffName,
    required List<XFile> files,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      List<Uint8List> imageBytes = <Uint8List>[];
      for (var f in files) {
        imageBytes.add(await f.readAsBytes());
      }

      final ocrData = await _receiptRepository.recognizeReceipt(imageBytes);

      final uploadedReceipt = await _receiptRepository.uploadReceipt(
        staffId: staffId,
        staffName: staffName,
        files: files,
        ocrData: ocrData,
      );

      _currentReceipt = uploadedReceipt;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  Future<void> deleteReceipt(String receiptId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _receiptRepository.deleteReceipt(receiptId);
    } catch (e) {
      _setError('Failed to delete receipt: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
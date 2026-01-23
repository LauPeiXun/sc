import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> scanAndUploadImage(String staffId, String staffName, List<XFile> file, {String extractedText = ''}) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String safeName = user?.displayName ?? "Unknown Staff";

      final uploadedReceipt = await _receiptRepository.uploadReceipt(
          staffId,
          safeName,
          file,
          extractedText: extractedText,
      );
    } catch (e) {
      _setError('Failed to upload receipt: $e');
    } finally {
      _setLoading(false);
    }
  }
}
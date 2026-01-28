import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  Future<Receipt> processScanOnly({
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

      // Create base64 images for display
      List<String> base64List = [];
      for (var file in files) {
        final bytes = await file.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          quality: 50,
          format: CompressFormat.jpeg,
        );
        base64List.add(base64Encode(compressedBytes));
      }

      final receipt = Receipt(
        receiptId: '',
        receiptName: ocrData['receiptName'] ?? '',
        receiptImg: base64List,
        staffId: staffId,
        staffName: staffName,
        createdAt: DateTime.now(),
        bank: ocrData['bank'] ?? '',
        bankAcc: ocrData['bankAcc'] ?? '',
        totalAmount: (ocrData['totalAmount'] is num) ? (ocrData['totalAmount'] as num).toDouble() : 0.0,
        transferDate: ocrData['transferDate'] ?? '',
        status: ocrData['status'] ?? 'Unclear',
      );

      _currentReceipt = receipt;
      notifyListeners();
      return receipt;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadCurrentReceipt({
    required List<XFile> files,
  }) async {
    if (_currentReceipt == null) {
      throw Exception('No receipt to upload.');
    }

    _setLoading(true);
    _setError(null);
    try {
      final uploaded = await _receiptRepository.uploadReceipt(
        staffId: _currentReceipt!.staffId,
        staffName: _currentReceipt!.staffName,
        files: files,
        ocrData: {
          'bankName': _currentReceipt!.bank,
          'bankAcc': _currentReceipt!.bankAcc,
          'totalAmount': _currentReceipt!.totalAmount,
          'transferDate': _currentReceipt!.transferDate.toString(),
          'status': _currentReceipt!.status,
        },
      );
      _currentReceipt = uploaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
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
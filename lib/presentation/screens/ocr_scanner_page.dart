import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sc/application/ocr_provider.dart';
import 'package:sc/application/receipt_provider.dart';
import 'package:sc/service/document_scanner_service.dart';

class OCRScannerPage extends StatelessWidget {
  const OCRScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: Consumer<OCRProvider>(
        builder: (context, ocrProvider, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _handleScanDocument(context),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Scan Document'),
                  ),
                ),
                if (ocrProvider.isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Extracting text...'),
                      ],
                    ),
                  ),
                if (ocrProvider.errorMessage.isNotEmpty &&
                    !ocrProvider.isProcessing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ocrProvider.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                if (ocrProvider.extractedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extracted Text:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(ocrProvider.extractedText),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _uploadToReceipt(context, ocrProvider),
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Save to Receipt'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => ocrProvider.clearText(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleScanDocument(BuildContext context) async {
    final scannerService = DocumentScannerService();

    try {
      // 1. Scan document
      final imagePaths = await scannerService.scanDocument();

      if (!context.mounted) return;

      // 2. Process each image with OCR - append text instead of replacing
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        if (context.mounted) {
          if (i == 0) {
            // First image - extract normally
            await context.read<OCRProvider>().extractTextFromImage(imagePath);
          } else {
            // Subsequent images - append text
            await context.read<OCRProvider>().appendTextFromImage(imagePath);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadToReceipt(
    BuildContext context,
    OCRProvider ocrProvider,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      return;
    }

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Upload receipt with extracted text AND scanned images
      await context.read<ReceiptProvider>().scanAndUploadImage(
        user.uid,
        user.displayName ?? 'Unknown Staff',
        ocrProvider.scannedImages, // 传入扫描的图片
        extractedText: ocrProvider.extractedText,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to receipt successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ocrProvider.clearText();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
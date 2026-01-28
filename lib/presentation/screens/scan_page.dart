import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sc/presentation/screens/receipt_detail_page.dart';
import 'package:sc/service/document_scanner_service.dart';
import 'package:sc/application/receipt_provider.dart';
import 'package:cross_file/cross_file.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String? _error;
  List<String>? _images;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _error = null;
      _images = null;
      _scanned = false;
    });
    try {
      final images = await DocumentScannerService().scanDocument();
      if (images.isNotEmpty) {
        // Process the scanned images and navigate to detail page
        await _processAndNavigateToDetail(images);
      } else {
        setState(() {
          _scanned = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanned = true;
      });
    }
  }

  Future<void> _processAndNavigateToDetail(List<String> images) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
      }
      return;
    }

    try {
      // Convert File paths to XFile
      final xFiles = images.map((path) => XFile(path)).toList();

      // Process scan (OCR only, don't upload yet)
      final processedReceipt = await context.read<ReceiptProvider>().processScanOnly(
        staffId: user.uid,
        staffName: user.displayName ?? 'Unknown',
        files: xFiles,
      );

      if (context.mounted) {
        // Navigate to detail page in confirmation mode
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptDetailPage(
              receipt: processedReceipt,
              isConfirmationMode: true,
              scannedFiles: xFiles,
            ),
          ),
        );

        // Handle result
        if (result == 'rescan') {
          _startScan(); // Rescan
        } else if (result == 'success') {
          Navigator.pop(context); // Return to previous screen
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _error = e.toString();
          _scanned = true;
        });
      }
    }
  }

  void _rescan() {
    _startScan();
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_scanned) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning document...'),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Scan failed: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startScan,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_images == null || _images!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.document_scanner, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No document scanned.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startScan,
                child: const Text('Scan Again'),
              ),
            ],
          ),
        ),
      );
    }

    // This should not be reached since we navigate immediately after processing
    return const Scaffold(
      body: Center(
        child: Text('Processing...'),
      ),
    );
  }
}

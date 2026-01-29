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
  String? _imagePath;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _error = null;
      _imagePath = null;
      _scanned = false;
    });
    try {
      final imagePath = await DocumentScannerService().scanDocument();
      await _processAndNavigateToDetail(imagePath);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanned = true;
      });
    }
  }

  Future<void> _processAndNavigateToDetail(String imagePath) async {
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
      final xFile = XFile(imagePath);

      // Process scan (OCR only, no upload yet)
      final processedReceipt = await context.read<ReceiptProvider>().processScanOnly(
        staffId: user.uid,
        staffName: user.displayName ?? 'Unknown',
        file: xFile,
      );

      if (context.mounted) {
        // Navigate to detail page in confirmation mode
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptDetailPage(
              receipt: processedReceipt,
              isConfirmationMode: true,
              scannedFile: xFile,
            ),
          ),
        );

        if (result == 'rescan') {
          _startScan();
        } else if (result == 'success') {
          if (mounted) Navigator.pop(context);
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

    //fix the black splash screen: old is just direct pop
    if (_error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
    if (_imagePath == null || _imagePath!.isEmpty) {
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      setState(() {
        _images = images;
        _scanned = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanned = true;
      });
    }
  }

  Future<void> _saveReceipt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
      }
      return;
    }

    if (_images == null || _images!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please scan a document first')),
        );
      }
      return;
    }

    try {
      // Convert File paths to XFile
      final xFiles = _images!.map((path) => XFile(path)).toList();

      // Call Provider to upload
      await context.read<ReceiptProvider>().processScanAndUpload(
        staffId: user.uid,
        staffName: user.displayName ?? 'Unknown',
        files: xFiles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Return to home screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Scan failed: $_error')),
      );
    }
    if (_images == null || _images!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No document scanned.')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _images!.length,
              itemBuilder: (context, idx) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    File(_images![idx]),
                    fit: BoxFit.contain,
                    height: 300,
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Consumer<ReceiptProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _saveReceipt,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rescan and Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _rescan,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text(
                              'Rescan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _cancel,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewer extends StatefulWidget {
  final String pdfBase64;
  final String fileName;

  final String staffId;
  final String staffName;

  const PdfViewer({
    required this.pdfBase64,
    required this.fileName,
    required this.staffId,
    required this.staffName,
    super.key,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  // Use '?' to make it nullable so we don't need 'late'
  PdfControllerPinch? _pdfControllerPinch;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      final bytes = base64Decode(widget.pdfBase64);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.fileName}');
      await file.writeAsBytes(bytes);

      final documentFuture = PdfDocument.openFile(file.path);
      final controller = PdfControllerPinch(document: documentFuture);
      final doc = await documentFuture;

      if (mounted) {
        setState(() {
          _pdfControllerPinch = controller;
          _totalPages = doc.pagesCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pdfControllerPinch?.dispose();
    super.dispose();
  }

  void _showDetailsSheet(){
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Receipt Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, "Staff Name", widget.staffName),
              const Divider(),
              _buildDetailRow(Icons.badge, "Staff ID", widget.staffId),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Close"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDetailsSheet,
          ),
        ],
      ),
      body: _isLoading || _pdfControllerPinch == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: _pdfControllerPinch!,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page $_currentPage of $_totalPages'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentPage > 1
                          ? () {
                        // FIX 2: Add Duration and Curve
                        _pdfControllerPinch!.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentPage < _totalPages
                          ? () {
                        // FIX 2: Add Duration and Curve
                        _pdfControllerPinch!.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

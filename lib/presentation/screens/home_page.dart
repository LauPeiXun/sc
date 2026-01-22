import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cross_file/cross_file.dart';

import 'package:sc/presentation/screens/profile_page.dart';
import 'package:sc/presentation/screens/report_page.dart';
import '../components/nav_bar.dart';
import '../../application/receipt_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ReportPage(),
    Container(),
    const ProfilePage(),
  ];

  Future<void> scanDocumentAsPdf() async {
    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScannedDocumentAsPdf(page: 4);
    } on PlatformException {
      print('Failed to get scanned documents.');
      return;
    }
    if (scannedDocuments == null) return;
    if (!mounted) return;

    if (scannedDocuments is Map && scannedDocuments['pdfUri'] != null) {
      final String originalPath = scannedDocuments['pdfUri'].toString().replaceFirst('file://', '');
      final XFile fileToUpload = XFile(originalPath);

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in!")));
        return;
      }

      try {
        if(mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
        }
        await context.read<ReceiptProvider>().scanAndUploadPdf(user.uid, fileToUpload);
        if (mounted) Navigator.pop(context);
        // Success Dialog...
      } catch (e) {
        if (mounted) Navigator.pop(context);
        // Error Snackbar...
      }
    }
  }

  // index 0,1,2
  void _handleNavTap(int index) {
    if (index == 1) {
      scanDocumentAsPdf();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: NavBar(
          currentIndex: _currentIndex,
          onTap: _handleNavTap,
        ),
      ),
    );
  }
}
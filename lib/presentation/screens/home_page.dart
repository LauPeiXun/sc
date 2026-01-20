import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:sc/presentation/screens/profile_page.dart';
import 'package:sc/presentation/screens/report_page.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  dynamic _scannedDocuments; // 用来存扫描后的 PDF 路径

  // 1. 页面列表：中间放个 Container 占位，因为永远不会切过去
  final List<Widget> _pages = [
    const ReportPage(),       // Index 0: Homepage
    Container(),              // Index 1: 占位 (不会显示)
    const ProfilePage(),      // Index 2: Profile
  ];

  // 2. 这是你指定的 PDF 扫描功能
  Future<void> scanDocumentAsPdf() async {
    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScannedDocumentAsPdf(page: 4) ??
          'Unknown platform documents';
    } on PlatformException {
      scannedDocuments = 'Failed to get scanned documents.';
    }

    print('Original PDF path: $scannedDocuments');

    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
    });

    // 2️⃣ 保存到 Downloads 目录
    String? savedPath;
    if (scannedDocuments is Map && scannedDocuments['pdfUri'] != null) {
      final String originalPath = scannedDocuments['pdfUri'].toString().replaceFirst('file://', '');
      final bytes = await File(originalPath).readAsBytes();

      // Downloads 目录
      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final String fileName = 'scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File savedFile = File('${downloadsDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes);
      savedPath = savedFile.path;

      print('Saved PDF path: $savedPath');
    }

    // 3️⃣ 弹窗告诉用户
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan Completed"),
        content: Text(savedPath != null
            ? "PDF saved at:\n$savedPath"
            : "Scan failed or path not found."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          ),
          if (savedPath != null)
            TextButton(
              onPressed: () {
                Share.shareXFiles([XFile(savedPath!)], text: 'Here is your scanned PDF');
              },
              child: const Text("Share", style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  // 3. 核心逻辑：拦截点击事件
  void _onTabTapped(int index) {
    if (index == 1) {
      // === 如果点击了中间 (Index 1) ===
      // 直接运行扫描功能，不要切换页面
      scanDocumentAsPdf();
    } else {
      // === 如果点击了旁边 (Index 0 或 2) ===
      // 正常切换页面
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 显示当前页面
      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onTabTapped, // 使用上面的拦截逻辑
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              // 这里看起来是个按钮，但实际是个 Function Trigger
              icon: Icon(Icons.camera_alt_outlined, size: 36),
              activeIcon: Icon(Icons.camera_alt, size: 36),
              label: 'Scan PDF',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
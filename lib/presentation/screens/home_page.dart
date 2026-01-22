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

  Future<void> scanDocumentAndUpload() async {
    dynamic result;

    try {
      // 1. 启动 Scanner
      result = await FlutterDocScanner().getScannedDocumentAsImages(page: 4);
    } on PlatformException catch (e) {
      print("Scanner Error: $e");
      return;
    }

    if (result == null) {
      print("User cancelled scanning");
      return;
    }

    if (!mounted) return;

    // 2. 解析原始路径 (先拿到所有的路径字符串)
    List<String> rawPaths = [];

    // 情况 A: List
    if (result is List && result.isNotEmpty) {
      for (var item in result) {
        rawPaths.add(item.toString());
      }
    }
    // 情况 B: Map
    else if (result is Map) {
      if (result.containsKey('images') && result['images'] is List) {
        for (var item in result['images']) {
          rawPaths.add(item.toString());
        }
      } else if (result.containsKey('imageUri')) {
        rawPaths.add(result['imageUri']);
      }
    }
    // 情况 C: String
    else if (result is String) {
      rawPaths.add(result);
    }

    if (rawPaths.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No images found")));
      return;
    }

    // 3. ✅ 核心修改：把路径清洗并转成 List<XFile>
    List<XFile> filesToUpload = [];

    for (String path in rawPaths) {
      String cleanPath = path;
      // 去除 file:// 前缀
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.replaceFirst('file://', '');
      }
      filesToUpload.add(XFile(cleanPath));
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    // 4. 开始上传 (只调用一次 Provider)
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      // ✅ 这里调用的是支持 List 的新 Provider 方法
      // Provider 内部会去获取 staffName，所以只需传 uid 和 文件列表
      await context.read<ReceiptProvider>().scanAndUploadImage(
        user.uid,
        '',
        filesToUpload, // 传入整个列表
      );

      if (mounted) {
        Navigator.pop(context); // 关掉 Loading
        // 成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! Uploaded ${filesToUpload.length} pages.")),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关掉 Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }
  // index 0,1,2
  void _handleNavTap(int index) {
    if (index == 1) {
      scanDocumentAndUpload();
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
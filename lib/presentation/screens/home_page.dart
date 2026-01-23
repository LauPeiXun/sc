import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sc/presentation/screens/profile_page.dart';
import 'package:sc/presentation/screens/report_page.dart';
import '../components/nav_bar.dart';

import 'package:sc/presentation/screens/ocr_scanner_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ReportPage(),
    const OCRScannerPage(),
    const ProfilePage(),
  ];

  // index 0 = Report, 1 = OCR Scanner, 2 = Profile
  void _handleNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
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
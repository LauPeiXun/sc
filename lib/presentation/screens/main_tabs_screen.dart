import 'package:flutter/material.dart';
import 'package:sc/presentation/screens/profile_page.dart';
import 'package:sc/presentation/screens/report_page.dart';
import 'package:sc/presentation/screens/home_page.dart';

import '../components/nav_bar.dart';
import 'scan_page.dart';

class MainTabsScreen extends StatefulWidget {
  final int initialIndex;
  const MainTabsScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _handleNavTap(int index) {
    if (index == 1 && _currentIndex == 1) {
      if (mounted) {
        setState(() {
          _currentIndex = -1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentIndex = 1;
            });
          }
        });
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const ReportPage(showBackButton: true);
      case 1:
        return const ScanPage();
      case 2:
        return const ProfilePage(showBackButton: true);
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavTap,
      ),
    );
  }
}

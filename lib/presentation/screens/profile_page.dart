import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/auth_provider.dart';
import '../../application/staff_provider.dart';
import '../screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StaffProvider>().getStaffById(uid);
      });
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final currentName = context.read<StaffProvider>().currentStaff?.staffName ?? "";
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Display Name",
            hintText: "Enter your name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {

                Navigator.pop(context);

                context.read<StaffProvider>().updateStaffName(newName);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Name updated!"),
                      duration: Duration(milliseconds: 500)
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = context.watch<StaffProvider>();
    final staff = staffProvider.currentStaff;
    final user = FirebaseAuth.instance.currentUser; // Email 还是可以从 Auth 拿

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: staffProvider.isLoading && staff == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: const Icon(Icons.person, size: 60),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (staff?.staffName == null || staff!.staffName.isEmpty)
                      ? "Unknown"
                      : staff.staffName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  onPressed: () => _showEditNameDialog(context),
                  tooltip: "Edit Name",
                ),
              ],
            ),

            Text(
              user?.email ?? "No Email",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("Logout"),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
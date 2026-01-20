import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PROFILE")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Placeholder
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
            const Text(
              "User Name",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("user@example.com"),
            const SizedBox(height: 40),

            const Divider(color: Colors.black, thickness: 2),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text("Settings"),
              onTap: () {},
            ),
            const Divider(color: Colors.black),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.black),
              title: const Text("Help & Support"),
              onTap: () {},
            ),
            const Divider(color: Colors.black),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Logout Logic -> Back to Login
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout),
                label: const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("LOGOUT"),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
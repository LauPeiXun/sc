import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("12", "Scanned"),
                      _buildStatItem("5", "Pending"),
                      _buildStatItem("98%", "Accuracy"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "HISTORY / REPORTS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // History List (Report items)
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(color: Colors.black),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.black,
                      child: const Icon(Icons.description, color: Colors.white),
                    ),
                    title: Text("Document_Scan_00${index + 1}.pdf"),
                    subtitle: Text("2026-01-20 • 14:3${index} PM"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
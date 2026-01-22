import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/pdf_viewer.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late String staffId;

  @override
  void initState() {
    super.initState();
    staffId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

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
            // 从 Firestore 动态加载 Receipt
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('receipt')
                    .where('staffId', isEqualTo: staffId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No receipts found'),
                    );
                  }

                  final receipts = snapshot.data!.docs;
                  
                  // 在客户端排序
                  receipts.sort((a, b) {
                    final dateA = (a['createdAt'] as Timestamp).toDate();
                    final dateB = (b['createdAt'] as Timestamp).toDate();
                    return dateB.compareTo(dateA);
                  });

                  return ListView.separated(
                    itemCount: receipts.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.black),
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      final receiptName = receipt['receiptName'] ?? 'Unknown.pdf';
                      final createdAt = (receipt['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final formattedDate = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} • ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          color: Colors.black,
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(receiptName),
                        subtitle: Text(formattedDate),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                        onTap: () {
                          // 点击打开 PDF 查看器
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfViewer(
                                pdfBase64: receipt['pdfBase64'] ?? '',
                                fileName: receiptName,
                                staffName: receipt['staffName'] ?? 'Unknown',
                                staffId: receipt['staffId'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    },
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
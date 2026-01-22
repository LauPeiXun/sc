import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/image_viewer.dart';

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
            // 实时监听流来获取总数
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('receipt')
                  .where('staffId', isEqualTo: staffId)
                  .snapshots(),
              builder: (context, snapshot) {
                // 计算当前数量 (如果没有数据就是 0)
                String totalScanned = snapshot.hasData ? snapshot.data!.docs.length.toString() : "-";

                return Container(
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
                          // ✅ 这里的数量现在是动态的了
                          _buildStatItem(totalScanned, "Scanned"),
                          _buildStatItem("5", "Pending"), // Pending 逻辑如果没做先写死
                          _buildStatItem("98%", "Accuracy"),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text(
              "HISTORY / REPORTS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 下半部分：列表
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

                  // ✅ 修复 1：安全的排序 (防止 null 崩溃)
                  receipts.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;

                    final tA = dataA['createdAt'] as Timestamp?;
                    final tB = dataB['createdAt'] as Timestamp?;

                    final dateA = tA?.toDate() ?? DateTime.now();
                    final dateB = tB?.toDate() ?? DateTime.now();

                    return dateB.compareTo(dateA);
                  });

                  return ListView.separated(
                    itemCount: receipts.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.black),
                    itemBuilder: (context, index) {
                      final receiptDoc = receipts[index];
                      // 获取数据 Map 以便安全访问
                      final data = receiptDoc.data() as Map<String, dynamic>;

                      final receiptName = data['receiptName'] ?? 'Unknown.pdf';
                      final Timestamp? timestamp = data['createdAt'] as Timestamp?;
                      final DateTime createdAt = timestamp?.toDate() ?? DateTime.now();
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
                          List<dynamic> imagesToShow = [];

                          if (data.containsKey('receiptImg') && data['receiptImg'] != null) {
                            imagesToShow = List.from(data['receiptImg']);
                          }

                          if (imagesToShow.isEmpty && data.containsKey('receiptImg')) {
                            imagesToShow.add(data['receiptImg']);
                          }

                          // ✅ 修复 3：调用新的 ImageViewer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageViewer(
                                images: imagesToShow, // 传 List
                                fileName: receiptName,
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
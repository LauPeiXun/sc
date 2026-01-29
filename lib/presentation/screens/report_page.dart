import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../application/receipt_provider.dart';
import 'package:provider/provider.dart';
import 'package:sc/data/model/receipt.dart';
import 'receipt_detail_page.dart';

class ReportPage extends StatefulWidget {
  final bool showBackButton;
  const ReportPage({super.key, this.showBackButton = false});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late String staffId;
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _receiptStream;
  String _sortBy = 'date'; //date, amount, name

  @override
  void initState() {
    super.initState();
    staffId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _searchController = TextEditingController();
    
    _receiptStream = FirebaseFirestore.instance
        .collection('receipt')
        .where('staffId', isEqualTo: staffId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String clean = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  void _confirmDelete(String receiptId, String receiptName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Receipt"),
        content: Text("Are you sure you want to delete '$receiptName'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<ReceiptProvider>().deleteReceipt(receiptId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Receipt deleted successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Report"),
        leading: widget.showBackButton 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _receiptStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          double totalTransfer = 0.0;
          int receiptCount = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            double totalAmount = _parseAmount(data['totalAmount']);
            totalTransfer += totalAmount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Receipts", "$receiptCount", Icons.receipt_long, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Total Amount", "RM ${(totalTransfer.toStringAsFixed(2))}", Icons.attach_money, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Search and Sort Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                        const PopupMenuItem(value: 'amount', child: Text('Sort by Amount')),
                        const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sort),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildRecentList(docs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentList(List<QueryDocumentSnapshot> docs) {
    // Filter by search query focusing on receiptName
    var filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final searchText = _searchController.text.toLowerCase();

      final receiptName = (data['receiptName'] ?? 'Receipt')
          .toString()
          .toLowerCase();

      return receiptName.contains(searchText);
    }).toList();

    // Sort the filtered documents
    filteredDocs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      switch (_sortBy) {
        case 'amount':
          final amountA = _parseAmount(dataA['totalAmount']);
          final amountB = _parseAmount(dataB['totalAmount']);
          return amountB.compareTo(amountA); // Descending
        case 'name':
          final nameA = (dataA['receiptName'] ?? 'Receipt').toString();
          final nameB = (dataB['receiptName'] ?? 'Receipt').toString();
          return nameA.compareTo(nameB); // Ascending
        case 'date':
        default:
          final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now();
          final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now();
          return dateB.compareTo(dateA); // Descending
      }
    });

    if (filteredDocs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchController.text.isNotEmpty
                ? 'No receipts found'
                : 'No recent transactions',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredDocs.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final data = filteredDocs[index].data() as Map<String, dynamic>;

          // Data Extraction
          final receiptName = data['receiptName'] ?? 'Receipt';
          final totalAmount = _parseAmount(data['totalAmount']);
          final receiptImg = data['receiptImg'] is String ? [data['receiptImg']] : (data['receiptImg'] as List<dynamic>? ?? []);
          final status = data['status'] ?? 'Unclear';

          final Timestamp? timestamp = data['createdAt'] as Timestamp?;
          final DateTime createdAt = timestamp?.toDate() ?? DateTime.now();
          final dateStr = "${createdAt.day}/${createdAt.month}/${createdAt
              .year}";

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: receiptImg.isNotEmpty
                      ? DecorationImage(
                      image: MemoryImage(base64Decode(receiptImg[0])),
                      fit: BoxFit.cover)
                      : null
              ),
              child: receiptImg.isEmpty ? const Icon(Icons.receipt) : null,
            ),
            title: Row(
              children: [
                Expanded(child: Text(receiptName,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'clear'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status.toLowerCase() == 'clear'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text("Scan at: $dateStr"),
            trailing: Text(
                "RM ${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)
            ),
            onTap: () {
              String imageString = "";
              if (data['receiptImg'] is String) {
                imageString = data['receiptImg'];
              } else if (data['receiptImg'] is List && (data['receiptImg'] as List).isNotEmpty) {
                imageString = data['receiptImg'][0];
              }


              final receipt = Receipt(
                receiptId: filteredDocs[index].id,
                receiptName: receiptName,
                receiptImg: imageString,
                staffId: data['staffId'] ?? '',
                staffName: data['staffName'] ?? '',
                createdAt: createdAt,
                bank: data['bank'] ?? '',
                bankAcc: data['bankAcc'] ?? '',
                totalAmount: totalAmount ?? 0.0,
                printedDate: data['printedDate'] ?? '',
                handwrittenDate: data['handwrittenDate'] ?? '',
                location: data['location'] ?? '',
                status: status,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptDetailPage(receipt: receipt),
                ),
              );
            },
            onLongPress: () =>
                _confirmDelete(filteredDocs[index].id, receiptName),
          );
        }
    );
  }
}
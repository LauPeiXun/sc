import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sc/data/model/receipt.dart';

class ReceiptDetailPage extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailPage({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank information
            _buildSection(
              title: 'Bank Information',
              children: [
                _buildInfoRow('Bank', receipt.bank.isEmpty ? '-' : receipt.bank),
                _buildInfoRow('Bank Account', receipt.bankAcc.isEmpty ? '-' : receipt.bankAcc),
              ],
            ),
            const SizedBox(height: 24),
            
            // Transfer information
            _buildSection(
              title: 'Transfer Information',
              children: [
                _buildInfoRow('Transfer Date', receipt.transferDate.isEmpty ? '-' : receipt.transferDate),
                _buildInfoRow(
                  'Amount',
                  'RM ${receipt.totalAmount.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Status
            _buildSection(
              title: 'Status',
              children: [
                _buildStatusBadge(receipt.status),
              ],
            ),
            const SizedBox(height: 24),
            
            // Staff information
            _buildSection(
              title: 'Staff Information',
              children: [
                _buildInfoRow('Staff Name', receipt.staffName),
                _buildInfoRow('Staff ID', receipt.staffId),
              ],
            ),
            const SizedBox(height: 24),
            
            // Receipt images
            if (receipt.receiptImg.isNotEmpty)
              _buildSection(
                title: 'Receipt Images',
                children: [
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: receipt.receiptImg.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => _showFullScreenImage(context, receipt.receiptImg[index]),
                            child: Hero(
                              tag: 'receipt_image_$index',
                              child: Image.memory(
                                base64Decode(receipt.receiptImg[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String base64Image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusUpper = status.toUpperCase();
    final isClear = statusUpper == 'CLEAR';
    final color = isClear ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          statusUpper,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
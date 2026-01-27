import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String receiptId;
  final String receiptName;
  final List<String> receiptImg;
  final String staffId;
  final String staffName;
  final DateTime createdAt;
  final String bank;
  final String bankAcc;
  final double totalAmount;
  final String transferDate;
  final String status;

  Receipt({
    required this.receiptId,
    required this.receiptName,
    required this.receiptImg,
    required this.staffId,
    required this.staffName,
    required this.createdAt,
    required this.bank,
    required this.bankAcc,
    required this.totalAmount,
    required this.transferDate,
    required this.status,

  });

  factory Receipt.fromJson(Map<String, dynamic> json){
    return Receipt(
        receiptId: json['receiptId'] ?? '',
        receiptName: json['receiptName'] ?? '',
        receiptImg: List<String> .from(json['receiptImg'] ?? []),
        staffId: json['staffId'] ?? '',
        staffName: json['staffName'] ?? '',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
        bank: json['bank'] ?? '',
        bankAcc: json['bankAcc'] ?? '',
        totalAmount: (json['totalAmount'] is num)
            ? (json['totalAmount'] as num).toDouble()
            : double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
        transferDate: json['transferDate'] ?? '',
        status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'receiptName': receiptName,
      'receiptImg': receiptImg,
      'staffId': staffId,
      'staffName': staffName,
      'createdAt': Timestamp.fromDate(createdAt),
      'bank': bank,
      'bankAcc': bankAcc,
      'totalAmount': totalAmount,
      'transferDate': transferDate,
      'status': status
    };
  }
}
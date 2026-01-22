import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String receiptId;
  final String receiptName;
  final List<String> receiptImg;
  final String staffId;
  final String staffName;
  final DateTime createdAt;

  Receipt({
    required this.receiptId,
    required this.receiptName,
    required this.receiptImg,
    required this.staffId,
    required this.staffName,
    required this.createdAt,
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
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now())
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'receiptName': receiptName,
      'receiptImg': receiptImg,
      'staffId': staffId,
      'staffName': staffName,
      'createdAt': Timestamp.fromDate(createdAt)
    };
  }
}
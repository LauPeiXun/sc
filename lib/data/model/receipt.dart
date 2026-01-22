import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String receiptId;
  final String receiptName;
  final String pdfBase64;
  final String staffId;
  final String staffName;
  final String description;
  final DateTime createdAt;

  Receipt({
    required this.receiptId,
    required this.receiptName,
    required this.pdfBase64,
    required this.staffId,
    required this.staffName,
    required this.description,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json){
    return Receipt(
        receiptId: json['receiptId'] ?? '',
        receiptName: json['receiptName'] ?? '',
        pdfBase64: json['pdfBase64'] ?? '',
        staffId: json['staffId'] ?? '',
        staffName: json['staffName'] ?? '',
        description: json['description'] ?? '',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now())
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'receiptName': receiptName,
      'pdfBase64': pdfBase64,
      'staffId': staffId,
      'staffName': staffName,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt)
    };
  }
}

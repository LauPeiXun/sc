import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reportId;
  final String receiptName;
  final String receiptImg;
  final String createBy;
  final DateTime createdAt;

  Report ({
    required this.reportId,
    required this.receiptName,
    required this.receiptImg,
    required this.createBy,
    required this.createdAt
  });

  factory Report.fromJson(Map<String, dynamic> json){
    return Report(
        reportId: json['reportId'] ?? '',
        receiptName: json['receiptName'] ?? '',
        receiptImg: json['receiptImg'] ?? '',
        createBy: json['createBy'] ?? '',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now())
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'receiptName': receiptName,
      'receiptImg': receiptImg,
      'createBy': createBy,
      'createdAt': Timestamp.fromDate(createdAt)
    };
  }

}
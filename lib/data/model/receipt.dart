import 'package:cloud_firestore/cloud_firestore.dart';

class ScannedReceipt {
  final String fileId;
  final String fileName;
  final String fileURL;
  final String staffId;
  final String description;
  final DateTime createdAt;

  ScannedReceipt({
    required this.fileId,
    required this.fileName,
    required this.fileURL,
    required this.staffId,
    required this.description,
    required this.createdAt,
  });

  factory ScannedReceipt.fromJson(Map<String, dynamic> json){
    return ScannedReceipt(
        fileId: json['fileId'] ?? json['fileId'] ?? '',
        fileName: json['fileName'] ?? '',
        fileURL: json['fileURL'] ?? '',
        staffId: json['staffId'] ?? '',
        description: json['description'] ?? '',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(json['createdAt'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileURL': fileURL,
      'staffId': staffId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt)
    };
  }
}
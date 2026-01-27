import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String staffId;
  final String staffName;
  final String email;
  final DateTime createdAt;

  Staff({
    required this.staffId,
    required this.staffName,
    required this.email,
    required this.createdAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json){
    return Staff(
        staffId: json['staffId'] ?? '',
        staffName: json['staffName'] ?? '',
        email: json['email'] ?? '',
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Staff copyWith({
    String? staffId,
    String? staffName,
    String? email,
    DateTime? createdAt
  }) {
    return Staff(
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
class Staff {
  final String staffId;
  final String staffName;
  final String email;

  Staff({
    required this.staffId,
    required this.staffName,
    required this.email,
  });

  factory Staff.fromJson(Map<String, dynamic> json){
    return Staff(
        staffId: json['staffId'] ?? json['staffId'] ?? '',
        staffName: json['staffName'] ?? '',
        email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'email': email,
    };
  }

  Staff copyWith({
    String? staffId,
    String? staffName,
    String? email,
  }) {
    return Staff(
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      email: email ?? this.email,
    );
  }

}
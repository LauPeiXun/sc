class Staff {
  final String staffId;
  final String staffName;
  final String email;
  final String profilePicUrl;

  Staff({
    required this.staffId,
    required this.staffName,
    required this.email,
    required this.profilePicUrl,
  });

  factory Staff.fromJson(Map<String, dynamic> json){
    return Staff(
        staffId: json['staffId'] ?? json['staffId'] ?? '',
        staffName: json['staffName'] ?? '',
        email: json['email'] ?? '',
        profilePicUrl: json['profilePicUrl'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'email': email,
      'profilePicUrl': profilePicUrl,
    };
  }
}
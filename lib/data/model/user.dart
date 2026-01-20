class User {
  final String userId;
  final String userName;
  final String email;
  final String password;
  final String profilePicUrl;

  User({
    required this.userId,
    required this.userName,
    required this.email,
    required this.password,
    required this.profilePicUrl,
  });

  factory User.fromJson(Map<String, dynamic> json){
    return User(
      userId: json['userId'] ?? json['userId'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      profilePicUrl: json['profilePicUrl'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'password': password,
      'profilePicUrl': profilePicUrl,
    };
  }
}
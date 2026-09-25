class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final int createdAt;
  // Collected at registration so the Profile screen has more than just
  // name/email/phone to show — previously the app asked for nothing else,
  // so Profile always fell back to "Not provided" for everything.
  final String dateOfBirth; // stored as 'dd MMM yyyy', empty if not set
  final String gender;
  final String address;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage = '',
    required this.createdAt,
    this.dateOfBirth = '',
    this.gender = '',
    this.address = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
    };
  }
}

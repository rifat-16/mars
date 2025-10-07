class UserModel {
  final String uid;
  final String email;
  final String? first_name;
  final String? last_name;
  final String? phone;
  final String? position;
  final String? address;

  UserModel({
    required this.uid,
    required this.email,
    this.first_name,
    this.last_name,
    this.phone,
    this.position,
    this.address,
  });

  // ✅ convert to Map for saving to local storage or Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': '$first_name $last_name',
    'phone': phone,
    'position': position,
    'address': address,
  };

  // ✅ convert Map to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] ?? '',
    email: json['email'] ?? '',
    first_name: json['first_name'],
    last_name: json['last_name'],
    phone: json['phone'],
    position: json['position'],
    address: json['address'],
  );
}
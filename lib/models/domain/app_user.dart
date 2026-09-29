import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String position;
  final String address;

  const AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.position,
    required this.address,
  });

  String get fullName => ('$firstName $lastName').trim();

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: FirestoreCompat.readString(data, [FirestoreFields.email]),
      firstName: FirestoreCompat.readString(data, [
        FirestoreFields.firstName,
        FirestoreFields.name,
      ]),
      lastName: FirestoreCompat.readString(data, [FirestoreFields.lastName]),
      phone: FirestoreCompat.readString(data, [
        FirestoreFields.phone,
        FirestoreFields.phoneNumber,
      ]),
      position: FirestoreCompat.readString(data, [FirestoreFields.position]),
      address: FirestoreCompat.readString(data, [
        FirestoreFields.address,
        FirestoreFields.location,
      ]),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'position': position,
      'address': address,
      'name': fullName,
    };
  }
}

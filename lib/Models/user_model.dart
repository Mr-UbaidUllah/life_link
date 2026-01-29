import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? phone;
  final String? city;
  final String? country;
  final String? bloodGroup;
  final bool isDonor;
  final bool profileCompleted;
  final String? profileImage;
  final DateTime createdAt;
  final String? fcmToken; // 👈 Add this line

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phone,
    this.city,
    this.country,
    this.bloodGroup,
    this.isDonor = false,
    this.profileCompleted = false,
    this.profileImage,
    required this.createdAt,
    this.fcmToken, // 👈 Add this line
  });

  /// 🔁 COPY WITH
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? city,
    String? country,
    String? bloodGroup,
    bool? isDonor,
    bool? profileCompleted,
    String? profileImage,
    DateTime? createdAt,
    String? fcmToken, // 👈 Add this line
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      country: country ?? this.country,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isDonor: isDonor ?? this.isDonor,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken, // 👈 Add this line
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'city': city,
      'country': country,
      'bloodGroup': bloodGroup,
      'isDonor': isDonor,
      'profileCompleted': profileCompleted,
      'profileImage': profileImage,
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': fcmToken, // 👈 Add this line
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];

    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'],
      phone: map['phone'],
      city: map['city'],
      country: map['country'],
      bloodGroup: map['bloodGroup'],
      isDonor: map['isDonor'] ?? false,
      profileCompleted: map['profileCompleted'] ?? false,
      profileImage: map['profileImage'],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'], // 👈 Add this line
    );
  }
}
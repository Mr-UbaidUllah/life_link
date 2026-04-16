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
  final String? fcmToken;
  final List<String> dismissedRequests;
  final String? dateOfBirth;
  final String? gender;
  final String? about;

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
    this.fcmToken,
    this.dismissedRequests = const [],
    this.dateOfBirth,
    this.gender,
    this.about,
  });

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
    String? fcmToken,
    List<String>? dismissedRequests,
    String? dateOfBirth,
    String? gender,
    String? about,
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
      fcmToken: fcmToken ?? this.fcmToken,
      dismissedRequests: dismissedRequests ?? this.dismissedRequests,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      about: about ?? this.about,
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
      'createdAt': createdAt, // Keep original createdAt if updating, or handle in service
      'fcmToken': fcmToken,
      'dismissedRequests': dismissedRequests,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'about': about,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final dynamic timestamp = map['createdAt'];
    final List<dynamic>? dismissed = map['dismissedRequests'];

    DateTime createdAtDate;
    if (timestamp is Timestamp) {
      createdAtDate = timestamp.toDate();
    } else {
      createdAtDate = DateTime.now();
    }

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
      createdAt: createdAtDate,
      fcmToken: map['fcmToken'],
      dismissedRequests: dismissed != null ? List<String>.from(dismissed) : [],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      about: map['about'],
    );
  }
}

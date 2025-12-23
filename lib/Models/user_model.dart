class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? phone;
  final String? city;
  final String? country;
  final String? bloodGroup;
  final bool isDonor;
  final bool profileCompleted; // ✅ ADD THIS
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phone,
    this.city,
    this.country,
    this.bloodGroup,
    this.isDonor = false,
    this.profileCompleted = false, // ✅ DEFAULT
    required this.createdAt,
  });

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
      'profileCompleted': profileCompleted, // ✅ SAVE
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      isDonor: map['isDonor'] ?? false,
      profileCompleted: map['profileCompleted'] ?? false, // ✅ READ
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

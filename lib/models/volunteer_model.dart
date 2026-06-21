import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  final String id;
  final String name;
  final String imageUrl;
  final String workDescription; // Current role or title
  final String? skills;
  final String? bio;
  final String? phone;
  final String? location;
  final DateTime? createdAt;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.workDescription,
    this.skills,
    this.bio,
    this.phone,
    this.location,
    this.createdAt,
  });

  /// 🔁 COPY WITH
  VolunteerModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? workDescription,
    String? skills,
    String? bio,
    String? phone,
    String? location,
    DateTime? createdAt,
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      workDescription: workDescription ?? this.workDescription,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 📤 SAVE TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'workDescription': workDescription,
      'skills': skills,
      'bio': bio,
      'phone': phone,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// 📥 READ FROM FIRESTORE
  factory VolunteerModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];

    return VolunteerModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      workDescription: map['workDescription'] ?? '',
      skills: map['skills'],
      bio: map['bio'],
      phone: map['phone'],
      location: map['location'],
      createdAt: timestamp?.toDate(),
    );
  }
}

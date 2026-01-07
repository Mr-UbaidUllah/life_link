import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  final String id;
  final String name;
  final String imageUrl;
  final String workDescription;
  final DateTime? createdAt;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.workDescription,
    this.createdAt,
  });

  /// 🔁 COPY WITH
  VolunteerModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? workDescription,
    DateTime? createdAt,
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      workDescription: workDescription ?? this.workDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 📤 SAVE TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'workDescription': workDescription,
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
      createdAt: timestamp?.toDate(),
    );
  }
}

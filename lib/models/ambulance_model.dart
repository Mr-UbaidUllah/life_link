import 'package:cloud_firestore/cloud_firestore.dart';

class AmbulanceModel {
  final String id;
  final String ambulanceName;
  final String hospitalName;
  final String address;
  final String imageUrl;
  final String phoneNumber;
  final DateTime? createdAt;

  AmbulanceModel({
    required this.id,
    required this.ambulanceName,
    required this.hospitalName,
    required this.address,
    required this.imageUrl,
    required this.phoneNumber,
    this.createdAt,
  });

  /// 🔁 COPY WITH
  AmbulanceModel copyWith({
    String? id,
    String? ambulanceName,
    String? hospitalName,
    String? address,
    String? imageUrl,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return AmbulanceModel(
      id: id ?? this.id,
      ambulanceName: ambulanceName ?? this.ambulanceName,
      hospitalName: hospitalName ?? this.hospitalName,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// SAVE TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'ambulanceName': ambulanceName,
      'hospitalName': hospitalName,
      'address': address,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// READ FROM FIRESTORE
  factory AmbulanceModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];

    return AmbulanceModel(
      id: id,
      ambulanceName: map['ambulanceName'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: timestamp?.toDate(),
    );
  }
}

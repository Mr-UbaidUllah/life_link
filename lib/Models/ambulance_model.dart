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

  factory AmbulanceModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];

    return AmbulanceModel(
      id: id,
      ambulanceName: map['ambulanceName'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

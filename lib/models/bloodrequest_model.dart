import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestModel {
  final String id;
  final String title;
  final String bloodGroup;
  final int bags;
  final String hospital;
  final String reason;
  final String contactName;
  final String phone;
  final String country;
  final String city;
  final String userId;
  final DateTime createdAt;
  final String status; // 'open' or 'closed'

  BloodRequestModel({
    required this.id,
    required this.title,
    required this.bloodGroup,
    required this.bags,
    required this.hospital,
    required this.reason,
    required this.contactName,
    required this.phone,
    required this.country,
    required this.city,
    required this.userId,
    required this.createdAt,
    this.status = 'open',
  });

  /// ✅ SAVE TO FIRESTORE (Server Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'bloodGroup': bloodGroup,
      'bags': bags,
      'hospital': hospital,
      'reason': reason,
      'contactName': contactName,
      'phone': phone,
      'country': country,
      'city': city,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  factory BloodRequestModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];

    return BloodRequestModel(
      id: id,
      title: map['title'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      bags: map['bags'] ?? 0,
      hospital: map['hospital'] ?? '',
      reason: map['reason'] ?? '',
      contactName: map['contactName'] ?? '',
      phone: map['phone'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'open',
    );
  }
}

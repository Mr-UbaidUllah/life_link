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
  final String? acceptedByUserId; // Added field
  final DateTime createdAt;
  final DateTime expiryDate;
  final String status; // 'open', 'in_progress', or 'closed'

  /// 'critical' | 'urgent' | 'routine'. Drives badge color, ordering and the
  /// pulsing emphasis on critical requests. Defaults to 'urgent' for legacy
  /// documents that predate this field.
  final String urgency;

  /// Optional geo-coordinates of the request (captured at creation when the
  /// donor grants location). Null for legacy / permission-denied requests.
  final double? lat;
  final double? lng;

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
    this.acceptedByUserId,
    required this.createdAt,
    required this.expiryDate,
    this.status = 'open',
    this.urgency = 'urgent',
    this.lat,
    this.lng,
  });

  /// ✅ SAVE TO FIRESTORE
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
      'acceptedByUserId': acceptedByUserId,
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'status': status,
      'urgency': urgency,
      'lat': lat,
      'lng': lng,
    };
  }

  factory BloodRequestModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? timestamp = map['createdAt'];
    final Timestamp? expiryTimestamp = map['expiryDate'];

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
      acceptedByUserId: map['acceptedByUserId'],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      expiryDate: expiryTimestamp?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      status: map['status'] ?? 'open',
      urgency: map['urgency'] ?? 'urgent',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}

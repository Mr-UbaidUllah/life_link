import 'package:cloud_firestore/cloud_firestore.dart';

enum AmbulanceType { cardiac, basic, neonatal, oxygen }

class AmbulanceModel {
  final String id;
  final String ambulanceName;
  final String hospitalName;
  final String address;
  final String imageUrl;
  final String phoneNumber;
  final AmbulanceType type;
  final bool isAvailable;
  final double rating;
  final int reviews;
  final double latitude;
  final double longitude;
  final String basePrice;
  final DateTime? createdAt;

  AmbulanceModel({
    required this.id,
    required this.ambulanceName,
    required this.hospitalName,
    required this.address,
    required this.imageUrl,
    required this.phoneNumber,
    this.type = AmbulanceType.basic,
    this.isAvailable = true,
    this.rating = 4.5,
    this.reviews = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.basePrice = '0',
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
    AmbulanceType? type,
    bool? isAvailable,
    double? rating,
    int? reviews,
    double? latitude,
    double? longitude,
    String? basePrice,
    DateTime? createdAt,
  }) {
    return AmbulanceModel(
      id: id ?? this.id,
      ambulanceName: ambulanceName ?? this.ambulanceName,
      hospitalName: hospitalName ?? this.hospitalName,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      basePrice: basePrice ?? this.basePrice,
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
      'type': type.name,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviews': reviews,
      'latitude': latitude,
      'longitude': longitude,
      'basePrice': basePrice,
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
      type: AmbulanceType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'basic'),
        orElse: () => AmbulanceType.basic,
      ),
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviews: map['reviews'] ?? 0,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      basePrice: map['basePrice'] ?? '0',
      createdAt: timestamp?.toDate(),
    );
  }
}

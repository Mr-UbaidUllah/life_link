import 'package:cloud_firestore/cloud_firestore.dart';

enum OrganizationType { hospital, bloodBank, ngo, clinic }

class OrganizationModel {
  final String id;
  final String name;
  final String image;
  final String address;
  final String phone;
  final String country;
  final String city;
  final String description;
  final String email;
  final String website;
  final OrganizationType type;
  final bool isVerified;
  final double rating;
  final DateTime? joinedAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.image,
    required this.address,
    required this.phone,
    required this.country,
    required this.city,
    this.description = '',
    this.email = '',
    this.website = '',
    this.type = OrganizationType.ngo,
    this.isVerified = false,
    this.rating = 0.0,
    this.joinedAt,
  });

  factory OrganizationModel.fromMap(String id, Map<String, dynamic> map) {
    return OrganizationModel(
      id: id,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      description: map['description'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      type: OrganizationType.values.firstWhere(
        (e) => e.toString() == 'OrganizationType.${map['type']}',
        orElse: () => OrganizationType.ngo,
      ),
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      joinedAt: map['joinedAt'] != null ? (map['joinedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'address': address,
      'phone': phone,
      'country': country,
      'city': city,
      'description': description,
      'email': email,
      'website': website,
      'type': type.name,
      'isVerified': isVerified,
      'rating': rating,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? image,
    String? address,
    String? phone,
    String? country,
    String? city,
    String? description,
    String? email,
    String? website,
    OrganizationType? type,
    bool? isVerified,
    double? rating,
    DateTime? joinedAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      description: description ?? this.description,
      email: email ?? this.email,
      website: website ?? this.website,
      type: type ?? this.type,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

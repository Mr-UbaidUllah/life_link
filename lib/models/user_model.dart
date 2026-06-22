import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blood_donation/utils/donation_eligibility.dart';

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
  final String? about;

  /// Access role: 'user' (default) or 'admin'. Drives RBAC in security rules.
  final String role;

  // ---- Health screening ----
  /// Donor weight in kilograms (null = not provided).
  final double? weightKg;

  /// Date of the donor's most recent donation (null = never / unknown).
  final DateTime? lastDonationDate;

  /// Declared health conditions (see [DonationEligibility.selectableConditions]).
  final List<String> healthConditions;

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
    this.about,
    this.role = 'user',
    this.weightKg,
    this.lastDonationDate,
    this.healthConditions = const [],
  });

  bool get isAdmin => role == 'admin';

  /// The next date this donor can give blood, based on their last donation.
  DateTime? get nextEligibleDate => lastDonationDate
      ?.add(const Duration(days: DonationEligibility.cooldownDays));

  bool get hasDeferringCondition => healthConditions
      .any((c) => DonationEligibility.deferringConditions.contains(c));

  /// Screens a donor against weight / cooldown / declared-condition rules.
  EligibilityResult evaluateEligibility({DateTime? now}) {
    final today = now ?? DateTime.now();

    if (!isDonor) {
      return const EligibilityResult(
        isEligible: false,
        reason: 'You have not opted in to donate blood.',
      );
    }
    if (hasDeferringCondition) {
      return const EligibilityResult(
        isEligible: false,
        reason:
            'A declared health condition requires review before donating.',
      );
    }
    if (weightKg == null) {
      return const EligibilityResult(
        isEligible: false,
        reason: 'Add your weight to check donation eligibility.',
      );
    }
    if (weightKg! < DonationEligibility.minWeightKg) {
      return EligibilityResult(
        isEligible: false,
        reason:
            'Donors must weigh at least ${DonationEligibility.minWeightKg.toInt()} kg.',
      );
    }
    final next = nextEligibleDate;
    if (next != null && next.isAfter(today)) {
      return EligibilityResult(
        isEligible: false,
        reason: 'You can donate again after your cooldown period.',
        nextEligibleDate: next,
      );
    }
    return const EligibilityResult(
      isEligible: true,
      reason: 'You are eligible to donate blood.',
    );
  }

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
    String? about,
    String? role,
    double? weightKg,
    DateTime? lastDonationDate,
    List<String>? healthConditions,
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
      about: about ?? this.about,
      role: role ?? this.role,
      weightKg: weightKg ?? this.weightKg,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      healthConditions: healthConditions ?? this.healthConditions,
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
      'about': about,
      'role': role,
      'weightKg': weightKg,
      'lastDonationDate': lastDonationDate,
      'healthConditions': healthConditions,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final dynamic timestamp = map['createdAt'];
    final List<dynamic>? dismissed = map['dismissedRequests'];
    final List<dynamic>? conditions = map['healthConditions'];
    final dynamic lastDonation = map['lastDonationDate'];
    final dynamic weight = map['weightKg'];

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
      about: map['about'],
      role: map['role'] ?? 'user',
      weightKg: weight == null ? null : (weight as num).toDouble(),
      lastDonationDate:
          lastDonation is Timestamp ? lastDonation.toDate() : null,
      healthConditions:
          conditions != null ? List<String>.from(conditions) : const [],
    );
  }
}

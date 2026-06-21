import 'package:cloud_firestore/cloud_firestore.dart';

class BloodInventoryModel {
  final String bloodGroup;
  final int bags;
  final DateTime lastUpdated;

  BloodInventoryModel({
    required this.bloodGroup,
    required this.bags,
    required this.lastUpdated,
  });

  factory BloodInventoryModel.fromMap(String id, Map<String, dynamic> map) {
    // Robust parsing for bags (handles String or int)
    int parseBags(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      if (val is double) return val.toInt();
      return 0;
    }

    final dynamic timestamp = map['lastUpdated'];
    DateTime lastUpdatedDate;
    if (timestamp is Timestamp) {
      lastUpdatedDate = timestamp.toDate();
    } else {
      lastUpdatedDate = DateTime.now();
    }

    return BloodInventoryModel(
      // Use the Document ID as bloodGroup if the field is missing inside the doc
      bloodGroup: map['bloodGroup'] ?? id,
      bags: parseBags(map['bags']),
      lastUpdated: lastUpdatedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bloodGroup': bloodGroup,
      'bags': bags,
      'lastUpdated': lastUpdated,
    };
  }
}

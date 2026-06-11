import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Live community totals shown on the Home "Our Impact" section.
///
/// Every field is backed by a real Firestore `count()` aggregate query
/// (server-side, so no documents are downloaded — one read per stat).
class CommunityStats {
  final int donors;
  final int openRequests;
  final int volunteers;
  final int organizations;
  final int ambulances;
  final int members;

  const CommunityStats({
    required this.donors,
    required this.openRequests,
    required this.volunteers,
    required this.organizations,
    required this.ambulances,
    required this.members,
  });
}

class StatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> _count(Query query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<CommunityStats> fetchCommunityStats() async {
    final results = await Future.wait([
      _count(_db.collection(FirebaseConstants.users).where('isDonor', isEqualTo: true)),
      _count(_db.collection(FirebaseConstants.bloodRequests).where('status', isEqualTo: 'open')),
      _count(_db.collection(FirebaseConstants.volunteer)),
      _count(_db.collection(FirebaseConstants.organizations)),
      _count(_db.collection(FirebaseConstants.ambulance)),
      _count(_db.collection(FirebaseConstants.users)),
    ]);

    return CommunityStats(
      donors: results[0],
      openRequests: results[1],
      volunteers: results[2],
      organizations: results[3],
      ambulances: results[4],
      members: results[5],
    );
  }
}

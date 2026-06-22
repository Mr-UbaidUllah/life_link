import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore CRUD service.
///
/// Eliminates the copy-pasted `add` / `getStream` boilerplate that was
/// duplicated across the ambulance, volunteer and organization services.
/// Concrete services extend this and only supply the collection name plus the
/// (de)serialization hooks for their model `T`.
abstract class BaseFirestoreService<T> {
  BaseFirestoreService(this.collectionName, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
  final String collectionName;

  CollectionReference<Map<String, dynamic>> get collection =>
      firestore.collection(collectionName);

  /// Build a model from a Firestore document.
  T fromMap(String id, Map<String, dynamic> map);

  /// Serialize a model for Firestore.
  Map<String, dynamic> toMap(T item);

  /// The document id for a model (used by [add]).
  String idOf(T item);

  Future<void> add(T item) => collection.doc(idOf(item)).set(toMap(item));

  Future<void> update(String id, Map<String, dynamic> data) =>
      collection.doc(id).update(data);

  Future<void> delete(String id) => collection.doc(id).delete();

  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return fromMap(doc.id, doc.data()!);
  }

  /// Stream the collection. Always pass a [limit] in production screens to
  /// avoid unbounded reads; [orderByField] enables newest-first ordering.
  Stream<List<T>> streamAll({
    int? limit,
    String? orderByField,
    bool descending = true,
  }) {
    Query<Map<String, dynamic>> query = collection;
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}

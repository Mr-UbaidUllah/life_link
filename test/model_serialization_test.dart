import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/notification_model.dart';
import 'package:blood_donation/models/organization_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests pin the defensive-deserialization fixes: a single malformed or
/// partially-written Firestore document must never throw and break a whole
/// stream/list. Each model's fromMap is exercised with missing/null fields.
void main() {
  group('OrganizationModel.fromMap — tolerates missing fields', () {
    test('full document round-trips', () {
      final org = OrganizationModel.fromMap('id1', {
        'name': 'Red Crescent',
        'image': 'http://img',
        'address': '123 St',
        'phone': '0300',
        'country': 'PK',
        'city': 'Lahore',
      });
      expect(org.id, 'id1');
      expect(org.name, 'Red Crescent');
      expect(org.city, 'Lahore');
    });

    test('missing fields fall back to empty strings (no crash)', () {
      // A doc created before a column existed, or with image not yet uploaded.
      final org = OrganizationModel.fromMap('id2', {'name': 'Partial'});
      expect(org.name, 'Partial');
      expect(org.image, '');
      expect(org.address, '');
      expect(org.phone, '');
      expect(org.country, '');
      expect(org.city, '');
    });

    test('completely empty document does not throw', () {
      expect(() => OrganizationModel.fromMap('id3', {}), returnsNormally);
    });
  });

  group('NotificationModel.fromMap — tolerates null/missing createdAt', () {
    test('valid Timestamp is converted', () {
      final ts = Timestamp.fromDate(DateTime(2024, 1, 1));
      final n = NotificationModel.fromMap('n1', {
        'title': 'Hi',
        'body': 'msg',
        'type': 'chat',
        'createdAt': ts,
        'isRead': true,
      });
      expect(n.title, 'Hi');
      expect(n.createdAt, ts.toDate());
      expect(n.isRead, true);
    });

    test('null createdAt (pending serverTimestamp) falls back, no crash', () {
      // Firestore emits a local snapshot with createdAt == null before the
      // server resolves a FieldValue.serverTimestamp() write.
      final n = NotificationModel.fromMap('n2', {
        'title': 'Hi',
        'body': 'msg',
        'type': 'chat',
        'createdAt': null,
      });
      expect(n.isRead, false);
      expect(n.createdAt, isA<DateTime>());
    });

    test('missing fields do not throw', () {
      expect(() => NotificationModel.fromMap('n3', {}), returnsNormally);
    });
  });

  group('NotificationModel.senderId/requestId — crash-proof getters', () {
    NotificationModel build(Map<String, dynamic> extra) =>
        NotificationModel.fromMap('n', {
          'title': 't',
          'body': 'b',
          'type': 'chat',
          'createdAt': null,
          ...extra,
        });

    test('senderId reads a valid string field', () {
      expect(build({'senderId': 'abc'}).senderId, 'abc');
    });

    test('senderId falls back to userId', () {
      expect(build({'userId': 'uid-9'}).senderId, 'uid-9');
    });

    test('senderId returns null (no throw) when the field is non-string', () {
      // A malformed doc where senderId got written as a number must NOT throw
      // a cast error from the getter — this is the regression being locked in.
      expect(build({'senderId': 12345}).senderId, isNull);
    });

    test('senderId returns null when absent', () {
      expect(build({}).senderId, isNull);
    });

    test('requestId reads a valid string and is null-safe on bad types', () {
      expect(build({'requestId': 'req-1'}).requestId, 'req-1');
      expect(build({'requestId': 99}).requestId, isNull);
      expect(build({}).requestId, isNull);
    });
  });

  group('ChatModel.fromMap — tolerates missing users/unreadCounts', () {
    test('full document round-trips', () {
      final c = ChatModel.fromMap('c1', {
        'users': ['a', 'b'],
        'lastMessage': 'hey',
        'unreadCounts': {'a': 2},
      });
      expect(c.users, ['a', 'b']);
      expect(c.lastMessage, 'hey');
      expect(c.unreadCounts['a'], 2);
    });

    test('missing users falls back to empty list (no crash)', () {
      final c = ChatModel.fromMap('c2', {'lastMessage': 'x'});
      expect(c.users, isEmpty);
      expect(c.unreadCounts, isEmpty);
    });

    test('completely empty document does not throw', () {
      expect(() => ChatModel.fromMap('c3', {}), returnsNormally);
    });
  });
}

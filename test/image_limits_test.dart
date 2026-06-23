import 'package:blood_donation/utils/image_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const oneMB = 1024 * 1024;

  group('isAcceptableImageSize — profile photo upload gate (10 MB)', () {
    test('limit constant is 10 MB', () {
      expect(kMaxImageBytes, 10 * 1024 * 1024);
    });

    test('a 1 MB image is accepted', () {
      expect(isAcceptableImageSize(1 * oneMB), isTrue);
    });

    test('a 5 MB image (rejected under the old 1 MB gate) is now accepted', () {
      expect(isAcceptableImageSize(5 * oneMB), isTrue);
    });

    test('exactly 10 MB is accepted (boundary, inclusive)', () {
      expect(isAcceptableImageSize(kMaxImageBytes), isTrue);
    });

    test('one byte over 10 MB is rejected', () {
      expect(isAcceptableImageSize(kMaxImageBytes + 1), isFalse);
    });

    test('a 15 MB image is rejected', () {
      expect(isAcceptableImageSize(15 * oneMB), isFalse);
    });
  });

  group('isAcceptableChatMediaSize — chat attachment upload gate (50 MB)', () {
    test('limit constant is 50 MB', () {
      expect(kMaxChatMediaBytes, 50 * 1024 * 1024);
    });

    test('a 25 MB attachment is accepted', () {
      expect(isAcceptableChatMediaSize(25 * oneMB), isTrue);
    });

    test('exactly 50 MB is accepted (boundary, inclusive)', () {
      expect(isAcceptableChatMediaSize(kMaxChatMediaBytes), isTrue);
    });

    test('one byte over 50 MB is rejected', () {
      expect(isAcceptableChatMediaSize(kMaxChatMediaBytes + 1), isFalse);
    });

    test('a 100 MB video (allowed under the old cap) is now rejected', () {
      expect(isAcceptableChatMediaSize(100 * oneMB), isFalse);
    });
  });
}

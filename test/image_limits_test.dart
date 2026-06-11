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
}

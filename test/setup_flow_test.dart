import 'package:blood_donation/utils/setup_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fully-filled Step 1 payload.
  Map<String, dynamic> step1() => {
        'name': 'Imad',
        'phone': '03001234567',
        'bloodGroup': 'O+',
        'country': 'Pakistan',
        'city': 'Islamabad',
      };

  group('firstIncompleteStep — resume routing', () {
    test('brand new user (empty doc) → Step 1', () {
      expect(firstIncompleteStep({}), SetupStep.personalInfo);
    });

    test('partial Step 1 (missing city) → Step 1', () {
      final data = step1()..remove('city');
      expect(firstIncompleteStep(data), SetupStep.personalInfo);
    });

    test('Step 1 fields present but blank/whitespace → Step 1', () {
      final data = step1()..['city'] = '   ';
      expect(firstIncompleteStep(data), SetupStep.personalInfo);
    });

    test('Step 1 done, Step 2 not done → Step 2', () {
      expect(firstIncompleteStep(step1()), SetupStep.basicInfo);
    });

    test('Step 1 done, basicInfoCompleted=false → Step 2', () {
      final data = step1()..['basicInfoCompleted'] = false;
      expect(firstIncompleteStep(data), SetupStep.basicInfo);
    });

    test('Steps 1 & 2 done, photo not done → Step 3', () {
      final data = step1()..['basicInfoCompleted'] = true;
      expect(firstIncompleteStep(data), SetupStep.photo);
    });

    test('isDonor=false still advances past Step 2 (chose "No")', () {
      // Regression guard: "No" must not look like "Step 2 unfinished".
      final data = step1()
        ..['isDonor'] = false
        ..['basicInfoCompleted'] = true;
      expect(firstIncompleteStep(data), SetupStep.photo);
    });

    test('profileCompleted=true → completed (skip everything)', () {
      final data = step1()
        ..['basicInfoCompleted'] = true
        ..['profileCompleted'] = true;
      expect(firstIncompleteStep(data), SetupStep.completed);
    });

    test('profileCompleted wins even if earlier steps look empty', () {
      expect(firstIncompleteStep({'profileCompleted': true}),
          SetupStep.completed);
    });
  });
}

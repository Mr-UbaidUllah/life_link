import 'package:blood_donation/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for the shimmer skeletons: each must build without throwing in
/// both light and dark themes (the skeletons branch on Theme brightness).
void main() {
  Widget host(Widget child, {Brightness brightness = Brightness.light}) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(body: child),
      ),
    );
  }

  final skeletons = <String, Widget>{
    'BloodRequestSkeleton': const BloodRequestSkeleton(),
    'ContactCardSkeleton': const ContactCardSkeleton(),
    'VolunteerCardSkeleton': const VolunteerCardSkeleton(),
    'UserTileSkeleton': const UserTileSkeleton(),
    'UserTileSkeleton(dense)': const UserTileSkeleton(dense: true),
    'UserNameShimmer': const UserNameShimmer(),
    'MessageListSkeleton': const MessageListSkeleton(),
  };

  for (final entry in skeletons.entries) {
    testWidgets('${entry.key} builds in light theme', (tester) async {
      await tester.pumpWidget(host(entry.value));
      expect(tester.takeException(), isNull);
    });

    testWidgets('${entry.key} builds in dark theme', (tester) async {
      await tester.pumpWidget(host(entry.value, brightness: Brightness.dark));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ShimmerList builds and renders skeleton items', (tester) async {
    await tester.pumpWidget(
      host(
        ShimmerList(
          itemCount: 4,
          itemBuilder: (_, __) => const ContactCardSkeleton(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // ListView.builder is lazy, so only the items in the viewport are built —
    // assert at least one rendered rather than the exact count.
    expect(find.byType(ContactCardSkeleton), findsWidgets);
  });
}

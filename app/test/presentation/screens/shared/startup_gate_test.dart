import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/screens/shared/startup_gate.dart';
import 'package:hostr/router.dart';

void main() {
  group('planStartupReadyNavigation', () {
    test('navigates to edit profile and seeds profile route when missing data',
        () {
      final plan = planStartupReadyNavigation(
        hasMetadata: false,
        hasPendingNavigation: false,
      );

      expect(plan.action, StartupReadyNavigationAction.editProfile);
      expect(plan.seedProfilePendingRoute, isTrue);
    });

    test('preserves existing pending route when metadata is missing', () {
      final plan = planStartupReadyNavigation(
        hasMetadata: false,
        hasPendingNavigation: true,
      );

      expect(plan.action, StartupReadyNavigationAction.editProfile);
      expect(plan.seedProfilePendingRoute, isFalse);
    });

    test('consumes pending navigation when metadata exists', () {
      final plan = planStartupReadyNavigation(
        hasMetadata: true,
        hasPendingNavigation: false,
      );

      expect(plan.action, StartupReadyNavigationAction.consumePending);
      expect(plan.seedProfilePendingRoute, isFalse);
    });
  });

  group('wrapInTabShellIfNeeded', () {
    test('wraps tab routes in TabShellRoute', () {
      final wrapped = wrapInTabShellIfNeeded(const InboxRoute());
      final children = wrapped.initialChildren;

      expect(wrapped.routeName, TabShellRoute.name);
      expect(children, isNotNull);
      expect(children, hasLength(1));
      expect(children!.single.routeName, InboxRoute.name);
    });

    test('leaves standalone routes untouched', () {
      final wrapped = wrapInTabShellIfNeeded(const EditProfileRoute());

      expect(wrapped.routeName, EditProfileRoute.name);
      expect(wrapped.initialChildren, isNull);
    });
  });
}

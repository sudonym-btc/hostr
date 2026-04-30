import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/screens/shared/startup_gate.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

void main() {
  group('planStartupReadyNavigation', () {
    test(
      'navigates to edit profile and seeds profile route when missing data',
      () {
        final plan = planStartupReadyNavigation(
          scope: StartupScope.user,
          hasMetadata: false,
          hasPendingNavigation: false,
        );

        expect(plan.action, StartupReadyNavigationAction.editProfile);
        expect(plan.seedProfilePendingRoute, isTrue);
      },
    );

    test('preserves existing pending route when metadata is missing', () {
      final plan = planStartupReadyNavigation(
        scope: StartupScope.user,
        hasMetadata: false,
        hasPendingNavigation: true,
      );

      expect(plan.action, StartupReadyNavigationAction.editProfile);
      expect(plan.seedProfilePendingRoute, isFalse);
    });

    test('consumes pending navigation when metadata exists', () {
      final plan = planStartupReadyNavigation(
        scope: StartupScope.user,
        hasMetadata: true,
        hasPendingNavigation: false,
      );

      expect(plan.action, StartupReadyNavigationAction.consumePending);
      expect(plan.seedProfilePendingRoute, isFalse);
    });

    test('does not consume pending navigation for public readiness', () {
      final plan = planStartupReadyNavigation(
        scope: StartupScope.public,
        hasMetadata: true,
        hasPendingNavigation: true,
      );

      expect(plan.action, StartupReadyNavigationAction.none);
      expect(plan.seedProfilePendingRoute, isFalse);
    });
  });

  group('shouldBlockStartupForBunker', () {
    test('blocks while bunker recovery is required or restoring', () {
      expect(
        shouldBlockStartupForBunker(
          const BunkerSessionRecoveryRequired(
            pubkey: 'pubkey',
            message: 'offline',
          ),
        ),
        isTrue,
      );
      expect(
        shouldBlockStartupForBunker(
          const BunkerSessionRestoring(pubkey: 'pubkey'),
        ),
        isTrue,
      );
    });

    test('does not block inactive or ready bunker states', () {
      expect(
        shouldBlockStartupForBunker(const BunkerSessionInactive()),
        isFalse,
      );
      expect(
        shouldBlockStartupForBunker(const BunkerSessionReady(pubkey: 'pubkey')),
        isFalse,
      );
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

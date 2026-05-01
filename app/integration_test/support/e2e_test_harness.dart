import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/amount/amount_input.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/presentation/in_app_notification_toast.dart';
import 'package:hostr/presentation/screens/guest/explore/explore_view.dart';
import 'package:hostr/presentation/screens/host/hostings/hostings.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_view.dart';
import 'package:hostr/presentation/screens/shared/signin/signin.dart';
import 'package:hostr/route/pending_navigation.dart';
import 'package:hostr/router.dart';
import 'package:hostr/setup.dart';
import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart' as sdk_di;
import 'package:hostr_sdk/testing/integration_test_harness.dart';
import 'package:hostr_sdk/usecase/payments/constants.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:models/main.dart';
import 'package:models/stubs/keypairs.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'browser_location_stub.dart'
    if (dart.library.js_interop) 'browser_location_web.dart';
import 'e2e_image_picker.dart';
import 'http_overrides_stub.dart' if (dart.library.io) 'http_overrides_io.dart';
import 'signet_test_controller.dart';

const _timeout = Timeout(Duration(minutes: 90));

enum E2eSuite {
  bunkerPopups,
  searchFilters,
  loginRouting,
  reservations,
  guestCancellations,
  hostBookings,
  listings,
  hostings,
  reviews,
  autoWithdraw,
  subscriptionLifecycle,
}

enum E2eReservationCase { usd, btc, negotiatedUsd, negotiatedBtc }

enum E2eCancellationCase { guestPending, guestLive, hostPending, hostLive }

void runE2eTests({
  Set<E2eSuite>? suites,
  Set<E2eLoginMode>? loginModes,
  Set<E2eReservationCase>? reservationCases,
  Set<E2eCancellationCase>? cancellationCases,
  bool singleBrowser = false,
}) {
  final activeSuites = suites ?? _defaultE2eSuites;
  final activeLoginModes = loginModes ?? E2eLoginMode.values.toSet();
  final activeReservationCases =
      reservationCases ?? E2eReservationCase.values.toSet();
  final activeCancellationCases =
      cancellationCases ?? E2eCancellationCase.values.toSet();
  bool has(E2eSuite suite) => activeSuites.contains(suite);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Hostr hostr;
  late IntegrationTestHarness harness;
  late _GodFixtures fixtures;
  SignetTestController? signet;
  var harnessCreated = false;

  setUpAll(() async {
    InAppNotificationToast.setSuppressForTesting(true);
    configureTestHttpOverrides();
    IntegrationTestHarness.acceptSelfSignedCerts();
    final listingImageData = await rootBundle.load(
      'assets/images/listing_placeholder.jpg',
    );
    final listingImageBytes = listingImageData.buffer.asUint8List();
    ImagePickerCubit.debugPickAllowedImagesFromGallery =
        ({required allowedFileTypes, required limit}) async {
          if (limit <= 0) return const <XFile>[];
          return [
            XFile.fromData(
              listingImageBytes,
              name: 'listing.jpg',
              mimeType: 'image/jpeg',
            ),
          ];
        };
    ImagePickerPlatform.instance = E2eImagePickerPlatform([
      XFile.fromData(
        listingImageBytes,
        name: 'listing.jpg',
        mimeType: 'image/jpeg',
      ),
    ]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') return null;
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        });

    await initCore(Env.dev);
    hostr = getIt<Hostr>();
    await hostr.auth.logout();

    harness = await IntegrationTestHarness.create(
      name: 'hostr_god_journey',
      hostr: hostr,
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
      cleanHydratedStorage: false,
    );
    harnessCreated = true;

    signet = SignetTestController();
    await signet!.deleteKeysWithPrefix('hostr-');
    fixtures = await _seedFixtures(harness);
  });

  tearDownAll(() async {
    InAppNotificationToast.setSuppressForTesting(false);
    ImagePickerCubit.debugPickAllowedImagesFromGallery = null;
    await signet?.deleteKeysWithPrefix('hostr-');
    await signet?.dispose();
    if (getIt.isRegistered<Hostr>()) {
      await getIt<Hostr>().dispose();
    }
    if (harnessCreated) {
      await harness.dispose();
    }
    await getIt.reset();
    await sdk_di.getIt.reset();
    IntegrationTestHarness.resetLogLevel();
  });

  Future<void> runSingleBrowserJourney(WidgetTester tester) async {
    if (has(E2eSuite.bunkerPopups)) {
      await _withSignedInUser(
        tester: tester,
        harness: harness,
        signet: signet!,
        loginMode: E2eLoginMode.bunker,
        profileName: 'God Pending Bunker',
        body: (session) async {
          await _assertSignerWaitingPopup(
            tester: tester,
            router: session.router,
            hostr: session.hostr,
            approvals: session.approvals as _SignetApprovalDriver,
            fixtures: session.fixtures,
          );
        },
      );

      late SignetTestUser reconnectUser;
      await _withFreshApp(tester, (router) async {
        reconnectUser = await signet!.createRandomUser(prefix: 'hostr-retry');
        await _publishProfileFor(harness, reconnectUser.keyPair, 'God Retry');
        final approvals = _SignetApprovalDriver(
          signet: signet!,
          keyName: reconnectUser.keyName,
        );
        await approvals.start();
        addTearDown(approvals.stop);
        await _signInWithNostrConnectUi(tester, router, signet!, reconnectUser);
        await approvals.stop();
        await _assertBunkerRestoreFailureAndRetry(
          tester: tester,
          router: router,
          signet: signet!,
          signetUser: reconnectUser,
        );
        hostr = getIt<Hostr>();
        await harness.dispose();
        harness = await IntegrationTestHarness.create(
          name: 'hostr_god_journey_after_bunker_retry',
          hostr: hostr,
          seed: DateTime.now().microsecondsSinceEpoch,
          logLevel: Level.warning,
          cleanHydratedStorage: false,
        );
        fixtures = await _seedFixtures(harness);
      });
    }

    if (has(E2eSuite.searchFilters)) {
      await _withFreshApp(tester, (router) async {
        await _exerciseExploreFilters(
          tester,
          router,
          hostr,
          fixtures.filterListings,
        );
      });
    }

    for (final loginMode in activeLoginModes) {
      if (has(E2eSuite.loginRouting)) {
        await _withFreshApp(tester, (router) async {
          await _assertLoginRoutingMatrixForMode(
            tester: tester,
            router: router,
            harness: harness,
            fixtures: fixtures,
            signet: signet!,
            loginMode: loginMode,
          );
        });
      }

      if (has(E2eSuite.reservations)) {
        for (final reservationCase in activeReservationCases) {
          await _withSignedInUser(
            tester: tester,
            harness: harness,
            signet: signet!,
            loginMode: loginMode,
            profileName:
                'God Reservation ${reservationCase.name} ${loginMode.label}',
            body: (session) async {
              await _runReservationCase(session, reservationCase);
            },
          );
        }
      }

      if (has(E2eSuite.guestCancellations)) {
        for (final cancellationCase in activeCancellationCases) {
          await _withSignedInUser(
            tester: tester,
            harness: harness,
            signet: signet!,
            loginMode: loginMode,
            profileName:
                'God Cancel ${cancellationCase.name} ${loginMode.label}',
            body: (session) async {
              await _runCancellationCase(session, cancellationCase);
            },
          );
        }
      }

      if (has(E2eSuite.hostBookings)) {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Host ${loginMode.label}',
          body: (session) async {
            await _runHostBookingFlows(session);
          },
        );
      }

      if (has(E2eSuite.listings)) {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Listing ${loginMode.label}',
          body: (session) async {
            final created = await _createListing(
              tester,
              session.router,
              session.label,
            );
            await _editListing(tester, session.router, created, session.label);
          },
        );
      }

      if (has(E2eSuite.hostings)) {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Hostings ${loginMode.label}',
          body: (session) async {
            final listing = await _createListing(
              tester,
              session.router,
              '${session.label}-hostings',
            );
            await _createBackendBookingAndAssertHostings(
              tester: tester,
              router: session.router,
              harness: harness,
              hostr: session.hostr,
              fixtures: session.fixtures,
              hostKeyPair: session.user,
              listing: listing,
              label: session.label,
            );
          },
        );
      }
    }

    if (has(E2eSuite.reviews)) {
      for (final loginMode in activeLoginModes) {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Review ${loginMode.label}',
          body: (session) async {
            await _runReviewFlow(session);
          },
        );
      }
    }

    if (has(E2eSuite.autoWithdraw)) {
      for (final loginMode in activeLoginModes) {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Auto Withdraw ${loginMode.label}',
          body: (session) async {
            await _backendArbitrateInFavorOfUser(
              harness: harness,
              hostr: session.hostr,
              escrowService: session.fixtures.escrowService,
            );
            await _assertBalancePageAndAutomaticSwapOut(
              tester,
              session.router,
              session.hostr,
              session.fixtures.escrowService,
            );
          },
        );
      }
    }

    if (has(E2eSuite.subscriptionLifecycle)) {
      await _withSignedInUser(
        tester: tester,
        harness: harness,
        signet: signet!,
        loginMode: E2eLoginMode.nsec,
        profileName: 'God Subscription Lifecycle',
        body: _runSubscriptionLifecycleCase,
      );
    }
  }

  if (singleBrowser) {
    testWidgets('god journey', runSingleBrowserJourney, timeout: _timeout);
    return;
  }

  // Keep bunker startup/popup flows first in the full journey so they can be
  // stabilized without paying for search/reservation/payment setup first.
  if (has(E2eSuite.bunkerPopups)) {
    testWidgets('pending bunker approval popup page', (tester) async {
      await _withSignedInUser(
        tester: tester,
        harness: harness,
        signet: signet!,
        loginMode: E2eLoginMode.bunker,
        profileName: 'God Pending Bunker',
        body: (session) async {
          await _assertSignerWaitingPopup(
            tester: tester,
            router: session.router,
            hostr: session.hostr,
            approvals: session.approvals as _SignetApprovalDriver,
            fixtures: session.fixtures,
          );
        },
      );
    }, timeout: _timeout);

    testWidgets('bunker reconnect failure and retry', (tester) async {
      late SignetTestUser reconnectUser;
      await _withFreshApp(tester, (router) async {
        reconnectUser = await signet!.createRandomUser(prefix: 'hostr-retry');
        await _publishProfileFor(harness, reconnectUser.keyPair, 'God Retry');
        final approvals = _SignetApprovalDriver(
          signet: signet!,
          keyName: reconnectUser.keyName,
        );
        await approvals.start();
        addTearDown(approvals.stop);
        await _signInWithNostrConnectUi(tester, router, signet!, reconnectUser);
        await approvals.stop();
        await _assertBunkerRestoreFailureAndRetry(
          tester: tester,
          router: router,
          signet: signet!,
          signetUser: reconnectUser,
        );
        hostr = getIt<Hostr>();
        await harness.dispose();
        harness = await IntegrationTestHarness.create(
          name: 'hostr_god_journey_after_bunker_retry',
          hostr: hostr,
          seed: DateTime.now().microsecondsSinceEpoch,
          logLevel: Level.warning,
          cleanHydratedStorage: false,
        );
        fixtures = await _seedFixtures(harness);
      });
    }, timeout: _timeout);
  }

  if (has(E2eSuite.searchFilters)) {
    testWidgets('anonymous search filter combinations', (tester) async {
      await _withFreshApp(tester, (router) async {
        await _exerciseExploreFilters(
          tester,
          router,
          hostr,
          fixtures.filterListings,
        );
      });
    }, timeout: _timeout);
  }

  for (final loginMode in activeLoginModes) {
    if (has(E2eSuite.loginRouting)) {
      testWidgets('login routing matrix (${loginMode.label})', (tester) async {
        await _withFreshApp(tester, (router) async {
          await _assertLoginRoutingMatrixForMode(
            tester: tester,
            router: router,
            harness: harness,
            fixtures: fixtures,
            signet: signet!,
            loginMode: loginMode,
          );
        });
      }, timeout: _timeout);
    }

    if (has(E2eSuite.reservations)) {
      for (final reservationCase in activeReservationCases) {
        testWidgets(
          'reservation ${reservationCase.name} and trips (${loginMode.label})',
          (tester) async {
            await _withSignedInUser(
              tester: tester,
              harness: harness,
              signet: signet!,
              loginMode: loginMode,
              profileName:
                  'God Reservation ${reservationCase.name} ${loginMode.label}',
              body: (session) async {
                await _runReservationCase(session, reservationCase);
              },
            );
          },
          timeout: _timeout,
        );
      }
    }

    if (has(E2eSuite.guestCancellations)) {
      for (final cancellationCase in activeCancellationCases) {
        testWidgets(
          'cancellation ${cancellationCase.name} (${loginMode.label})',
          (tester) async {
            await _withSignedInUser(
              tester: tester,
              harness: harness,
              signet: signet!,
              loginMode: loginMode,
              profileName:
                  'God Cancel ${cancellationCase.name} ${loginMode.label}',
              body: (session) async {
                await _runCancellationCase(session, cancellationCase);
              },
            );
          },
          timeout: _timeout,
        );
      }
    }

    if (has(E2eSuite.hostBookings)) {
      testWidgets('host booking flows (${loginMode.label})', (tester) async {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Host ${loginMode.label}',
          body: (session) async {
            await _runHostBookingFlows(session);
          },
        );
      }, timeout: _timeout);
    }

    if (has(E2eSuite.listings)) {
      testWidgets('listing create/edit (${loginMode.label})', (tester) async {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Listing ${loginMode.label}',
          body: (session) async {
            final created = await _createListing(
              tester,
              session.router,
              session.label,
            );
            await _editListing(tester, session.router, created, session.label);
          },
        );
      }, timeout: _timeout);
    }

    if (has(E2eSuite.hostings)) {
      testWidgets('booking appears on hostings (${loginMode.label})', (
        tester,
      ) async {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Hostings ${loginMode.label}',
          body: (session) async {
            final listing = await _createListing(
              tester,
              session.router,
              '${session.label}-hostings',
            );
            await _createBackendBookingAndAssertHostings(
              tester: tester,
              router: session.router,
              harness: harness,
              hostr: session.hostr,
              fixtures: session.fixtures,
              hostKeyPair: session.user,
              listing: listing,
              label: session.label,
            );
          },
        );
      }, timeout: _timeout);
    }
  }

  if (has(E2eSuite.reviews)) {
    for (final loginMode in activeLoginModes) {
      testWidgets('add review (${loginMode.label})', (tester) async {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Review ${loginMode.label}',
          body: (session) async {
            await _runReviewFlow(session);
          },
        );
      }, timeout: _timeout);
    }
  }

  if (has(E2eSuite.autoWithdraw)) {
    for (final loginMode in activeLoginModes) {
      testWidgets('auto-withdraw escrow balance (${loginMode.label})', (
        tester,
      ) async {
        await _withSignedInUser(
          tester: tester,
          harness: harness,
          signet: signet!,
          loginMode: loginMode,
          profileName: 'God Auto Withdraw ${loginMode.label}',
          body: (session) async {
            await _backendArbitrateInFavorOfUser(
              harness: harness,
              hostr: session.hostr,
              escrowService: session.fixtures.escrowService,
            );
            await _assertBalancePageAndAutomaticSwapOut(
              tester,
              session.router,
              session.hostr,
              session.fixtures.escrowService,
            );
          },
        );
      }, timeout: _timeout);
    }
  }

  if (has(E2eSuite.subscriptionLifecycle)) {
    testWidgets('nostr subscriptions are disposed after navigation', (
      tester,
    ) async {
      await _withSignedInUser(
        tester: tester,
        harness: harness,
        signet: signet!,
        loginMode: E2eLoginMode.nsec,
        profileName: 'God Subscription Lifecycle',
        body: _runSubscriptionLifecycleCase,
      );
    }, timeout: _timeout);
  }
}

final Set<E2eSuite> _defaultE2eSuites = E2eSuite.values
    .where((suite) => suite != E2eSuite.subscriptionLifecycle)
    .toSet();

class _GodFixtures {
  final KeyPair hostKeyPair;
  final EscrowMethod hostEscrowMethod;
  final Listing btcListing;
  final Listing usdListing;
  final Listing negotiableBtcListing;
  final Listing negotiableUsdListing;
  final List<Listing> filterListings;
  final EscrowService escrowService;

  const _GodFixtures({
    required this.hostKeyPair,
    required this.hostEscrowMethod,
    required this.btcListing,
    required this.usdListing,
    required this.negotiableBtcListing,
    required this.negotiableUsdListing,
    required this.filterListings,
    required this.escrowService,
  });
}

class _ReservationJourneyResult {
  final AppRouter router;
  final Listing listing;
  final String threadAnchor;
  final String tradeId;

  const _ReservationJourneyResult({
    required this.router,
    required this.listing,
    required this.threadAnchor,
    required this.tradeId,
  });
}

class _BackendLiveBooking {
  final String tradeId;
  final String threadAnchor;

  const _BackendLiveBooking({
    required this.tradeId,
    required this.threadAnchor,
  });
}

enum E2eLoginMode {
  nsec('nsec'),
  bunker('bunker');

  const E2eLoginMode(this.label);
  final String label;
}

class _E2eSession {
  final WidgetTester tester;
  final AppRouter router;
  final Hostr hostr;
  final IntegrationTestHarness harness;
  final _GodFixtures fixtures;
  final _ApprovalDriver approvals;
  final KeyPair user;
  final String label;

  const _E2eSession({
    required this.tester,
    required this.router,
    required this.hostr,
    required this.harness,
    required this.fixtures,
    required this.approvals,
    required this.user,
    required this.label,
  });
}

class _ArbitrationTrade {
  final String title;
  final KeyPair hostKeyPair;
  final Reservation negotiateReservation;

  const _ArbitrationTrade({
    required this.title,
    required this.hostKeyPair,
    required this.negotiateReservation,
  });
}

abstract class _ApprovalDriver {
  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
}

class _NoopApprovalDriver implements _ApprovalDriver {
  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _SignetApprovalDriver implements _ApprovalDriver {
  _SignetApprovalDriver({required this.signet, required this.keyName});

  final SignetTestController signet;
  final String keyName;

  bool _paused = false;
  bool _stopped = false;
  Future<void>? _loop;
  final Set<String> _submittedRequestIds = <String>{};

  @override
  Future<void> start() async {
    _loop ??= _approveLoop();
  }

  @override
  Future<void> pause() async {
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _paused = false;
  }

  Future<void> setTrustLevel(String trustLevel) async {
    await signet.updateAppTrustLevelForKey(keyName, trustLevel);
    _submittedRequestIds.clear();
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    await _loop;
  }

  Future<void> _approveLoop() async {
    while (!_stopped) {
      try {
        if (!_paused) {
          final pending = (await signet.requests())
              .where(
                (request) =>
                    request.keyName == keyName &&
                    !_submittedRequestIds.contains(request.id),
              )
              .toList(growable: false);
          if (pending.isNotEmpty) {
            debugPrint(
              'GOD_STEP signet:approve-batch key=$keyName '
              'ids=${pending.map((request) => request.id).join(',')}',
            );
            await signet.approveBatch(pending);
            _submittedRequestIds.addAll(pending.map((request) => request.id));
          }
        }
      } on SignetHttpException catch (e) {
        debugPrint('GOD_STEP signet:approve-loop-error $e');
        if (e.message.contains('429')) {
          await Future<void>.delayed(const Duration(seconds: 5));
          _submittedRequestIds.clear();
        } else {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      } catch (error) {
        debugPrint('GOD_STEP signet:approve-loop-error $error');
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}

Future<_GodFixtures> _seedFixtures(IntegrationTestHarness harness) async {
  final hostr = harness.hostr;
  final host = await harness.seeds.freshHost(listingCount: 0, hasEvm: true);
  final hostLud16 = host.profile.metadata.lud16;
  if (hostLud16 != null && hostLud16.isNotEmpty) {
    await harness.ensureLnbitsPayLinkForLud16(hostLud16);
  }
  final chainConfig = env.evmConfig.chains.first;
  final chain = hostr.evm.getChainByChainId(chainConfig.chainId);
  if (chain == null) {
    throw StateError('No configured EVM chain for ${chainConfig.chainId}');
  }
  final contractAddress = chainConfig.escrowContractAddress;
  if (contractAddress == null || contractAddress.isEmpty) {
    throw StateError('No escrow contract configured for ${chainConfig.id}');
  }
  final contractBytecodeHash =
      await SupportedEscrowContractRegistry.bytecodeHashForAddress(
        chain,
        EthereumAddress.fromHex(contractAddress),
      );
  debugPrint(
    'GOD_ESCROW_SEED chain=${chainConfig.id} contract=$contractAddress '
    'bytecode=$contractBytecodeHash',
  );
  final escrowService = (await harness.seeds.factory.buildEscrowServices(
    contractAddress: contractAddress,
    multiEscrowBytecodeHash: contractBytecodeHash,
  )).first;
  final hostEscrowMethod = await harness.seeds.entities.escrowMethod(
    signer: host.keyPair,
    multiEscrowBytecodeHash: contractBytecodeHash,
    chainId: chainConfig.chainId,
    tbtcAddress: chainConfig.tokens['tBTC']?.address,
    usdtAddress: chainConfig.tokens['USDT']?.address,
  );

  await hostr.metadata.upsert(host.profile);
  if (host.identityClaims != null) {
    await hostr.identityClaims.upsert(host.identityClaims!);
  }
  await hostr.escrows.upsert(escrowService);
  await hostr.escrowMethods.upsert(hostEscrowMethod);

  final runId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  var listingCreatedAt =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 +
      const Duration(minutes: 20).inSeconds;
  Listing listing({
    required String suffix,
    required String title,
    required DenominatedAmount amount,
    required bool negotiable,
    required ListingType type,
    required Specifications specs,
  }) {
    return harness.seeds.entities.listing(
      signer: host.keyPair,
      dTag: 'god-$runId-$suffix',
      title: title,
      description: '$title fixture for the god journey.',
      price: [Price(amount: amount, frequency: Frequency.daily)],
      location: 'San Salvador, El Salvador',
      type: type,
      specifications: specs,
      negotiable: negotiable,
      instantBook: false,
      createdAt: listingCreatedAt++,
      images: ['https://picsum.photos/seed/god-$suffix/1200/800'],
    );
  }

  final btcListing = listing(
    suffix: 'btc',
    title: 'God Test BTC Stay',
    amount: DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(25000),
    ),
    negotiable: false,
    type: ListingType.house,
    specs: Specifications({
      'max_guests': 4,
      'bedrooms': 2,
      'beds': 2,
      'bathrooms': 1,
      'kitchen': true,
    }),
  );
  final usdListing = listing(
    suffix: 'usd',
    title: 'God Test USDT Stay',
    amount: DenominatedAmount.fromDecimal('12', 'USD', 6),
    negotiable: false,
    type: ListingType.apartment,
    specs: Specifications({
      'max_guests': 2,
      'bedrooms': 1,
      'beds': 1,
      'bathrooms': 1,
      'allows_pets': true,
    }),
  );
  final negotiableBtcListing = listing(
    suffix: 'neg-btc',
    title: 'God Test Negotiable BTC Stay',
    amount: DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(30000),
    ),
    negotiable: true,
    type: ListingType.villa,
    specs: Specifications({
      'max_guests': 6,
      'bedrooms': 3,
      'beds': 4,
      'bathrooms': 2,
      'beachfront': true,
      'kitchen': true,
      'allows_pets': true,
    }),
  );
  final negotiableUsdListing = listing(
    suffix: 'neg-usd',
    title: 'God Test Negotiable USDT Stay',
    amount: DenominatedAmount.fromDecimal('20', 'USD', 6),
    negotiable: true,
    type: ListingType.room,
    specs: Specifications({
      'max_guests': 1,
      'bedrooms': 1,
      'beds': 1,
      'bathrooms': 1,
      'beachfront': true,
    }),
  );
  final listings = [
    btcListing,
    usdListing,
    negotiableBtcListing,
    negotiableUsdListing,
  ];
  await _publishListingFixtures(hostr, listings);

  return _GodFixtures(
    hostKeyPair: host.keyPair,
    hostEscrowMethod: hostEscrowMethod,
    btcListing: btcListing,
    usdListing: usdListing,
    negotiableBtcListing: negotiableBtcListing,
    negotiableUsdListing: negotiableUsdListing,
    filterListings: listings,
    escrowService: escrowService,
  );
}

Future<void> _publishListingFixtures(
  Hostr hostr,
  List<Listing> listings,
) async {
  var missing = listings;
  for (var attempt = 0; attempt < 4 && missing.isNotEmpty; attempt++) {
    for (final listing in missing) {
      try {
        await hostr.listings.upsert(listing);
      } catch (error, stackTrace) {
        // In web e2e runs NDK can occasionally complete broadcastDoneFuture
        // before the delayed relay OK is observed. Fixture setup verifies by
        // querying the relay below, so keep retrying unless the listing never
        // becomes visible.
        debugPrint(
          'Listing fixture publish attempt failed for ${listing.id}: '
          '$error\n$stackTrace',
        );
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final published = await hostr.listings.list(
      Filter(ids: listings.map((listing) => listing.id).toList()),
      name: 'god-listing-fixture-verify',
    );
    final publishedIds = published.map((listing) => listing.id).toSet();
    missing = listings
        .where((listing) => !publishedIds.contains(listing.id))
        .toList(growable: false);
  }
  if (missing.isNotEmpty) {
    throw StateError(
      'Could not publish listing fixtures to relay: '
      '${missing.map((listing) => listing.title).join(', ')}',
    );
  }
}

// Kept as the future threaded god-test scaffold; smaller tests below exercise
// the same steps independently.
// ignore: unused_element
Future<void> _runJourney({
  required WidgetTester tester,
  required AppRouter router,
  required Hostr hostr,
  required IntegrationTestHarness harness,
  required _GodFixtures fixtures,
  required _ApprovalDriver approvalDriver,
  required KeyPair walletUser,
  required String label,
}) async {
  var activeRouter = router;
  final reservationResults = <_ReservationJourneyResult>[];
  await _ensureBuyerEscrowPrerequisites(hostr: hostr, fixtures: fixtures);
  _godStep('$label reserve USDT');
  var reservationResult = await _reserveListing(
    tester: tester,
    router: activeRouter,
    listing: fixtures.usdListing,
    label: '$label-usdt-reservation',
  );
  activeRouter = reservationResult.router;
  reservationResults.add(reservationResult);
  _godStep('$label reserve BTC');
  reservationResult = await _reserveListing(
    tester: tester,
    router: activeRouter,
    listing: fixtures.btcListing,
    label: '$label-btc-reservation',
  );
  activeRouter = reservationResult.router;
  reservationResults.add(reservationResult);
  _godStep('$label negotiate USDT');
  reservationResult = await _reserveListing(
    tester: tester,
    router: activeRouter,
    listing: fixtures.negotiableUsdListing,
    label: '$label-negotiated-usdt',
    negotiatedDigits: '15',
  );
  activeRouter = reservationResult.router;
  reservationResults.add(reservationResult);
  _godStep('$label negotiate BTC');
  reservationResult = await _reserveListing(
    tester: tester,
    router: activeRouter,
    listing: fixtures.negotiableBtcListing,
    label: '$label-negotiated-btc',
    negotiatedDigits: '25000',
  );
  activeRouter = reservationResult.router;
  reservationResults.add(reservationResult);

  await _exerciseCounterNegotiation(
    tester: tester,
    router: activeRouter,
    hostr: hostr,
    hostKeyPair: fixtures.hostKeyPair,
    reservation: reservationResults[2],
  );
  await _exerciseCounterNegotiation(
    tester: tester,
    router: activeRouter,
    hostr: hostr,
    hostKeyPair: fixtures.hostKeyPair,
    reservation: reservationResults[3],
  );
  _godStep('$label pay reservations');
  for (final reservation in reservationResults) {
    _godStep('$label pay ${reservation.listing.title} ${reservation.tradeId}');
    await _payReservationWithExternalAlby(
      tester: tester,
      router: activeRouter,
      hostr: hostr,
      harness: harness,
      reservation: reservation,
    );
  }
  await _assertTripsPageContainsReservations(
    tester,
    activeRouter,
    reservationResults,
  );
  await _settle(tester, frames: 180);
  final cancellableReservation = await _reserveListing(
    tester: tester,
    router: activeRouter,
    listing: fixtures.usdListing,
    label: '$label-cancellable-usdt',
  );
  activeRouter = cancellableReservation.router;
  _godStep('$label chat and cancel');
  await _sendThreadMessage(tester, approvalDriver);
  await _cancelPendingReservation(
    tester,
    tradeId: cancellableReservation.tradeId,
    actor: 'guest',
  );
  _godStep('$label arbitration');
  await _backendArbitrateInFavorOfUser(
    harness: harness,
    hostr: hostr,
    escrowService: fixtures.escrowService,
  );
  await _assertBalancePageAndAutomaticSwapOut(
    tester,
    activeRouter,
    hostr,
    fixtures.escrowService,
  );
  _godStep('$label edit profile/listing');
  await _editProfile(tester, activeRouter, label);
  final created = await _createListing(tester, activeRouter, label);
  await _editListing(tester, activeRouter, created, label);
  await _createBackendPendingRequestAndCancelAsHost(
    tester: tester,
    router: activeRouter,
    harness: harness,
    hostr: hostr,
    listing: created,
    label: label,
  );
  await _createBackendBookingAndAssertHostings(
    tester: tester,
    router: activeRouter,
    harness: harness,
    hostr: hostr,
    fixtures: fixtures,
    hostKeyPair: walletUser,
    listing: created,
    label: label,
  );
  _godStep('$label explore filters');
  await _exerciseExploreFilters(
    tester,
    activeRouter,
    hostr,
    fixtures.filterListings,
  );
}

Future<void> _ensureBuyerEscrowPrerequisites({
  required Hostr hostr,
  required _GodFixtures fixtures,
}) async {
  await hostr.identityClaims.ensureEvmAddress();
  await _assertMutualEscrowAvailable(hostr: hostr, fixtures: fixtures);
}

Future<void> _assertMutualEscrowAvailable({
  required Hostr hostr,
  required _GodFixtures fixtures,
}) async {
  final buyerPubkey = hostr.auth.activeKeyPair?.publicKey;
  if (buyerPubkey == null) {
    throw StateError('Cannot check mutual escrow without an active buyer');
  }

  final sellerPubkey = fixtures.hostKeyPair.publicKey;
  final result = await hostr.escrows.determineMutualEscrow(
    buyerPubkey,
    sellerPubkey,
  );
  final seededServices = await hostr.escrows.list(
    Filter(
      kinds: EscrowService.kinds,
      authors: [fixtures.escrowService.pubKey],
    ),
    name: 'god-debug-escrow-service',
  );
  final sellerMethod = result.sellerMethod;
  final buyerMethod = result.buyerMethod;
  final debugDetails = [
    'buyer=$buyerPubkey',
    'seller=$sellerPubkey',
    'buyerMethod=${buyerMethod?.id}',
    'buyerTrusted=${buyerMethod?.trustedEscrowPubkeys}',
    'buyerHashes=${buyerMethod?.supportedContractBytecodeHashes}',
    'sellerMethod=${sellerMethod?.id}',
    'sellerTrusted=${sellerMethod?.trustedEscrowPubkeys}',
    'sellerHashes=${sellerMethod?.supportedContractBytecodeHashes}',
    'expectedSellerMethod=${fixtures.hostEscrowMethod.id}',
    'seededServicePubkey=${fixtures.escrowService.pubKey}',
    'seededServiceHash=${fixtures.escrowService.contractBytecodeHash}',
    'queriedServices=${seededServices.map((e) => '${e.pubKey}:${e.contractBytecodeHash}').toList()}',
    'compatible=${result.compatibleServices.map((e) => '${e.pubKey}:${e.contractBytecodeHash}').toList()}',
  ].join(' | ');
  debugPrint('GOD_ESCROW_PREFLIGHT $debugDetails');

  if (result.compatibleServices.isEmpty) {
    throw StateError('No compatible escrow for god journey. $debugDetails');
  }
}

Future<void> _withFreshApp(
  WidgetTester tester,
  Future<void> Function(AppRouter router) body,
) async {
  debugPrint('GOD_STEP withFreshApp:start');
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  debugPrint('GOD_STEP withFreshApp:clear-navigation');
  getIt<PendingNavigation>().clear();
  final hostr = getIt<Hostr>();
  debugPrint('GOD_STEP withFreshApp:stop-session');
  await _stopUserSession(hostr);
  debugPrint('GOD_STEP withFreshApp:logout');
  await hostr.auth.logout();
  debugPrint('GOD_STEP withFreshApp:pump-app');
  await tester.pumpWidget(const SizedBox.shrink());
  await _settle(tester, frames: 4);
  resetBrowserRouteForE2e();
  final router = AppRouter();
  await mockNetworkImages(() async {
    await tester.pumpWidget(MyApp(key: UniqueKey(), appRouter: router));
    await _settle(tester);
    debugPrint('GOD_STEP withFreshApp:body');
    await body(router);
  });
  debugPrint('GOD_STEP withFreshApp:done');
}

Future<void> _withSignedInUser({
  required WidgetTester tester,
  required IntegrationTestHarness harness,
  required SignetTestController signet,
  required E2eLoginMode loginMode,
  required String profileName,
  required Future<void> Function(_E2eSession session) body,
}) async {
  await _withFreshApp(tester, (router) async {
    debugPrint('GOD_STEP signedInUser:start ${loginMode.label} $profileName');
    late final KeyPair user;
    _ApprovalDriver? approvals;
    String? signetKeyName;
    var ownsSignetKey = false;

    try {
      switch (loginMode) {
        case E2eLoginMode.nsec:
          debugPrint('GOD_STEP signedInUser:create-nsec');
          user = Bip340.generatePrivateKey();
          approvals = _NoopApprovalDriver();
          debugPrint('GOD_STEP signedInUser:publish-profile');
          await _publishProfileFor(harness, user, profileName);
          debugPrint('GOD_STEP signedInUser:sign-in-nsec');
          await _signInWithPrivateKeyUi(tester, router, user);
        case E2eLoginMode.bunker:
          debugPrint('GOD_STEP signedInUser:create-bunker');
          final signetUser = await signet.createRandomUser(
            prefix: 'hostr-${loginMode.label}',
          );
          ownsSignetKey = true;
          signetKeyName = signetUser.keyName;
          user = signetUser.keyPair;
          debugPrint('GOD_STEP signedInUser:publish-profile');
          await _publishProfileFor(harness, user, profileName);
          final signetApprovals = _SignetApprovalDriver(
            signet: signet,
            keyName: signetUser.keyName,
          );
          approvals = signetApprovals;
          debugPrint('GOD_STEP signedInUser:start-approvals');
          await signetApprovals.start();
          debugPrint('GOD_STEP signedInUser:sign-in-bunker');
          await _signInWithNostrConnectUi(tester, router, signet, signetUser);
      }

      debugPrint('GOD_STEP signedInUser:seed-fixtures');
      final fixtures = await _seedFixtures(harness);
      debugPrint('GOD_STEP signedInUser:seed-fixtures:done');
      debugPrint('GOD_STEP signedInUser:wait-ready:start');
      await _waitForSignedInShellReady(tester, expectedPubkey: user.publicKey);
      debugPrint('GOD_STEP signedInUser:wait-ready:done');
      debugPrint('GOD_STEP signedInUser:body:start');
      await body(
        _E2eSession(
          tester: tester,
          router: router,
          hostr: getIt<Hostr>(),
          harness: harness,
          fixtures: fixtures,
          approvals: approvals,
          user: user,
          label: loginMode.label,
        ),
      );
      debugPrint('GOD_STEP signedInUser:done ${loginMode.label} $profileName');
    } finally {
      try {
        debugPrint(
          'GOD_STEP signedInUser:stop-session ${loginMode.label} $profileName',
        );
        await _stopUserSession(getIt<Hostr>());
      } catch (error) {
        debugPrint(
          'GOD_STEP signedInUser:stop-session-error '
          '${loginMode.label} $profileName $error',
        );
      }
      if (loginMode == E2eLoginMode.bunker) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await approvals?.stop();
      }
      final keyName = signetKeyName;
      if (keyName != null) {
        try {
          if (ownsSignetKey) {
            await signet.deleteKey(keyName);
          } else {
            await signet.revokeAppsForKey(keyName);
          }
        } catch (error) {
          debugPrint(
            'GOD_STEP signet:cleanup-key-error key=$keyName '
            'delete=$ownsSignetKey $error',
          );
        }
      }
    }
  });
}

Future<void> _assertLoginRoutingMatrixForMode({
  required WidgetTester tester,
  required AppRouter router,
  required IntegrationTestHarness harness,
  required _GodFixtures fixtures,
  required SignetTestController signet,
  required E2eLoginMode loginMode,
}) async {
  final cases = [
    (hasMetadata: true, hasContinue: false),
    (hasMetadata: true, hasContinue: true),
    (hasMetadata: false, hasContinue: false),
    (hasMetadata: false, hasContinue: true),
  ];
  final continueRouteTimeout = loginMode == E2eLoginMode.bunker
      ? const Duration(minutes: 2)
      : const Duration(seconds: 60);

  for (final testCase in cases) {
    debugPrint(
      'GOD_STEP loginMatrix:${loginMode.label}:case metadata=${testCase.hasMetadata} continue=${testCase.hasContinue}:start',
    );
    final userLabel =
        'God Login ${loginMode.label} metadata=${testCase.hasMetadata} continue=${testCase.hasContinue}';
    final user = await _createLoginUser(
      harness: harness,
      signet: signet,
      loginMode: loginMode,
      profileName: userLabel,
      publishProfile: testCase.hasMetadata,
    );
    final approvals = user.approvals;

    try {
      if (testCase.hasContinue) {
        getIt<PendingNavigation>().set(
          ListingRoute(a: fixtures.usdListing.naddr()!),
        );
      } else {
        getIt<PendingNavigation>().clear();
      }

      await _signInCreatedUser(tester, router, signet, user);
      if (testCase.hasMetadata && testCase.hasContinue) {
        await _waitForText(
          tester,
          fixtures.usdListing.title,
          timeout: continueRouteTimeout,
        );
      } else if (testCase.hasMetadata) {
        await _waitFor(
          tester,
          () =>
              find.byKey(const ValueKey('ready')).evaluate().isNotEmpty &&
              find
                  .byKey(const ValueKey('edit_profile_name_input'))
                  .evaluate()
                  .isEmpty,
          timeout: const Duration(seconds: 60),
          reason: 'existing metadata should not route to profile completion',
        );
      } else {
        await _waitForKey(
          tester,
          const ValueKey('edit_profile_name_input'),
          timeout: const Duration(seconds: 60),
          reasonBuilder: () => _visibleTextSnapshot(
            tester,
            'missing metadata should route to profile completion',
          ),
        );
        await _completeRequiredProfile(tester, userLabel);
        if (testCase.hasContinue) {
          await _waitForText(
            tester,
            fixtures.usdListing.title,
            timeout: continueRouteTimeout,
          );
        } else {
          await _waitForText(tester, userLabel);
        }
      }

      await _signOut(tester, router, getIt<Hostr>());
    } finally {
      getIt<PendingNavigation>().clear();
      await approvals.stop();
      final signetUser = user.signetUser;
      if (signetUser != null) {
        try {
          await signet.deleteKey(signetUser.keyName);
        } catch (error) {
          debugPrint(
            'GOD_STEP signet:delete-key-error key=${signetUser.keyName} '
            '$error',
          );
        }
      }
    }
    debugPrint(
      'GOD_STEP loginMatrix:${loginMode.label}:case metadata=${testCase.hasMetadata} continue=${testCase.hasContinue}:done',
    );
  }
}

class _CreatedLoginUser {
  final E2eLoginMode loginMode;
  final KeyPair keyPair;
  final SignetTestUser? signetUser;
  final _ApprovalDriver approvals;

  const _CreatedLoginUser({
    required this.loginMode,
    required this.keyPair,
    required this.signetUser,
    required this.approvals,
  });

  Future<void> delete() async {}
}

Future<_CreatedLoginUser> _createLoginUser({
  required IntegrationTestHarness harness,
  required SignetTestController signet,
  required E2eLoginMode loginMode,
  required String profileName,
  required bool publishProfile,
}) async {
  switch (loginMode) {
    case E2eLoginMode.nsec:
      final keyPair = Bip340.generatePrivateKey();
      if (publishProfile) {
        await _publishProfileFor(harness, keyPair, profileName);
      }
      return _CreatedLoginUser(
        loginMode: loginMode,
        keyPair: keyPair,
        signetUser: null,
        approvals: _NoopApprovalDriver(),
      );
    case E2eLoginMode.bunker:
      final signetUser = await signet.createRandomUser(prefix: 'hostr-login');
      if (publishProfile) {
        await _publishProfileFor(harness, signetUser.keyPair, profileName);
      }
      final approvals = _SignetApprovalDriver(
        signet: signet,
        keyName: signetUser.keyName,
      );
      await approvals.start();
      return _CreatedLoginUser(
        loginMode: loginMode,
        keyPair: signetUser.keyPair,
        signetUser: signetUser,
        approvals: approvals,
      );
  }
}

Future<void> _signInCreatedUser(
  WidgetTester tester,
  AppRouter router,
  SignetTestController signet,
  _CreatedLoginUser user,
) async {
  switch (user.loginMode) {
    case E2eLoginMode.nsec:
      await _signInWithPrivateKeyUi(tester, router, user.keyPair);
    case E2eLoginMode.bunker:
      await _signInWithNostrConnectUi(tester, router, signet, user.signetUser!);
  }
}

// ignore: unused_element
Future<void> _runReservationMatrix(_E2eSession session) async {
  _godStep('${session.label} reservation-matrix:escrow-prereqs:start');
  await _ensureBuyerEscrowPrerequisites(
    hostr: session.hostr,
    fixtures: session.fixtures,
  );
  _godStep('${session.label} reservation-matrix:escrow-prereqs:done');
  final reservations = <_ReservationJourneyResult>[];
  final cases = [
    (listing: session.fixtures.usdListing, digits: null),
    (listing: session.fixtures.btcListing, digits: null),
    (listing: session.fixtures.negotiableUsdListing, digits: '15'),
    (listing: session.fixtures.negotiableBtcListing, digits: '25000'),
  ];
  for (final testCase in cases) {
    _godStep(
      '${session.label} reservation-matrix:reserve:${testCase.listing.title}:start',
    );
    final reservation = await _reserveListing(
      tester: session.tester,
      router: session.router,
      listing: testCase.listing,
      label: '${session.label}-${testCase.listing.id}',
      negotiatedDigits: testCase.digits,
    );
    reservations.add(reservation);
    _godStep(
      '${session.label} reservation-matrix:reserve:${testCase.listing.title}:done:${reservation.tradeId}',
    );
  }
  _godStep('${session.label} reservation-matrix:counter:usd:start');
  await _exerciseCounterNegotiation(
    tester: session.tester,
    router: session.router,
    hostr: session.hostr,
    hostKeyPair: session.fixtures.hostKeyPair,
    reservation: reservations[2],
  );
  _godStep('${session.label} reservation-matrix:counter:usd:done');
  _godStep('${session.label} reservation-matrix:counter:btc:start');
  await _exerciseCounterNegotiation(
    tester: session.tester,
    router: session.router,
    hostr: session.hostr,
    hostKeyPair: session.fixtures.hostKeyPair,
    reservation: reservations[3],
  );
  _godStep('${session.label} reservation-matrix:counter:btc:done');
  for (final reservation in reservations) {
    _godStep(
      '${session.label} reservation-matrix:pay:${reservation.listing.title}:start:${reservation.tradeId}',
    );
    await _payReservationWithExternalAlby(
      tester: session.tester,
      router: session.router,
      hostr: session.hostr,
      harness: session.harness,
      reservation: reservation,
    );
    _godStep(
      '${session.label} reservation-matrix:pay:${reservation.listing.title}:done:${reservation.tradeId}',
    );
  }
  _godStep('${session.label} reservation-matrix:trips:start');
  await _assertTripsPageContainsReservations(
    session.tester,
    session.router,
    reservations,
  );
  _godStep('${session.label} reservation-matrix:trips:done');
}

Future<void> _runReservationCase(
  _E2eSession session,
  E2eReservationCase reservationCase,
) async {
  _godStep('${session.label} reservation:${reservationCase.name}:start');
  _godStep(
    '${session.label} reservation:${reservationCase.name}:escrow-prereqs',
  );
  await _ensureBuyerEscrowPrerequisites(
    hostr: session.hostr,
    fixtures: session.fixtures,
  );
  _godStep(
    '${session.label} reservation:${reservationCase.name}:escrow-prereqs:done',
  );

  final (:listing, :negotiatedDigits) = switch (reservationCase) {
    E2eReservationCase.usd => (
      listing: session.fixtures.usdListing,
      negotiatedDigits: null,
    ),
    E2eReservationCase.btc => (
      listing: session.fixtures.btcListing,
      negotiatedDigits: null,
    ),
    E2eReservationCase.negotiatedUsd => (
      listing: session.fixtures.negotiableUsdListing,
      negotiatedDigits: '15',
    ),
    E2eReservationCase.negotiatedBtc => (
      listing: session.fixtures.negotiableBtcListing,
      negotiatedDigits: '25000',
    ),
  };

  final reservation = await _reserveListing(
    tester: session.tester,
    router: session.router,
    listing: listing,
    label: '${session.label}-${reservationCase.name}',
    negotiatedDigits: negotiatedDigits,
  );

  if (reservationCase == E2eReservationCase.negotiatedUsd ||
      reservationCase == E2eReservationCase.negotiatedBtc) {
    await _exerciseCounterNegotiation(
      tester: session.tester,
      router: session.router,
      hostr: session.hostr,
      hostKeyPair: session.fixtures.hostKeyPair,
      reservation: reservation,
    );
  }

  await _payReservationWithExternalAlby(
    tester: session.tester,
    router: session.router,
    hostr: session.hostr,
    harness: session.harness,
    reservation: reservation,
  );

  await _assertTripsPageContainsReservations(session.tester, session.router, [
    reservation,
  ]);
  _godStep('${session.label} reservation:${reservationCase.name}:done');
}

Future<void> _runSubscriptionLifecycleCase(_E2eSession session) async {
  final tester = session.tester;
  _godStep('${session.label} subscriptions:lifecycle:start');
  await _navigateToTabRoute(
    tester,
    session.router,
    const ExploreRoute(),
    routeName: ExploreRoute.name,
  );
  await _waitForExploreListToSettle(tester);

  final baseline = await _waitForStableNostrSubscriptionSnapshot(
    tester: tester,
    hostr: session.hostr,
    label: '${session.label} subscriptions:lifecycle:baseline',
  );
  expect(
    baseline.liveCount,
    greaterThan(0),
    reason:
        'Logged-in app should have intentional baseline live '
        'subscriptions.\n${baseline.dump()}',
  );
  _godStep(
    '${session.label} subscriptions:lifecycle:baseline '
    'live=${baseline.liveCount} queries=${baseline.queryCount}',
  );

  await _runReservationCase(session, E2eReservationCase.usd);
  final expectedAfterReservation =
      _expectedSubscriptionCountsAfterUsdReservation(baseline.liveCounts);

  await _navigateToTabRoute(
    tester,
    session.router,
    const ExploreRoute(),
    routeName: ExploreRoute.name,
  );
  await _waitForExploreListToSettle(tester);

  var after = _nostrSubscriptionSnapshot(session.hostr);
  await _waitFor(
    tester,
    () {
      after = _nostrSubscriptionSnapshot(session.hostr);
      return after.queryCounts.isEmpty &&
          _sameStringIntMap(after.liveCounts, expectedAfterReservation);
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _subscriptionSnapshotMismatchReason(
      baseline: baseline,
      expectedLiveCounts: expectedAfterReservation,
      actual: after,
      label: '${session.label} subscriptions:lifecycle:after',
    ),
  );
  _godStep(
    '${session.label} subscriptions:lifecycle:done '
    'live=${after.liveCount} queries=${after.queryCount}',
  );
}

Map<String, int> _expectedSubscriptionCountsAfterUsdReservation(
  Map<String, int> baseline,
) {
  final expected = Map<String, int>.of(baseline);

  // Creating the first reservation gives UserSubscriptions real trade IDs and
  // participants to track. These are intentional long-lived account streams,
  // not page-owned route subscriptions, so the lifecycle assertion allows
  // exactly one expansion for this single USD reservation journey.
  for (final name in const [
    'Reservation-user-reservations-live',
    'ReservationTransition-user-transitions-live',
    'ReceivedHeartbeat-user-heartbeats-live',
    'ZapReceipts-sub',
  ]) {
    expected[name] = (expected[name] ?? 0) + 1;
  }

  return expected;
}

Future<void> _runCancellationCase(
  _E2eSession session,
  E2eCancellationCase cancellationCase,
) async {
  _godStep('${session.label} cancellation:${cancellationCase.name}:start');
  await _ensureBuyerEscrowPrerequisites(
    hostr: session.hostr,
    fixtures: session.fixtures,
  );

  switch (cancellationCase) {
    case E2eCancellationCase.guestPending:
      final pending = await _reserveListing(
        tester: session.tester,
        router: session.router,
        listing: session.fixtures.negotiableUsdListing,
        label: '${session.label}-guest-cancel-pending',
        negotiatedDigits: '15',
      );
      await _cancelPendingReservation(
        session.tester,
        tradeId: pending.tradeId,
        actor: 'guest',
      );
    case E2eCancellationCase.guestLive:
      final live = await _reserveListing(
        tester: session.tester,
        router: session.router,
        listing: session.fixtures.usdListing,
        label: '${session.label}-guest-cancel-live',
      );
      await _payReservationWithExternalAlby(
        tester: session.tester,
        router: session.router,
        hostr: session.hostr,
        harness: session.harness,
        reservation: live,
      );
      await _cancelLiveReservation(
        session.tester,
        role: 'guest',
        tradeId: live.tradeId,
      );
    case E2eCancellationCase.hostPending:
      final created = await _createListing(
        session.tester,
        session.router,
        '${session.label}-host-pending-cancel',
      );
      await _createBackendPendingRequestAndCancelAsHost(
        tester: session.tester,
        router: session.router,
        harness: session.harness,
        hostr: session.hostr,
        listing: created,
        label: session.label,
      );
    case E2eCancellationCase.hostLive:
      final created = await _createListing(
        session.tester,
        session.router,
        '${session.label}-host-live-cancel',
      );
      final booking = await _createBackendLiveBooking(
        harness: session.harness,
        hostr: session.hostr,
        fixtures: session.fixtures,
        hostKeyPair: session.user,
        listing: created,
        label: session.label,
      );
      await _openThread(
        tester: session.tester,
        router: session.router,
        anchor: booking.threadAnchor,
      );
      await _cancelLiveReservation(
        session.tester,
        role: 'host',
        tradeId: booking.tradeId,
      );
  }
  _godStep('${session.label} cancellation:${cancellationCase.name}:done');
}

Future<void> _runHostBookingFlows(_E2eSession session) async {
  final created = await _createListing(
    session.tester,
    session.router,
    '${session.label}-host-flow',
  );
  await _createBackendPendingRequestAndCancelAsHost(
    tester: session.tester,
    router: session.router,
    harness: session.harness,
    hostr: session.hostr,
    listing: created,
    label: session.label,
  );
  await _createBackendBookingAndAssertHostings(
    tester: session.tester,
    router: session.router,
    harness: session.harness,
    hostr: session.hostr,
    fixtures: session.fixtures,
    hostKeyPair: session.user,
    listing: created,
    label: session.label,
  );
}

Future<void> _runReviewFlow(_E2eSession session) async {
  _godStep('review:backend-booking:start');
  final booking = await _createBackendCompletedReviewBooking(
    harness: session.harness,
    hostr: session.hostr,
    listing: session.fixtures.usdListing,
    guestIdentityKeyPair: session.user,
    hostKeyPair: session.fixtures.hostKeyPair,
    label: '${session.label}-review',
  );
  _godStep('review:backend-booking:done:${booking.tradeId}');
  _godStep('review:open-thread:start:${booking.threadAnchor}');
  await _openThread(
    tester: session.tester,
    router: session.router,
    anchor: booking.threadAnchor,
  );
  _godStep('review:open-thread:done:${booking.threadAnchor}');
  _godStep('review:add:start:${booking.tradeId}');
  await _addReviewForReservation(
    session.tester,
    _ReservationJourneyResult(
      router: session.router,
      listing: session.fixtures.usdListing,
      threadAnchor: booking.threadAnchor,
      tradeId: booking.tradeId,
    ),
  );
  _godStep('review:add:done:${booking.tradeId}');
}

// ignore: unused_element
Future<void> _assertSignInRoutingMatrix({
  required WidgetTester tester,
  required AppRouter router,
  required IntegrationTestHarness harness,
  required _GodFixtures fixtures,
}) async {
  final pendingNavigation = getIt<PendingNavigation>();

  pendingNavigation.clear();
  var user = Bip340.generatePrivateKey();
  await _publishProfileFor(harness, user, 'God Existing Metadata');
  await _signInWithPrivateKeyUi(tester, router, user);
  await _waitFor(
    tester,
    () =>
        find.byKey(const ValueKey('ready')).evaluate().isNotEmpty &&
        find
            .byKey(const ValueKey('edit_profile_name_input'))
            .evaluate()
            .isEmpty,
    timeout: const Duration(seconds: 60),
    reason: 'existing metadata should not route to profile completion',
  );
  await _signOut(tester, router, getIt<Hostr>());

  pendingNavigation.set(ListingRoute(a: fixtures.btcListing.naddr()!));
  user = Bip340.generatePrivateKey();
  await _publishProfileFor(harness, user, 'God Existing Pending Metadata');
  await _signInWithPrivateKeyUi(tester, router, user);
  await _waitForText(
    tester,
    fixtures.btcListing.title,
    timeout: const Duration(seconds: 60),
  );
  await _signOut(tester, router, getIt<Hostr>());

  pendingNavigation.clear();
  user = Bip340.generatePrivateKey();
  await _signInWithPrivateKeyUi(tester, router, user);
  await _waitForKey(
    tester,
    const ValueKey('edit_profile_name_input'),
    timeout: const Duration(seconds: 60),
    reason: 'missing metadata without pending action should route to profile',
  );
  await _completeRequiredProfile(tester, 'God Missing Metadata');
  await _waitForText(tester, 'God Missing Metadata');
  await _signOut(tester, router, getIt<Hostr>());

  pendingNavigation.set(ListingRoute(a: fixtures.usdListing.naddr()!));
  user = Bip340.generatePrivateKey();
  await _signInWithPrivateKeyUi(tester, router, user);
  await _waitForKey(
    tester,
    const ValueKey('edit_profile_name_input'),
    timeout: const Duration(seconds: 60),
    reason:
        'missing metadata with pending action should first route to profile',
  );
  await _completeRequiredProfile(tester, 'God Missing Metadata Pending');
  await _waitForText(
    tester,
    fixtures.usdListing.title,
    timeout: const Duration(seconds: 60),
  );
  await _signOut(tester, router, getIt<Hostr>());
  pendingNavigation.clear();
}

Future<void> _completeRequiredProfile(WidgetTester tester, String name) async {
  await tester.enterText(
    find.byKey(const ValueKey('edit_profile_name_input')),
    name,
  );
  await _tapSave(tester, const ValueKey('edit_profile_save_button'));
}

Future<void> _signInWithPrivateKeyUi(
  WidgetTester tester,
  AppRouter router,
  KeyPair keyPair,
) async {
  await _navigateToSignIn(tester, router, label: 'signInPrivate');
  debugPrint('GOD_STEP signInPrivate:screen-visible');
  final manualTab = find.byKey(const ValueKey('signin_tab_manual'));
  if (manualTab.evaluate().isNotEmpty) {
    await _tapKey(tester, manualTab);
  }
  final keyField = find
      .byKey(const ValueKey('signin_private_key_input'))
      .hitTestable();
  final loginButton = find.byKey(const ValueKey('signin_manual_login_button'));
  await _waitFor(
    tester,
    () => keyField.evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'private key field should be visible'),
  );
  debugPrint('GOD_STEP signInPrivate:enter-key');
  await tester.tap(keyField.first, warnIfMissed: false);
  await tester.enterText(keyField.first, keyPair.privateKey!);
  await _waitFor(
    tester,
    () => tester.widget<FilledButton>(loginButton).onPressed != null,
    timeout: const Duration(seconds: 10),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'manual login button should enable'),
  );
  debugPrint('GOD_STEP signInPrivate:tap-login');
  await _tapKey(tester, loginButton);
  await _waitFor(
    tester,
    () => getIt<Hostr>().auth.authState.value is LoggedIn,
    timeout: const Duration(seconds: 60),
    reason: _visibleTextSnapshot(tester, 'manual sign-in did not complete'),
  );
  debugPrint('GOD_STEP signInPrivate:logged-in');
}

Future<void> _publishProfileFor(
  IntegrationTestHarness harness,
  KeyPair keyPair,
  String name,
) async {
  final lud16 = await harness.createLnbitsPayLink(
    username:
        'e2e-${keyPair.publicKey.substring(0, 16)}-${DateTime.now().microsecondsSinceEpoch}',
  );
  final profile = await harness.seeds.entities.profile(
    signer: keyPair,
    name: name,
    displayName: name,
    lud16: lud16,
  );
  await harness.hostr.metadata.upsert(profile);
  await harness.hostr.ndk.config.cache.saveMetadata(profile.metadata);
  final readback = await harness.hostr.metadata
      .loadMetadata(keyPair.publicKey, forceRefresh: true)
      .timeout(const Duration(seconds: 20), onTimeout: () => null);
  debugPrint(
    'GOD_STEP publishProfile:readback '
    'pubkey=${keyPair.publicKey} found=${readback != null} name=$name',
  );
  if (readback == null) {
    throw StateError(
      'Published profile for ${keyPair.publicKey} was not readable before sign-in',
    );
  }
}

Future<void> _signInWithNostrConnectUi(
  WidgetTester tester,
  AppRouter router,
  SignetTestController signet,
  SignetTestUser user,
) async {
  await _navigateToSignIn(tester, router, label: 'signInBunker');
  debugPrint('GOD_STEP signInBunker:screen-visible');
  var uri = await _waitForNostrConnectUri(tester);
  expect(uri.startsWith('nostrconnect://'), isTrue);
  debugPrint('GOD_STEP signInBunker:connect');
  var connectAttempt = 0;
  var nextConnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? lastSentAt;
  int? lastSentAppId;

  Future<void> refreshNostrConnectUri(String reason, {int? revokeAppId}) async {
    debugPrint('GOD_STEP signInBunker:refresh-uri reason=$reason');
    if (revokeAppId != null) {
      try {
        await signet.revokeApp(revokeAppId);
        debugPrint('GOD_STEP signInBunker:revoked-refresh-app $revokeAppId');
      } catch (error) {
        debugPrint(
          'GOD_STEP signInBunker:revoke-refresh-app-error '
          '$revokeAppId $error',
        );
      }
    }
    final stateFinder = find.byType(SignInScreen);
    if (stateFinder.evaluate().isEmpty) {
      await _replaceWithSignIn(tester, router);
    } else {
      await tester.state<SignInScreenState>(stateFinder).restartNostrConnect();
      await _settle(tester, frames: 10);
    }
    await _waitFor(
      tester,
      () {
        final refreshedUri = _currentNostrConnectUri(tester);
        return refreshedUri != null && refreshedUri != uri;
      },
      timeout: const Duration(seconds: 30),
      reasonBuilder: () => _visibleTextSnapshot(
        tester,
        'nostrconnect URI should rotate after refresh',
      ),
    );
    final refreshedUri = await _waitForNostrConnectUri(tester);
    debugPrint(
      'GOD_STEP signInBunker:refresh-uri:done '
      'changed=${refreshedUri != uri}',
    );
    uri = refreshedUri;
    connectAttempt = 0;
    lastSentAt = null;
    lastSentAppId = null;
    nextConnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  await _approveSignetRequestsUntil(
    tester,
    signet: signet,
    keyName: user.keyName,
    condition: () => getIt<Hostr>().auth.authState.value is LoggedIn,
    timeout: const Duration(minutes: 2),
    beforePoll: () async {
      final displayedUri = _currentNostrConnectUri(tester);
      if (displayedUri != null && displayedUri != uri) {
        debugPrint('GOD_STEP signInBunker:uri-rotated');
        uri = displayedUri;
        connectAttempt = 0;
        lastSentAt = null;
        lastSentAppId = null;
        nextConnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
      }
      final now = DateTime.now();
      final sentAt = lastSentAt;
      if (sentAt != null &&
          now.difference(sentAt) >= const Duration(seconds: 20)) {
        await refreshNostrConnectUri(
          'sent-response-timeout',
          revokeAppId: lastSentAppId,
        );
        return;
      }
      if (now.isBefore(nextConnectAttempt)) return;
      connectAttempt++;
      debugPrint('GOD_STEP signInBunker:connect-attempt=$connectAttempt');
      try {
        final response = await signet.connectNostrConnect(
          uri: uri,
          keyName: user.keyName,
        );
        final appId = _jsonInt(response['appId']);
        final responseSent = response['connectResponseSent'] == true;
        debugPrint(
          'GOD_STEP signInBunker:connect-response '
          'appId=$appId sent=$responseSent '
          'error=${response['connectResponseError']}',
        );
        if (!responseSent) {
          if (appId != null) {
            await signet.revokeApp(appId);
            debugPrint('GOD_STEP signInBunker:revoked-unsent-app $appId');
          }
          nextConnectAttempt = now.add(const Duration(seconds: 1));
          return;
        }
        lastSentAt = now;
        lastSentAppId = appId;
        nextConnectAttempt = now.add(const Duration(seconds: 20));
      } on SignetHttpException catch (e) {
        debugPrint('GOD_STEP signInBunker:connect-error $e');
        if (e.statusCode == 409 && e.message.contains('already_connected')) {
          final appId = _existingAppIdFromSignetError(e.message);
          if (appId != null) {
            await refreshNostrConnectUri(
              'already-connected',
              revokeAppId: appId,
            );
          } else {
            await signet.revokeAppsForKey(user.keyName);
            await refreshNostrConnectUri('already-connected-no-app');
          }
          return;
        }
        if (e.statusCode == 429 || e.message.contains('429')) {
          nextConnectAttempt = now.add(const Duration(seconds: 5));
          return;
        }
        rethrow;
      }
    },
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'nostrconnect sign-in did not complete'),
  );
  debugPrint('GOD_STEP signInBunker:logged-in');
}

Future<void> _navigateToSignIn(
  WidgetTester tester,
  AppRouter router, {
  required String label,
}) async {
  debugPrint('GOD_STEP $label:navigate');
  unawaited(router.navigate(const TabShellRoute(children: [SignInRoute()])));
  await _settle(tester, frames: 20);
  if (find.byType(SignInScreen).evaluate().isEmpty) {
    final navKey = find.byKey(const ValueKey('app_nav_SignInRoute'));
    if (navKey.evaluate().isNotEmpty) {
      await _tapKey(tester, navKey);
      await _settle(tester, frames: 20);
    }
  }
  if (find.byType(SignInScreen).evaluate().isEmpty) {
    await _replaceWithSignIn(tester, router);
  }
  await _waitFor(
    tester,
    () => find.byType(SignInScreen).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 90),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'SignInScreen should be visible'),
  );
}

Future<void> _replaceWithSignIn(WidgetTester tester, AppRouter router) async {
  await router.replaceAll([
    const RootRoute(
      children: [
        StartupShellRoute(
          children: [
            AppShellRoute(
              children: [
                TabShellRoute(children: [SignInRoute()]),
              ],
            ),
          ],
        ),
      ],
    ),
  ]);
  await _settle(tester, frames: 20);
  await _waitFor(
    tester,
    () => find.byType(SignInScreen).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 90),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'SignInScreen should be visible'),
  );
}

Future<void> _waitForSignedInShellReady(
  WidgetTester tester, {
  String? expectedPubkey,
}) async {
  var lastLog = DateTime.fromMillisecondsSinceEpoch(0);
  await _waitFor(
    tester,
    () {
      final hasStartupReadyGate = find
          .byKey(const ValueKey('ready'))
          .evaluate()
          .isNotEmpty;
      final hasRenderedAppNav = find
          .byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> && key.value.startsWith('app_nav_');
          })
          .evaluate()
          .isNotEmpty;
      final now = DateTime.now();
      if (now.difference(lastLog) >= const Duration(seconds: 5)) {
        lastLog = now;
        debugPrint(
          'GOD_STEP signedInUser:wait-ready:state '
          '${_signedInShellReadySnapshot(tester, expectedPubkey: expectedPubkey)}',
        );
      }

      return getIt<Hostr>().auth.authState.value is LoggedIn &&
          (hasStartupReadyGate || hasRenderedAppNav) &&
          find.byType(SignInScreen).evaluate().isEmpty &&
          find
              .byKey(const ValueKey('edit_profile_name_input'))
              .evaluate()
              .isEmpty;
    },
    timeout: const Duration(minutes: 2),
    reasonBuilder: () => _signedInShellReadySnapshot(
      tester,
      expectedPubkey: expectedPubkey,
      prefix: 'signed-in session should land on the app shell',
    ),
  );
}

String _signedInShellReadySnapshot(
  WidgetTester tester, {
  String? expectedPubkey,
  String prefix = 'shell readiness',
}) {
  final hostr = getIt<Hostr>();
  final authState = hostr.auth.authState.value;
  final activePubkey = hostr.auth.activePubkey;
  final startupStream = hostr.startup.snapshots;
  final startup = startupStream.hasValue
      ? _describeStartupSnapshot(startupStream.value)
      : 'startup=<none>';
  final hasReady = find.byKey(const ValueKey('ready')).evaluate().isNotEmpty;
  final appNavKeys = find
      .byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.startsWith('app_nav_');
      })
      .evaluate()
      .length;
  final signInScreens = find.byType(SignInScreen).evaluate().length;
  final editProfileInputs = find
      .byKey(const ValueKey('edit_profile_name_input'))
      .evaluate()
      .length;
  return [
    _visibleTextSnapshot(tester, prefix),
    'expectedPubkey=$expectedPubkey',
    'activePubkey=$activePubkey',
    'auth=${authState.runtimeType}',
    'ready=$hasReady',
    'appNavKeys=$appNavKeys',
    'signInScreens=$signInScreens',
    'editProfileInputs=$editProfileInputs',
    startup,
  ].join(' | ');
}

String _describeStartupSnapshot(StartupSnapshot snapshot) {
  final result = switch (snapshot.result) {
    null => 'result=null',
    UserStartupReady(:final pubkey, :final hasMetadata, :final inboxLive) =>
      'result=UserStartupReady(pubkey=$pubkey, hasMetadata=$hasMetadata, inboxLive=$inboxLive)',
    PublicStartupReady() => 'result=PublicStartupReady',
    BackgroundStartupReady(:final pubkey) =>
      'result=BackgroundStartupReady(pubkey=$pubkey)',
  };
  final items = snapshot.items
      .map((item) => '${item.id.name}:${item.state.name}')
      .join(',');
  return 'startup=scope=${snapshot.scope.name} $result items=[$items] error=${snapshot.error}';
}

Future<void> _approveSignetRequestsUntil(
  WidgetTester tester, {
  required SignetTestController signet,
  required String keyName,
  required FutureOr<bool> Function() condition,
  Duration timeout = const Duration(seconds: 30),
  Future<void> Function()? beforePoll,
  String Function()? reasonBuilder,
}) async {
  final deadline = DateTime.now().add(timeout);
  final submitted = <String>{};
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (await condition()) return;
    await beforePoll?.call();

    try {
      final pending = (await signet.requests())
          .where(
            (request) =>
                request.keyName == keyName && !submitted.contains(request.id),
          )
          .toList(growable: false);
      if (pending.isNotEmpty) {
        debugPrint(
          'GOD_STEP signet:approve-inline key=$keyName '
          'ids=${pending.map((request) => request.id).join(',')}',
        );
        await signet.approveBatch(pending);
        submitted.addAll(pending.map((request) => request.id));
      }
    } on SignetHttpException catch (e) {
      debugPrint('GOD_STEP signet:approve-inline-error $e');
      if (e.message.contains('429')) {
        submitted.clear();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 5)),
        );
      }
    }

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  }

  throw TimeoutException(
    reasonBuilder?.call() ?? 'condition was not met',
    timeout,
  );
}

Future<String> _waitForNostrConnectUri(WidgetTester tester) async {
  final uriText = find.byKey(const ValueKey('signin_nostrconnect_uri'));
  await _waitFor(
    tester,
    () => uriText.evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
  );
  return tester.widget<Text>(uriText).data!;
}

String? _currentNostrConnectUri(WidgetTester tester) {
  final uriText = find.byKey(const ValueKey('signin_nostrconnect_uri'));
  final elements = uriText.evaluate();
  if (elements.isEmpty) return null;
  return tester.widget<Text>(uriText).data;
}

int? _existingAppIdFromSignetError(String message) {
  final match = RegExp(r'"existingAppId"\s*:\s*(\d+)').firstMatch(message);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

int? _jsonInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Future<void> _signOut(
  WidgetTester tester,
  AppRouter router,
  Hostr hostr,
) async {
  await _stopUserSession(hostr);
  await hostr.auth.logout();
  await _navigateToSignIn(tester, router, label: 'signOut');
  expect(hostr.auth.authState.value, isNot(isA<LoggedIn>()));
}

Future<void> _stopUserSession(Hostr hostr) async {
  await _closeAllNostrSubscriptions(hostr, 'before-stop');
  await hostr.backgroundWorker.stop();
  await hostr.calendar.stop();
  await hostr.fundsMonitor.reset();
  await hostr.paymentProofOrchestrator.reset();
  await hostr.userSubscriptions.reset();
  await hostr.messaging.threads.reset();
  await hostr.nwc.reset();
  await hostr.reservations.reset();
  await _closeAllNostrSubscriptions(hostr, 'after-stop');
}

Future<void> _closeAllNostrSubscriptions(Hostr hostr, String phase) async {
  debugPrint('GOD_STEP stop-session:close-ndk-subscriptions:$phase:start');
  try {
    await hostr.ndk.requests.closeAllSubscription();
    debugPrint('GOD_STEP stop-session:close-ndk-subscriptions:$phase:done');
  } catch (error, stackTrace) {
    debugPrint(
      'GOD_STEP stop-session:close-ndk-subscriptions:$phase:error $error\n'
      '$stackTrace',
    );
  }
}

Future<_ReservationJourneyResult> _reserveListing({
  required WidgetTester tester,
  required AppRouter router,
  required Listing listing,
  required String label,
  String? negotiatedDigits,
}) async {
  final start = DateTime.now().toUtc().add(const Duration(days: 21));
  final end = start.add(const Duration(days: 2));
  debugPrint('GOD_STEP reserve:$label:open-listing:start');
  await _openListingForReservation(
    tester: tester,
    router: router,
    listing: listing,
    start: start,
    end: end,
  );
  debugPrint('GOD_STEP reserve:$label:open-listing:done');
  await _waitForListingTitleOrReserve(tester, listing.title);
  debugPrint('GOD_STEP reserve:$label:title-visible');
  if (negotiatedDigits != null) {
    debugPrint('GOD_STEP reserve:$label:enter-amount:start');
    await _enterReserveAmount(tester, negotiatedDigits);
    debugPrint('GOD_STEP reserve:$label:enter-amount:done');
  }
  final existingTradeIds = getIt<Hostr>().messaging.threads.threads.values
      .map((thread) => thread.conversationTag)
      .where((tag) => tag.isNotEmpty)
      .toSet();
  final reserveButton = find.byKey(const ValueKey('listing_reserve_button'));
  await _waitFor(
    tester,
    () => reserveButton.evaluate().isNotEmpty,
    timeout: const Duration(seconds: 120),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'reservation $label should show a reserve button',
    ),
  );
  debugPrint('GOD_STEP reserve:$label:reserve-button-visible');
  await _tapKeyUntilKeyAppears(
    tester,
    tapKey: const ValueKey('listing_reserve_button'),
    expectedKey: const ValueKey('trade_request_cancel_button'),
    timeout: const Duration(seconds: 120),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'reservation $label should land in a thread',
    ),
  );
  await _waitFor(
    tester,
    () => getIt<Hostr>().messaging.threads.threads.values.any(
      (thread) =>
          thread.conversationTag.isNotEmpty &&
          !existingTradeIds.contains(thread.conversationTag) &&
          _threadHasReservationForListing(thread, listing),
    ),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'reservation $label should create a new conversation thread',
    ),
  );
  debugPrint('GOD_STEP reserve:$label:thread-created');
  final newTradeThreads =
      getIt<Hostr>().messaging.threads.threads.values
          .where(
            (thread) =>
                thread.conversationTag.isNotEmpty &&
                !existingTradeIds.contains(thread.conversationTag) &&
                _threadHasReservationForListing(thread, listing),
          )
          .toList()
        ..sort(
          (a, b) => b.lastActivityTimestamp.compareTo(a.lastActivityTimestamp),
        );
  final thread = newTradeThreads.first;
  return _ReservationJourneyResult(
    router: router,
    listing: listing,
    threadAnchor: thread.anchor,
    tradeId: thread.conversationTag,
  );
}

bool _threadHasReservationForListing(Thread thread, Listing listing) {
  final listingAnchor = listing.anchor;
  if (listingAnchor == null) {
    return false;
  }
  return thread.state.value.reservationRequests.any(
    (request) => request.parsedTags.listingAnchor == listingAnchor,
  );
}

Future<void> _openListingForReservation({
  required WidgetTester tester,
  required AppRouter router,
  required Listing listing,
  required DateTime start,
  required DateTime end,
}) async {
  final route = ListingRoute(
    a: listing.naddr()!,
    dateRangeStart: start.toIso8601String(),
    dateRangeEnd: end.toIso8601String(),
  );
  await _waitFor(
    tester,
    () => tester
        .stateList<AutoRouterState>(find.byType(AutoRouter))
        .any((state) => state.controller?.routeData.name == AppShellRoute.name),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'listing navigation should start from the app shell',
    ),
  );
  final shellRouter = tester
      .stateList<AutoRouterState>(find.byType(AutoRouter))
      .lastWhere(
        (state) => state.controller?.routeData.name == AppShellRoute.name,
      )
      .controller!;
  await shellRouter.replaceAll([route], updateExistingRoutes: false);
  router.notifyAll();
  await _settle(tester);
}

Future<StackRouter> _appShellRouter(WidgetTester tester) async {
  await _waitFor(
    tester,
    () => tester
        .stateList<AutoRouterState>(find.byType(AutoRouter))
        .any((state) => state.controller?.routeData.name == AppShellRoute.name),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'app shell router should be available'),
  );
  return tester
      .stateList<AutoRouterState>(find.byType(AutoRouter))
      .lastWhere(
        (state) => state.controller?.routeData.name == AppShellRoute.name,
      )
      .controller!;
}

Future<void> _openThread({
  required WidgetTester tester,
  required AppRouter router,
  required String anchor,
}) async {
  final shellRouter = await _appShellRouter(tester);
  await shellRouter.replaceAll([
    TabShellRoute(children: [const InboxRoute()]),
  ], updateExistingRoutes: false);
  router.notifyAll();
  await _waitFor(
    tester,
    () => tester
        .stateList<AutoRouterState>(find.byType(AutoRouter))
        .any((state) => state.controller?.routeData.name == InboxRoute.name),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'inbox router should be available'),
  );
  final inboxRouter = tester
      .stateList<AutoRouterState>(find.byType(AutoRouter))
      .lastWhere((state) => state.controller?.routeData.name == InboxRoute.name)
      .controller!;
  await inboxRouter.replaceAll([
    ThreadRoute(anchor: anchor),
  ], updateExistingRoutes: false);
  router.notifyAll();
  await _waitFor(
    tester,
    () {
      final embedded = find.byKey(ValueKey('embedded-$anchor')).hitTestable();
      final standalone = find
          .byKey(ValueKey('standalone-$anchor'))
          .hitTestable();
      if (embedded.evaluate().isNotEmpty) return true;
      if (standalone.evaluate().isNotEmpty) return true;
      return false;
    },
    timeout: const Duration(seconds: 45),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'thread $anchor should be open'),
  );
}

Future<void> _enterReserveAmount(WidgetTester tester, String digits) async {
  await _tapKey(
    tester,
    find.byKey(const ValueKey('listing_reserve_amount_input')),
  );
  await _waitForKey(
    tester,
    const ValueKey('amount_editor_done_button'),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'reserve amount editor should open'),
  );
  await _replaceOpenAmountInput(tester, digits);
  await _tapKey(
    tester,
    find.byKey(const ValueKey('amount_editor_done_button')),
  );
  await _waitFor(
    tester,
    () => find
        .byKey(const ValueKey('amount_editor_done_button'))
        .evaluate()
        .isEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'reserve amount editor should close'),
  );
}

Future<void> _replaceOpenAmountInput(WidgetTester tester, String text) async {
  for (var i = 0; i < 24; i++) {
    await _tapKey(
      tester,
      find.byKey(const ValueKey('amount_input_keypad_backspace')),
    );
  }
  for (final input in text.split('')) {
    await _tapKey(tester, find.byKey(ValueKey('amount_input_keypad_$input')));
  }
}

Future<void> _waitForListingTitleOrReserve(
  WidgetTester tester,
  String title,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (find.textContaining(title).evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  }
  throw TimeoutException(
    _visibleTextSnapshot(tester, 'waiting for listing "$title"'),
    const Duration(seconds: 45),
  );
}

Future<void> _sendThreadMessage(
  WidgetTester tester,
  _ApprovalDriver approvalDriver,
) async {
  final field = find.byKey(const ValueKey('thread_reply_input'));
  await tester.enterText(field, 'Escrow hello from the god journey');
  await _tapKey(tester, find.byKey(const ValueKey('thread_reply_send_button')));
  await _waitForText(
    tester,
    'Escrow hello from the god journey',
    timeout: const Duration(seconds: 60),
  );
}

Future<void> _cancelPendingReservation(
  WidgetTester tester, {
  required String tradeId,
  required String actor,
}) async {
  final cancelAction = find.byKey(
    ValueKey('trade_request_cancel_button_$tradeId'),
  );
  await _waitFor(tester, () => cancelAction.evaluate().isNotEmpty);
  final trade = tester.element(cancelAction).read<Trade>();
  if (trade.tradeId != tradeId) {
    throw StateError(
      'Expected to cancel trade $tradeId but found ${trade.tradeId}',
    );
  }
  await _tapKey(tester, cancelAction);
  await _tapKey(
    tester,
    find.byKey(ValueKey('trade_request_cancel_confirm_button_$tradeId')),
  );
  await _waitFor(
    tester,
    () {
      final state = trade.state;
      return state is TradeReady &&
          state.tradeId == tradeId &&
          state.availability == TradeAvailability.cancelled &&
          find
              .byKey(ValueKey('trade_request_cancel_button_$tradeId'))
              .evaluate()
              .isEmpty;
    },
    timeout: const Duration(seconds: 90),
    reason: '$actor should be able to cancel pending reservation $tradeId',
  );
}

Future<void> _cancelLiveReservation(
  WidgetTester tester, {
  required String role,
  required String tradeId,
}) async {
  _debugTradeHeaders(tester, tradeId: tradeId, label: '$role live cancel');
  final actionsMenuKey = ValueKey(
    'trade_live_${role}_actions_menu_button_$tradeId',
  );
  var lastDebugLog = DateTime.fromMillisecondsSinceEpoch(0);
  await _waitFor(
    tester,
    () {
      final found = find.byKey(actionsMenuKey).evaluate().isNotEmpty;
      final now = DateTime.now();
      if (!found &&
          now.difference(lastDebugLog) > const Duration(seconds: 10)) {
        lastDebugLog = now;
        _debugTradeHeaders(
          tester,
          tradeId: tradeId,
          label: '$role live cancel waiting',
        );
      }
      return found;
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      '$role live reservation actions should be visible for $tradeId',
    ),
  );
  final actionsMenu = find.byKey(actionsMenuKey);
  await tester.ensureVisible(actionsMenu.first);
  await _settle(tester, frames: 6);
  final trade = tester.element(actionsMenu.first).read<Trade>();
  await _tapKey(tester, actionsMenu);

  final menuItemKey = ValueKey(
    'trade_live_${role}_cancel_${tradeId}_menu_item',
  );
  await _waitForKey(
    tester,
    menuItemKey,
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      '$role live reservation cancel menu item should be visible for $tradeId',
    ),
  );
  await _tapKey(tester, find.byKey(menuItemKey));

  final confirmKey = ValueKey(
    'trade_live_${role}_cancel_${tradeId}_confirm_button',
  );
  await _waitForKey(
    tester,
    confirmKey,
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      '$role live reservation cancel confirmation should be visible for $tradeId',
    ),
  );
  await _tapKey(tester, find.byKey(confirmKey));
  await _waitFor(
    tester,
    () {
      final state = trade.state;
      return state is TradeReady &&
          state.tradeId == tradeId &&
          state.availability == TradeAvailability.cancelled &&
          !state.actions.contains(TradeAction.cancel);
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () {
      _debugTradeHeaders(
        tester,
        tradeId: tradeId,
        label: '$role live cancel after confirm',
      );
      return _visibleTextSnapshot(
        tester,
        '$role should be able to cancel live reservation $tradeId',
      );
    },
  );
}

void _debugTradeHeaders(
  WidgetTester tester, {
  required String tradeId,
  required String label,
}) {
  final headers = tester
      .widgetList<TradeHeader>(find.byType(TradeHeader))
      .toList(growable: false);
  final tradeStates = <String>[];
  for (final element
      in find
          .byWidgetPredicate(
            (widget) => widget is BlocBuilder<Trade, TradeState>,
          )
          .evaluate()) {
    try {
      final trade = BlocProvider.of<Trade>(element, listen: false);
      final state = trade.state;
      final groups = trade.resolvedReservationGroup$.items
          .map((item) {
            final group = item.group;
            final validation = item.validation;
            final stages = group.reservations
                .map(
                  (r) =>
                      '${r.pubKey.substring(0, 8)}:${r.stage.name}:created=${r.createdAt}',
                )
                .join(',');
            final validity = validation is Valid<ReservationGroup>
                ? 'valid'
                : validation is Invalid<ReservationGroup>
                ? 'invalid:${validation.reason}'
                : validation.runtimeType.toString();
            return '${group.tradeId}:$validity:cancelled=${group.cancelled}:raw=${item.participants.rawGroupId}:resolved=${item.participants.resolvedGroupId}:stages=$stages';
          })
          .join(' || ');
      tradeStates.add(
        '${trade.tradeId}:conversation=${trade.conversationId}:participants=${trade.participants.join(",")}:state=${_describeTradeState(state)}:groups=[$groups]',
      );
    } catch (error) {
      tradeStates.add('error=$error');
    }
  }
  debugPrint(
    'GOD_TRADE_HEADERS label="$label" target=$tradeId count=${headers.length} '
    'headers=${headers.map((header) => '${header.tradeId}:showActions=${header.showActions}:participants=${Threads.normalizeParticipants(header.participants).join(",")}').join(" | ")} '
    'states=${tradeStates.join(" | ")}',
  );
}

String _describeTradeState(TradeState state) {
  switch (state) {
    case TradeReady():
      return 'ready:role=${state.role.name}:stage=${state.stage.runtimeType}:actions=${state.actions.map((a) => a.name).join(",")}:availability=${state.availability.name}';
    case TradeInitialising():
      return 'initialising';
    case TradeError():
      return 'error:${state.message}';
  }
}

Future<void> _addReviewForReservation(
  WidgetTester tester,
  _ReservationJourneyResult reservation,
) async {
  final actionsMenuKey = ValueKey(
    'trade_live_guest_actions_menu_button_${reservation.tradeId}',
  );
  await _waitForKey(
    tester,
    actionsMenuKey,
    timeout: const Duration(seconds: 60),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'review actions menu should be visible for ${reservation.tradeId}',
    ),
  );
  await _tapKey(tester, find.byKey(actionsMenuKey));
  final reviewMenuKey = ValueKey(
    'trade_live_guest_review_menu_item_${reservation.tradeId}',
  );
  await _waitForKey(
    tester,
    reviewMenuKey,
    timeout: const Duration(seconds: 60),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'review menu item should be visible for ${reservation.tradeId}',
    ),
  );
  await _tapKey(tester, find.byKey(reviewMenuKey));
  await _waitForKey(tester, const ValueKey('review_message_input'));
  const reviewText = 'God journey review: everything worked.';
  await tester.enterText(
    find.byKey(const ValueKey('review_message_input')),
    reviewText,
  );
  await _tapKey(tester, find.byKey(const ValueKey('review_rating_star_5')));
  await _tapKey(tester, find.byKey(const ValueKey('review_save_button')));
  await _waitFor(
    tester,
    () {
      final reviewInputVisible = find
          .byKey(const ValueKey('review_message_input'))
          .evaluate()
          .isNotEmpty;
      final snackBarsVisible = find.byType(SnackBar).evaluate().isNotEmpty;
      return !reviewInputVisible || snackBarsVisible;
    },
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'review save should either close the modal or show an error',
    ),
  );
  if (find
      .byKey(const ValueKey('review_message_input'))
      .evaluate()
      .isNotEmpty) {
    throw StateError(
      _visibleTextSnapshot(
        tester,
        'review modal remained open after save attempt',
      ),
    );
  }
  await _waitFor(
    tester,
    () async {
      final reviews = await getIt<Hostr>().reviews.list(
        Filter(
          kinds: Review.kinds,
          authors: [getIt<Hostr>().auth.getActiveKey().publicKey],
        ),
        name: 'god-review-check',
      );
      return reviews.any((review) => review.reviewText == reviewText);
    },
    timeout: const Duration(seconds: 90),
    reason: 'review should be published',
  );
}

Future<void> _assertTripsPageContainsReservations(
  WidgetTester tester,
  AppRouter router,
  List<_ReservationJourneyResult> reservations,
) async {
  for (final reservation in reservations) {
    await _dismissTripBookedPopupIfItAppears(
      tester,
      reservation.tradeId,
      timeout: const Duration(seconds: 2),
    );
  }
  await _navigateToTabRoute(
    tester,
    router,
    const TripsRoute(),
    routeName: TripsRoute.name,
  );
  for (final reservation in reservations) {
    await _dismissTripBookedPopupIfItAppears(
      tester,
      reservation.tradeId,
      timeout: const Duration(seconds: 2),
    );
  }
  for (final reservation in reservations) {
    await _waitFor(
      tester,
      () =>
          find.byKey(ValueKey(reservation.tradeId)).evaluate().isNotEmpty &&
          (getIt<Hostr>().userSubscriptions.myTripsList$.items.lastOrNull ??
                  const <Validation<ReservationGroup>>[])
              .whereType<Valid<ReservationGroup>>()
              .any((item) => item.event.tradeId == reservation.tradeId),
      timeout: const Duration(seconds: 60),
      reasonBuilder: () => _reservationGroupsSnapshot(
        tester,
        'Trips should include valid paid reservation ${reservation.tradeId}',
      ),
    );
  }
}

Future<void> _navigateToTabRoute(
  WidgetTester tester,
  AppRouter router,
  PageRouteInfo route, {
  required String routeName,
}) async {
  unawaited(router.navigate(TabShellRoute(children: [route])));
  await _settle(tester, frames: 20);
  final navKey = find.byKey(ValueKey('app_nav_$routeName'));
  if (navKey.evaluate().isNotEmpty) {
    await _tapKey(tester, navKey);
    await _settle(tester, frames: 20);
  }
}

Future<void> _navigateToAppShellRoute(
  WidgetTester tester,
  AppRouter router,
  PageRouteInfo route,
) async {
  if (route.routeName == EditListingRoute.name) {
    final args = route.args;
    if (args is EditListingRouteArgs && args.a == null) {
      unawaited(router.navigatePath('/edit-listing/new'));
      await _settle(tester, frames: 20);
      if (_appShellRouteExpectedKey(route).evaluate().isNotEmpty) return;
    }
  }

  unawaited(router.navigate(AppShellRoute(children: [route])));
  await _settle(tester, frames: 20);
  if (_appShellRouteExpectedKey(route).evaluate().isNotEmpty) return;

  await router.replaceAll([
    RootRoute(
      children: [
        StartupShellRoute(
          children: [
            AppShellRoute(children: [route]),
          ],
        ),
      ],
    ),
  ]);
  await _settle(tester, frames: 20);
}

Finder _appShellRouteExpectedKey(PageRouteInfo route) {
  if (route.routeName == EditListingRoute.name) {
    return find.byKey(const ValueKey('edit_listing_title_input'));
  }
  if (route.routeName == EditProfileRoute.name) {
    return find.byKey(const ValueKey('edit_profile_name_input'));
  }
  return find.byType(Scaffold);
}

String _reservationGroupsSnapshot(WidgetTester tester, String prefix) {
  String describe(Validation<ReservationGroup> item) {
    final group = item.event;
    final type = item.runtimeType;
    final reason = item is Invalid<ReservationGroup> ? ': ${item.reason}' : '';
    final reservations = group.reservations
        .map(
          (reservation) =>
              '${reservation.pubKey.substring(0, 8)}'
              '/${reservation.stage.name}'
              '/proof=${reservation.proof != null}'
              '/escrow=${reservation.proof?.escrowProof != null}',
        )
        .join(',');
    return '${group.tradeId}=$type$reason [$reservations]';
  }

  final trips =
      (getIt<Hostr>().userSubscriptions.myTripsList$.items.lastOrNull ??
              const <Validation<ReservationGroup>>[])
          .map(describe)
          .join(' | ');
  final all = getIt<Hostr>().userSubscriptions.allMyReservationGroups$.items
      .map(describe)
      .join(' | ');
  final keys = tester
      .widgetList<KeyedSubtree>(find.byType(KeyedSubtree))
      .map((widget) => widget.key)
      .whereType<ValueKey>()
      .map((key) => key.value.toString())
      .where((value) => value.length == 64)
      .take(12)
      .join(',');
  return '$prefix. Trips=[$trips]. All=[$all]. RenderedTradeKeys=[$keys]. '
      '${_visibleTextSnapshot(tester, 'visible')}';
}

Future<void> _exerciseCounterNegotiation({
  required WidgetTester tester,
  required AppRouter router,
  required Hostr hostr,
  required KeyPair hostKeyPair,
  required _ReservationJourneyResult reservation,
}) async {
  final thread = _threadForReservation(hostr, reservation);
  final guestOffer = thread?.state.value.reservationRequests.lastOrNull;
  if (thread == null || guestOffer?.amount == null) {
    throw StateError('No guest negotiation offer for ${reservation.tradeId}');
  }

  final listingAmount = reservation.listing.cost(
    start: guestOffer!.start!,
    end: guestOffer.end!,
    quantity: guestOffer.quantity,
  );
  final hostCounterAmount = _amountBetween(guestOffer.amount!, listingAmount);
  await _sendHostNegotiationEvent(
    hostr: hostr,
    hostKeyPair: hostKeyPair,
    reservation: reservation,
    amount: hostCounterAmount,
  );

  await _openThread(
    tester: tester,
    router: router,
    anchor: reservation.threadAnchor,
  );
  final currentThread = _threadForReservation(hostr, reservation);
  final beforeGuestCounterCount =
      currentThread?.state.value.reservationRequests.length ??
      thread.state.value.reservationRequests.length;
  final counterButton = find.byKey(
    ValueKey('trade_action_counter_${reservation.tradeId}'),
  );
  await _waitFor(
    tester,
    () => counterButton.hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'guest should be able to counter ${reservation.tradeId}',
    ),
  );
  final trade = tester.element(counterButton).read<Trade>();
  if (trade.tradeId != reservation.tradeId) {
    throw StateError(
      'Expected counter button for ${reservation.tradeId} but found '
      '${trade.tradeId}',
    );
  }
  final guestCounterAmount = _validCounterAmountForTrade(trade);
  await _tapKey(tester, counterButton);
  await _waitForKey(
    tester,
    ValueKey('trade_counter_submit_button_${reservation.tradeId}'),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'counter sheet should open for ${reservation.tradeId}',
    ),
  );
  await _replaceOpenAmountInput(tester, _amountInputText(guestCounterAmount));
  await _waitFor(
    tester,
    () {
      final button = tester.widget<FutureButton>(
        find.byKey(
          ValueKey('trade_counter_submit_button_${reservation.tradeId}'),
        ),
      );
      return button.onPressed != null;
    },
    timeout: const Duration(seconds: 10),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'counter submit should be enabled for ${reservation.tradeId}',
    ),
  );
  await _tapKey(
    tester,
    find.byKey(ValueKey('trade_counter_submit_button_${reservation.tradeId}')),
  );
  await _waitFor(
    tester,
    () => find
        .byKey(ValueKey('trade_counter_submit_button_${reservation.tradeId}'))
        .evaluate()
        .isEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'counter sheet should close for ${reservation.tradeId}',
    ),
  );
  await _waitFor(
    tester,
    () {
      final thread = hostr.messaging.threads.threads[reservation.threadAnchor];
      final requests = thread?.state.value.reservationRequests ?? const [];
      return requests.length > beforeGuestCounterCount &&
          requests.last.pubKey != hostKeyPair.publicKey;
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'guest counter should publish for ${reservation.tradeId}',
    ),
  );

  await _sendHostNegotiationEvent(
    hostr: hostr,
    hostKeyPair: hostKeyPair,
    reservation: reservation,
    amount: _latestReservationRequestForTrade(hostr, reservation).amount!,
  );
  await _waitFor(
    tester,
    () {
      final requests = _latestReservationRequestsForTrade(hostr, reservation);
      return requests.isNotEmpty &&
          requests.last.pubKey == hostKeyPair.publicKey;
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'host should accept guest counter for ${reservation.tradeId}',
    ),
  );
}

Thread? _threadForReservation(
  Hostr hostr,
  _ReservationJourneyResult reservation,
) => hostr.messaging.threads.threads[reservation.threadAnchor];

List<Reservation> _latestReservationRequestsForTrade(
  Hostr hostr,
  _ReservationJourneyResult reservation,
) {
  return hostr
          .messaging
          .threads
          .threads[reservation.threadAnchor]
          ?.state
          .value
          .reservationRequests ??
      const <Reservation>[];
}

Reservation _latestReservationRequestForTrade(
  Hostr hostr,
  _ReservationJourneyResult reservation,
) {
  final requests = _latestReservationRequestsForTrade(hostr, reservation);
  if (requests.isEmpty) {
    throw StateError('No reservation requests for ${reservation.tradeId}');
  }
  return requests.last;
}

DenominatedAmount _validCounterAmountForTrade(Trade trade) {
  final state = trade.state;
  if (state is! TradeReady || state.stage is! NegotiationStage) {
    throw StateError('Trade ${trade.tradeId} is not ready for negotiation');
  }
  final policy = (state.stage as NegotiationStage).policy;
  final min = policy.counterMin;
  final max = policy.counterMax;
  if (!policy.canCounter || max == null) {
    throw StateError('Trade ${trade.tradeId} cannot be countered');
  }
  if (min == null) return max;
  if (min.denomination != max.denomination || min.decimals != max.decimals) {
    return max;
  }
  if (!min.isBtc) {
    final majorUnit = BigInt.from(10).pow(min.decimals);
    final nextWholeUnit =
        ((min.value + majorUnit - BigInt.one) ~/ majorUnit) * majorUnit;
    if (nextWholeUnit <= max.value) {
      return DenominatedAmount(
        denomination: min.denomination,
        decimals: min.decimals,
        value: nextWholeUnit,
      );
    }
  }
  return _amountBetween(min, max);
}

Future<void> _sendHostNegotiationEvent({
  required Hostr hostr,
  required KeyPair hostKeyPair,
  required _ReservationJourneyResult reservation,
  required DenominatedAmount amount,
}) async {
  final thread = _threadForReservation(hostr, reservation);
  final latestRequest = thread?.state.value.reservationRequests.lastOrNull;
  if (thread == null || latestRequest == null) {
    throw StateError('No negotiation thread for ${reservation.tradeId}');
  }

  final event = await hostr.reservationRequests.createCounterOffer(
    listing: reservation.listing,
    previousRequest: latestRequest,
    amount: amount,
    signerKeyPair: hostKeyPair,
  );
  final buyerPubkey = hostr.auth.getActiveKey().publicKey;
  thread.addRoutingParticipants([hostKeyPair.publicKey, buyerPubkey]);
  thread.process(
    Message(
      pubKey: hostKeyPair.publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        [kConversationTag, reservation.tradeId],
        ['p', buyerPubkey],
      ]),
      child: event,
      content: event.toString(),
    ),
  );
}

DenominatedAmount _amountBetween(
  DenominatedAmount low,
  DenominatedAmount high,
) {
  if (low.denomination != high.denomination || low.decimals != high.decimals) {
    return high;
  }
  final difference = high.value - low.value;
  if (difference <= BigInt.one) {
    return high;
  }
  final halfStep = difference ~/ BigInt.two;
  return DenominatedAmount(
    denomination: low.denomination,
    decimals: low.decimals,
    value: low.value + (halfStep > BigInt.zero ? halfStep : BigInt.one),
  );
}

String _amountInputText(DenominatedAmount amount) {
  if (amount.isBtc) {
    return amount.value.toString();
  }
  var text = amount.toDecimalString(maxDecimals: amount.decimals);
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0*$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}

Future<void> _payReservationWithExternalAlby({
  required WidgetTester tester,
  required AppRouter router,
  required Hostr hostr,
  required IntegrationTestHarness harness,
  required _ReservationJourneyResult reservation,
}) async {
  await hostr.paymentProofOrchestrator.start();
  await _openThread(
    tester: tester,
    router: router,
    anchor: reservation.threadAnchor,
  );
  final payKey = ValueKey('trade_action_pay_${reservation.tradeId}');
  await _waitForKey(
    tester,
    payKey,
    timeout: const Duration(seconds: 90),
    reason: 'Reservation ${reservation.tradeId} should expose Pay',
  );
  await _tapKeyUntilKeyAppears(
    tester,
    tapKey: payKey,
    expectedKey: const ValueKey('escrow_fund_confirm_button'),
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'Pay should open escrow funding for ${reservation.tradeId}',
    ),
  );
  await _waitForKey(
    tester,
    const ValueKey('escrow_fund_confirm_button'),
    timeout: const Duration(seconds: 90),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'Escrow funding confirmation should be shown for ${reservation.tradeId}',
    ),
  );
  await _tapKey(
    tester,
    find.byKey(const ValueKey('escrow_fund_confirm_button')),
  );
  await _waitForInvoiceCopyButton(tester, reservation.tradeId);
  await _tapKey(
    tester,
    find.byKey(const ValueKey('payment_invoice_copy_button')),
  );
  final copyButton = tester.widget<CopyFeedbackButton>(
    find.byKey(const ValueKey('payment_invoice_copy_button')),
  );
  final invoice = (await copyButton.value()).trim();
  if (invoice.isEmpty) {
    throw StateError('No Lightning invoice copied for ${reservation.tradeId}');
  }

  debugPrint(
    'GOD_STEP pay:${reservation.tradeId}:invoice '
    '${invoice.substring(0, invoice.length < 80 ? invoice.length : 80)}',
  );
  await _payInvoiceWithExternalAlbyRetry(
    tester: tester,
    hostr: hostr,
    harness: harness,
    reservation: reservation,
    invoice: invoice,
  );

  final doneKey = await _waitForPaidReservationGroupAndTripBookedDoneButton(
    tester,
    hostr,
    reservation,
  );
  await _tapKey(tester, find.byKey(doneKey));
  await _waitFor(
    tester,
    () => find.byKey(doneKey).evaluate().isEmpty,
    timeout: const Duration(seconds: 15),
    reason: 'Trip booked popup should dismiss before trips assertion',
  );
}

Future<void> _payInvoiceWithExternalAlbyRetry({
  required WidgetTester tester,
  required Hostr hostr,
  required IntegrationTestHarness harness,
  required _ReservationJourneyResult reservation,
  required String invoice,
}) async {
  const maxAttempts = 3;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      debugPrint(
        'GOD_STEP pay:${reservation.tradeId}:alby-pay:start '
        'attempt=$attempt',
      );
      await harness.albyHub
          .payInvoice(invoice: invoice)
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw TimeoutException(
              'Timed out paying Lightning invoice for ${reservation.tradeId}',
              const Duration(minutes: 3),
            ),
          );
      debugPrint(
        'GOD_STEP pay:${reservation.tradeId}:alby-pay:done '
        'attempt=$attempt',
      );
      return;
    } catch (error, stackTrace) {
      final alreadyPaid = _isAlbyAlreadyPaidError(error);
      final retryable = _isRetryableAlbyPayError(error);
      debugPrint(
        'GOD_STEP pay:${reservation.tradeId}:alby-pay:error '
        'attempt=$attempt alreadyPaid=$alreadyPaid retryable=$retryable '
        'error=$error',
      );

      if (alreadyPaid || retryable) {
        final paidVisible = await _waitForPaidReservationAfterAlbyResult(
          tester,
          hostr,
          reservation,
          attempts: alreadyPaid ? 180 : 60,
        );
        if (paidVisible) {
          debugPrint(
            'GOD_STEP pay:${reservation.tradeId}:alby-pay:paid-after-error '
            'attempt=$attempt',
          );
          return;
        }
      }

      if (!retryable || attempt == maxAttempts) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      await tester.runAsync(
        () => Future<void>.delayed(Duration(seconds: 2 * attempt)),
      );
    }
  }
}

bool _isRetryableAlbyPayError(Object error) {
  if (error is TimeoutException) return true;
  final message = error.toString();
  return message.contains('FAILURE_REASON_TIMEOUT');
}

bool _isAlbyAlreadyPaidError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('already') &&
      (message.contains('paid') || message.contains('settled'));
}

Future<bool> _waitForPaidReservationAfterAlbyResult(
  WidgetTester tester,
  Hostr hostr,
  _ReservationJourneyResult reservation, {
  required int attempts,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await _settle(tester, frames: 2);
    if (_currentThreadShowsPaidReservation(tester, reservation)) {
      return true;
    }
    if (_hasPaidReservationGroup(hostr, reservation.tradeId)) {
      debugPrint(
        'GOD_STEP pay:${reservation.tradeId}:alby-pay:paid-group-visible',
      );
      return true;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
  }
  return false;
}

Future<Key> _waitForPaidReservationGroupAndTripBookedDoneButton(
  WidgetTester tester,
  Hostr hostr,
  _ReservationJourneyResult reservation,
) async {
  final tradeId = reservation.tradeId;
  final doneKey = ValueKey('trip_booked_done_button_$tradeId');
  final popupKey = ValueKey('trip_booked_popup_$tradeId');
  const timeout = Duration(minutes: 2);
  final deadline = DateTime.now().add(timeout);
  var attempts = 0;
  var sawPaidGroup = false;
  Key? seenDoneKey;
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (find.byKey(doneKey).hitTestable().evaluate().isNotEmpty) {
      seenDoneKey = doneKey;
    }
    final expectedPopup = find.byKey(popupKey).evaluate().isNotEmpty;
    final genericDone = find
        .byKey(const ValueKey('trip_booked_done_button'))
        .hitTestable();
    if (expectedPopup && genericDone.evaluate().isNotEmpty) {
      seenDoneKey = const ValueKey('trip_booked_done_button');
    }
    if (_hasPaidReservationGroup(hostr, tradeId)) {
      if (!sawPaidGroup) {
        debugPrint('GOD_STEP pay:$tradeId:paid-group-visible');
      }
      sawPaidGroup = true;
    }
    // This UI regression test is about both halves of the booking flow. A
    // committed reservation group proves the payment proof landed, while the
    // trip-booked popup proves the app listener surfaced it to the user.
    if (sawPaidGroup && seenDoneKey != null) {
      return seenDoneKey;
    }
    attempts++;
    if (attempts % 25 == 0) {
      debugPrint(
        'GOD_STEP pay:$tradeId:waiting-for-trip-booked '
        'sawPopup=${seenDoneKey != null} '
        '${_paidReservationGroupSnapshot(hostr, tradeId)}',
      );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  throw TimeoutException(
    _visibleTextSnapshot(
      tester,
      'Paid reservation group and trip booked popup should be shown for '
      '$tradeId (paidGroup=$sawPaidGroup, popup=${seenDoneKey != null})',
    ),
    timeout,
  );
}

bool _hasPaidReservationGroup(Hostr hostr, String tradeId) {
  return hostr.userSubscriptions.allMyReservationGroups$.items.any((item) {
    if (item.event.tradeId != tradeId) return false;
    final group = item.event;
    return group.reservations.any(
      (reservation) =>
          reservation.stage == ReservationStage.commit &&
          reservation.proof != null,
    );
  });
}

String _paidReservationGroupSnapshot(Hostr hostr, String tradeId) {
  final groups = hostr.userSubscriptions.allMyReservationGroups$.items
      .where((item) => item.event.tradeId == tradeId)
      .map(
        (item) =>
            '${item.runtimeType}:'
            '${item.event.reservations.map((reservation) => '${reservation.pubKey.substring(0, 8)}:${reservation.stage.name}:proof=${reservation.proof != null}').join(',')}',
      )
      .join(' | ');
  return groups.isEmpty ? 'groups=[]' : 'groups=[$groups]';
}

bool _currentThreadShowsPaidReservation(
  WidgetTester tester,
  _ReservationJourneyResult reservation,
) {
  final titleVisible = find
      .textContaining(reservation.listing.title)
      .hitTestable()
      .evaluate()
      .isNotEmpty;
  final paidVisible = find.text('Paid').hitTestable().evaluate().isNotEmpty;
  final successMessageVisible = find
      .textContaining('You successfully reserved ${reservation.listing.title}')
      .hitTestable()
      .evaluate()
      .isNotEmpty;
  return titleVisible && (paidVisible || successMessageVisible);
}

Future<void> _waitForInvoiceCopyButton(
  WidgetTester tester,
  String tradeId,
) async {
  const timeout = Duration(minutes: 3);
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (find
        .byKey(const ValueKey('payment_invoice_copy_button'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  throw TimeoutException(
    _visibleTextSnapshot(
      tester,
      'External Lightning invoice should be shown for $tradeId',
    ),
    timeout,
  );
}

Future<void> _dismissTripBookedPopupIfItAppears(
  WidgetTester tester,
  String tradeId, {
  required Duration timeout,
}) async {
  final popupKey = ValueKey('trip_booked_popup_$tradeId');
  final doneKey = ValueKey('trip_booked_done_button_$tradeId');
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    // Only dismiss the popup for the trade under test. A generic dismissal here
    // would hide the exact bug we are chasing: a proof popup for an unrelated
    // or failed reservation publish.
    final scopedButton = find.byKey(doneKey).hitTestable();
    final expectedPopup = find.byKey(popupKey).evaluate().isNotEmpty;
    final fallbackButton = expectedPopup
        ? find.byKey(const ValueKey('trip_booked_done_button')).hitTestable()
        : find.byWidgetPredicate((_) => false);
    final bookedButton = scopedButton.evaluate().isNotEmpty
        ? scopedButton
        : fallbackButton;
    if (bookedButton.evaluate().isNotEmpty) {
      debugPrint('GOD_STEP pay:$tradeId:trip-booked-dismiss-late');
      await tester.tap(bookedButton.first, warnIfMissed: false);
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            find.byKey(doneKey).hitTestable().evaluate().isEmpty &&
            find.byKey(popupKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 15),
        reason:
            'Trip booked popup for $tradeId should dismiss before continuing',
      );
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
}

Future<void> _backendArbitrateInFavorOfUser({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required EscrowService escrowService,
}) async {
  final btcTrade = await _createArbitrationTrade(
    harness: harness,
    title: 'God Arbitration BTC Stay',
    amount: DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(60000),
    ),
  );
  final usdTrade = await _createArbitrationTrade(
    harness: harness,
    title: 'God Arbitration USDT Stay',
    amount: DenominatedAmount.fromDecimal('50', 'USD', 6),
  );
  final chain = hostr.evm.getChainForEscrowService(escrowService);
  final nonces = _EvmNonceCursor(chain);
  final activeBuyerKey = await hostr.auth.hd.getActiveEvmKey();
  final chainController = chain.config.id.contains('rootstock')
      ? harness.anvilRootstock
      : harness.anvil;
  final activeBuyerAddress = activeBuyerKey.address;
  final tbtcAddress = env.evmConfig.chains.first.tokens['tBTC']!.address;
  final usdtAddress = env.evmConfig.chains.first.tokens['USDT']!.address;

  await _fundDirectErc20Escrow(
    harness: harness,
    hostr: hostr,
    trade: btcTrade,
    escrowService: escrowService,
    buyerAddress: activeBuyerAddress,
    tokenAddress: tbtcAddress,
    paymentValue: BigInt.from(60000) * BigInt.from(10).pow(10),
    nonces: nonces,
  );
  await _fundDirectErc20Escrow(
    harness: harness,
    hostr: hostr,
    trade: usdTrade,
    escrowService: escrowService,
    buyerAddress: activeBuyerAddress,
    tokenAddress: usdtAddress,
    paymentValue: BigInt.from(50) * BigInt.from(10).pow(6),
    nonces: nonces,
  );

  final contract = chain.escrow.getSupportedEscrowContract(escrowService);
  final arbiterKey = await deriveEvmKey(MockKeys.escrow.privateKey!);
  final arbitrationBroadcasterKey = EthPrivateKey.fromHex(
    Bip340.generatePrivateKey().privateKey!,
  );
  // MultiEscrow only requires the arbitration payload to be signed by the
  // arbiter; anyone may broadcast it. Use a fresh broadcaster account so e2e
  // setup does not share pending nonces with the real escrow daemon key.
  await chainController.setBalance(
    address: arbitrationBroadcasterKey.address.eip55With0x,
    amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
  );
  for (final trade in [btcTrade, usdTrade]) {
    final call = contract.arbitrate(
      tradeId: trade.negotiateReservation.getDtag()!,
      paymentForward: 0,
      bondForward: 0,
      ethKey: arbiterKey,
    );
    final tx = await _sendEvmWriteWithNonceRetry(
      label: 'arbitrate ${trade.title}',
      nonces: nonces,
      key: arbitrationBroadcasterKey,
      send: (transaction) => chain.client.sendTransaction(
        arbitrationBroadcasterKey,
        Transaction(
          to: call.to,
          value: EtherAmount.inWei(call.value),
          data: _hexToBytes(call.data),
          nonce: transaction.nonce,
        ),
        chainId: chain.config.chainId,
      ),
    );
    await _awaitSuccessfulReceipt(chain, tx, 'arbitrate ${trade.title}');
  }
  final awardedBalances = await contract.allBalances(
    beneficiary: activeBuyerAddress,
  );
  debugPrint(
    'GOD_ARBITRATION_BALANCES beneficiary=${activeBuyerAddress.eip55With0x} '
    '${awardedBalances.entries.map((entry) => '${entry.key.eip55With0x}:${entry.value}').join(',')}',
  );
  if (awardedBalances.isEmpty) {
    throw StateError(
      'Arbitration did not credit any escrow balance for '
      '${activeBuyerAddress.eip55With0x}',
    );
  }
  await hostr.fundsMonitor.refetchAccount(chain, 0);
}

Future<_ArbitrationTrade> _createArbitrationTrade({
  required IntegrationTestHarness harness,
  required String title,
  required DenominatedAmount amount,
}) async {
  final hostKeyPair = Bip340.generatePrivateKey();
  final guestKeyPair = Bip340.generatePrivateKey();
  final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final listing = harness.seeds.entities.listing(
    signer: hostKeyPair,
    dTag: 'god-arbitration-$nonce',
    title: title,
    description: '$title fixture for arbitration.',
    price: [Price(amount: amount, frequency: Frequency.daily)],
    location: 'San Salvador, El Salvador',
    type: ListingType.apartment,
    specifications: Specifications({
      'max_guests': 2,
      'bedrooms': 1,
      'beds': 1,
      'bathrooms': 1,
    }),
    images: ['https://picsum.photos/seed/god-arbitration-$nonce/1200/800'],
  );
  final start = DateTime.now().toUtc().add(const Duration(days: 84));
  final end = start.add(const Duration(days: 2));
  final tradeId = Bip340.generatePrivateKey().privateKey!;
  final reservation = await harness.seeds.entities.reservation(
    guestKeyPair: guestKeyPair,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    amount: amount,
    stage: ReservationStage.negotiate,
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: reservation,
    buyerParticipantPubkey: reservation.pubKey,
    hostPubkey: listing.pubKey,
    label: 'backend arbitration request',
  );

  return _ArbitrationTrade(
    title: title,
    hostKeyPair: hostKeyPair,
    negotiateReservation: reservation,
  );
}

Future<String> _fundDirectErc20Escrow({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _ArbitrationTrade trade,
  required EscrowService escrowService,
  required EthereumAddress buyerAddress,
  required String tokenAddress,
  required BigInt paymentValue,
  required _EvmNonceCursor nonces,
}) async {
  final chain = hostr.evm.getChainForEscrowService(escrowService);
  final contract = chain.escrow.getSupportedEscrowContract(escrowService);
  final token = EthereumAddress.fromHex(tokenAddress);
  final tokenContract = TestERC20(address: token, client: chain.client);
  final sellerAddress = (await deriveEvmKey(
    trade.hostKeyPair.privateKey!,
  )).address;
  final arbiter = EthereumAddress.fromHex(escrowService.evmAddress);
  final fee = escrowService.escrowFee(
    paymentValue,
    tokenAddress: token.eip55With0x,
  );
  final totalNeeded = paymentValue + fee;

  final chainController = chain.config.id.contains('rootstock')
      ? harness.anvilRootstock
      : harness.anvil;
  final sourceKey = EthPrivateKey.fromHex(
    Bip340.generatePrivateKey().privateKey!,
  );

  // This backend setup path is intentionally isolated from the local deployer
  // and pre-funded Anvil keys. A fresh source account plus direct ERC-20 balance
  // injection keeps repeated e2e runs from sharing pending nonces while still
  // exercising the real ERC-20 approve -> escrow createTrade path.
  await chainController.setBalance(
    address: sourceKey.address.eip55With0x,
    amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
  );
  await chainController.setErc20Balance(
    token: token.eip55With0x,
    account: sourceKey.address.eip55With0x,
    amount: totalNeeded,
  );

  final approveTx = await _sendEvmWriteWithNonceRetry(
    label: 'approve ${trade.title}',
    nonces: nonces,
    key: sourceKey,
    send: (transaction) => tokenContract.approve(
      (spender: contract.address, value: totalNeeded),
      credentials: sourceKey,
      transaction: transaction,
    ),
  );
  await _awaitSuccessfulReceipt(chain, approveTx, 'approve ${trade.title}');

  final multiEscrow = MultiEscrow(
    address: contract.address,
    client: chain.client,
  );
  final tx = await _sendEvmWriteWithNonceRetry(
    label: 'createTrade ${trade.title}',
    nonces: nonces,
    key: sourceKey,
    send: (transaction) => multiEscrow.createTrade(
      (
        tradeId: getBytes32(trade.negotiateReservation.getDtag()!),
        buyer: buyerAddress,
        seller: sellerAddress,
        arbiter: arbiter,
        token: token,
        paymentAmount: paymentValue,
        bondAmount: BigInt.zero,
        unlockAt: BigInt.from(
          trade.negotiateReservation.end!.millisecondsSinceEpoch ~/ 1000,
        ),
        escrowFee: fee,
      ),
      credentials: sourceKey,
      transaction: transaction,
    ),
  );
  await _awaitSuccessfulReceipt(chain, tx, 'createTrade ${trade.title}');
  return tx;
}

Token _escrowTokenForAmount(DenominatedAmount amount) {
  final chainConfig = env.evmConfig.chains.first;
  if (amount.denomination == 'USD') {
    final token = chainConfig.tokens['USDT'];
    if (token == null) {
      throw StateError('No USDT token configured for backend booking');
    }
    return Token(
      chainId: chainConfig.chainId,
      address: token.address,
      decimals: 6,
    );
  }
  if (amount.isBtc) {
    final token = chainConfig.tokens['tBTC'];
    if (token == null) {
      throw StateError('No tBTC token configured for backend booking');
    }
    return Token(
      chainId: chainConfig.chainId,
      address: token.address,
      decimals: 18,
    );
  }
  throw StateError('No E2E escrow token configured for ${amount.denomination}');
}

class _EvmNonceCursor {
  _EvmNonceCursor(this.chain);

  final EvmChain chain;
  final Map<String, int> _nextByAddress = {};

  Future<int> next(EthPrivateKey key) async {
    final address = key.address.eip55With0x.toLowerCase();
    final chainNext = await chain.client.getTransactionCount(
      key.address,
      atBlock: const BlockNum.pending(),
    );
    final cached = _nextByAddress[address];
    final next = cached == null || chainNext > cached ? chainNext : cached;
    _nextByAddress[address] = next + 1;
    debugPrint(
      'GOD_EVM_NONCE address=$address chainPending=$chainNext '
      'cached=${cached ?? 'null'} selected=$next',
    );
    return next;
  }

  void forget(EthPrivateKey key) {
    _nextByAddress.remove(key.address.eip55With0x.toLowerCase());
  }
}

Future<String> _sendEvmWriteWithNonceRetry({
  required String label,
  required _EvmNonceCursor nonces,
  required EthPrivateKey key,
  required Future<String> Function(Transaction transaction) send,
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 1; attempt <= 5; attempt++) {
    final nonce = await nonces.next(key);
    debugPrint(
      'GOD_EVM_TX label="$label" attempt=$attempt '
      'from=${key.address.eip55With0x} nonce=$nonce',
    );
    try {
      return await send(Transaction(nonce: nonce));
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (!_isRetryableNonceError(error)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      debugPrint(
        'GOD_EVM_TX retryable-nonce-error label="$label" attempt=$attempt '
        'from=${key.address.eip55With0x} nonce=$nonce error=$error',
      );
      nonces.forget(key);
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace ?? StackTrace.current);
}

bool _isRetryableNonceError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('nonce too low') ||
      message.contains('transaction already imported') ||
      (message.contains('-32003') && message.contains('nonce'));
}

Future<void> _awaitSuccessfulReceipt(
  EvmChain chain,
  String txHash,
  String label,
) async {
  final receipt = await chain.awaitReceipt(txHash);
  if (receipt.status == false) {
    throw StateError('$label transaction reverted: $txHash');
  }
}

Future<void> _assertBalancePageAndAutomaticSwapOut(
  WidgetTester tester,
  AppRouter router,
  Hostr hostr,
  EscrowService escrowService,
) async {
  await _navigateToTabRoute(
    tester,
    router,
    const ProfileRoute(),
    routeName: ProfileRoute.name,
  );
  await hostr.backgroundWorker.watch();
  await hostr.fundsMonitor.start();
  await hostr.fundsMonitor.seedAndAwait();
  final config = await hostr.userConfig.state;
  if (!config.autoWithdrawEnabled) {
    await hostr.userConfig.update(config.copyWith(autoWithdrawEnabled: true));
  }
  for (final chain in hostr.evm.configuredChains) {
    await hostr.fundsMonitor.refetchAccount(chain, 0);
  }
  await hostr.fundsMonitor.refetchEscrowService(escrowService, 0);
  await _settle(tester, frames: 40);
  expect(find.textContaining('Balance'), findsWidgets);
  final previousSwapOutIds = (await hostr.operationStateStore.readAll(
    'swap_out',
  )).map((state) => state['id']).toSet();
  Object? sweepError;
  StackTrace? sweepStack;
  var sweepDone = false;
  final sweepFuture = hostr.fundsMonitor
      .checkNow()
      .then((_) {
        sweepDone = true;
      })
      .catchError((Object error, StackTrace stackTrace) {
        sweepDone = true;
        sweepError = error;
        sweepStack = stackTrace;
      });
  unawaited(sweepFuture);
  try {
    await _waitFor(tester, () async {
      if (await hostr.backgroundWorker.hasActiveOnchainOperations()) {
        return true;
      }
      final states = await hostr.operationStateStore.readAll('swap_out');
      return states.any((state) => !previousSwapOutIds.contains(state['id']));
    }, timeout: const Duration(minutes: 2));
  } on TimeoutException {
    debugPrint(
      '${await _describeAutoWithdrawState(hostr)}'
      'sweepDone=$sweepDone sweepError=$sweepError\n$sweepStack',
    );
    rethrow;
  }
  await sweepFuture;
  await _waitFor(
    tester,
    () async => !(await hostr.backgroundWorker.hasActiveOnchainOperations()),
    timeout: const Duration(minutes: 15),
    reason: 'automatic swap-out should finish',
  );
  final swapOutStates = await hostr.operationStateStore.readAll('swap_out');
  expect(
    swapOutStates.any((state) => !previousSwapOutIds.contains(state['id'])),
    isTrue,
  );
}

Future<String> _describeAutoWithdrawState(Hostr hostr) async {
  final buffer = StringBuffer('Auto-withdraw diagnostic snapshot');
  try {
    final destination = await hostr.payments
        .resolveAutomaticInvoiceDestination();
    final config = await hostr.userConfig.state;
    buffer.writeln(
      'destination=${destination.type} label=${destination.label} '
      'error=${destination.error} autoWithdraw=${config.autoWithdrawEnabled}',
    );
  } catch (error) {
    buffer.writeln('destination error=$error');
  }

  try {
    final key = await hostr.auth.hd.getActiveEvmKey();
    for (final chain in hostr.evm.configuredChains) {
      final address = chain.aa == null
          ? key.address
          : await chain.aa!.getSmartAccountAddress(key);
      final balances = await chain.getBalancesBatch([address]);
      buffer.writeln(
        'chain=${chain.config.id} monitored=${address.eip55With0x} '
        'native=${balances[address]?.value}',
      );
    }
  } catch (error) {
    buffer.writeln('balance probe error=$error');
  }

  try {
    final funds = await hostr.fundsMonitor.fundsStream$.first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => const [],
    );
    buffer.writeln('funds_items=${funds.length}');
    for (final item in funds) {
      buffer.writeln(
        'fund item chain=${item.chain.config.id} '
        'address=${item.address.eip55With0x} '
        'token=${item.token.tagId} value=${item.balance.value} '
        'dust=${item.dust}',
      );
      try {
        final quote = await _quoteFundsItem(
          item,
        ).timeout(const Duration(seconds: 30));
        final feeRatio =
            quote.feeBreakdown.networkFees.value.toDouble() /
            item.balance.value.toDouble();
        buffer.writeln(
          'quote receive=${quote.receiveAmount.value} '
          'networkFee=${quote.feeBreakdown.networkFees.value} '
          'feeRatio=$feeRatio gasSponsored=${quote.feeBreakdown.gasSponsored}',
        );
      } catch (error) {
        buffer.writeln('quote probe error=$error');
      }
    }
  } catch (error) {
    buffer.writeln('funds probe error=$error');
  }

  try {
    final store = hostr.operationStateStore;
    for (final namespace in ['swap_in', 'swap_out', 'escrow_fund']) {
      final states = await store.readAll(namespace);
      buffer.writeln(
        '$namespace=${states.map((state) => state['state']).join(',')}',
      );
    }
  } catch (error) {
    buffer.writeln('operation-store probe error=$error');
  }
  return buffer.toString();
}

Future<SwapQuote> _quoteFundsItem(FundsItem item) async {
  Map<String, Call>? preLockCalls;
  if (item.isEscrowLocked) {
    final destination = await item.chain.getAccountAddress(item.keypair);
    final tokenAddress = EthereumAddress.fromHex(item.token.address);
    preLockCalls = {
      'withdraw': item.contract!.withdraw(
        WithdrawArgs(
          token: tokenAddress,
          ethKey: item.keypair,
          beneficiary: item.keypair.address,
          destination: destination,
        ),
      ),
    };
  }
  return item.chain.swapOutQuote(
    params: SwapOutParams(
      evmKey: item.keypair,
      accountIndex: item.accountIndex,
      amountSpec: AmountSpec.input(item.balance),
      preLockCalls: preLockCalls,
    ),
  );
}

Future<void> _editProfile(
  WidgetTester tester,
  AppRouter router,
  String label,
) async {
  await _navigateToAppShellRoute(tester, router, const EditProfileRoute());
  await _waitForKey(tester, const ValueKey('edit_profile_name_input'));
  await tester.enterText(
    find.byKey(const ValueKey('edit_profile_name_input')),
    'God Journey $label',
  );
  await _tapSave(tester, const ValueKey('edit_profile_save_button'));
}

Future<Listing> _createListing(
  WidgetTester tester,
  AppRouter router,
  String label,
) async {
  await _navigateToAppShellRoute(tester, router, EditListingRoute());
  await _waitForKey(
    tester,
    const ValueKey('edit_listing_title_input'),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'create listing form should be visible'),
  );
  final viewState = tester.state<EditListingViewState>(
    find.byType(EditListingView),
  );
  final controller = viewState.controller;
  await _tapKey(
    tester,
    find.byKey(const ValueKey('edit_listing_add_image_button')),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  if (controller.imageField.images.isEmpty) {
    await _tapKey(
      tester,
      find.byKey(const ValueKey('edit_listing_add_image_button')),
    );
  }
  await _waitFor(
    tester,
    () =>
        controller.imageField.images.isNotEmpty &&
        controller.imageField.resolvedPaths.isNotEmpty &&
        controller.imageField.canSubmit,
    // Local Blossom still performs the real media-optimisation upload during
    // e2e runs. In docker that `/media` request can take well over a minute, so
    // keep this as a real upload checkpoint but give the service enough time.
    timeout: const Duration(minutes: 3),
    reasonBuilder: () {
      final imageField = controller.imageField;
      final cubit = imageField.cubit;
      return 'listing image was not uploaded successfully. '
          'images=${imageField.images.length} '
          'resolved=${imageField.resolvedPaths.length} '
          'canSubmit=${imageField.canSubmit} '
          'isUploading=${cubit.isUploading} '
          'state=${cubit.state.runtimeType}';
    },
  );
  await tester.enterText(
    find.byKey(const ValueKey('edit_listing_title_input')),
    'God Created $label',
  );
  await _selectLocationSuggestion(
    tester,
    inputKey: const ValueKey('edit_listing_location_input'),
    location: 'San Salvador, El Salvador',
    suggestionKey: const ValueKey(
      'location_suggestion_san_salvador_el_salvador',
    ),
  );
  await _waitFor(
    tester,
    () => controller.locationController.canSubmit,
    timeout: const Duration(seconds: 45),
    reason: 'listing address did not resolve to H3 tags',
  );
  final priceInput = tester.widget<AmountTapInput>(
    find.byKey(const ValueKey('edit_listing_price_input')),
  );
  priceInput.controller.setValue(
    DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(25000),
    ),
  );
  priceInput.onChanged?.call(priceInput.controller.amount!);
  await _settle(tester, frames: 10);
  await tester.enterText(
    find.byKey(const ValueKey('edit_listing_description_input')),
    'Created by the end-to-end journey.',
  );
  await _tapSave(tester, const ValueKey('edit_listing_save_button'));

  final created = await getIt<Hostr>().listings.list(
    Filter(authors: [getIt<Hostr>().auth.getActiveKey().publicKey]),
  );
  return created.firstWhere((listing) => listing.title == 'God Created $label');
}

Future<void> _editListing(
  WidgetTester tester,
  AppRouter router,
  Listing listing,
  String label,
) async {
  await _navigateToAppShellRoute(
    tester,
    router,
    EditListingRoute(a: listing.naddr()),
  );
  await _waitForKey(tester, const ValueKey('edit_listing_title_input'));
  await tester.enterText(
    find.byKey(const ValueKey('edit_listing_title_input')),
    'God Edited $label',
  );
  await _tapSave(tester, const ValueKey('edit_listing_save_button'));
}

void _assertDriveReservationUsesParticipantProofs({
  required Reservation reservation,
  required String buyerParticipantPubkey,
  required String hostPubkey,
  required String label,
}) {
  if (reservation.parsedTags.tags.any(
    (tag) => tag.isNotEmpty && tag.first == 'pubkey_proof',
  )) {
    throw StateError(
      '$label still uses legacy pubkey_proof tags for '
      '${reservation.getDtag()}',
    );
  }

  final hostDecryptableBuyerProof = reservation.parsedTags.participantProofs
      .where(
        (proof) =>
            proof.role == 'buyer' &&
            proof.participantPubkey == buyerParticipantPubkey &&
            proof.recipientPubkey == hostPubkey,
      )
      .toList(growable: false);
  if (hostDecryptableBuyerProof.isEmpty) {
    throw StateError(
      '$label is missing a host-decryptable buyer participant_proof for '
      '${reservation.getDtag()}',
    );
  }
  if (hostDecryptableBuyerProof.any((proof) => proof.payloadHash.isEmpty)) {
    throw StateError(
      '$label has a buyer participant_proof without a payload hash for '
      '${reservation.getDtag()}',
    );
  }
}

Future<void> _createBackendPendingRequestAndCancelAsHost({
  required WidgetTester tester,
  required AppRouter router,
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required Listing listing,
  required String label,
}) async {
  final guest = Bip340.generatePrivateKey();
  await _publishProfileFor(harness, guest, 'God Pending Guest $label');

  final accountIndex = DateTime.now().microsecondsSinceEpoch % 100000;
  final tradeId = await deriveTradeId(
    guest.privateKey!,
    accountIndex: accountIndex,
  );
  final start = DateTime.now().toUtc().add(const Duration(days: 63));
  final end = start.add(const Duration(days: 2));
  final amount = listing.cost(start: start, end: end);
  final guestRequest = await harness.seeds.entities.reservation(
    guestKeyPair: guest,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    accountIndex: accountIndex,
    amount: amount,
    stage: ReservationStage.negotiate,
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: guestRequest,
    buyerParticipantPubkey: guestRequest.pubKey,
    hostPubkey: listing.pubKey,
    label: 'backend pending request',
  );

  final currentConfig = await hostr.userConfig.state;
  await hostr.userConfig.update(currentConfig.copyWith(mode: AppMode.host));
  final thread = hostr.messaging.threads.ensureConversation(
    participants: {hostr.auth.getActiveKey().publicKey, guest.publicKey},
    conversationTag: tradeId,
  );
  thread.process(
    Message(
      pubKey: guest.publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        PTag.seller(listing.pubKey).toTag(),
        PTag.buyer(guest.publicKey).toTag(),
      ]),
      child: guestRequest,
    ),
  );

  await _openThread(tester: tester, router: router, anchor: thread.anchor);
  await _waitForKey(
    tester,
    const ValueKey('trade_request_cancel_button'),
    timeout: const Duration(seconds: 90),
    reason: 'Host should see cancel on pending request $tradeId',
  );
  await _cancelPendingReservation(tester, tradeId: tradeId, actor: 'host');
}

Future<void> _createBackendBookingAndAssertHostings({
  required WidgetTester tester,
  required AppRouter router,
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _GodFixtures fixtures,
  required KeyPair hostKeyPair,
  required Listing listing,
  required String label,
}) async {
  final booking = await _createBackendLiveBooking(
    harness: harness,
    hostr: hostr,
    fixtures: fixtures,
    hostKeyPair: hostKeyPair,
    listing: listing,
    label: label,
  );
  _godStep('hostings:$label:backend-booking:done:${booking.tradeId}');
  await _waitFor(
    tester,
    () => hostr.auth.authState.value is LoggedIn,
    timeout: const Duration(seconds: 10),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'host should still be signed in'),
  );
  _godStep('hostings:$label:stream-wait:start:${booking.tradeId}');
  await _waitFor(
    tester,
    () => hostr.userSubscriptions.myResolvedHostingsList$.items
        .expand((items) => items)
        .any((item) => item.group.tradeId == booking.tradeId),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        'Resolved hostings stream should include ${booking.tradeId}. '
        '${_describeResolvedHostings(hostr)}',
  );
  _godStep('hostings:$label:stream-wait:done:${booking.tradeId}');
  await _switchToHostMode(tester);
  _godStep('hostings:$label:navigate:start:${booking.tradeId}');
  await _replaceWithHostingsRoute(tester, router);
  _godStep('hostings:$label:navigate:done:${booking.tradeId}');
  await _waitFor(
    tester,
    () => find.byType(HostingsScreen).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'HostingsScreen should be visible'),
  );
  await _waitForKey(
    tester,
    ValueKey(booking.tradeId),
    timeout: const Duration(seconds: 90),
    reasonBuilder: () =>
        'Hostings should include backend-created booking ${booking.tradeId}. '
        '${_describeResolvedHostings(hostr)}. '
        '${_visibleTextSnapshot(tester, 'hostings UI snapshot')}',
  );
}

Future<void> _replaceWithHostingsRoute(
  WidgetTester tester,
  AppRouter router,
) async {
  await router.replaceAll([
    const RootRoute(
      children: [
        StartupShellRoute(
          children: [
            AppShellRoute(
              children: [
                TabShellRoute(children: [HostingsRoute()]),
              ],
            ),
          ],
        ),
      ],
    ),
  ]);
  await _settle(tester, frames: 20);
}

Future<void> _switchToHostMode(WidgetTester tester) async {
  await _waitFor(
    tester,
    () => tester
        .stateList<AutoRouterState>(find.byType(AutoRouter))
        .any((state) => state.controller?.routeData.name == AppShellRoute.name),
    timeout: const Duration(seconds: 15),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'app shell router should be present'),
  );

  final configStore = getIt<Hostr>().userConfig;
  final current = await configStore.state;
  if (current.mode != AppMode.host) {
    await configStore.update(current.copyWith(mode: AppMode.host));
  }

  await _waitFor(
    tester,
    () async => (await configStore.state).mode == AppMode.host,
    timeout: const Duration(seconds: 15),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'mode should switch to host'),
  );
}

Future<_BackendLiveBooking> _createBackendLiveBooking({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _GodFixtures fixtures,
  required KeyPair hostKeyPair,
  required Listing listing,
  required String label,
}) async {
  final guest = Bip340.generatePrivateKey();
  await _publishProfileFor(harness, guest, 'God Booking Guest $label');

  final accountIndex = DateTime.now().microsecondsSinceEpoch % 100000;
  final tradeId = await deriveTradeId(
    guest.privateKey!,
    accountIndex: accountIndex,
  );
  hostr.userSubscriptions.trackTradeId(tradeId);
  final start = DateTime.now().toUtc().add(const Duration(days: 70));
  final end = start.add(const Duration(days: 2));
  final amount = listing.cost(start: start, end: end);
  final guestRequest = await harness.seeds.entities.reservation(
    guestKeyPair: guest,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    accountIndex: accountIndex,
    amount: amount,
    stage: ReservationStage.negotiate,
  );
  final guestTradeKeyPair = await deriveTradeKeyPair(
    guest.privateKey!,
    accountIndex: accountIndex,
  );
  await hostr.escrowMethods.ensureEscrowMethod(
    bytecodeHashes: {fixtures.escrowService.contractBytecodeHash},
    trustedEscrowPubkeys: [fixtures.escrowService.pubKey],
  );
  final hostEscrowMethod = await hostr.escrowMethods.myMethod();
  if (hostEscrowMethod == null) {
    throw StateError('Could not load host escrow method for backend booking');
  }
  final hostProfile = await hostr.metadata.loadMetadata(hostKeyPair.publicKey);
  if (hostProfile == null) {
    throw StateError('Could not load host profile for backend booking');
  }
  final escrowToken = _escrowTokenForAmount(amount);
  final chain = hostr.evm.getChainForEscrowService(fixtures.escrowService);
  final txHash = await _fundDirectErc20Escrow(
    harness: harness,
    hostr: hostr,
    trade: _ArbitrationTrade(
      title: 'backend live booking $label',
      hostKeyPair: hostKeyPair,
      negotiateReservation: guestRequest,
    ),
    escrowService: fixtures.escrowService,
    buyerAddress: (await deriveEvmKey(guest.privateKey!)).address,
    tokenAddress: escrowToken.address,
    paymentValue: TokenAmount.fromDenominated(amount, escrowToken).value,
    nonces: _EvmNonceCursor(chain),
  );
  final proof = harness.seeds.entities.escrowPaymentProof(
    hostProfile: hostProfile,
    listing: listing,
    txHash: txHash,
    escrowService: fixtures.escrowService,
    hostsEscrowMethod: hostEscrowMethod,
  );
  final reservationParticipants = [
    PTag.seller(listing.pubKey),
    PTag.buyer(guestTradeKeyPair.publicKey),
    PTag.escrow(fixtures.escrowService.escrowPubkey),
  ];
  final buyerCommit = await harness.seeds.entities.reservation(
    guestKeyPair: guest,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    accountIndex: accountIndex,
    amount: amount,
    recipient: guestTradeKeyPair.publicKey,
    stage: ReservationStage.commit,
    signerOverride: guestTradeKeyPair,
    pTags: reservationParticipants,
    proof: proof,
  );
  final hostCommit = await harness.seeds.entities.reservation(
    guestKeyPair: guest,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    amount: amount,
    stage: ReservationStage.commit,
    signerOverride: hostKeyPair,
    pTags: reservationParticipants,
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: buyerCommit,
    buyerParticipantPubkey: guestRequest.pubKey,
    hostPubkey: listing.pubKey,
    label: 'backend live booking buyer commit',
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: hostCommit,
    buyerParticipantPubkey: guestRequest.pubKey,
    hostPubkey: listing.pubKey,
    label: 'backend live booking host commit',
  );

  await hostr.reservations.upsert(buyerCommit);
  await hostr.reservations.upsert(hostCommit);
  hostr.userSubscriptions.allMyReservations$.stream.add(buyerCommit);
  hostr.userSubscriptions.allMyReservations$.stream.add(hostCommit);
  await _waitForResolvedReservationGroup(
    hostr: hostr,
    tradeId: tradeId,
    label: 'backend live booking $label',
  );

  final thread = hostr.messaging.threads.ensureConversation(
    participants: {hostr.auth.getActiveKey().publicKey, guest.publicKey},
    conversationTag: tradeId,
  );
  thread.process(
    Message(
      pubKey: guest.publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        [kConversationTag, tradeId],
        PTag.seller(listing.pubKey).toTag(),
        PTag.buyer(guest.publicKey).toTag(),
      ]),
      child: buyerCommit,
    ),
  );
  thread.process(
    Message(
      pubKey: hostr.auth.getActiveKey().publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        [kConversationTag, tradeId],
        PTag.seller(listing.pubKey).toTag(),
        PTag.buyer(guest.publicKey).toTag(),
      ]),
      child: hostCommit,
    ),
  );
  return _BackendLiveBooking(tradeId: tradeId, threadAnchor: thread.anchor);
}

Future<ResolvedValidatedReservationGroupParticipants>
_waitForResolvedReservationGroup({
  required Hostr hostr,
  required String tradeId,
  required String label,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final matches = hostr
        .userSubscriptions
        .allMyResolvedReservationGroups$
        .items
        .where((item) => item.group.tradeId == tradeId)
        .toList(growable: false);
    if (matches.isNotEmpty) {
      final item = matches.last;
      debugPrint(
        'GOD_RESOLVED_GROUP label="$label" trade=$tradeId '
        'validation=${item.validation.runtimeType} '
        'rawGroup=${item.participants.rawGroupId} '
        'resolvedGroup=${item.participants.resolvedGroupId} '
        'raw=${item.participants.rawParticipantSet.join(",")} '
        'resolved=${item.participants.resolvedParticipantSet.join(",")} '
        'seller=${item.group.sellerReservation?.pubKey} '
        'buyer=${item.group.buyerReservation?.pubKey} '
        'escrowPubkey=${item.group.escrowPubkey} '
        'escrowReservation=${item.group.escrowReservation?.pubKey} '
        'stages=${item.group.reservations.map((r) => '${r.pubKey}:${r.stage.name}:proof=${r.proof != null}:participantProofs=${r.parsedTags.participantProofs.length}').join("|")}',
      );
      return item;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  final unresolved = hostr.userSubscriptions.allMyReservationGroups$.items
      .where((item) => item.event.tradeId == tradeId)
      .map(_describeReservationGroupValidation)
      .join(' || ');
  final rawReservations = hostr
      .userSubscriptions
      .allMyReservations$
      .stream
      .items
      .where((reservation) => reservation.getDtag() == tradeId)
      .map(
        (reservation) =>
            '${reservation.pubKey}:${reservation.stage.name}:p=${reservation.parsedTags.getTags('p').join(",")}:proof=${reservation.proof != null}:participantProofs=${reservation.parsedTags.participantProofs.length}',
      )
      .join(' || ');
  throw TimeoutException(
    'Timed out waiting for resolved reservation group for $label/$tradeId. '
    'unresolved=[$unresolved] rawReservations=[$rawReservations]',
    timeout,
  );
}

String _describeReservationGroupValidation(
  Validation<ReservationGroup> validation,
) {
  final group = validation.event;
  final status = validation is Invalid<ReservationGroup>
      ? 'Invalid:${validation.reason}'
      : validation.runtimeType.toString();
  return '$status rawGroup=${group.groupId} '
      'participants=${group.participantSet.join(",")} '
      'seller=${group.sellerReservation?.pubKey} '
      'buyer=${group.buyerReservation?.pubKey} '
      'escrowPubkey=${group.escrowPubkey} '
      'escrowReservation=${group.escrowReservation?.pubKey} '
      'stages=${group.reservations.map((r) => '${r.pubKey}:${r.stage.name}:proof=${r.proof != null}:participantProofs=${r.parsedTags.participantProofs.length}').join("|")}';
}

Future<_BackendLiveBooking> _createBackendCompletedReviewBooking({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required Listing listing,
  required KeyPair guestIdentityKeyPair,
  required KeyPair hostKeyPair,
  required String label,
}) async {
  final accountIndex = await hostr.tradeAccountAllocator
      .reserveNextTradeIndex();
  final guestTradeKeyPair = await hostr.auth.hd.getTradeKeyPair(
    accountIndex: accountIndex,
  );
  final tradeId = await hostr.auth.hd.getTradeId(accountIndex: accountIndex);
  final end = DateTime.now().toUtc().subtract(const Duration(days: 2));
  final start = end.subtract(const Duration(days: 2));
  final amount = listing.cost(start: start, end: end);
  final buyerCommit = await harness.seeds.entities.reservation(
    guestKeyPair: guestIdentityKeyPair,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    accountIndex: accountIndex,
    amount: amount,
    recipient: guestTradeKeyPair.publicKey,
    stage: ReservationStage.commit,
    signerOverride: guestTradeKeyPair,
    pTags: [
      PTag.seller(listing.pubKey),
      PTag.buyer(guestTradeKeyPair.publicKey),
    ],
  );
  final hostCommit = await harness.seeds.entities.reservation(
    guestKeyPair: guestIdentityKeyPair,
    dTag: tradeId,
    listing: listing,
    start: start,
    end: end,
    accountIndex: accountIndex,
    amount: amount,
    recipient: guestTradeKeyPair.publicKey,
    stage: ReservationStage.commit,
    signerOverride: hostKeyPair,
    pTags: [
      PTag.seller(listing.pubKey),
      PTag.buyer(guestTradeKeyPair.publicKey),
    ],
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: buyerCommit,
    buyerParticipantPubkey: guestTradeKeyPair.publicKey,
    hostPubkey: listing.pubKey,
    label: 'backend completed review buyer commit $label',
  );
  _assertDriveReservationUsesParticipantProofs(
    reservation: hostCommit,
    buyerParticipantPubkey: guestTradeKeyPair.publicKey,
    hostPubkey: listing.pubKey,
    label: 'backend completed review host commit $label',
  );

  await hostr.reservations.upsert(buyerCommit);
  await hostr.reservations.upsert(hostCommit);
  hostr.userSubscriptions.allMyReservations$.stream.add(buyerCommit);
  hostr.userSubscriptions.allMyReservations$.stream.add(hostCommit);
  hostr.userSubscriptions.allMyReservations$.stream.addStatus(
    StreamStatusQueryComplete(),
  );
  hostr.userSubscriptions.allMyReservations$.stream.addStatus(
    StreamStatusLive(),
  );

  final thread = hostr.messaging.threads.ensureConversation(
    participants: {hostKeyPair.publicKey, guestIdentityKeyPair.publicKey},
    conversationTag: tradeId,
  );
  thread.addRoutingParticipants([
    hostKeyPair.publicKey,
    guestIdentityKeyPair.publicKey,
  ]);
  thread.process(
    Message(
      pubKey: guestIdentityKeyPair.publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        [kConversationTag, tradeId],
        PTag.seller(hostKeyPair.publicKey).toTag(),
        PTag.buyer(guestIdentityKeyPair.publicKey).toTag(),
      ]),
      child: buyerCommit,
    ),
  );
  thread.process(
    Message(
      pubKey: hostKeyPair.publicKey,
      createdAt: _nowSeconds(),
      tags: MessageTags([
        [kConversationTag, tradeId],
        PTag.seller(hostKeyPair.publicKey).toTag(),
        PTag.buyer(guestIdentityKeyPair.publicKey).toTag(),
      ]),
      child: hostCommit,
    ),
  );
  return _BackendLiveBooking(tradeId: tradeId, threadAnchor: thread.anchor);
}

Future<void> _exerciseExploreFilters(
  WidgetTester tester,
  AppRouter router,
  Hostr hostr,
  List<Listing> listings,
) async {
  _godStep('search:navigate');
  await _navigateToTabRoute(
    tester,
    router,
    const ExploreRoute(),
    routeName: ExploreRoute.name,
  );
  await _waitFor(
    tester,
    () => find.byType(ExploreView).evaluate().isNotEmpty,
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'ExploreView should be visible'),
  );
  _godStep('search:view-visible');
  final exploreContext = tester.element(find.byType(ExploreView));
  final filterCubit = exploreContext.read<FilterCubit>();
  final listCubit = exploreContext.read<ListCubit<Listing>>();
  final fixtureIds = listings.map((listing) => listing.id).toSet();

  _godStep('search:fixtures-wait');
  await _waitFor(
    tester,
    () {
      final state = listCubit.state;
      if (state.fetching || state.synching) return false;
      final actualIds = state.results.map((listing) => listing.id).toSet();
      return actualIds.containsAll(fixtureIds);
    },
    timeout: const Duration(seconds: 90),
    reasonBuilder: () {
      final state = listCubit.state;
      final actualTitles = state.results
          .where((listing) => fixtureIds.contains(listing.id))
          .map((listing) => listing.title)
          .toSet();
      return 'Explore should load filter fixtures before combinations. '
          'fetching=${state.fetching} synching=${state.synching} '
          'actualFixtures=${actualTitles.join(', ')}';
    },
  );

  await _exerciseExploreLocationInput(
    tester: tester,
    hostr: hostr,
    filterCubit: filterCubit,
    listCubit: listCubit,
    fixtureIds: fixtureIds,
  );

  final cases = _filterCases();
  for (final filterCase in cases) {
    _godStep('search:case:start ${filterCase.name}');
    await _applyExploreFilterCaseThroughUi(tester, filterCase);
    final uiFilter = filterCubit.state.filter ?? filterCase.buildFilter();
    final expectedFixtureIds = listings
        .where(filterCase.matches)
        .map((listing) => listing.id)
        .toSet();
    var backendFixtureIds = <String>{};
    var nonMatchingBackendResults = <String>[];
    await _waitFor(
      tester,
      () async {
        final backendResults = await hostr.listings.list(
          uiFilter,
          name: 'e2e-search-filter-${filterCase.name}',
        );
        backendFixtureIds = backendResults
            .where((listing) => fixtureIds.contains(listing.id))
            .map((listing) => listing.id)
            .toSet();
        nonMatchingBackendResults = backendResults
            .where((listing) => !filterCase.matches(listing))
            .map((listing) => listing.title)
            .toList(growable: false);
        return nonMatchingBackendResults.isEmpty &&
            _sameStringSet(backendFixtureIds, expectedFixtureIds);
      },
      timeout: const Duration(seconds: 60),
      reasonBuilder: () {
        final expectedTitles = listings
            .where((listing) => expectedFixtureIds.contains(listing.id))
            .map((listing) => listing.title)
            .toSet();
        final actualTitles = listings
            .where((listing) => backendFixtureIds.contains(listing.id))
            .map((listing) => listing.title)
            .toSet();
        return 'raw Hostr query for ${filterCase.name} did not match the '
            'expected seeded fixture set. '
            'expected=${expectedTitles.join(', ')} '
            'actual=${actualTitles.join(', ')} '
            'nonMatching=${nonMatchingBackendResults.join(', ')}';
      },
    );
    await _waitFor(
      tester,
      () {
        final state = listCubit.state;
        return !state.fetching && !state.synching;
      },
      timeout: const Duration(seconds: 30),
      reasonBuilder: () {
        final state = listCubit.state;
        return 'filter combination ${filterCase.name} did not finish relay '
            'fetch. fetching=${state.fetching} synching=${state.synching}';
      },
    );
    await _waitFor(
      tester,
      () {
        final state = listCubit.state;
        if (state.fetching || state.synching) return false;
        final actualIds = state.results
            .where((listing) => fixtureIds.contains(listing.id))
            .map((listing) => listing.id)
            .toSet();
        return _sameStringSet(actualIds, expectedFixtureIds);
      },
      timeout: const Duration(seconds: 60),
      reasonBuilder: () {
        final state = listCubit.state;
        final actualTitles = state.results
            .where((listing) => fixtureIds.contains(listing.id))
            .map((listing) => listing.title)
            .toSet();
        final expectedTitles = listings
            .where((listing) => expectedFixtureIds.contains(listing.id))
            .map((listing) => listing.title)
            .toSet();
        return 'filter combination ${filterCase.name} did not return '
            'the expected seeded fixture set. '
            'expected=${expectedTitles.join(', ')} '
            'actual=${actualTitles.join(', ')} '
            'fetching=${state.fetching} synching=${state.synching}';
      },
    );
    _godStep('search:case:done ${filterCase.name}');
  }
  filterCubit.clear();
  await _settle(tester);
  _godStep('search:done');
}

bool _sameStringSet(Set<String> a, Set<String> b) {
  return a.length == b.length && a.containsAll(b);
}

bool _sameStringIntMap(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

final _liveSubscriptionSuffixPattern = RegExp(r'-[A-Za-z0-9]{5}$');

class _NostrSubscriptionSnapshot {
  final Map<String, int> liveCounts;
  final Map<String, int> queryCounts;
  final List<String> liveRawNames;
  final List<String> queryRawNames;

  const _NostrSubscriptionSnapshot({
    required this.liveCounts,
    required this.queryCounts,
    required this.liveRawNames,
    required this.queryRawNames,
  });

  int get liveCount => _totalCount(liveCounts);
  int get queryCount => _totalCount(queryCounts);

  String dump() {
    return [
      'live=$liveCount ${_formatCountMap(liveCounts)}',
      'queries=$queryCount ${_formatCountMap(queryCounts)}',
      if (liveRawNames.isNotEmpty) 'liveRaw=${liveRawNames.join(', ')}',
      if (queryRawNames.isNotEmpty) 'queryRaw=${queryRawNames.join(', ')}',
    ].join('\n');
  }
}

int _totalCount(Map<String, int> counts) =>
    counts.values.fold<int>(0, (sum, count) => sum + count);

Map<String, int> _countByCanonicalSubscriptionName(Iterable<String> names) {
  final counts = <String, int>{};
  for (final name in names) {
    final canonical = name.replaceFirst(_liveSubscriptionSuffixPattern, '');
    counts[canonical] = (counts[canonical] ?? 0) + 1;
  }
  return counts;
}

String _formatCountMap(Map<String, int> counts) {
  if (counts.isEmpty) return '{}';
  final entries = counts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
}

_NostrSubscriptionSnapshot _nostrSubscriptionSnapshot(Hostr hostr) {
  final liveRawNames = <String>[];
  final queryRawNames = <String>[];
  for (final state in hostr.ndk.relays.globalState.inFlightRequests.values) {
    final name = _nostrRequestName(state);
    final isQuery = _nostrRequestClosesOnEose(state);
    if (isQuery) {
      queryRawNames.add(name);
    } else {
      liveRawNames.add(name);
    }
  }
  liveRawNames.sort();
  queryRawNames.sort();
  return _NostrSubscriptionSnapshot(
    liveCounts: _countByCanonicalSubscriptionName(liveRawNames),
    queryCounts: _countByCanonicalSubscriptionName(queryRawNames),
    liveRawNames: liveRawNames,
    queryRawNames: queryRawNames,
  );
}

String _nostrRequestName(dynamic state) {
  final request = state.request;
  final name = request.name?.toString();
  if (name != null && name.trim().isNotEmpty) return name;
  return state.id?.toString() ?? 'unnamed';
}

bool _nostrRequestClosesOnEose(dynamic state) =>
    state.request.closeOnEOSE == true;

Future<_NostrSubscriptionSnapshot> _waitForStableNostrSubscriptionSnapshot({
  required WidgetTester tester,
  required Hostr hostr,
  required String label,
  Duration timeout = const Duration(seconds: 90),
}) async {
  var snapshot = _nostrSubscriptionSnapshot(hostr);
  _NostrSubscriptionSnapshot? previous;
  var stableSamples = 0;
  await _waitFor(
    tester,
    () {
      snapshot = _nostrSubscriptionSnapshot(hostr);
      final matchesPrevious =
          previous != null &&
          _sameStringIntMap(snapshot.liveCounts, previous!.liveCounts);
      if (snapshot.queryCounts.isEmpty && matchesPrevious) {
        stableSamples += 1;
      } else {
        stableSamples = 0;
      }
      previous = snapshot;
      return snapshot.queryCounts.isEmpty && stableSamples >= 3;
    },
    timeout: timeout,
    reasonBuilder: () =>
        '$label did not reach a stable subscription baseline.\n'
        '${snapshot.dump()}',
  );
  return snapshot;
}

String _subscriptionSnapshotMismatchReason({
  required _NostrSubscriptionSnapshot baseline,
  required Map<String, int> expectedLiveCounts,
  required _NostrSubscriptionSnapshot actual,
  required String label,
}) {
  return '$label did not reach the expected live subscription set.\n'
      'diff=${_subscriptionCountDiff(expectedLiveCounts, actual.liveCounts)}\n'
      'expected=${_formatCountMap(expectedLiveCounts)}\n'
      'baseline:\n${baseline.dump()}\n'
      'actual:\n${actual.dump()}';
}

String _subscriptionCountDiff(
  Map<String, int> expected,
  Map<String, int> actual,
) {
  final keys = {...expected.keys, ...actual.keys}.toList()..sort();
  final deltas = <String>[];
  for (final key in keys) {
    final expectedCount = expected[key] ?? 0;
    final actualCount = actual[key] ?? 0;
    if (expectedCount == actualCount) continue;
    final sign = actualCount > expectedCount ? '+' : '';
    deltas.add(
      '$key:$expectedCount->$actualCount($sign${actualCount - expectedCount})',
    );
  }
  return deltas.isEmpty ? 'none' : deltas.join(', ');
}

Future<void> _waitForExploreListToSettle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  await _waitFor(
    tester,
    () {
      final views = find.byType(ExploreView).evaluate();
      if (views.isEmpty) return false;
      final context = views.first;
      final state = context.read<ListCubit<Listing>>().state;
      return !state.fetching && !state.synching;
    },
    timeout: timeout,
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'Explore list should settle'),
  );
}

Future<void> _exerciseExploreLocationInput({
  required WidgetTester tester,
  required Hostr hostr,
  required FilterCubit filterCubit,
  required ListCubit<Listing> listCubit,
  required Set<String> fixtureIds,
}) async {
  const location = 'San Salvador, El Salvador';
  const suggestionKey = ValueKey(
    'location_suggestion_san_salvador_el_salvador',
  );
  _godStep('search:location:start');
  await _tapKey(
    tester,
    find.byKey(const ValueKey('explore_search_box_button')),
  );
  await _waitForKey(
    tester,
    const ValueKey('search_filters_location_input'),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'search location input should open'),
  );
  final locationInput = find.byKey(
    const ValueKey('search_filters_location_input'),
  );
  await _selectLocationSuggestion(
    tester,
    inputFinder: locationInput,
    location: location,
    suggestionKey: suggestionKey,
  );
  _godStep('search:location:suggestion-tapped');
  await _waitFor(
    tester,
    () => find.byKey(const ValueKey('suggestions')).evaluate().isEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'location suggestions should clear after selection tap',
    ),
  );
  _godStep('search:location:suggestion-committed');
  await _waitFor(
    tester,
    () =>
        tester
            .widget<ModalBottomSheetPrimaryButton>(
              find.byKey(const ValueKey('explore_filters_search_button')),
            )
            .onPressed !=
        null,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'search button should enable after entering a location',
    ),
  );
  await _tapKey(
    tester,
    find.byKey(const ValueKey('explore_filters_search_button')),
  );
  await _waitFor(
    tester,
    () => filterCubit.state.location.trim() == location,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        'expected filterCubit location to be "$location", got '
        '"${filterCubit.state.location}"',
  );
  final locationFilter = filterCubit.state.filter;
  expect(
    locationFilter,
    isNotNull,
    reason: 'location search should produce a concrete filter',
  );
  final backendResults = await hostr.listings.list(
    locationFilter!,
    name: 'e2e-search-filter-location',
  );
  final backendFixtureIds = backendResults
      .where((listing) => fixtureIds.contains(listing.id))
      .map((listing) => listing.id)
      .toSet();
  await _waitFor(
    tester,
    () {
      final state = listCubit.state;
      if (state.fetching || state.synching) return false;
      final actualIds = state.results
          .where((listing) => fixtureIds.contains(listing.id))
          .map((listing) => listing.id)
          .toSet();
      return actualIds.length == backendFixtureIds.length &&
          actualIds.containsAll(backendFixtureIds);
    },
    timeout: const Duration(seconds: 60),
    reasonBuilder: () {
      final state = listCubit.state;
      final actualIds = state.results
          .where((listing) => fixtureIds.contains(listing.id))
          .map((listing) => listing.id)
          .toSet();
      return 'location search UI results should match raw Hostr query. '
          'expected=${backendFixtureIds.join(', ')} '
          'actual=${actualIds.join(', ')} '
          'fetching=${state.fetching} synching=${state.synching}';
    },
  );

  await _tapKey(
    tester,
    find.byKey(const ValueKey('explore_clear_filters_button')),
  );
  await _waitFor(
    tester,
    () => filterCubit.state.location.trim().isEmpty,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        'expected cleared location, got "${filterCubit.state.location}"',
  );
  await _waitFor(
    tester,
    () {
      final state = listCubit.state;
      if (state.fetching || state.synching) return false;
      final actualIds = state.results
          .where((listing) => fixtureIds.contains(listing.id))
          .map((listing) => listing.id)
          .toSet();
      return actualIds.containsAll(fixtureIds);
    },
    timeout: const Duration(seconds: 60),
    reasonBuilder: () =>
        'fixtures should return after clearing location search.',
  );
  _godStep('search:location:done');
}

Future<void> _applyExploreFilterCaseThroughUi(
  WidgetTester tester,
  _FilterCase filterCase,
) async {
  await _tapKey(
    tester,
    find.byKey(const ValueKey('explore_search_box_button')),
  );
  await _waitForKey(
    tester,
    const ValueKey('search_filters_advanced_toggle'),
    timeout: const Duration(seconds: 30),
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'search filters sheet should open'),
  );

  if (find
      .byKey(const ValueKey('search_filters_beachfront_switch'))
      .evaluate()
      .isEmpty) {
    await _tapKey(
      tester,
      find.byKey(const ValueKey('search_filters_advanced_toggle')),
    );
  }

  await _setSearchSwitch(
    tester,
    const ValueKey('search_filters_beachfront_switch'),
    filterCase.beachfront,
  );
  await _setSearchSwitch(
    tester,
    const ValueKey('search_filters_kitchen_switch'),
    filterCase.kitchen,
  );
  await _setSearchSwitch(
    tester,
    const ValueKey('search_filters_allows_pets_switch'),
    filterCase.pets,
  );
  await _setSearchSwitch(
    tester,
    const ValueKey('search_filters_negotiable_switch'),
    filterCase.negotiable,
  );

  final searchButton = find.byKey(
    const ValueKey('explore_filters_search_button'),
  );
  if (_filterCaseHasAnySelection(filterCase)) {
    await _tapKey(tester, searchButton);
  } else {
    final clearButton = find.byKey(
      const ValueKey('explore_filters_clear_button'),
    );
    if (clearButton.evaluate().isNotEmpty) {
      await _tapKey(tester, clearButton);
    }
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('search_filters_advanced_toggle')),
      ),
    ).pop();
    await _settle(tester);
  }
}

Future<void> _setSearchSwitch(
  WidgetTester tester,
  ValueKey<String> key,
  bool expected,
) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await _settle(tester);
  final current = tester.widget<SwitchListTile>(finder).value;
  if (current == expected) return;
  await _tapKey(tester, finder);
}

bool _filterCaseHasAnySelection(_FilterCase filterCase) =>
    filterCase.beachfront ||
    filterCase.kitchen ||
    filterCase.pets ||
    filterCase.negotiable;

List<_FilterCase> _filterCases() {
  final bools = [false, true];
  final cases = <_FilterCase>[];
  for (final beachfront in bools) {
    for (final kitchen in bools) {
      for (final pets in bools) {
        for (final negotiable in bools) {
          cases.add(
            _FilterCase(
              name:
                  'beachfront=$beachfront kitchen=$kitchen pets=$pets negotiable=$negotiable',
              beachfront: beachfront,
              kitchen: kitchen,
              pets: pets,
              negotiable: negotiable,
            ),
          );
        }
      }
    }
  }
  return cases;
}

class _FilterCase {
  final String name;
  final bool beachfront;
  final bool kitchen;
  final bool pets;
  final bool negotiable;

  const _FilterCase({
    required this.name,
    required this.beachfront,
    required this.kitchen,
    required this.pets,
    required this.negotiable,
  });

  void apply(SearchFormController controller) {
    controller.beachfrontField.setValue(beachfront);
    controller.kitchenField.setValue(kitchen);
    controller.allowsPetsField.setValue(pets);
    controller.negotiableField.setValue(negotiable);
  }

  Filter buildFilter() {
    final controller = SearchFormController();
    try {
      apply(controller);
      return controller.buildFilter();
    } finally {
      controller.dispose();
    }
  }

  bool matches(Listing listing) {
    if (beachfront && !listing.specifications.beachfront) return false;
    if (kitchen && !listing.specifications.kitchen) return false;
    if (pets && !listing.specifications.allows_pets) return false;
    if (negotiable && !listing.negotiable) return false;
    return true;
  }
}

Future<void> _assertSignerWaitingPopup({
  required WidgetTester tester,
  required AppRouter router,
  required Hostr hostr,
  required _SignetApprovalDriver approvals,
  required _GodFixtures fixtures,
}) async {
  await approvals.pause();
  await approvals.setTrustLevel('paranoid');
  final activePubkey = hostr.auth.activePubkey;
  if (activePubkey == null) {
    throw StateError('No active pubkey for signer waiting popup test');
  }

  final signCompleter = Completer<Nip01Event>();
  unawaited(
    hostr.auth
        .signEvent(
          Nip01Event(
            pubKey: activePubkey,
            kind: kNostrKindJsonMessage,
            content: 'Trigger waiting popup',
            tags: const [],
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        )
        .then(signCompleter.complete, onError: signCompleter.completeError),
  );

  try {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 7)),
    );
    await tester.pump();
    await _waitForKey(
      tester,
      const ValueKey('signer_request_popup_page'),
      timeout: const Duration(seconds: 15),
    );
    expect(
      find.byKey(const ValueKey('signer_request_popup_title')),
      findsOneWidget,
    );
    await approvals.resume();
    await tester.runAsync(
      () => signCompleter.future.timeout(const Duration(seconds: 30)),
    );
  } finally {
    await approvals.setTrustLevel('full');
    await approvals.resume();
  }
}

Future<void> _assertBunkerRestoreFailureAndRetry({
  required WidgetTester tester,
  required AppRouter router,
  required SignetTestController signet,
  required SignetTestUser signetUser,
}) async {
  await signet.deleteKey(signetUser.keyName);

  await tester.pumpWidget(const SizedBox.shrink());
  await getIt<Hostr>().dispose();
  await getIt.reset();
  await sdk_di.getIt.reset();
  await initCore(Env.dev);
  router = AppRouter();
  await tester.pumpWidget(MyApp(appRouter: router));
  await _waitForText(
    tester,
    'Hostr could not restore the saved bunker session.',
    timeout: const Duration(seconds: 60),
  );
  await _tapKey(
    tester,
    find.byKey(const ValueKey('bunker_restore_retry_button')),
  );
  await _settle(tester, frames: 20);
  expect(
    find.textContaining('Hostr could not restore the saved bunker session.'),
    findsOneWidget,
  );

  await signet.importUser(
    keyName: signetUser.keyName,
    keyPair: signetUser.keyPair,
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  final restoreDeadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(restoreDeadline)) {
    if (getIt<Hostr>().auth.authState.value is LoggedIn) return;
    if (find
        .byKey(const ValueKey('bunker_restore_retry_button'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      await _tapKey(
        tester,
        find.byKey(const ValueKey('bunker_restore_retry_button')),
      );
    }
    await _settle(tester, frames: 20);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
  }
  throw TimeoutException(
    'bunker retry did not restore the session after re-importing the key',
    const Duration(seconds: 90),
  );
}

Future<void> _tapSave(WidgetTester tester, Key key) async {
  await _tapKey(tester, find.byKey(key));
  await _settle(tester, frames: 60);
}

Future<void> _selectLocationSuggestion(
  WidgetTester tester, {
  Finder? inputFinder,
  Key? inputKey,
  required String location,
  required Key suggestionKey,
}) async {
  final finder = inputFinder ?? find.byKey(inputKey!);
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
  await tester.enterText(finder, location);
  await _waitForKey(
    tester,
    suggestionKey,
    timeout: const Duration(seconds: 30),
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'location suggestion should appear after entering a location',
    ),
  );
  await _settle(tester, frames: 8);
  await _tapFinderCenter(tester, find.byKey(suggestionKey));
}

Future<void> _tapKey(WidgetTester tester, Finder finder) async {
  await _waitFor(
    tester,
    () => finder.evaluate().isNotEmpty,
    reasonBuilder: () =>
        _visibleTextSnapshot(tester, 'tap target should exist: $finder'),
  );
  try {
    await tester.ensureVisible(finder.first);
    await _settle(tester, frames: 2);
  } catch (_) {
    // Overlay/menu targets are already in the overlay tree and may not have a
    // scrollable ancestor. In that case the hit-testable wait below is enough.
  }
  final hitTestable = finder.hitTestable();
  await _waitFor(
    tester,
    () => hitTestable.evaluate().isNotEmpty,
    reasonBuilder: () => _visibleTextSnapshot(
      tester,
      'tap target should be hit-testable: $finder',
    ),
  );
  await tester.tap(hitTestable.first, warnIfMissed: false);
  await tester.pump();
}

Future<void> _tapFinderCenter(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, () => finder.evaluate().isNotEmpty);
  await tester.ensureVisible(finder.first);
  await _settle(tester, frames: 2);
  final target = finder.first;
  final center = tester.getCenter(target);
  await tester.tapAt(center);
  await tester.pump();
}

Future<void> _tapKeyUntilKeyAppears(
  WidgetTester tester, {
  required Key tapKey,
  required Key expectedKey,
  Duration timeout = const Duration(seconds: 30),
  String Function()? reasonBuilder,
}) async {
  final deadline = DateTime.now().add(timeout);
  final tapTarget = find.byKey(tapKey).hitTestable();
  final expected = find.byKey(expectedKey);
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (expected.evaluate().isNotEmpty) return;
    if (tapTarget.evaluate().isNotEmpty) {
      await tester.tap(tapTarget.first, warnIfMissed: false);
      await tester.pump();
    }
    final retryDeadline = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(retryDeadline)) {
      await _settle(tester, frames: 2);
      if (expected.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
  }
  throw TimeoutException(
    reasonBuilder?.call() ?? 'tapping $tapKey did not reveal $expectedKey',
    timeout,
  );
}

Future<void> _waitForKey(
  WidgetTester tester,
  Key key, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
  String Function()? reasonBuilder,
}) async {
  final caller = StackTrace.current
      .toString()
      .split('\n')
      .skip(1)
      .take(8)
      .join('\n');
  await _waitFor(
    tester,
    () => find.byKey(key).evaluate().isNotEmpty,
    timeout: timeout,
    reasonBuilder:
        reasonBuilder ??
        (reason != null ? () => reason : null) ??
        () =>
            '${_visibleTextSnapshot(tester, 'waiting for key $key')}\n$caller',
  );
}

Future<void> _waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await _waitFor(
    tester,
    () => find.textContaining(text).evaluate().isNotEmpty,
    timeout: timeout,
    reason: _visibleTextSnapshot(tester, 'waiting for text "$text"'),
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
  String Function()? reasonBuilder,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (await condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  throw TimeoutException(
    reasonBuilder?.call() ?? reason ?? 'condition was not met',
    timeout,
  );
}

void _godStep(String message) {
  debugPrint('GOD_STEP $message');
}

String _visibleTextSnapshot(WidgetTester tester, String prefix) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((text) => text.trim().isNotEmpty)
      .take(30)
      .join(' | ');
  return '$prefix. Auth=${getIt<Hostr>().auth.authState.value.runtimeType}. Texts=$texts';
}

String _describeResolvedHostings(Hostr hostr) {
  final stream = hostr.userSubscriptions.myResolvedHostingsList$;
  final items = stream.items
      .expand((items) => items)
      .map(
        (item) =>
            '${item.group.tradeId}:seller=${item.group.sellerPubkey}:'
            'stages=${item.group.reservations.map((r) => '${r.pubKey}:${r.stage.name}').join(",")}:'
            'raw=${item.participants.rawGroupId}:'
            'resolved=${item.participants.resolvedGroupId}',
      )
      .join(' | ');
  return 'myResolvedHostingsList status=${stream.status.value.runtimeType} '
      'batches=${stream.items.length} items=[$items]';
}

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Uint8List _hexToBytes(String hex) {
  final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
  final bytes = <int>[];
  for (var i = 0; i < clean.length; i += 2) {
    bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

@Tags(['integration', 'docker'])
library;

import 'dart:async';

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/seed/signet_bunker_client.dart';
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:models/stubs.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../support/integration_test_harness.dart';

const _caseTimeout = Timeout(Duration(minutes: 20));

enum _PaymentProofCase {
  usd,
  btc,
  negotiatedUsd,
  negotiatedBtc;

  bool get negotiated =>
      this == _PaymentProofCase.negotiatedUsd ||
      this == _PaymentProofCase.negotiatedBtc;
}

enum _PaymentProofLoginMode { nsec, bunker }

class _EscrowFixture {
  final TestHost host;
  final ProfileMetadata hostProfile;
  final EscrowService escrowService;
  final EscrowMethod hostEscrowMethod;
  final Listing btcListing;
  final Listing usdListing;
  final Listing negotiatedBtcListing;
  final Listing negotiatedUsdListing;

  const _EscrowFixture({
    required this.host,
    required this.hostProfile,
    required this.escrowService,
    required this.hostEscrowMethod,
    required this.btcListing,
    required this.usdListing,
    required this.negotiatedBtcListing,
    required this.negotiatedUsdListing,
  });

  Listing listingFor(_PaymentProofCase testCase) => switch (testCase) {
    _PaymentProofCase.usd => usdListing,
    _PaymentProofCase.btc => btcListing,
    _PaymentProofCase.negotiatedUsd => negotiatedUsdListing,
    _PaymentProofCase.negotiatedBtc => negotiatedBtcListing,
  };
}

class _PreparedTrade {
  final Listing listing;
  final Reservation payableRequest;
  final EscrowServiceSelected selectedEscrow;
  final String tradeId;

  const _PreparedTrade({
    required this.listing,
    required this.payableRequest,
    required this.selectedEscrow,
    required this.tradeId,
  });
}

void main() {
  late IntegrationTestHarness harness;
  late Hostr hostr;
  late _EscrowFixture fixture;

  setUpAll(() async {
    await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
    harness = await IntegrationTestHarness.create(
      name: 'hostr_payment_proof_orchestrator_escrow_fund_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.debug,
      cleanHydratedStorage: true,
    );
    hostr = harness.hostr;
    fixture = await _seedEscrowFixture(harness);
  });

  tearDownAll(() async {
    await hostr.paymentProofOrchestrator.reset();
    await harness.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await _resetSession(hostr);
  });

  for (final loginMode in _PaymentProofLoginMode.values) {
    for (final testCase in _PaymentProofCase.values) {
      test(
        '${loginMode.name} ${testCase.name} escrow fund publishes a '
        'self-signed payment proof',
        () => _runPaymentProofCase(
          harness: harness,
          hostr: hostr,
          fixture: fixture,
          loginMode: loginMode,
          testCase: testCase,
        ),
        timeout: _caseTimeout,
      );
    }
  }
}

Future<void> _runPaymentProofCase({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _EscrowFixture fixture,
  required _PaymentProofLoginMode loginMode,
  required _PaymentProofCase testCase,
}) async {
  final label = '${loginMode.name}-${testCase.name}';
  print('PAYMENT_PROOF_IT $label:start');

  await IntegrationTestHarness.clearBoltzPendingEvmTransactions();
  final buyer = harness.seeds.deriveKeyPair(
    DateTime.now().microsecondsSinceEpoch % 1000000000,
  );
  final bunker = loginMode == _PaymentProofLoginMode.bunker
      ? await _signInBunkerBuyer(
          harness: harness,
          hostr: hostr,
          buyer: buyer,
          label: label,
        )
      : null;
  try {
    if (loginMode == _PaymentProofLoginMode.nsec) {
      await harness.signInAndConnectNwc(
        user: buyer,
        appNamePrefix: 'payment-proof-$label',
      );
    }
    await _runSignedInPaymentProofCase(
      harness: harness,
      hostr: hostr,
      fixture: fixture,
      buyer: buyer,
      testCase: testCase,
      label: label,
    );
  } finally {
    await bunker?.dispose();
  }
}

Future<void> _runSignedInPaymentProofCase({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _EscrowFixture fixture,
  required KeyPair buyer,
  required _PaymentProofCase testCase,
  required String label,
}) async {
  await hostr.identityClaims.ensureEvmAddress();
  await hostr.paymentProofOrchestrator.reset();
  await hostr.paymentProofOrchestrator.start();

  final prepared = await _prepareTrade(
    harness: harness,
    hostr: hostr,
    fixture: fixture,
    buyer: buyer,
    testCase: testCase,
  );

  final proofCompleter = Completer<Reservation>();
  final proofPublishCompleter = Completer<void>();
  final updatesSub = hostr.orderWorkflows.updates.listen((reservation) {
    if (_isBuyerEscrowProofReservation(
      reservation: reservation,
      tradeId: prepared.tradeId,
      sellerPubkey: prepared.listing.pubKey,
    )) {
      if (!proofCompleter.isCompleted) {
        proofCompleter.complete(reservation);
      }
    }
  });

  final seenSwapStates = <String>[];
  var proofPublishStarted = false;
  var completedSwapFromStream = false;
  StreamSubscription? swapSub;

  try {
    final preparer = hostr.escrow.fund(
      EscrowFundParams(
        escrowService: fixture.escrowService,
        negotiateReservation: prepared.payableRequest,
        sellerProfile: fixture.hostProfile,
        sellerEvmAddress: fixture.host.evmAddress!,
        amount: prepared.payableRequest.amount!,
        sellerEscrowMethod: fixture.hostEscrowMethod,
        listingName: prepared.listing.title,
        dexInputBuffer: SwapInDexBuffer.zero,
      ),
    );

    final swapInParams = await preparer.prepare();
    final configured = preparer.configuredChain;
    final fundingKey = await hostr.auth.hd.getActiveEvmKey(
      accountIndex: preparer.accountIndex,
    );
    final chainController = configured.config.id.contains('rootstock')
        ? harness.anvilRootstock
        : harness.anvil;
    await chainController.setBalance(
      address: fundingKey.address.eip55With0x,
      amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
    );
    final accountAddress = await configured.getAccountAddress(fundingKey);
    await chainController.setBalance(
      address: accountAddress.eip55With0x,
      amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
    );

    final swapIn = configured.swapIn(params: swapInParams);
    seenSwapStates.add(swapIn.state.runtimeType.toString());

    // The app publishes the self-signed reservation from this stream callback,
    // so this test fails if the swap only becomes completed synchronously after
    // execute() without notifying stream listeners.
    swapSub = swapIn.stream.listen((state) {
      seenSwapStates.add(state.runtimeType.toString());
      if (proofPublishStarted || state is! SwapInCompleted) return;
      completedSwapFromStream = true;
      proofPublishStarted = true;

      final txHash = state.data.claimTxHash;
      if (txHash == null || txHash.isEmpty) {
        if (!proofCompleter.isCompleted) {
          proofCompleter.completeError(
            StateError('Completed swap had no claim tx for $label'),
          );
        }
        return;
      }

      print(
        'PAYMENT_PROOF_IT $label:completed-swap '
        'trade=${prepared.tradeId} tx=$txHash',
      );
      final publishFuture = hostr.paymentProofOrchestrator
          .publishEscrowProofForCompletedSwap(
            tradeId: prepared.tradeId,
            transactionHash: txHash,
            escrowService: prepared.selectedEscrow,
          );
      unawaited(
        publishFuture.then(
          (_) {
            if (!proofPublishCompleter.isCompleted) {
              proofPublishCompleter.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!proofPublishCompleter.isCompleted) {
              proofPublishCompleter.completeError(error, stackTrace);
            }
            if (!proofCompleter.isCompleted) {
              proofCompleter.completeError(error, stackTrace);
            }
          },
        ),
      );
    });

    await swapIn.execute().timeout(
      const Duration(minutes: 12),
      onTimeout: () => throw TimeoutException(
        'Swap did not complete for $label. '
        '${_snapshot(hostr, prepared.tradeId)} '
        'states=${seenSwapStates.join(" > ")}',
      ),
    );

    final completed = swapIn.state;
    expect(
      completed,
      isA<SwapInCompleted>(),
      reason:
          'Swap must complete before a payment proof can be published. '
          'states=${seenSwapStates.join(" > ")}',
    );
    if (!completedSwapFromStream) {
      fail(
        'Swap reached SwapInCompleted but the stream listener never saw it '
        'for $label. states=${seenSwapStates.join(" > ")}',
      );
    }

    final completedData = (completed as SwapInCompleted).data;
    final txHash = completedData.claimTxHash;
    expect(txHash, isNotNull, reason: 'Completed swap must have claim tx');

    final published = await proofCompleter.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw TimeoutException(
        'PaymentProofOrchestrator did not publish buyer proof for $label. '
        'tx=$txHash ${_snapshot(hostr, prepared.tradeId)} '
        'states=${seenSwapStates.join(" > ")}',
      ),
    );
    expect(
      published.proof?.escrowProof?.txHash.toLowerCase(),
      equals(txHash!.toLowerCase()),
      reason: 'Published proof must reference the completed escrow tx',
    );
    await proofPublishCompleter.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw TimeoutException(
        'PaymentProofOrchestrator did not finish proof publish for $label. '
        'tx=$txHash ${_snapshot(hostr, prepared.tradeId)} '
        'states=${seenSwapStates.join(" > ")}',
      ),
    );

    await _expectProofReadableFromRelay(
      hostr: hostr,
      tradeId: prepared.tradeId,
      sellerPubkey: prepared.listing.pubKey,
      txHash: txHash,
      label: label,
    );
    print(
      'PAYMENT_PROOF_IT $label:done '
      'trade=${prepared.tradeId} tx=$txHash proof=${published.id}',
    );
  } finally {
    await swapSub?.cancel();
    await updatesSub.cancel();
  }
}

Future<_BunkerBuyerSession> _signInBunkerBuyer({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required KeyPair buyer,
  required String label,
}) async {
  final signet = SignetBunkerClient(
    baseUri: Uri.parse('https://bunker-nostr.hostr.development/'),
    maxRateLimitRetries: 12,
  );
  final keyName =
      'hostr-sdk-payment-proof-$label-'
      '${DateTime.now().microsecondsSinceEpoch}';
  _SignetApprovalLoop? approvals;

  try {
    final imported = await signet.importNsec(
      keyName: keyName,
      nsec: buyer.privateKeyBech32!,
    );
    if (imported.bunkerUri.isEmpty) {
      throw StateError('Signet did not return a bunker URI for $keyName');
    }

    approvals = _SignetApprovalLoop(signet: signet, keyName: keyName);
    await approvals.start();
    // Signet reports the key as online even though nostr-tools may not have
    // finished registering the backend relay subscription. The first bunker
    // connect is an ephemeral kind 24133 event, so logging in immediately can
    // publish it just before Signet is actually listening.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await hostr.auth.signinWithBunkerUrl(imported.bunkerUri);
    expect(
      hostr.auth.isBunkerBacked,
      isTrue,
      reason: 'Bunker cases must exercise the remote signer auth path',
    );
    await harness.connectNwc(
      user: buyer,
      appNamePrefix: 'payment-proof-$label',
    );
    return _BunkerBuyerSession(
      signet: signet,
      keyName: keyName,
      approvals: approvals,
    );
  } catch (_) {
    await approvals?.stop();
    try {
      await signet.deleteKey(keyName);
    } finally {
      await signet.close();
    }
    rethrow;
  }
}

class _BunkerBuyerSession {
  _BunkerBuyerSession({
    required this.signet,
    required this.keyName,
    required this.approvals,
  });

  final SignetBunkerClient signet;
  final String keyName;
  final _SignetApprovalLoop approvals;

  Future<void> dispose() async {
    await approvals.stop();
    try {
      // Each bunker test imports a fresh remote signer. Delete it after the
      // case so looped `dart test` runs do not accumulate Signet apps/keys.
      await signet.deleteKey(keyName);
    } finally {
      await signet.close();
    }
  }
}

class _SignetApprovalLoop {
  _SignetApprovalLoop({required this.signet, required this.keyName});

  final SignetBunkerClient signet;
  final String keyName;

  bool _stopped = false;
  Future<void>? _loop;
  final Set<String> _submittedRequestIds = <String>{};

  Future<void> start() async {
    _loop ??= _approveLoop();
  }

  Future<void> stop() async {
    _stopped = true;
    await _loop;
  }

  Future<void> _approveLoop() async {
    while (!_stopped) {
      try {
        final pending = (await signet.requests())
            .where(
              (request) =>
                  request.keyName == keyName &&
                  !_submittedRequestIds.contains(request.id),
            )
            .toList(growable: false);
        if (pending.isNotEmpty) {
          print(
            'PAYMENT_PROOF_IT bunker-approve key=$keyName '
            'ids=${pending.map((request) => request.id).join(',')}',
          );
          await signet.approveBatch(pending);
          _submittedRequestIds.addAll(pending.map((request) => request.id));
        }
      } on SignetBunkerException catch (error) {
        print('PAYMENT_PROOF_IT bunker-approve-error $error');
        if (error.statusCode == 429) {
          _submittedRequestIds.clear();
          await Future<void>.delayed(const Duration(seconds: 5));
        } else {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      } catch (error) {
        print('PAYMENT_PROOF_IT bunker-approve-error $error');
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}

Future<_EscrowFixture> _seedEscrowFixture(
  IntegrationTestHarness harness,
) async {
  final hostr = harness.hostr;
  final host = await harness.seeds.freshHost(listingCount: 0, hasEvm: true);
  final chainConfig = env.evmConfig.chains.first;
  final chain = hostr.evm.getChainByChainId(chainConfig.chainId);
  if (chain == null) {
    throw StateError('No configured EVM chain for ${chainConfig.chainId}');
  }
  final contractAddress = chainConfig.escrowContractAddress;
  if (contractAddress == null || contractAddress.isEmpty) {
    throw StateError('No escrow contract configured for ${chainConfig.id}');
  }
  final bytecodeHash =
      await SupportedEscrowContractRegistry.bytecodeHashForAddress(
        chain,
        EthereumAddress.fromHex(contractAddress),
      );
  final escrowService = (await harness.seeds.factory.buildEscrowServices(
    contractAddress: contractAddress,
    multiEscrowBytecodeHash: bytecodeHash,
  )).first;
  await hostr.auth.signin(MockKeys.escrow.privateKey!);
  await hostr.escrows.upsert(escrowService);
  await hostr.auth.logout();
  await hostr.ndk.relays.closeAllTransports();

  await hostr.auth.signin(host.privateKey);
  if (host.identityClaims != null) {
    await hostr.identityClaims.upsert(host.identityClaims!);
  }
  await hostr.metadata.upsert(host.profile);
  await hostr.metadata.ensureSellerConfig(host.keyPair.publicKey);
  final hostEscrowMethod = await hostr.escrowMethods.myMethod();
  if (hostEscrowMethod == null) {
    throw StateError('Host escrow method was not published for payment proof');
  }

  final runId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  var createdAt =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 +
      const Duration(minutes: 20).inSeconds;
  Listing listing({
    required String suffix,
    required String title,
    required DenominatedAmount amount,
    required bool negotiable,
  }) {
    return harness.seeds.entities.listing(
      signer: host.keyPair,
      dTag: 'payment-proof-$runId-$suffix',
      title: title,
      description: '$title fixture for payment proof orchestrator tests.',
      price: [Price(amount: amount, frequency: Frequency.daily)],
      location: 'San Salvador, El Salvador',
      type: ListingType.apartment,
      negotiable: negotiable,
      instantBook: false,
      createdAt: createdAt++,
      specifications: Specifications({
        'max_guests': 2,
        'bedrooms': 1,
        'beds': 1,
        'bathrooms': 1,
      }),
      images: ['https://picsum.photos/seed/payment-proof-$suffix/1200/800'],
    );
  }

  final btcListing = listing(
    suffix: 'btc',
    title: 'Payment Proof BTC Stay',
    amount: DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(25000),
    ),
    negotiable: false,
  );
  final usdListing = listing(
    suffix: 'usd',
    title: 'Payment Proof USDT Stay',
    amount: DenominatedAmount.fromDecimal('12', 'USD', 6),
    negotiable: false,
  );
  final negotiatedBtcListing = listing(
    suffix: 'neg-btc',
    title: 'Payment Proof Negotiated BTC Stay',
    amount: DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(30000),
    ),
    negotiable: true,
  );
  final negotiatedUsdListing = listing(
    suffix: 'neg-usd',
    title: 'Payment Proof Negotiated USDT Stay',
    amount: DenominatedAmount.fromDecimal('20', 'USD', 6),
    negotiable: true,
  );
  for (final listing in [
    btcListing,
    usdListing,
    negotiatedBtcListing,
    negotiatedUsdListing,
  ]) {
    await hostr.listings.upsert(listing);
  }
  await _expectListingsReadable(hostr, [
    btcListing,
    usdListing,
    negotiatedBtcListing,
    negotiatedUsdListing,
  ]);
  await hostr.auth.logout();
  await hostr.ndk.relays.closeAllTransports();

  return _EscrowFixture(
    host: host,
    hostProfile: host.profile,
    escrowService: escrowService,
    hostEscrowMethod: hostEscrowMethod,
    btcListing: btcListing,
    usdListing: usdListing,
    negotiatedBtcListing: negotiatedBtcListing,
    negotiatedUsdListing: negotiatedUsdListing,
  );
}

Future<_PreparedTrade> _prepareTrade({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required _EscrowFixture fixture,
  required KeyPair buyer,
  required _PaymentProofCase testCase,
}) async {
  final listing = fixture.listingFor(testCase);
  final start = DateTime.now().toUtc().add(
    Duration(days: 21 + _PaymentProofCase.values.indexOf(testCase)),
  );
  final end = start.add(const Duration(days: 2));
  final listingAmount = listing.cost(start: start, end: end);
  final firstOfferAmount = switch (testCase) {
    _PaymentProofCase.negotiatedUsd => DenominatedAmount.fromDecimal(
      '15',
      'USD',
      6,
    ),
    _PaymentProofCase.negotiatedBtc => DenominatedAmount(
      denomination: 'BTC',
      decimals: 8,
      value: BigInt.from(25000),
    ),
    _ => listingAmount,
  };

  final firstOffer = await hostr.reservationRequests.createReservationRequest(
    listing: listing,
    startDate: start,
    endDate: end,
    amount: firstOfferAmount,
  );
  final tradeId = firstOffer.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Reservation request did not include a trade id');
  }
  hostr.userSubscriptions.trackTradeId(tradeId);

  final thread = hostr.messaging.threads.ensureTradeConversation(
    tradeId: tradeId,
    participants: {buyer.publicKey, fixture.host.publicKey},
  );
  _processReservationMessage(
    thread: thread,
    senderPubkey: buyer.publicKey,
    counterpartyPubkey: fixture.host.publicKey,
    buyerPubkey: buyer.publicKey,
    tradeId: tradeId,
    listing: listing,
    reservation: firstOffer,
  );
  await _waitForThreadRequestCount(
    thread: thread,
    expectedCount: 1,
    label: '${testCase.name} first offer',
  );

  var payableRequest = firstOffer;
  if (testCase.negotiated) {
    // Negotiated cases publish buyer offer -> host counter -> buyer counter
    // before funding. That keeps the lower-level test close to the UI flow
    // while still letting `dart test` isolate the payment-proof invariant.
    final hostCounterAmount = _amountBetween(firstOfferAmount, listingAmount);
    final hostCounter = await hostr.reservationRequests.createCounterOffer(
      listing: listing,
      previousRequest: firstOffer,
      amount: hostCounterAmount,
      signerKeyPair: fixture.host.keyPair,
    );
    _processReservationMessage(
      thread: thread,
      senderPubkey: fixture.host.publicKey,
      counterpartyPubkey: buyer.publicKey,
      buyerPubkey: buyer.publicKey,
      tradeId: tradeId,
      listing: listing,
      reservation: hostCounter,
    );
    await _waitForThreadRequestCount(
      thread: thread,
      expectedCount: 2,
      label: '${testCase.name} host counter',
    );

    final accountIndex = await hostr.tradeAccountAllocator
        .findTradeAccountIndexByTradeId(tradeId);
    final tradeKeyPair = await hostr.auth.hd.getTradeKeyPair(
      accountIndex: accountIndex,
    );
    final buyerCounterAmount = _amountBetween(
      firstOfferAmount,
      hostCounterAmount,
    );
    final buyerCounter = await hostr.reservationRequests.createCounterOffer(
      listing: listing,
      previousRequest: hostCounter,
      amount: buyerCounterAmount,
      signerKeyPair: tradeKeyPair,
    );
    _processReservationMessage(
      thread: thread,
      senderPubkey: buyer.publicKey,
      counterpartyPubkey: fixture.host.publicKey,
      buyerPubkey: buyer.publicKey,
      tradeId: tradeId,
      listing: listing,
      reservation: buyerCounter,
    );
    await _waitForThreadRequestCount(
      thread: thread,
      expectedCount: 3,
      label: '${testCase.name} buyer counter',
    );
    payableRequest = buyerCounter;
  }

  final selectedEscrow = harness.seeds.entities.escrowServiceSelected(
    signer: buyer,
    listingAnchor: listing.anchor!,
    threadAnchor: tradeId,
    sellerPubkey: fixture.host.publicKey,
    service: fixture.escrowService,
    sellerMethods: fixture.hostEscrowMethod,
    dTag: 'payment-proof-selected-$tradeId',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );

  print(
    'PAYMENT_PROOF_IT prepare case=${testCase.name} trade=$tradeId '
    'requests=${thread.state.value.reservationRequests.length} '
    'payableAmount=${payableRequest.amount}',
  );

  return _PreparedTrade(
    listing: listing,
    payableRequest: payableRequest,
    selectedEscrow: selectedEscrow,
    tradeId: tradeId,
  );
}

void _processReservationMessage({
  required Thread thread,
  required String senderPubkey,
  required String counterpartyPubkey,
  required String buyerPubkey,
  required String tradeId,
  required Listing listing,
  required Reservation reservation,
}) {
  thread.addRoutingParticipants([senderPubkey, counterpartyPubkey]);
  thread.process(
    Message(
      pubKey: senderPubkey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: MessageTags([
        [kConversationTag, tradeId],
        ['p', counterpartyPubkey],
        PTag.seller(listing.pubKey).toTag(),
        PTag.buyer(buyerPubkey).toTag(),
      ]),
      child: reservation,
      content: reservation.toString(),
    ),
  );
}

Future<void> _waitForThreadRequestCount({
  required Thread thread,
  required int expectedCount,
  required String label,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (thread.state.value.reservationRequests.length >= expectedCount) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TimeoutException(
    'Thread did not process $label before funding. '
    'expectedRequests=$expectedCount '
    'actualRequests=${thread.state.value.reservationRequests.length}',
  );
}

Future<void> _expectListingsReadable(
  Hostr hostr,
  List<Listing> listings,
) async {
  final ids = listings.map((listing) => listing.id).toSet();
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    final published = await hostr.listings.list(
      Filter(ids: ids.toList()),
      name: 'payment-proof-listing-fixture-verify',
    );
    final publishedIds = published.map((listing) => listing.id).toSet();
    if (publishedIds.containsAll(ids)) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TimeoutException('Listing fixtures were not readable from relay');
}

Future<void> _expectProofReadableFromRelay({
  required Hostr hostr,
  required String tradeId,
  required String sellerPubkey,
  required String txHash,
  required String label,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  var lastSeen = const <Reservation>[];
  while (DateTime.now().isBefore(deadline)) {
    lastSeen = await hostr.orderWorkflows.getByTradeId(tradeId);
    if (lastSeen.any(
      (reservation) =>
          _isBuyerEscrowProofReservation(
            reservation: reservation,
            tradeId: tradeId,
            sellerPubkey: sellerPubkey,
          ) &&
          reservation.proof?.escrowProof?.txHash.toLowerCase() ==
              txHash.toLowerCase(),
    )) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TimeoutException(
    'Self-signed proof update fired but relay query could not read it for '
    '$label. lastSeen=${_describeReservations(lastSeen, sellerPubkey)}',
  );
}

bool _isBuyerEscrowProofReservation({
  required Reservation reservation,
  required String tradeId,
  required String sellerPubkey,
}) {
  return reservation.getDtag() == tradeId &&
      reservation.isCommit &&
      reservation.pubKey != sellerPubkey &&
      reservation.proof?.escrowProof != null;
}

String _snapshot(Hostr hostr, String tradeId) {
  final threads = hostr.messaging.threads.findByConversationTag(tradeId);
  final threadSummary = threads
      .map(
        (thread) =>
            '${thread.anchor}:requests='
            '${thread.state.value.reservationRequests.map((request) => '${request.pubKey.substring(0, 8)}:${request.stage.name}:${request.amount}').join(",")}',
      )
      .join(' | ');
  final cachedReservations = hostr
      .userSubscriptions
      .allMyReservations$
      .stream
      .items
      .where((reservation) => reservation.getDtag() == tradeId);
  return 'threads=[$threadSummary] '
      'cachedReservations=${_describeReservations(cachedReservations, '')}';
}

String _describeReservations(
  Iterable<Reservation> reservations,
  String sellerPubkey,
) {
  final values = reservations
      .map(
        (reservation) =>
            '${reservation.pubKey.substring(0, 8)}'
            ':${reservation.stage.name}'
            ':proof=${reservation.proof?.escrowProof?.txHash}'
            ':seller=${sellerPubkey.isNotEmpty && reservation.pubKey == sellerPubkey}',
      )
      .join(',');
  return values.isEmpty ? '[]' : '[$values]';
}

DenominatedAmount _amountBetween(
  DenominatedAmount low,
  DenominatedAmount high,
) {
  if (low.denomination != high.denomination || low.decimals != high.decimals) {
    return high;
  }
  final difference = high.value - low.value;
  if (difference <= BigInt.one) return high;
  return DenominatedAmount(
    denomination: low.denomination,
    decimals: low.decimals,
    value: low.value + (difference ~/ BigInt.two),
  );
}

Future<void> _resetSession(Hostr hostr) async {
  await hostr.paymentProofOrchestrator.reset();
  await hostr.backgroundWorker.stop();
  await hostr.calendar.stop();
  await hostr.fundsMonitor.reset();
  await hostr.userSubscriptions.reset();
  await hostr.messaging.threads.reset();
  await hostr.nwc.reset();
  await hostr.orderWorkflows.reset();
  await hostr.auth.logout();
  await hostr.ndk.relays.closeAllTransports();
}

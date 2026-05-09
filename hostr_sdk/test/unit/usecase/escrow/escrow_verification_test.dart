@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/evm/capabilities/escrow_capability.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01Utils;
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show BlockInformation;
import 'package:web3dart/web3dart.dart' show GeneratedContract;

final _f = EntityFactory();

class _FakeSupportedEscrowContract extends Fake
    implements SupportedEscrowContract<GeneratedContract> {
  _FakeSupportedEscrowContract(this.fundedEvent);

  final EscrowFundedEvent? fundedEvent;

  int allEventsCallCount = 0;
  int fundedEventFromTransactionCallCount = 0;

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
  }) {
    allEventsCallCount++;
    return StreamWithStatus<EscrowEvent>()
      ..addStatus(StreamStatusQueryComplete());
  }

  @override
  Future<EscrowFundedEvent?> fundedEventFromTransaction({
    required String tradeId,
    required String txHash,
    EscrowServiceSelected? selectedEscrow,
  }) async {
    fundedEventFromTransactionCallCount++;
    if (fundedEvent?.tradeId == tradeId &&
        fundedEvent?.transactionHash == txHash) {
      return fundedEvent;
    }
    return null;
  }
}

class _FakeEscrowCapability extends Fake implements EscrowCapability {
  _FakeEscrowCapability(this.contract);

  final SupportedEscrowContract<GeneratedContract> contract;

  @override
  SupportedEscrowContract<GeneratedContract> getSupportedEscrowContract(
    EscrowService escrowService,
  ) => contract;
}

class _FakeConfiguredEvmChain extends Fake implements EvmChain {
  _FakeConfiguredEvmChain(this._escrow);

  final EscrowCapability _escrow;

  @override
  EscrowCapability get escrow => _escrow;
}

class _FakeEvm extends Fake implements Evm {
  _FakeEvm(this._configured);

  final EvmChain _configured;

  @override
  EvmChain getChainForEscrowService(EscrowService service) => _configured;
}

Listing _listing({
  bool negotiable = true,
  int pricePerNightSats = 100000,
  List<Price>? price,
  DenominatedAmount? securityDeposit,
  int? maxDisputePeriod,
}) => _f.listing(
  signer: MockKeys.hoster,
  dTag: 'listing-escrow-verify',
  title: 'Escrow Verify Listing',
  description: 'Test listing',
  images: const ['https://picsum.photos/seed/escrow/800/600'],
  price: price,
  priceSats: pricePerNightSats,
  location: 'test-location',
  type: ListingType.house,
  specifications: Specifications(),
  negotiable: negotiable,
  allowSelfSignedReservation: true,
  instantBook: true,
  securityDeposit: securityDeposit,
  maxDisputePeriod: maxDisputePeriod,
  createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
);

EscrowService _escrowService() {
  return MOCK_ESCROWS(
    contractAddress: '0x000000000000000000000000000000000000dEaD',
    evmAddress: '0x000000000000000000000000000000000000bEEF',
  ).first;
}

EscrowMethod _escrowMethod({
  required EscrowService escrowService,
  bool includeAcceptedToken = true,
}) {
  final chosenEscrowType = escrowService.escrowType
      .toString()
      .split('.')
      .last
      .toLowerCase();
  final tags = <List<String>>[
    ['t', chosenEscrowType],
    ['c', escrowService.contractBytecodeHash],
    ['p', escrowService.pubKey],
    if (includeAcceptedToken)
      [kAcceptedPaymentFormTag, 'BTC', Token.native(30).tagId],
  ];
  final event = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowMethod,
      pubKey: MockKeys.hoster.publicKey,
      tags: tags,
      content: '',
      createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );
  return EscrowMethod.fromNostrEvent(event);
}

PaymentProof _paymentProof({
  required Listing listing,
  required String txHash,
  bool includeAcceptedToken = true,
}) {
  final escrowService = _escrowService();
  final hoster = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: 0,
      pubKey: MockKeys.hoster.publicKey,
      tags: const [],
      content: '',
      createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );

  return PaymentProof(
    hoster: hoster,
    listing: listing,
    zapProof: null,
    escrowProof: EscrowProof(
      txHash: txHash,
      escrowService: escrowService,
      hostsEscrowMethods: _escrowMethod(
        escrowService: escrowService,
        includeAcceptedToken: includeAcceptedToken,
      ),
    ),
  );
}

Reservation _reservation({
  required Listing listing,
  required DenominatedAmount? amount,
  required PaymentProof proof,
  bool includeSellerSignature = false,
}) {
  var reservation = Reservation.create(
    pubKey: MockKeys.guest.publicKey,
    dTag: 'trade-escrow-verify',
    listingAnchor: listing.anchor!,
    start: DateTime(2026, 3, 1),
    end: DateTime(2026, 3, 2),
    stage: ReservationStage.commit,
    quantity: 1,
    amount: amount,
    proof: proof,
  );

  if (includeSellerSignature) {
    final authorization = CommitAuthorization.create(
      pubKey: MockKeys.hoster.publicKey,
      listingAnchor: listing.anchor!,
      tradeId: reservation.getDtag()!,
      commitHash: reservation.commitHash(),
    ).signAs(MockKeys.hoster, CommitAuthorization.fromNostrEvent);
    reservation = reservation.copy(
      content: reservation.parsedContent.copyWith(
        commitAuthorization: authorization,
      ),
    );
  }

  return reservation.signAs(MockKeys.guest, Reservation.fromNostrEvent);
}

EscrowFundedEvent _fundedEvent({
  required String tradeId,
  required String txHash,
  required int amountSats,
  int? bondAmountSats,
  int unlockAt = 0,
}) {
  return EscrowFundedEvent(
    tradeId: tradeId,
    blockNum: 1,
    block: BlockInformation(baseFeePerGas: null, timestamp: DateTime.utc(2026)),
    transactionHash: txHash,
    chainId: 412346,
    contractAddress: '0x0000000000000000000000000000000000000001',
    transactionIndex: 0,
    logIndex: 0,
    amount: rbtcFromSats(BigInt.from(amountSats)),
    bondAmount: bondAmountSats != null
        ? rbtcFromSats(BigInt.from(bondAmountSats))
        : null,
    unlockAt: unlockAt,
  );
}

void main() {
  test(
    'uses seller-signed negotiated amount when validating escrow funding',
    () async {
      final listing = _listing();
      const txHash = '0xnegotiated';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: DenominatedAmount(
          value: BigInt.from(80000),
          denomination: 'BTC',
          decimals: 8,
        ),
        proof: proof,
        includeSellerSignature: true,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 80000,
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
      expect(result.fundedEvent, isNotNull);
      expect(contract.fundedEventFromTransactionCallCount, 1);
      expect(contract.allEventsCallCount, 0);
    },
  );

  test(
    'uses seller-signed cross-denomination amount when listing price changed',
    () async {
      final listing = _listing(
        price: [
          Price(
            amount: DenominatedAmount(
              value: BigInt.from(5000000),
              denomination: 'USD',
              decimals: 6,
            ),
            frequency: Frequency.daily,
          ),
        ],
      );
      const txHash = '0xcross-denomination';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: DenominatedAmount(
          value: BigInt.from(5003),
          denomination: 'BTC',
          decimals: 8,
        ),
        proof: proof,
        includeSellerSignature: true,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 5003,
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
      expect(result.fundedEvent, isNotNull);
    },
  );

  test(
    'falls back to listing amount when negotiated amount lacks seller signature',
    () async {
      final listing = _listing();
      const txHash = '0xlisting';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: DenominatedAmount(
          value: BigInt.from(80000),
          denomination: 'BTC',
          decimals: 8,
        ),
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 80000,
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('listing amount'));
      expect(result.reason, contains('Missing valid host commitment'));
    },
  );

  test(
    'fails when host escrow method does not accept the funded token',
    () async {
      final listing = _listing();
      const txHash = '0xmissing-accepted-token';
      final proof = _paymentProof(
        listing: listing,
        txHash: txHash,
        includeAcceptedToken: false,
      );
      final reservation = _reservation(
        listing: listing,
        amount: DenominatedAmount(
          value: BigInt.from(100000),
          denomination: 'BTC',
          decimals: 8,
        ),
        proof: proof,
        includeSellerSignature: true,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('does not accept token'));
    },
  );

  // ── Security deposit (bond) verification ──────────────────────────

  test(
    'valid when listing has security deposit and bond is escrowed',
    () async {
      final listing = _listing(
        securityDeposit: DenominatedAmount(
          value: BigInt.from(50000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      const txHash = '0xbond-valid';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          bondAmountSats: 50000,
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
      expect(result.fundedEvent, isNotNull);
      expect(result.fundedEvent!.bondAmount, isNotNull);
    },
  );

  test(
    'invalid when listing has security deposit but no bond escrowed',
    () async {
      final listing = _listing(
        securityDeposit: DenominatedAmount(
          value: BigInt.from(50000),
          denomination: 'BTC',
          decimals: 8,
        ),
      );
      const txHash = '0xbond-missing';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          // no bondAmountSats → null bond
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('security deposit'));
      expect(result.reason, contains('no bond'));
    },
  );

  test('invalid when bond is less than required security deposit', () async {
    final listing = _listing(
      securityDeposit: DenominatedAmount(
        value: BigInt.from(50000),
        denomination: 'BTC',
        decimals: 8,
      ),
    );
    const txHash = '0xbond-insufficient';
    final proof = _paymentProof(listing: listing, txHash: txHash);
    final reservation = _reservation(
      listing: listing,
      amount: null,
      proof: proof,
    );

    final contract = _FakeSupportedEscrowContract(
      _fundedEvent(
        tradeId: reservation.getDtag()!,
        txHash: txHash,
        amountSats: 100000,
        bondAmountSats: 25000, // less than required 50000
      ),
    );
    final verification = EscrowVerification(
      evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
      logger: CustomLogger(),
    );

    final result = await verification.verify(reservation: reservation);

    expect(result.isValid, isFalse);
    expect(result.reason, contains('bond'));
    expect(result.reason, contains('less than required'));
  });

  test(
    'valid when listing has no security deposit and no bond escrowed',
    () async {
      final listing = _listing(); // no securityDeposit
      const txHash = '0xno-deposit';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          // no bond — fine since listing doesn't require one
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
    },
  );

  test('valid when bond exceeds required security deposit', () async {
    final listing = _listing(
      securityDeposit: DenominatedAmount(
        value: BigInt.from(50000),
        denomination: 'BTC',
        decimals: 8,
      ),
    );
    const txHash = '0xbond-excess';
    final proof = _paymentProof(listing: listing, txHash: txHash);
    final reservation = _reservation(
      listing: listing,
      amount: null,
      proof: proof,
    );

    final contract = _FakeSupportedEscrowContract(
      _fundedEvent(
        tradeId: reservation.getDtag()!,
        txHash: txHash,
        amountSats: 100000,
        bondAmountSats: 75000, // more than required 50000
      ),
    );
    final verification = EscrowVerification(
      evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
      logger: CustomLogger(),
    );

    final result = await verification.verify(reservation: reservation);

    expect(result.isValid, isTrue);
    expect(result.fundedEvent!.bondAmount!.value, greaterThan(BigInt.zero));
  });

  // ── Max claim period verification ─────────────────────────────────

  test(
    'valid when unlockAt is within maxDisputePeriod of reservation end',
    () async {
      // Reservation end: DateTime(2026, 3, 2) — use same value for endUnix.
      final endUnix =
          DateTime(2026, 3, 2).toUtc().millisecondsSinceEpoch ~/ 1000;
      const oneWeek = 7 * 24 * 60 * 60;

      final listing = _listing(maxDisputePeriod: oneWeek);
      const txHash = '0xclaim-period-ok';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          unlockAt: endUnix + oneWeek, // exactly at the limit
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
    },
  );

  test(
    'invalid when unlockAt exceeds maxDisputePeriod after reservation end',
    () async {
      final endUnix =
          DateTime(2026, 3, 2).toUtc().millisecondsSinceEpoch ~/ 1000;
      const oneWeek = 7 * 24 * 60 * 60;

      final listing = _listing(maxDisputePeriod: oneWeek);
      const txHash = '0xclaim-period-exceeded';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          unlockAt: endUnix + oneWeek + 1, // 1 second over the limit
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('unlockAt'));
      expect(result.reason, contains('maxDisputePeriod'));
    },
  );

  test(
    'uses default 2-week maxDisputePeriod when listing does not set one',
    () async {
      final endUnix =
          DateTime(2026, 3, 2).toUtc().millisecondsSinceEpoch ~/ 1000;
      const twoWeeks = 14 * 24 * 60 * 60;

      final listing = _listing(); // no explicit maxDisputePeriod → default
      const txHash = '0xclaim-period-default';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      // Exactly at 2-week limit → valid
      final contractOk = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          unlockAt: endUnix + twoWeeks,
        ),
      );
      final verificationOk = EscrowVerification(
        evm: _FakeEvm(
          _FakeConfiguredEvmChain(_FakeEscrowCapability(contractOk)),
        ),
        logger: CustomLogger(),
      );
      final resultOk = await verificationOk.verify(reservation: reservation);
      expect(resultOk.isValid, isTrue);

      // 1 second over → invalid
      final contractBad = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          unlockAt: endUnix + twoWeeks + 1,
        ),
      );
      final verificationBad = EscrowVerification(
        evm: _FakeEvm(
          _FakeConfiguredEvmChain(_FakeEscrowCapability(contractBad)),
        ),
        logger: CustomLogger(),
      );
      final resultBad = await verificationBad.verify(reservation: reservation);
      expect(resultBad.isValid, isFalse);
      expect(resultBad.reason, contains('maxDisputePeriod'));
    },
  );

  test(
    'valid when unlockAt is before reservation end (within claim period)',
    () async {
      final endUnix =
          DateTime(2026, 3, 2).toUtc().millisecondsSinceEpoch ~/ 1000;

      final listing = _listing(maxDisputePeriod: 86400); // 1 day
      const txHash = '0xclaim-period-early';
      final proof = _paymentProof(listing: listing, txHash: txHash);
      final reservation = _reservation(
        listing: listing,
        amount: null,
        proof: proof,
      );

      final contract = _FakeSupportedEscrowContract(
        _fundedEvent(
          tradeId: reservation.getDtag()!,
          txHash: txHash,
          amountSats: 100000,
          unlockAt: endUnix - 3600, // before end date
        ),
      );
      final verification = EscrowVerification(
        evm: _FakeEvm(_FakeConfiguredEvmChain(_FakeEscrowCapability(contract))),
        logger: CustomLogger(),
      );

      final result = await verification.verify(reservation: reservation);

      expect(result.isValid, isTrue);
    },
  );
}

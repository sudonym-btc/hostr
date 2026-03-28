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
  _FakeSupportedEscrowContract(this.events);

  final StreamWithStatus<EscrowEvent> events;

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
  }) => events;
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

Listing _listing({bool allowBarter = true, int pricePerNightSats = 100000}) =>
    _f.listing(
      signer: MockKeys.hoster,
      dTag: 'listing-escrow-verify',
      title: 'Escrow Verify Listing',
      description: 'Test listing',
      images: const ['https://picsum.photos/seed/escrow/800/600'],
      priceSats: pricePerNightSats,
      location: 'test-location',
      type: ListingType.house,
      amenities: Amenities(),
      allowBarter: allowBarter,
      allowSelfSignedReservation: true,
      requiresEscrow: true,
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
    ['d', 'escrow-method'],
    ['t', chosenEscrowType],
    if (includeAcceptedToken) ['a', 'BTC', Token.native(30).tagId],
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
    reservation = reservation.copy(
      content: reservation.parsedContent.copyWith(
        signatures: {
          MockKeys.hoster.publicKey: reservation.signCommit(MockKeys.hoster),
        },
      ),
    );
  }

  return reservation.signAs(MockKeys.guest, Reservation.fromNostrEvent);
}

EscrowFundedEvent _fundedEvent({
  required String tradeId,
  required String txHash,
  required int amountSats,
}) {
  return EscrowFundedEvent(
    tradeId: tradeId,
    block: BlockInformation(baseFeePerGas: null, timestamp: DateTime.utc(2026)),
    transactionHash: txHash,
    amount: rbtcFromSats(BigInt.from(amountSats)),
    unlockAt: 0,
  );
}

StreamWithStatus<EscrowEvent> _eventsSource(EscrowFundedEvent fundedEvent) {
  return StreamWithStatus<EscrowEvent>()
    ..add(fundedEvent)
    ..addStatus(StreamStatusQueryComplete());
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
        _eventsSource(
          _fundedEvent(
            tradeId: reservation.getDtag()!,
            txHash: txHash,
            amountSats: 80000,
          ),
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
        _eventsSource(
          _fundedEvent(
            tradeId: reservation.getDtag()!,
            txHash: txHash,
            amountSats: 80000,
          ),
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
        _eventsSource(
          _fundedEvent(
            tradeId: reservation.getDtag()!,
            txHash: txHash,
            amountSats: 100000,
          ),
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
}

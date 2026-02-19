part of 'deterministic_seed_builder.dart';

extension _DeterministicSeedThreads on DeterministicSeedBuilder {
  Future<List<SeedThread>> buildThreads({
    required List<SeedUser> hosts,
    required List<SeedUser> guests,
    required List<Listing> listings,
    required Map<String, ProfileMetadata> hostProfileByPubkey,
    required EscrowService escrowService,
    required Map<String, EscrowTrust> hostTrustByPubkey,
    required Map<String, EscrowMethod> hostMethodByPubkey,
  }) async {
    final threads = <SeedThread>[];
    var threadIndex = 0;

    for (final guest in guests) {
      for (var i = 0; i < config.reservationRequestsPerGuest; i++) {
        threadIndex++;
        final listing = listings[_random.nextInt(listings.length)];
        final host =
            _findUserByPubkey(listing.pubKey, hosts) ??
            SeedUser(
              index: -1,
              keyPair: MockKeys.hoster,
              isHost: true,
              hasEvm: true,
            );

        if (host.keyPair.publicKey == guest.keyPair.publicKey) {
          continue;
        }

        final start = _baseDate.add(Duration(days: 10 + _random.nextInt(180)));
        final end = start.add(Duration(days: 1 + _random.nextInt(6)));
        final salt = 'seed-${config.seed}-thread-$threadIndex';

        final request = ReservationRequest(
          pubKey: guest.keyPair.publicKey,
          tags: ReservationRequestTags([
            [kListingRefTag, listing.anchor!],
            ['d', 'seed-rr-$threadIndex'],
          ]),
          createdAt: _timestampDaysAfter(30 + threadIndex),
          content: ReservationRequestContent(
            start: start,
            end: end,
            quantity: 1,
            amount: listing.cost(start, end),
            salt: salt,
          ),
        ).signAs(guest.keyPair, ReservationRequest.fromNostrEvent);

        final shouldUseEscrow =
            host.hasEvm && _pickByRatio(config.paidViaEscrowRatio);

        final commitmentHash = ParticipationProof.computeCommitmentHash(
          guest.keyPair.publicKey,
          salt,
        );

        Nip01Event? zapReceipt;
        EscrowOutcome? escrowOutcome;
        PaymentProof? proof;

        if (shouldUseEscrow) {
          final outcome = _pickEscrowOutcome();
          escrowOutcome = outcome;
          final trust = hostTrustByPubkey[host.keyPair.publicKey];
          final method = hostMethodByPubkey[host.keyPair.publicKey];
          final hostProfile = hostProfileByPubkey[host.keyPair.publicKey];
          if (trust != null && method != null) {
            final escrowProof = await _createEscrowProof(
              threadIndex: threadIndex,
              request: request,
              host: host,
              guest: guest,
              outcome: outcome,
              escrowService: escrowService,
              trust: trust,
              method: method,
            );

            proof = PaymentProof(
              hoster: hostProfile ?? MOCK_PROFILES.first,
              listing: listing,
              zapProof: null,
              escrowProof: escrowProof,
            );
          }
        } else {
          final hostProfile = hostProfileByPubkey[host.keyPair.publicKey];
          zapReceipt = _buildZapReceipt(
            threadIndex: threadIndex,
            request: request,
            listing: listing,
            host: host,
            guest: guest,
            hostProfile: hostProfile,
          );

          proof = PaymentProof(
            hoster: hostProfile ?? MOCK_PROFILES.first,
            listing: listing,
            zapProof: ZapProof(receipt: Nip01EventModel.fromEntity(zapReceipt)),
            escrowProof: null,
          );
        }

        final reservation = Reservation(
          pubKey: guest.keyPair.publicKey,
          tags: ReservationTags([
            [kListingRefTag, listing.anchor!],
            [kThreadRefTag, request.anchor!],
            ['d', 'seed-rsv-$threadIndex'],
            [kCommitmentHashTag, commitmentHash],
            if (escrowOutcome != null) ['escrowOutcome', escrowOutcome.name],
          ]),
          createdAt: _timestampDaysAfter(31 + threadIndex),
          content: ReservationContent(start: start, end: end, proof: proof),
        ).signAs(guest.keyPair, Reservation.fromNostrEvent);

        threads.add(
          SeedThread(
            host: host,
            guest: guest,
            listing: listing,
            request: request,
            reservation: reservation,
            zapReceipt: zapReceipt,
            paidViaEscrow: shouldUseEscrow,
            escrowOutcome: escrowOutcome,
            salt: salt,
          ),
        );
      }
    }

    return threads;
  }

  Future<EscrowProof> _createEscrowProof({
    required int threadIndex,
    required ReservationRequest request,
    required SeedUser host,
    required SeedUser guest,
    required EscrowOutcome outcome,
    required EscrowService escrowService,
    required EscrowTrust trust,
    required EscrowMethod method,
  }) async {
    final contract = _multiEscrowContract(
      escrowService.parsedContent.contractAddress,
    );
    final tradeId = getBytes32(request.id);
    final tradeIdHex = request.id;
    final amountWei =
        request.parsedContent.amount.value * BigInt.from(10).pow(10);

    final guestCredentials = EthPrivateKey.fromHex(guest.keyPair.privateKey!);
    final hostCredentials = EthPrivateKey.fromHex(host.keyPair.privateKey!);
    final arbiterCredentials = EthPrivateKey.fromHex(
      MockKeys.escrow.privateKey!,
    );

    final buyer = getEvmCredentials(guest.keyPair.privateKey!).address;
    final seller = getEvmCredentials(host.keyPair.privateKey!).address;
    final arbiter = getEvmCredentials(MockKeys.escrow.privateKey!).address;

    final unlockAt = BigInt.from(
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 600,
    );

    final createTxHash = await contract.createTrade(
      (
        tradeId: tradeId,
        buyer: buyer,
        seller: seller,
        arbiter: arbiter,
        unlockAt: unlockAt,
        escrowFee: BigInt.zero,
      ),
      credentials: guestCredentials,
      transaction: Transaction(
        value: EtherAmount.inWei(amountWei),
        maxGas: 450000,
      ),
    );

    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex outcome=${outcome.name} '
      'fundTx=$createTxHash amountWei=$amountWei buyer=${buyer.eip55With0x} '
      'seller=${seller.eip55With0x} arbiter=${arbiter.eip55With0x}',
    );

    if (outcome == EscrowOutcome.arbitrated) {
      final arbitrateTxHash = await contract.arbitrate(
        (tradeId: tradeId, factor: BigInt.from(700)),
        credentials: arbiterCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex arbitrateTx=$arbitrateTxHash factor=700',
      );
    } else if (outcome == EscrowOutcome.claimedByHost) {
      await _advanceChainTime(seconds: 900);
      final claimTxHash = await contract.claim(
        (tradeId: tradeId),
        credentials: hostCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex claimTx=$claimTxHash',
      );
    } else {
      final releaseTxHash = await contract.releaseToCounterparty(
        (tradeId: tradeId),
        credentials: hostCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex releaseTx=$releaseTxHash',
      );
    }

    return EscrowProof(
      txHash: createTxHash,
      escrowService: escrowService,
      hostsTrustedEscrows: trust,
      hostsEscrowMethods: method,
    );
  }

  List<Nip01Event> buildThreadMessages({required List<SeedThread> threads}) {
    final messages = <Nip01Event>[];

    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      final threadAnchor = thread.request.anchor!;

      final requestMessage = Nip01Utils.signWithPrivateKey(
        privateKey: thread.guest.keyPair.privateKey!,
        event: Nip01Event(
          pubKey: thread.guest.keyPair.publicKey,
          kind: kNostrKindDM,
          tags: [
            [kThreadRefTag, threadAnchor],
            ['p', thread.host.keyPair.publicKey],
          ],
          createdAt: _timestampDaysAfter(40 + i),
          content: thread.request.toString(),
        ),
      );
      messages.add(requestMessage);

      final extraMessageCount = _sampleAverage(
        config.messagesPerThreadAvg.toDouble(),
      );
      for (var m = 0; m < extraMessageCount; m++) {
        final fromGuest = m.isEven;
        final sender = fromGuest ? thread.guest : thread.host;
        final recipient = fromGuest ? thread.host : thread.guest;

        final msg = Nip01Utils.signWithPrivateKey(
          privateKey: sender.keyPair.privateKey!,
          event: Nip01Event(
            pubKey: sender.keyPair.publicKey,
            kind: kNostrKindDM,
            tags: [
              [kThreadRefTag, threadAnchor],
              ['p', recipient.keyPair.publicKey],
            ],
            createdAt: _timestampDaysAfter(41 + i + m),
            content:
                'Seed message ${m + 1} for thread ${i + 1} (${thread.paidViaEscrow ? 'escrow' : 'zap'})',
          ),
        );
        messages.add(msg);
      }
    }

    return messages;
  }

  List<Review> buildReviews({required List<SeedThread> threads}) {
    final reviews = <Review>[];

    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      if (!_pickByRatio(config.reviewRatio)) {
        continue;
      }

      final review = Review(
        pubKey: thread.guest.keyPair.publicKey,
        tags: ReviewTags([
          [kReservationRefTag, thread.reservation.anchor!],
          [kListingRefTag, thread.listing.anchor!],
          ['d', 'seed-review-${i + 1}'],
        ]),
        createdAt: _timestampDaysAfter(90 + i),
        content: ReviewContent(
          rating: 3 + _random.nextInt(3),
          content:
              'Deterministic review for listing ${thread.listing.anchor} (${thread.paidViaEscrow ? 'escrow' : 'zap'}).',
          proof: ParticipationProof(salt: thread.salt),
        ),
      ).signAs(thread.guest.keyPair, Review.fromNostrEvent);

      reviews.add(review);
    }

    return reviews;
  }

  Nip01Event _buildZapReceipt({
    required int threadIndex,
    required ReservationRequest request,
    required Listing listing,
    required SeedUser host,
    required SeedUser guest,
    required ProfileMetadata? hostProfile,
  }) {
    final amountMsats = request.parsedContent.amount.value * BigInt.from(1000);
    final lnurl = hostProfile != null
        ? Metadata.fromEvent(hostProfile).lud16
        : null;

    return Nip01Utils.signWithPrivateKey(
      privateKey: host.keyPair.privateKey!,
      event: Nip01Event(
        pubKey: host.keyPair.publicKey,
        kind: kNostrKindZapReceipt,
        tags: [
          ['bolt11', 'lnbc-seed-$threadIndex'],
          ['preimage', 'seed-preimage-$threadIndex'],
          ['amount', amountMsats.toString()],
          ['p', host.keyPair.publicKey],
          ['P', guest.keyPair.publicKey],
          ['e', request.id],
          ['l', listing.anchor!],
          if (lnurl != null) ['lnurl', lnurl],
          [
            'description',
            jsonEncode({'seed': config.seed, 'thread': threadIndex}),
          ],
        ],
        content: 'Seed zap payment',
        createdAt: _timestampDaysAfter(32 + threadIndex),
      ),
    );
  }

  SeedUser? _findUserByPubkey(String pubkey, List<SeedUser> users) {
    for (final user in users) {
      if (user.keyPair.publicKey == pubkey) {
        return user;
      }
    }
    return null;
  }

  EscrowOutcome _pickEscrowOutcome() {
    final value = _random.nextDouble();
    if (value < config.paidViaEscrowArbitrateRatio) {
      return EscrowOutcome.arbitrated;
    }

    if (value <
        config.paidViaEscrowArbitrateRatio + config.paidViaEscrowClaimedRatio) {
      return EscrowOutcome.claimedByHost;
    }

    return EscrowOutcome.releaseToCounterparty;
  }
}

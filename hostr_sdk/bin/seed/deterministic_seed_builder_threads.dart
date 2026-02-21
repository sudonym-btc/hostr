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

        final chainNow = (await _chainClient().getBlockInformation()).timestamp
            .toUtc();
        final now = chainNow;
        final isFutureReservation = _pickByRatio(0.5);
        final stayDays = 1 + _random.nextInt(6);
        late final DateTime start;
        late final DateTime end;
        if (isFutureReservation) {
          start = now.add(Duration(days: 3 + _random.nextInt(180)));
          end = start.add(Duration(days: stayDays));
        } else {
          end = now.subtract(Duration(days: 1 + _random.nextInt(180)));
          start = end.subtract(Duration(days: stayDays));
        }
        final salt = 'seed-${config.seed}-thread-$threadIndex';

        final commitmentHash = ParticipationProof.computeCommitmentHash(
          guest.keyPair.publicKey,
          salt,
        );

        final request = ReservationRequest(
          pubKey: guest.keyPair.publicKey,
          tags: ReservationRequestTags([
            [kListingRefTag, listing.anchor!],
            ['d', commitmentHash],
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

        Reservation? reservation;

        final escrowEligible = end.isAfter(
          chainNow.add(const Duration(seconds: 30)),
        );

        final isCompleted = _pickByRatio(config.completedRatio);
        final shouldUseEscrow =
            isCompleted &&
            escrowEligible &&
            host.hasEvm &&
            _pickByRatio(config.paidViaEscrowRatio);

        Nip01Event? zapReceipt;
        EscrowOutcome? escrowOutcome;
        PaymentProof? proof;

        if (isCompleted && shouldUseEscrow) {
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
        } else if (isCompleted) {
          final hostProfile = hostProfileByPubkey[host.keyPair.publicKey];
          zapReceipt = _buildZapReceipt(
            threadIndex: threadIndex,
            commitmentHash: commitmentHash,
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

        if (isCompleted) {
          reservation = Reservation(
            pubKey: guest.keyPair.publicKey,
            tags: ReservationTags([
              [kListingRefTag, listing.anchor!],
              [kThreadRefTag, request.getDtag()!],
              ['d', 'seed-rsv-$threadIndex'],
              [kCommitmentHashTag, commitmentHash],
              if (escrowOutcome != null) ['escrowOutcome', escrowOutcome.name],
            ]),
            createdAt: _timestampDaysAfter(31 + threadIndex),
            content: ReservationContent(start: start, end: end, proof: proof),
          ).signAs(guest.keyPair, Reservation.fromNostrEvent);
        }

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
    final tradeIdHex = request.getDtag() ?? '';
    final tradeId = getBytes32(tradeIdHex);
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
      request.parsedContent.end.toUtc().millisecondsSinceEpoch ~/ 1000,
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
    await _assertTxSucceeded(
      txHash: createTxHash,
      threadIndex: threadIndex,
      stage: 'createTrade',
      tradeIdHex: tradeIdHex,
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
      await _assertTxSucceeded(
        txHash: arbitrateTxHash,
        threadIndex: threadIndex,
        stage: 'arbitrate',
        tradeIdHex: tradeIdHex,
      );
    } else if (outcome == EscrowOutcome.claimedByHost) {
      final nowSeconds =
          (await _chainClient().getBlockInformation()).timestamp
              .toUtc()
              .millisecondsSinceEpoch ~/
          1000;
      final unlockAtSeconds = unlockAt.toInt();
      if (unlockAtSeconds >= nowSeconds) {
        await _advanceChainTime(seconds: (unlockAtSeconds - nowSeconds) + 1);
      }
      final claimTxHash = await contract.claim(
        (tradeId: tradeId),
        credentials: hostCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex claimTx=$claimTxHash',
      );
      await _assertTxSucceeded(
        txHash: claimTxHash,
        threadIndex: threadIndex,
        stage: 'claim',
        tradeIdHex: tradeIdHex,
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
      await _assertTxSucceeded(
        txHash: releaseTxHash,
        threadIndex: threadIndex,
        stage: 'releaseToCounterparty',
        tradeIdHex: tradeIdHex,
      );
    }

    return EscrowProof(
      txHash: createTxHash,
      escrowService: escrowService,
      hostsTrustedEscrows: trust,
      hostsEscrowMethods: method,
    );
  }

  Future<void> _assertTxSucceeded({
    required String txHash,
    required int threadIndex,
    required String stage,
    required String tradeIdHex,
  }) async {
    final receipt = await _waitForReceipt(txHash);
    if (receipt == null) {
      final tx = await _chainClient().getTransactionByHash(txHash);
      throw Exception(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex stage=$stage tx=$txHash has no receipt '
        '(txKnown=${tx != null})',
      );
    }
    if (receipt.status != true) {
      throw Exception(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex stage=$stage tx=$txHash failed (status=${receipt.status})',
      );
    }
  }

  Future<dynamic> _waitForReceipt(String txHash) async {
    const maxAttempts = 30;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final receipt = await _chainClient().getTransactionReceipt(txHash);
      if (receipt != null) {
        return receipt;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return null;
  }

  Future<List<Nip01Event>> buildThreadMessages({
    required List<SeedThread> threads,
  }) async {
    final messages = <Nip01Event>[];
    final giftWrapNdk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        defaultQueryTimeout: const Duration(seconds: 10),
        bootstrapRelays: [
          if (config.relayUrl != null && config.relayUrl!.isNotEmpty)
            config.relayUrl!,
        ],
      ),
    );
    try {
      for (var i = 0; i < threads.length; i++) {
        final thread = threads[i];
        final threadAnchor = thread.request.getDtag()!;

        final requestMessageWraps = await _giftWrapDmForParticipants(
          ndk: giftWrapNdk,
          sender: thread.guest,
          recipient: thread.host,
          tags: [
            [kThreadRefTag, threadAnchor],
            ['p', thread.host.keyPair.publicKey],
          ],
          createdAt: _timestampDaysAfter(40 + i),
          content: thread.request.toString(),
        );
        messages.addAll(requestMessageWraps);

        if (thread.paidViaEscrow && thread.reservation != null) {
          final escrowProof =
              thread.reservation!.parsedContent.proof?.escrowProof;
          if (escrowProof != null) {
            final selectedEscrow =
                EscrowServiceSelected(
                  pubKey: thread.guest.keyPair.publicKey,
                  tags: EscrowServiceSelectedTags([
                    [kListingRefTag, thread.listing.anchor!],
                    [kThreadRefTag, threadAnchor],
                    ['p', thread.host.keyPair.publicKey],
                    ['d', 'seed-escrow-selected-${i + 1}'],
                  ]),
                  createdAt: _timestampDaysAfter(40 + i),
                  content: EscrowServiceSelectedContent(
                    service: escrowProof.escrowService,
                    sellerTrusts: escrowProof.hostsTrustedEscrows,
                    sellerMethods: escrowProof.hostsEscrowMethods,
                  ),
                ).signAs(
                  thread.guest.keyPair,
                  EscrowServiceSelected.fromNostrEvent,
                );

            final selectedEscrowWraps = await _giftWrapDmForParticipants(
              ndk: giftWrapNdk,
              sender: thread.guest,
              recipient: thread.host,
              tags: [
                [kThreadRefTag, threadAnchor],
                ['p', thread.host.keyPair.publicKey],
              ],
              createdAt: _timestampDaysAfter(41 + i),
              content: selectedEscrow.toString(),
            );
            messages.addAll(selectedEscrowWraps);
          }
        }

        final extraMessageCount = _sampleAverage(
          config.messagesPerThreadAvg.toDouble(),
        );
        for (var m = 0; m < extraMessageCount; m++) {
          final fromGuest = m.isEven;
          final sender = fromGuest ? thread.guest : thread.host;
          final recipient = fromGuest ? thread.host : thread.guest;

          final wraps = await _giftWrapDmForParticipants(
            ndk: giftWrapNdk,
            sender: sender,
            recipient: recipient,
            tags: [
              [kThreadRefTag, threadAnchor],
              ['p', recipient.keyPair.publicKey],
            ],
            createdAt: _timestampDaysAfter(41 + i + m),
            content:
                'Seed message ${m + 1} for thread ${i + 1} (${thread.paidViaEscrow ? 'escrow' : 'zap'})',
          );
          messages.addAll(wraps);
        }
      }

      return messages;
    } finally {
      await giftWrapNdk.destroy();
    }
  }

  Future<List<Nip01Event>> _giftWrapDmForParticipants({
    required Ndk ndk,
    required SeedUser sender,
    required SeedUser recipient,
    required List<List<String>> tags,
    required int createdAt,
    required String content,
  }) async {
    _ensureLoggedInAsSender(ndk: ndk, sender: sender);

    final rumor = Nip01Event(
      pubKey: sender.keyPair.publicKey,
      kind: kNostrKindDM,
      tags: tags,
      createdAt: createdAt,
      content: content,
    );

    final toRecipient = await ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipient.keyPair.publicKey,
    );
    final toSender = await ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: sender.keyPair.publicKey,
    );

    return [toRecipient, toSender];
  }

  void _ensureLoggedInAsSender({required Ndk ndk, required SeedUser sender}) {
    final pubkey = sender.keyPair.publicKey;
    final privkey = sender.keyPair.privateKey!;

    if (ndk.accounts.hasAccount(pubkey)) {
      ndk.accounts.switchAccount(pubkey: pubkey);
      return;
    }

    ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privkey);
  }

  List<Review> buildReviews({required List<SeedThread> threads}) {
    final reviews = <Review>[];

    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      if (thread.reservation == null) {
        continue;
      }
      if (!_pickByRatio(config.reviewRatio)) {
        continue;
      }

      final rating = _pickReviewRating();

      final review = Review(
        pubKey: thread.guest.keyPair.publicKey,
        tags: ReviewTags([
          [kReservationRefTag, thread.reservation!.anchor!],
          [kListingRefTag, thread.listing.anchor!],
          ['d', 'seed-review-${i + 1}'],
        ]),
        createdAt: _timestampDaysAfter(90 + i),
        content: ReviewContent(
          rating: rating,
          content: _buildReviewContentForRating(
            rating: rating,
            paidViaEscrow: thread.paidViaEscrow,
          ),
          proof: ParticipationProof(salt: thread.salt),
        ),
      ).signAs(thread.guest.keyPair, Review.fromNostrEvent);

      reviews.add(review);
    }

    return reviews;
  }

  static const Map<int, List<String>> _reviewTemplatesByRating = {
    1: [
      'Unfortunately the stay did not match the listing photos and we had several issues during check-in.',
      'Communication was difficult and the space was not as clean as expected.',
      'This booking did not work out for us due to maintenance issues and poor responsiveness.',
      'The location was fine, but overall comfort and cleanliness were below expectations.',
    ],
    2: [
      'The place was acceptable for one night, but we ran into a few avoidable issues.',
      'Some parts of the stay were okay, but check-in and communication could be much better.',
      'Decent location, though the apartment needed better upkeep and clearer instructions.',
      'Not terrible, but the stay felt overpriced for the quality we received.',
    ],
    3: [
      'Solid stay overall with a convenient location, though there is room for improvement.',
      'The listing mostly matched expectations and we had a comfortable visit.',
      'Good value for a short trip, with a few minor issues that were manageable.',
      'A generally pleasant experience with straightforward check-in and decent amenities.',
    ],
    4: [
      'Very good stay with a clean space, easy check-in, and quick host communication.',
      'Great location and comfortable setup; we would happily book again.',
      'Everything went smoothly and the home felt welcoming throughout our trip.',
      'A really enjoyable stay with thoughtful touches and clear instructions.',
    ],
    5: [
      'Excellent stay from start to finish, exactly as described and beautifully prepared.',
      'Fantastic host and a wonderful space. One of our best booking experiences.',
      'Perfect for our trip: spotless, comfortable, and in an ideal location.',
      'Absolutely loved this place. Check-in was seamless and the stay exceeded expectations.',
    ],
  };

  static const Map<int, List<String>> _reviewPaymentNotesByRating = {
    1: [
      'Payment worked, but it did not make up for the problems during the stay.',
      'Transaction was completed, but our hosting experience was disappointing.',
    ],
    2: [
      'Payment was straightforward, though the stay itself needed improvement.',
      'No payment issues, but the hosting experience felt inconsistent.',
    ],
    3: [
      'Payment and booking flow were smooth and uncomplicated.',
      'The payment process was easy and matched what we expected.',
    ],
    4: [
      'Payment was smooth and the overall booking experience felt reliable.',
      'Everything from payment to check-out was clear and easy.',
    ],
    5: [
      'Flawless booking and payment experience from start to finish.',
      'Payment was instant and the whole process felt premium and stress-free.',
    ],
  };

  int _pickReviewRating() {
    final roll = _random.nextDouble();
    if (roll < 0.06) return 1;
    if (roll < 0.15) return 2;
    if (roll < 0.35) return 3;
    if (roll < 0.70) return 4;
    return 5;
  }

  String _buildReviewContentForRating({
    required int rating,
    required bool paidViaEscrow,
  }) {
    final clampedRating = rating.clamp(1, 5);
    final base = _pickFrom(_reviewTemplatesByRating[clampedRating]!);
    final paymentNote = _pickFrom(_reviewPaymentNotesByRating[clampedRating]!);
    final paymentKind = paidViaEscrow ? 'Escrow' : 'Zap';
    return '$base $paymentKind payment: $paymentNote';
  }

  Nip01Event _buildZapReceipt({
    required int threadIndex,
    required ReservationRequest request,
    required String commitmentHash,
    required Listing listing,
    required SeedUser host,
    required SeedUser guest,
    required ProfileMetadata? hostProfile,
  }) {
    final amountMsats = request.parsedContent.amount.value * BigInt.from(1000);
    final lnurl = hostProfile != null
        ? Metadata.fromEvent(hostProfile).lud16
        : null;

    final zapRequest = Nip01Utils.signWithPrivateKey(
      privateKey: guest.keyPair.privateKey!,
      event: Nip01Event(
        pubKey: guest.keyPair.publicKey,
        kind: kNostrKindZapRequest,
        tags: [
          ['p', host.keyPair.publicKey],
          ['amount', amountMsats.toString()],
          ['e', commitmentHash],
          ['l', listing.anchor!],
          if (lnurl != null) ['lnurl', lnurl],
        ],
        content: 'Seed zap request',
        createdAt: _timestampDaysAfter(31 + threadIndex),
      ),
    );

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
          ['e', zapRequest.getEId()!],
          ['l', listing.anchor!],
          if (lnurl != null) ['lnurl', lnurl],
          [
            'description',
            Nip01EventModel.fromEntity(zapRequest).toJsonString(),
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

  String _tradeIdHexForThread(int threadIndex) {
    final random = Random(config.seed * 1000000 + threadIndex);
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

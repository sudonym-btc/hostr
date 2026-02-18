import 'dart:convert';
import 'dart:math';

import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/usecase/payments/constants.dart';
import 'package:http/http.dart' as http;
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'seed_models.dart';

part 'deterministic_seed_builder_listings.dart';
part 'deterministic_seed_builder_threads.dart';
part 'deterministic_seed_builder_users.dart';
part 'deterministic_seed_builder_utils.dart';

enum EscrowOutcome { releaseToCounterparty, arbitrated, claimedByHost }

class SeedUser {
  final int index;
  final KeyPair keyPair;
  final bool isHost;
  final bool hasEvm;

  const SeedUser({
    required this.index,
    required this.keyPair,
    required this.isHost,
    required this.hasEvm,
  });
}

class SeedThread {
  final SeedUser host;
  final SeedUser guest;
  final Listing listing;
  final ReservationRequest request;
  final Reservation reservation;
  final Nip01Event? zapReceipt;
  final bool paidViaEscrow;
  final EscrowOutcome? escrowOutcome;
  final String salt;

  const SeedThread({
    required this.host,
    required this.guest,
    required this.listing,
    required this.request,
    required this.reservation,
    required this.zapReceipt,
    required this.paidViaEscrow,
    required this.escrowOutcome,
    required this.salt,
  });
}

class DeterministicSeedData {
  final List<SeedUser> users;
  final List<ProfileMetadata> profiles;
  final List<Listing> listings;
  final List<EscrowService> escrowServices;
  final List<EscrowTrust> escrowTrusts;
  final List<EscrowMethod> escrowMethods;
  final List<ReservationRequest> reservationRequests;
  final List<Nip01Event> threadMessages;
  final List<Reservation> reservations;
  final List<Nip01Event> zapReceipts;
  final List<Review> reviews;

  const DeterministicSeedData({
    required this.users,
    required this.profiles,
    required this.listings,
    required this.escrowServices,
    required this.escrowTrusts,
    required this.escrowMethods,
    required this.reservationRequests,
    required this.threadMessages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
  });

  List<Nip01Event> get allEvents => [
    ...profiles,
    ...escrowServices,
    ...escrowTrusts,
    ...escrowMethods,
    ...listings,
    ...reservationRequests,
    ...threadMessages,
    ...zapReceipts,
    ...reservations,
    ...reviews,
  ];

  SeedSummary get summary {
    final hosts = users.where((u) => u.isHost).length;
    return SeedSummary(
      users: users.length,
      hosts: hosts,
      guests: users.length - hosts,
      profiles: profiles.length,
      listings: listings.length,
      reservationRequests: reservationRequests.length,
      messages: threadMessages.length,
      reservations: reservations.length,
      zapReceipts: zapReceipts.length,
      reviews: reviews.length,
      escrowServices: escrowServices.length,
      escrowTrusts: escrowTrusts.length,
      escrowMethods: escrowMethods.length,
    );
  }
}

class DeterministicSeedBuilder {
  final DeterministicSeedConfig config;
  final String contractAddress;
  final String rpcUrl;
  final Random _random;
  final DateTime _baseDate;
  http.Client? _httpClient;
  Web3Client? _web3Client;
  final Map<String, MultiEscrow> _escrowContracts = {};

  DeterministicSeedBuilder({
    required this.config,
    required this.contractAddress,
    this.rpcUrl = 'http://localhost:8545',
  }) : _random = Random(config.seed),
       _baseDate = _computePastBaseDate(config);

  static DateTime _computePastBaseDate(DeterministicSeedConfig config) {
    final now = DateTime.now().toUtc();

    // Upper-bound the latest offset used by builder functions:
    // reviews are the furthest at roughly 90 + threadCount days.
    final maxThreads = config.userCount * config.reservationRequestsPerGuest;
    final safetyDays = 30;
    final totalBackDays = 90 + maxThreads + safetyDays;

    return now.subtract(Duration(days: totalBackDays));
  }

  Future<DeterministicSeedData> build() async {
    try {
      final users = buildUsers();
      final hosts = users.where((u) => u.isHost).toList(growable: false);
      final guests = users.where((u) => !u.isHost).toList(growable: false);

      final profiles = buildProfiles(users);
      final profileByPubkey = {for (final p in profiles) p.pubKey: p};

      final escrowServices = buildEscrowServices();
      final escrowTrusts = await buildEscrowTrusts(hosts);
      final escrowMethods = await buildEscrowMethods(hosts);
      final hostTrustByPubkey = {
        for (final trust in escrowTrusts) trust.pubKey: trust,
      };
      final hostMethodByPubkey = {
        for (final method in escrowMethods) method.pubKey: method,
      };

      final listings = buildListings(hosts);

      final threads = await buildThreads(
        hosts: hosts,
        guests: guests,
        listings: listings,
        hostProfileByPubkey: profileByPubkey,
        escrowService: escrowServices.first,
        hostTrustByPubkey: hostTrustByPubkey,
        hostMethodByPubkey: hostMethodByPubkey,
      );

      final reservationRequests = threads
          .map((thread) => thread.request)
          .toList(growable: false);
      final reservations = threads
          .map((thread) => thread.reservation)
          .toList(growable: false);
      final zapReceipts = threads
          .map((thread) => thread.zapReceipt)
          .whereType<Nip01Event>()
          .toList(growable: false);

      final threadMessages = buildThreadMessages(threads: threads);
      final reviews = buildReviews(threads: threads);

      return DeterministicSeedData(
        users: users,
        profiles: profiles,
        listings: listings,
        escrowServices: escrowServices,
        escrowTrusts: escrowTrusts,
        escrowMethods: escrowMethods,
        reservationRequests: reservationRequests,
        threadMessages: threadMessages,
        reservations: reservations,
        zapReceipts: zapReceipts,
        reviews: reviews,
      );
    } finally {
      _disposeWeb3Client();
    }
  }

  List<SeedUser> deriveUsers() {
    return buildUsers();
  }
}

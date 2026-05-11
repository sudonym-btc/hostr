@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/reservation_groups/reservation_group_participant_resolver.dart';
import 'package:hostr_sdk/usecase/reservations/reservation_participant_keyring.dart';
import 'package:hostr_sdk/usecase/reservations/reservation_participant_tags.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

class _FakeParticipantKeyring implements ReservationParticipantKeyring {
  final Map<String, ResolvedReservationParticipantProof> resolvedByPayload;
  int decryptCalls = 0;

  _FakeParticipantKeyring({this.resolvedByPayload = const {}});

  @override
  Future<bool> controlsPubkey({
    required String pubkey,
    required String tradeId,
  }) async {
    return resolvedByPayload.isNotEmpty;
  }

  @override
  Future<ResolvedReservationParticipantProof?> tryDecryptParticipantProof({
    required Reservation reservation,
    required ReservationParticipantProofTag proof,
  }) async {
    decryptCalls += 1;
    return resolvedByPayload[proof.payload];
  }
}

Reservation _reservation({
  required String tradeId,
  required String authorPubkey,
  required List<List<String>> extraTags,
}) {
  return Reservation.create(
    pubKey: authorPubkey,
    dTag: tradeId,
    listingAnchor: '30402:${MockKeys.hoster.publicKey}:listing-resolver',
    extraTags: extraTags,
  );
}

void main() {
  const tradeId = 'trade-resolved-participants';
  final tempBuyer = mockKeys[40];
  final escrow = MockKeys.escrow.publicKey;

  group('ReservationGroupParticipantResolver', () {
    test('returns raw participants unchanged when no proofs resolve', () async {
      final keyring = _FakeParticipantKeyring();
      final resolver = ReservationGroupParticipantResolver(keyring: keyring);
      final reservation = _reservation(
        tradeId: tradeId,
        authorPubkey: MockKeys.guest.publicKey,
        extraTags: [
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
        ],
      );
      final group = ReservationGroup(reservations: [reservation]);

      final resolved = await resolver.resolve(group);

      expect(resolved.group, same(group));
      expect(resolved.rawParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(resolved.resolvedParticipantSet, resolved.rawParticipantSet);
      expect(resolved.rawGroupId, group.groupId);
      expect(resolved.resolvedGroupId, group.groupId);
      expect(resolved.resolvedProofs, isEmpty);
      expect(resolved.hasResolvedParticipants, isFalse);
      expect(keyring.decryptCalls, 0);
    });

    test(
      'replaces hidden participant pubkeys and derives the unhidden thread id',
      () async {
        final proof = ResolvedReservationParticipantProof(
          participantPubkey: tempBuyer.publicKey,
          identityPubkey: MockKeys.guest.publicKey,
        );
        final keyring = _FakeParticipantKeyring(
          resolvedByPayload: {'buyer-proof': proof},
        );
        final resolver = ReservationGroupParticipantResolver(keyring: keyring);
        final reservation = _reservation(
          tradeId: tradeId,
          authorPubkey: tempBuyer.publicKey,
          extraTags: [
            ['p', MockKeys.hoster.publicKey, '', 'seller'],
            ['p', escrow, '', 'escrow'],
            ReservationParticipantProofTag(
              role: 'buyer',
              participantPubkey: tempBuyer.publicKey,
              recipientPubkey: MockKeys.hoster.publicKey,
              scheme: kReservationParticipantProofSchemeNip44,
              payloadHash: ReservationParticipantProofTag.hashPayload(
                'buyer-proof',
              ),
              payload: 'buyer-proof',
            ).toTag(),
          ],
        );
        final group = ReservationGroup(reservations: [reservation]);

        final resolved = await resolver.resolve(group);

        final unhiddenParticipants = {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
          escrow,
        };
        expect(resolved.rawParticipantSet, {
          tempBuyer.publicKey,
          MockKeys.hoster.publicKey,
          escrow,
        });
        expect(resolved.resolvedParticipantSet, unhiddenParticipants);
        expect(resolved.resolvedParticipantSetWithoutEscrow, {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
        });
        expect(resolved.rawGroupId, isNot(resolved.resolvedGroupId));
        expect(
          resolved.resolvedGroupId,
          Threads.conversationId(tradeId, unhiddenParticipants),
        );
        expect(resolved.identityByParticipantPubkey, {
          tempBuyer.publicKey: MockKeys.guest.publicKey,
        });
        expect(
          resolved.rawParticipantPubkeyForRole('buyer'),
          tempBuyer.publicKey,
        );
        expect(
          resolved.resolvedParticipantPubkeyForRole('buyer'),
          MockKeys.guest.publicKey,
        );
        expect(
          resolved.resolvedParticipantPubkeyForRole('seller'),
          MockKeys.hoster.publicKey,
        );
        expect(resolved.hasParticipantProofFor(tempBuyer.publicKey), isTrue);
        expect(resolved.hasResolvedProofFor(tempBuyer.publicKey), isTrue);
        expect(resolved.hasResolvedParticipants, isTrue);
        expect(keyring.decryptCalls, 1);
      },
    );

    test('deduplicates repeated resolved proofs for the same alias', () async {
      final proof = ResolvedReservationParticipantProof(
        participantPubkey: tempBuyer.publicKey,
        identityPubkey: MockKeys.guest.publicKey,
      );
      final keyring = _FakeParticipantKeyring(
        resolvedByPayload: {'buyer-proof-a': proof, 'buyer-proof-b': proof},
      );
      final resolver = ReservationGroupParticipantResolver(keyring: keyring);
      final reservation = _reservation(
        tradeId: tradeId,
        authorPubkey: tempBuyer.publicKey,
        extraTags: [
          ['p', MockKeys.hoster.publicKey, '', 'seller'],
          ReservationParticipantProofTag(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            recipientPubkey: MockKeys.hoster.publicKey,
            scheme: kReservationParticipantProofSchemeNip44,
            payloadHash: ReservationParticipantProofTag.hashPayload(
              'buyer-proof-a',
            ),
            payload: 'buyer-proof-a',
          ).toTag(),
          ReservationParticipantProofTag(
            role: 'buyer',
            participantPubkey: tempBuyer.publicKey,
            recipientPubkey: escrow,
            scheme: kReservationParticipantProofSchemeNip44,
            payloadHash: ReservationParticipantProofTag.hashPayload(
              'buyer-proof-b',
            ),
            payload: 'buyer-proof-b',
          ).toTag(),
        ],
      );

      final resolved = await resolver.resolve(
        ReservationGroup(reservations: [reservation]),
      );

      expect(resolved.resolvedProofs, hasLength(1));
      expect(resolved.resolvedParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(keyring.decryptCalls, 2);
    });

    test('maps reservation group streams into resolved participants', () async {
      final proof = ResolvedReservationParticipantProof(
        participantPubkey: tempBuyer.publicKey,
        identityPubkey: MockKeys.guest.publicKey,
      );
      final resolver = ReservationGroupParticipantResolver(
        keyring: _FakeParticipantKeyring(
          resolvedByPayload: {'buyer-proof': proof},
        ),
      );
      final source = StreamWithStatus<ReservationGroup>();
      final mapped = source.resolveParticipantSets(resolver: resolver);
      final next = mapped.replayStream.first;

      source.add(
        ReservationGroup(
          reservations: [
            _reservation(
              tradeId: tradeId,
              authorPubkey: tempBuyer.publicKey,
              extraTags: [
                ['p', MockKeys.hoster.publicKey, '', 'seller'],
                ReservationParticipantProofTag(
                  role: 'buyer',
                  participantPubkey: tempBuyer.publicKey,
                  recipientPubkey: MockKeys.hoster.publicKey,
                  scheme: kReservationParticipantProofSchemeNip44,
                  payloadHash: ReservationParticipantProofTag.hashPayload(
                    'buyer-proof',
                  ),
                  payload: 'buyer-proof',
                ).toTag(),
              ],
            ),
          ],
        ),
      );

      final resolved = await next;
      expect(resolved.resolvedParticipantSet, {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
    });

    test('maps validated group streams while preserving validation', () async {
      final resolver = ReservationGroupParticipantResolver(
        keyring: _FakeParticipantKeyring(),
      );
      final source = StreamWithStatus<Validation<ReservationGroup>>();
      final mapped = source.resolveParticipantSets(resolver: resolver);
      final next = mapped.replayStream.first;
      final group = ReservationGroup(
        reservations: [
          _reservation(
            tradeId: tradeId,
            authorPubkey: MockKeys.guest.publicKey,
            extraTags: [
              ['p', MockKeys.hoster.publicKey, '', 'seller'],
            ],
          ),
        ],
      );

      source.add(Invalid(group, 'nope'));

      final resolved = await next;
      expect(resolved.validation, isA<Invalid<ReservationGroup>>());
      expect((resolved.validation as Invalid<ReservationGroup>).reason, 'nope');
      expect(resolved.participants.group, same(group));
    });
  });
}

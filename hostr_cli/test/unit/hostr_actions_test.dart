import 'dart:io';

import 'package:hostr_cli/src/actions/hostr_actions.dart';
import 'package:test/test.dart';

import '../../bin/generate_mcp_types.dart';

void main() {
  test('action catalog publishes MCP tool names and typed input schemas', () {
    expect(
      HostrActionCatalog.all.map((spec) => spec.mcpToolName),
      containsAll([
        'hostr_session_status',
        'hostr_listings_search',
        'hostr_listings_list',
        'hostr_listings_create',
        'hostr_listings_edit',
        'hostr_listings_availability',
        'hostr_listings_reviews',
        'hostr_listings_reservationGroups',
        'hostr_reservations_negotiateOffer',
        'hostr_reservations_negotiateAccept',
        'hostr_reservations_pay',
        'hostr_reservations_commit',
        'hostr_reservations_cancel',
        'hostr_updates',
        'hostr_reply',
        'hostr_thread_view',
        'hostr_thread_message',
        'hostr_escrow_involve',
        'hostr_profile_show',
        'hostr_profile_edit',
        'hostr_trips_list',
        'hostr_bookings_list',
        'hostr_escrow_methods',
        'hostr_swaps_watch',
        'hostr_swaps_recoverAll',
        'hostr_swaps_list',
      ]),
    );

    expect(
      HostrActionCatalog.all.map((spec) => spec.id),
      isNot(contains('hostr.reservations.offer')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.mcpToolName).join('\n'),
      isNot(contains('counter')),
    );

    final reservation = HostrActionCatalog.byId(
      'hostr.reservations.negotiateOffer',
    );
    expect(reservation.inputTypeName, 'HostrReservationsOfferInput');
    expect(reservation.inputSchema, isNot(contains('required')));
    expect(
      reservation.typescriptInput,
      contains('HostrReservationsOfferInput'),
    );
  });

  test('listings search input normalizes optional fields safely', () {
    final input = HostrListingsSearchInput.fromJson({
      'location': '  Lisbon ',
      'features': [' wifi ', '', 'kitchen'],
      'limit': 500,
    });

    expect(input.location, 'Lisbon');
    expect(input.features, ['wifi', 'kitchen']);
    expect(input.limit, 50);
  });

  test('write action inputs default to dry run and expose dryRun controls', () {
    final create = HostrListingsCreateInput.fromJson({
      'title': 'MCP preview',
      'description': 'Preview listing',
      'address': '123 Test Street',
      'images': [
        {'url': 'https://hostr.network/example.jpg'},
      ],
      'prices': [
        {
          'amount': {'value': '42', 'currency': 'USD'},
        },
      ],
    });
    expect(create.dryRun, isTrue);

    final liveCreate = HostrListingsCreateInput.fromJson({
      'title': 'MCP live create',
      'description': 'Publish listing',
      'address': '123 Test Street',
      'images': [
        {'url': 'https://hostr.network/example.jpg'},
      ],
      'prices': [
        {
          'amount': {'value': '42', 'currency': 'USD'},
        },
      ],
      'dryRun': false,
    });
    expect(liveCreate.dryRun, isFalse);

    final reservation = HostrReservationsOfferInput.fromJson({
      'listingAnchor': 'naddr1...',
      'start': '2026-05-04T12:00:00Z',
      'end': '2026-05-05T12:00:00Z',
    });
    expect(reservation.dryRun, isTrue);
    expect(reservation.isFollowUpOffer, isFalse);

    final followUpOffer = HostrReservationsOfferInput.fromJson({
      'tradeId': 'trade-1',
      'amount': {'value': '1.50', 'currency': 'USD'},
    });
    expect(followUpOffer.tradeId, 'trade-1');
    expect(followUpOffer.amount?.value, '1.50');
    expect(followUpOffer.dryRun, isTrue);
    expect(followUpOffer.isFollowUpOffer, isTrue);

    final pay = HostrReservationPayInput.fromJson({'tradeId': 'trade-1'});
    expect(pay.dryRun, isTrue);

    final commit = HostrReservationCommitInput.fromJson({'swapId': 'swap-1'});
    expect(commit.dryRun, isTrue);

    final createSchema = HostrActionCatalog.byId(
      'hostr.listings.create',
    ).inputSchema;
    final createProperties = createSchema['properties'] as Map<String, Object?>;
    expect(createProperties, contains('dryRun'));
    expect(createProperties, isNot(contains('publish')));

    final offerSchema = HostrActionCatalog.byId(
      'hostr.reservations.negotiateOffer',
    ).inputSchema;
    final offerProperties = offerSchema['properties'] as Map<String, Object?>;
    expect(offerProperties, contains('dryRun'));
    expect(offerProperties, isNot(contains('broadcast')));

    final paySchema = HostrActionCatalog.byId(
      'hostr.reservations.pay',
    ).inputSchema;
    final payProperties = paySchema['properties'] as Map<String, Object?>;
    expect(payProperties, contains('dryRun'));
    expect(payProperties, isNot(contains('broadcast')));
    expect(payProperties, isNot(contains('publish')));
  });

  test('listing image inputs require upload URLs in MCP schema', () {
    final image = HostrListingImageInput.fromJson({
      'url': 'https://blossom.example/abc.jpg',
      'filename': 'room.png',
      'alt': 'Bedroom view',
      'mime': 'image/png',
    });
    expect(image.url, startsWith('https://blossom.example/'));
    expect(image.filename, 'room.png');
    expect(image.toJson(), containsPair('url', image.url));

    final createSchema = HostrActionCatalog.byId(
      'hostr.listings.create',
    ).inputSchema;
    final createProperties = createSchema['properties'] as Map<String, Object?>;
    final images = createProperties['images'] as Map<String, Object?>;
    final items = images['items'] as Map<String, Object?>;
    final imageProperties = items['properties'] as Map<String, Object?>;
    expect(items['required'], contains('url'));
    expect(imageProperties, contains('url'));
    expect(imageProperties, isNot(contains('dataUrl')));
    expect(imageProperties, isNot(contains('base64')));
    expect(imageProperties, isNot(contains('data')));
    expect(imageProperties, contains('filename'));
    expect(imageProperties, isNot(contains('path')));
    expect(images['description'], contains('accepts image URLs only'));
    expect(images['description'], contains('/mcp/uploads/images'));
    expect(images['description'], contains('original file bytes'));
    expect(images['description'], contains('Do not resize'));
    expect(images['description'], contains('Do not base64-encode'));
    expect(images['description'], contains('Do not start or serve'));
    expect(images['description'], contains('Never pass'));
  });

  test(
    'single-item aliases are accepted without schema forcing plural fields',
    () {
      final availability = HostrListingsAvailabilityInput.fromJson({
        'anchor': 'naddr1listing',
        'start': '2026-05-04T12:00:00Z',
        'end': '2026-05-05T12:00:00Z',
      });
      expect(availability.anchors, ['naddr1listing']);

      final availabilitySchema = HostrActionCatalog.byId(
        'hostr.listings.availability',
      ).inputSchema;
      expect(availabilitySchema['required'], ['start', 'end']);

      final reply = HostrReplyInput.fromJson({
        'recipientPubkey': 'npub-or-hex',
        'content': 'Hello',
      });
      expect(reply.recipientPubkeys, ['npub-or-hex']);
      expect(reply.dryRun, isTrue);

      final replySchema = HostrActionCatalog.byId('hostr.reply').inputSchema;
      expect(replySchema['required'], ['content']);
    },
  );

  test('action documentation teaches multi-step workflows', () {
    final docs = HostrActionCatalog.documentationMarkdown();
    expect(docs, contains('New listing workflow'));
    expect(docs, contains('Edit listing workflow'));
    expect(docs, contains('Negotiation workflow'));
    expect(docs, contains('Payment workflow'));
    expect(docs, contains('hostr_reservations_negotiateOffer'));
    expect(docs, contains('hostr_reservations_pay'));
    expect(docs, contains('hostr_reservations_commit'));
    expect(docs, contains('hostr_profile_show'));
    expect(docs, contains('hostr_trips_list'));
    expect(docs, contains('hostr_bookings_list'));
    expect(docs, contains('hostr_escrow_methods'));
    expect(docs, contains('dryRun: false'));
    expect(docs.toLowerCase(), isNot(contains('counter-offer')));
  });

  test('generated MCP TypeScript action types are up to date', () {
    final generated = File(
      '../ai/mcp-server/src/generated/hostr-actions.ts',
    ).readAsStringSync();

    expect(generated, generateHostrActionsTypescript());
  });
}

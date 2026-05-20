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
        'hostr_listings_orderGroups',
        'hostr_orders_negotiateOffer',
        'hostr_orders_negotiateAccept',
        'hostr_orders_pay',
        'hostr_orders_commit',
        'hostr_orders_cancel',
        'hostr_updates',
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
      isNot(contains('hostr.orders.offer')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.id),
      isNot(contains('hostr.reply')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.id),
      isNot(contains('hostr.escrow.service.update')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.mcpToolName),
      isNot(contains('hostr_reply')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.mcpToolName),
      isNot(contains('hostr_escrow_service_update')),
    );
    expect(
      HostrActionCatalog.all.map((spec) => spec.mcpToolName).join('\n'),
      isNot(contains('counter')),
    );

    final reservation = HostrActionCatalog.byId('hostr.orders.negotiateOffer');
    expect(reservation.inputTypeName, 'HostrOrdersOfferInput');
    expect(reservation.inputSchema, isNot(contains('required')));
    expect(reservation.typescriptInput, contains('HostrOrdersOfferInput'));
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
      'dTag': 'draft-listing-1',
    });
    expect(liveCreate.dryRun, isFalse);
    expect(liveCreate.dTag, 'draft-listing-1');
    expect(liveCreate.toListingJson(), containsPair('dTag', 'draft-listing-1'));

    final reservation = HostrOrdersOfferInput.fromJson({
      'listingAnchor': 'naddr1...',
      'start': '2026-05-04T12:00:00Z',
      'end': '2026-05-05T12:00:00Z',
    });
    expect(reservation.dryRun, isTrue);
    expect(reservation.isFollowUpOffer, isFalse);

    final followUpOffer = HostrOrdersOfferInput.fromJson({
      'tradeId': 'trade-1',
      'amount': {'value': '1.50', 'currency': 'USD'},
    });
    expect(followUpOffer.tradeId, 'trade-1');
    expect(followUpOffer.amount?.value, '1.50');
    expect(followUpOffer.dryRun, isTrue);
    expect(followUpOffer.isFollowUpOffer, isTrue);

    final pay = HostrOrderPayInput.fromJson({'tradeId': 'trade-1'});
    expect(pay.dryRun, isTrue);

    final commit = HostrOrderCommitInput.fromJson({'swapId': 'swap-1'});
    expect(commit.dryRun, isTrue);

    final createSchema = HostrActionCatalog.byId(
      'hostr.listings.create',
    ).inputSchema;
    final createProperties = createSchema['properties'] as Map<String, Object?>;
    expect(createProperties, contains('dryRun'));
    expect(createProperties, isNot(contains('publish')));

    final offerSchema = HostrActionCatalog.byId(
      'hostr.orders.negotiateOffer',
    ).inputSchema;
    final offerProperties = offerSchema['properties'] as Map<String, Object?>;
    expect(offerProperties, contains('dryRun'));
    expect(offerProperties, isNot(contains('broadcast')));

    final paySchema = HostrActionCatalog.byId('hostr.orders.pay').inputSchema;
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
    expect(createProperties, contains('dTag'));
    final dTag = createProperties['dTag'] as Map<String, Object?>;
    expect(dTag['description'], contains('reuse the dTag'));
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

      final message = HostrThreadMessageInput.fromJson({
        'recipientPubkey': 'npub-or-hex',
        'content': 'Hello',
      });
      expect(message.recipientPubkeys, ['npub-or-hex']);
      expect(message.dryRun, isTrue);

      final messageSchema = HostrActionCatalog.byId(
        'hostr.thread.message',
      ).inputSchema;
      expect(messageSchema['required'], ['content']);
    },
  );

  test('action documentation teaches multi-step workflows', () {
    final docs = HostrActionCatalog.documentationMarkdown();
    expect(docs, contains('New listing workflow'));
    expect(docs, contains('Edit listing workflow'));
    expect(docs, contains('Negotiation workflow'));
    expect(docs, contains('Payment workflow'));
    expect(docs, contains('hostr_orders_negotiateOffer'));
    expect(docs, contains('hostr_orders_pay'));
    expect(docs, contains('hostr_orders_commit'));
    expect(docs, contains('hostr_profile_show'));
    expect(docs, contains('hostr_trips_list'));
    expect(docs, contains('hostr_bookings_list'));
    expect(docs, contains('hostr_escrow_methods'));
    expect(docs, contains('dryRun: false'));
    expect(docs, contains('Hostr-created per-trade temporary pubkeys'));
    expect(docs.toLowerCase(), isNot(contains('counter-offer')));
  });

  test(
    'reservation privacy descriptions do not frame temp pubkeys as mismatches',
    () {
      final booking = HostrActionCatalog.byId('hostr.orders.bookAndPay');
      final trips = HostrActionCatalog.byId('hostr.trips.list');
      final swaps = HostrActionCatalog.byId('hostr.swaps.watch');

      for (final spec in [booking, trips, swaps]) {
        expect(spec.description, contains('temporary pubkey'));
        expect(spec.description, contains('identity mismatch'));
      }
    },
  );

  test('session connect contract avoids Nostr Connect listener races', () {
    final sessionConnect = HostrActionCatalog.byId('hostr.session.connect');
    expect(sessionConnect.description, contains('immediately call'));
    expect(sessionConnect.description, contains('wait true'));

    final schema = sessionConnect.inputSchema;
    final properties = schema['properties'] as Map<String, Object?>;
    expect(properties, contains('wait'));
    expect(properties, contains('regenerate'));
  });

  test('read-only action schemas do not expose dryRun', () {
    final offenders = HostrActionCatalog.all
        .where((spec) => spec.readOnly)
        .where((spec) {
          final properties = spec.inputSchema['properties'];
          return properties is Map && properties.containsKey('dryRun');
        })
        .map((spec) => spec.id)
        .toList();

    expect(offenders, isEmpty);
  });

  test('generated MCP TypeScript action types are up to date', () {
    final generated = File(
      '../ai/mcp-server/src/generated/hostr-actions.ts',
    ).readAsStringSync();

    expect(generated, generateHostrActionsTypescript());
  });
}

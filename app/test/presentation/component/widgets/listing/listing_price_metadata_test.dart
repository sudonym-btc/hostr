import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_list_item.dart';
import 'package:hostr/presentation/screens/shared/listing/listing_view.dart';
import 'package:models/main.dart';

Price _price() => Price(
  amount: DenominatedAmount(
    value: BigInt.from(100000),
    denomination: 'BTC',
    decimals: 8,
  ),
  frequency: Frequency.daily,
);

Future<void> _pumpWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('negotiable tag is a compact label, not a full chip', (
    tester,
  ) async {
    await _pumpWidget(tester, const ListingNegotiableTag());

    expect(
      find.byKey(const ValueKey('listing_negotiable_tag')),
      findsOneWidget,
    );
    expect(find.text('Negotiable'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);

    final label = tester.widget<Text>(find.text('Negotiable'));
    expect(label.style?.fontSize, 10.5);
    expect(label.style?.height, 1);
  });

  testWidgets('price metadata stays price-only so reviews align beside it', (
    tester,
  ) async {
    await _pumpWidget(tester, ListingPriceMetadataWidget(price: _price()));

    expect(find.byKey(const ValueKey('listing_negotiable_tag')), findsNothing);
    expect(find.text('Negotiable'), findsNothing);
  });

  testWidgets('listing detail summary places negotiable tag after reviews', (
    tester,
  ) async {
    await _pumpWidget(
      tester,
      const ListingDetailsReviewsSummary(
        reviewsSummaryWidget: Text('2 reviews / 3 stays'),
        negotiable: true,
      ),
    );

    expect(find.text('2 reviews / 3 stays'), findsOneWidget);
    expect(find.text('Negotiable'), findsOneWidget);

    final reviewsLeft = tester.getTopLeft(find.text('2 reviews / 3 stays'));
    final tagLeft = tester.getTopLeft(find.text('Negotiable'));
    expect(tagLeft.dx, greaterThan(reviewsLeft.dx));
  });
}

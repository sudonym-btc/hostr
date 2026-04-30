import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

const _testBolt11 =
    'lnbc10u1pdsw4dkpp5mmlhfpcw4rj0scnyqmw02yvwpn4h6d40wyep3yew8l954sfl6ucqdqq'
    'cqzysxqrrssaayzylslcav0sr3c7237mwea5k67vk7t3j6pdmvnuuadxy0dsj5zalg6merxgnd'
    'c74nc753lnuyx7t2sjecfpxp820r9use77n7vyqcpp7dlfy';

void main() {
  testWidgets('pay invoice popup fits inside a short viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PaymentExternalRequiredWidget(
            PayExternalRequired(
              params: PayParameters(to: 'satoshi@hostr.cc'),
              callbackDetails: LightningCallbackDetails(
                invoice: Bolt11PaymentRequest(_testBolt11),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final qrFinder = find.byKey(const ValueKey('payment_invoice_qr'));
    final qrSize = tester.getSize(qrFinder);
    final qrCenter = tester.getCenter(qrFinder);
    final screenCenterX = tester.view.physicalSize.width / 2;

    expect(qrSize.width, qrSize.height);
    expect(qrCenter.dx, closeTo(screenCenterX, 0.5));
  });
}

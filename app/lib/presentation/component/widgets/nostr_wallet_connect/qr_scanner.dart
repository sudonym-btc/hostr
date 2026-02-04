import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class NwcQrScannerWidget extends StatefulWidget {
  const NwcQrScannerWidget({super.key});

  @override
  State<StatefulWidget> createState() => NwcQrScannerWidgetState();
}

class NwcQrScannerWidgetState extends State<NwcQrScannerWidget>
    with WidgetsBindingObserver {
  CustomLogger logger = CustomLogger();
  final MobileScannerController controller = MobileScannerController(
      // required options for the scanner
      );

  StreamSubscription<Object?>? _subscription;

  @override
  initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Start listening to the barcode events.
    _subscription = controller.barcodes.listen(_handleQR);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  void _handleQR(BarcodeCapture code) {
    logger.i('QR code: ${code.barcodes}');
    // context.read<NostrWalletConnectCubit>().connect(code.value);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
            width: 300, // Set a fixed width for the container
            child: AspectRatio(
                aspectRatio: 1.0, // Set the aspect ratio to 1:1 (square)
                child: MobileScanner(controller: controller))));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(_handleQR);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();
  }
}

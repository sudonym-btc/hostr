import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class NwcQrScannerWidget extends StatefulWidget {
  final ValueChanged<String>? onScanned;
  const NwcQrScannerWidget({super.key, this.onScanned});

  @override
  State<StatefulWidget> createState() => NwcQrScannerWidgetState();
}

class NwcQrScannerWidgetState extends State<NwcQrScannerWidget>
    with WidgetsBindingObserver {
  CustomLogger logger = CustomLogger();
  final MobileScannerController controller = MobileScannerController(
    autoStart: true,
  );

  StreamSubscription<Object?>? _subscription;
  bool _handled = false;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = controller.barcodes.listen(_handleQR);
  }

  void _handleQR(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    logger.i('QR code scanned: $code');
    _handled = true;
    widget.onScanned?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: MobileScanner(controller: controller),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleQR);
        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await controller.dispose();
  }
}

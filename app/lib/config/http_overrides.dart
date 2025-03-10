import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // If not running as web app, check device proxy settings
    // incase traffic needs to be routed from physical device to local development server
    // if (!kIsWeb) {
    //   NativeProxyReader.proxySetting.then((value) {
    //     proxy = value;
    //   });
    //   client.findProxy = (url) {
    //     if (proxy != null && proxy.host != null && proxy.port != null) {
    //       return 'PROXY ${proxy.host}:${proxy.port}';
    //     } else {
    //       return 'DIRECT';
    //     }
    //   };
    // }

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      print('badCertificateCallback called for: $host:$port');
      print('Certificate: ${cert.subject}');
      return true;
    };
    return client;
  }
}

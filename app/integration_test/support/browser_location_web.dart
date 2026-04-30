import 'package:web/web.dart' as web;

void resetBrowserRouteForE2e() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}${location.search}#/',
  );
}

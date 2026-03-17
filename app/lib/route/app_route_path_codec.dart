import 'package:auto_route/auto_route.dart';

/// App-specific wrapper around AutoRoute's default parser.
///
/// This keeps the existing `AppDefaultRouteParser` call sites stable even when
/// the app does not need any custom path encoding/decoding behavior.
class AppDefaultRouteParser extends DefaultRouteParser {
  AppDefaultRouteParser(
    super.matcher, {
    super.includePrefixMatches = false,
    super.deepLinkTransformer,
  });
}

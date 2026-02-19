import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

@injectable
class ReviewActions {
  final ThreadTrade trade;

  ReviewActions({required this.trade});

  review() {
    throw UnimplementedError('Review action is not implemented yet');
  }
}

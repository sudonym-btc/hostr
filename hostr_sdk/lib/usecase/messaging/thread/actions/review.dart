import 'package:injectable/injectable.dart';

import '../trade.dart';

@injectable
class ReviewActions {
  final ThreadTrade trade;

  ReviewActions({required this.trade});

  void review() {
    throw UnimplementedError('Review action is not implemented yet');
  }
}

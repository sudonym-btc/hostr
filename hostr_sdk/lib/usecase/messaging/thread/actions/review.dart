import 'package:injectable/injectable.dart';

import '../trade.dart';

@injectable
class ReviewActions {
  final Trade trade;

  ReviewActions({required this.trade});

  void review() {
    throw UnimplementedError('Review action is not implemented yet');
  }
}

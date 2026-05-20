import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../../../util/main.dart';
import '../../orders/orders.dart';
import '../trade.dart';
import 'trade_action_resolver.dart';

@injectable
class OrderActions {
  final Trade trade;
  final Orders orders;

  OrderActions({required this.trade, required this.orders});

  static List<TradeAction> resolve(
    List<Order> orders,
    StreamStatus orderStreamStatus,
    TradeRole role, {
    List<Order>? allOrders,
  }) {
    final actions = <TradeAction>[];
    final orderStatus = Order.getOrderStatus(orders: orders);

    final escrowOrders = allOrders ?? orders;

    final hasEscrowOrder = escrowOrders.any((order) {
      final escrowPubkey = order.parsedTags.getTagValueByMarker('p', 'escrow');
      return escrowPubkey != null && escrowPubkey.isNotEmpty;
    });
    final hasTerminalOrderState =
        orderStatus == OrderStatus.cancelled ||
        orderStatus == OrderStatus.invalid ||
        orderStatus == OrderStatus.completed;
    if (!hasTerminalOrderState) {
      actions.add(TradeAction.cancel);
    }

    if (hasEscrowOrder) {
      actions.add(TradeAction.messageEscrow);
    }

    return actions;
  }

  Future<void> cancel() async {
    final keyPair = await trade.activeKeyPair();

    await orders.cancel(
      trade.currentOrderGroups.whereType<Valid<OrderGroup>>().first.event,
      keyPair,
    );
  }
}

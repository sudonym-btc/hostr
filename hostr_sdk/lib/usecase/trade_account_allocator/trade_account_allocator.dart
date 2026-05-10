/// HD account index reserved for the stable public/profile EVM address.
///
/// Trade-scoped material must never consume account `0`, otherwise a user's
/// first trade address would collide with their publicly advertised profile
/// address and weaken privacy. New trade allocations therefore begin at `1`.
const kFirstTradeAccountIndex = 1;

abstract class TradeAccountAllocator {
  Future<int> reserveNextTradeIndex();

  Future<int> findTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 64,
  });

  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 64,
  });

  List<int> getReservedTradeIndices();
}

abstract class TradeAccountAllocator {
  Future<int> reserveNextTradeIndex();

  Future<int> findTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 128,
  });

  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 128,
  });

  Future<int> findTradeAccountIndexBySalt(String salt, {int maxScan = 128});

  Future<int?> tryFindTradeAccountIndexBySalt(String salt, {int maxScan = 128});

  List<int> getReservedTradeIndices();
}

/// Identifies each screen in the CLI navigation state machine.
enum Screen {
  mainMenu,
  tradeList,
  tradeDetail,
  audit,
  arbitrate,
  threadList,
  threadDetail,
  serviceList,
  serviceEdit,
  profileEdit,
  exit,
}

/// Return value from a screen — tells the main loop where to go next,
/// plus any context (selected trade, thread, etc.).
class Navigation {
  final Screen next;
  final String? selectedTradeId;
  final String? selectedThreadId;
  final String? selectedServiceId;

  const Navigation(
    this.next, {
    this.selectedTradeId,
    this.selectedThreadId,
    this.selectedServiceId,
  });

  const Navigation.to(this.next)
      : selectedTradeId = null,
        selectedThreadId = null,
        selectedServiceId = null;
}

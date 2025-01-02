class RequestEscrow {
  final String id;
  final String buyer;
  final String seller;
  final String amount;
  final String status;
  final String createdAt;
  final String updatedAt;

  RequestEscrow({
    required this.id,
    required this.buyer,
    required this.seller,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

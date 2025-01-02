import 'package:equatable/equatable.dart';

enum PaymentStatus { PENDING, PAID, CANCELLED }

enum PaymentType { ZAP, ROOTSTOCK }

// abstract class PaymentState extends Equatable {
//   String id;
//   String name;
//   String description;
//   String currency;
//   double price;
//   PaymentStatus status = PaymentStatus.PENDING;
//   PaymentType type = PaymentType.ZAP;

//   Payment(
//       {required this.id,
//       required this.name,
//       required this.description,
//       required this.currency,
//       required this.price});

//   String initiate();
//   PaymentStatus fetchStatus();
// }

// class RootstockPayment extends Payment {
//   @override
//   PaymentStatus fetchStatus() {
//     return PaymentStatus.PAID;
//   }

//   @override
//   String initiate() {
//     // TODO: implement initiate
//     throw UnimplementedError();
//   }
// }

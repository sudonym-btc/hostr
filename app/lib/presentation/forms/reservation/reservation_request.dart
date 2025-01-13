// import 'package:flutter/material.dart';
// import 'package:hostr/data/main.dart';
// import 'package:hostr/presentation/component/widgets/main.dart';

// class ReservationRequestFormState {
//   final DateTimeRange dateRange;
//   final Amount price;

//   const ReservationRequestFormState({
//     required this.dateRange,
//     this.availabilityRange,
//   });

//   ReservationRequestFormState copyWith({
//     String? location,
//     DateTimeRange? availabilityRange,
//   }) {
//     return ReservationRequestFormState(
//       location: location ?? this.location,
//       availabilityRange: availabilityRange ?? this.availabilityRange,
//     );
//   }
// }

// class ReservationRequestForm extends StatefulWidget {
//   final Function(ReservationRequestFormState) onSubmit;

//   const ReservationRequestForm({super.key, required this.onSubmit});

//   @override
//   State<ReservationRequestForm> createState() => _ReservationRequestFormState();
// }

// class _ReservationRequestFormState extends State<ReservationRequestForm> {
//   final _formKey = GlobalKey<FormState>();
//   late ReservationRequestFormState _formState;

//   @override
//   void initState() {
//     super.initState();
//     _formState = ReservationRequestFormState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Row(
//         children: [
//           // CustomPadding(
//           //   child: LocationField(
//           //     value: _formState.location,
//           //     onChanged: (value) => setState(() {
//           //       _formState = _formState.copyWith(location: value);
//           //     }),
//           //   ),
//           // ),
//           // CustomPadding(
//           //   child: DateRangeButtons(
//           //       onTap: showDatePicker,
//           //       selectedDateRange: _formState.availabilityRange),
//           // ),
//           // FilledButton(
//           //   onPressed: () {
//           //     if (_formKey.currentState!.validate()) {
//           //       widget.onSubmit(_formState);
//           //     }
//           //   },
//           //   child: Text('Search'),
//           // ),
//         ],
//       ),
//     );
//   }

//   // showDatePicker() async {
//   //   final picked = await showDateRangePicker(
//   //       context: context,
//   //       firstDate: DateTime.now(),
//   //       lastDate: DateTime.now().add(Duration(days: 365)),
//   //       initialDateRange: _formState.availabilityRange);
//   //   setState(() {
//   //     _formState = _formState.copyWith(availabilityRange: picked);
//   //   });
//   // }
// }

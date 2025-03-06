import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year) {
    return DateFormat('MMM d').format(date);
  } else {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

String getDateRangeText(DateTime start, DateTime end) {
  return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year) {
    return DateFormat('MMM d').format(date);
  } else {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

String formatDateLong(DateTime date) {
  final localDate = date.toLocal();
  final now = DateTime.now();
  if (localDate.year == now.year) {
    return DateFormat('MMM d, HH:mm').format(localDate);
  } else {
    return DateFormat('MMM d, yyyy, HH:mm').format(localDate);
  }
}

String formatDateShort(DateTime date, Locale locale) {
  final now = DateTime.now();
  final dayDateFormat = DateFormat('MMM d', locale.toString());
  final yearFormat = DateFormat('MMM d, yyyy', locale.toString());
  return date.year == now.year
      ? dayDateFormat.format(date)
      : yearFormat.format(date);
}

String formatDateRangeShort(DateTimeRange<DateTime> dateRange, Locale locale) {
  final localeStr = locale.toString();
  final dayFormat = DateFormat('MMM d', localeStr);
  final yearFormat = DateFormat('MMM d, yyyy', localeStr);
  final now = DateTime.now();

  final endStr = dateRange.end.year == now.year
      ? dayFormat.format(dateRange.end)
      : yearFormat.format(dateRange.end);

  // Only show the year on the start date when it differs from the end date's year.
  final startStr = dateRange.start.year != dateRange.end.year
      ? yearFormat.format(dateRange.start)
      : dayFormat.format(dateRange.start);

  return '$startStr - $endStr';
}

String getDateRangeText(DateTime start, DateTime end) {
  return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
}

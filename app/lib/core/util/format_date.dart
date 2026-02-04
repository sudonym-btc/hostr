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

formatDateShort(DateTime date, Locale locale) {
  final now = DateTime.now();
  final dayDateFormat = DateFormat('MMM d', locale.toString());
  final yearFormat = DateFormat('MMM d, yyyy', locale.toString());
  return date.year == now.year
      ? dayDateFormat.format(date)
      : yearFormat.format(date);
}

String formatDateRangeShort(DateTimeRange<DateTime> dateRange, Locale locale) {
  return '${formatDateShort(dateRange.start, locale)} - ${formatDateShort(dateRange.end, locale)}';
}

String getDateRangeText(DateTime start, DateTime end) {
  return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
}

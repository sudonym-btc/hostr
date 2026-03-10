DateTime normalizeDateUtc(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

({DateTime start, DateTime end}) normalizeOrderedDateBounds(
  DateTime start,
  DateTime end,
) {
  var normalizedStart = normalizeDateUtc(start);
  var normalizedEnd = normalizeDateUtc(end);

  if (normalizedStart.isAfter(normalizedEnd)) {
    final temp = normalizedStart;
    normalizedStart = normalizedEnd;
    normalizedEnd = temp;
  }

  return (start: normalizedStart, end: normalizedEnd);
}

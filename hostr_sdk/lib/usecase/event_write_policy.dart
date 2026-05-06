int nextUpsertCreatedAt(int previousCreatedAt, {DateTime? now}) {
  final current =
      (now ?? DateTime.now()).millisecondsSinceEpoch ~/
      Duration.millisecondsPerSecond;
  if (previousCreatedAt <= 0) return current;
  return current > previousCreatedAt ? current : previousCreatedAt + 1;
}

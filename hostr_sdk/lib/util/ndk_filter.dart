import 'package:ndk/ndk.dart';

Filter? cleanTags(Filter? filter) {
  if (filter == null) {
    return null;
  }

  final tags = filter.tags;
  if (tags == null) {
    return filter;
  }

  final cleaned = <String, List<String>>{};
  for (final entry in tags.entries) {
    final key = entry.key.startsWith('#') ? entry.key : '#${entry.key}';
    cleaned.update(
      key,
      (existing) => [...existing, ...entry.value],
      ifAbsent: () => [...entry.value],
    );
  }

  Filter cleanFilter = filter.clone();
  cleanFilter.tags = cleaned.isEmpty ? null : cleaned;
  return cleanFilter;
}

Filter getCombinedFilter(Filter? filter1, Filter? filter2) {
  final cleanedFilter1 = cleanTags(filter1);
  final cleanedFilter2 = cleanTags(filter2);

  Map<String, List<String>>? mergeTags(
    Map<String, List<String>>? first,
    Map<String, List<String>>? second,
  ) {
    if (first == null && second == null) {
      return null;
    }

    final merged = <String, List<String>>{};

    void addAll(Map<String, List<String>> source) {
      for (final entry in source.entries) {
        merged.update(
          entry.key,
          (existing) => [...existing, ...entry.value],
          ifAbsent: () => [...entry.value],
        );
      }
    }

    if (first != null) {
      addAll(first);
    }
    if (second != null) {
      addAll(second);
    }

    return merged.isEmpty ? null : merged;
  }

  return Filter(
    ids: (cleanedFilter1?.ids != null || cleanedFilter2?.ids != null)
        ? [...?cleanedFilter1?.ids, ...?cleanedFilter2?.ids]
        : null,
    authors:
        (cleanedFilter1?.authors != null || cleanedFilter2?.authors != null)
        ? [...?cleanedFilter1?.authors, ...?cleanedFilter2?.authors]
        : null,
    kinds: (cleanedFilter1?.kinds != null || cleanedFilter2?.kinds != null)
        ? {...?cleanedFilter1?.kinds, ...?cleanedFilter2?.kinds}.toList()
        : null,
    eTags: (cleanedFilter1?.eTags != null || cleanedFilter2?.eTags != null)
        ? [...?cleanedFilter1?.eTags, ...?cleanedFilter2?.eTags]
        : null,
    pTags: (cleanedFilter1?.pTags != null || cleanedFilter2?.pTags != null)
        ? [...?cleanedFilter1?.pTags, ...?cleanedFilter2?.pTags]
        : null,
    tTags: (cleanedFilter1?.tTags != null || cleanedFilter2?.tTags != null)
        ? [...?cleanedFilter1?.tTags, ...?cleanedFilter2?.tTags]
        : null,
    aTags: (cleanedFilter1?.aTags != null || cleanedFilter2?.aTags != null)
        ? [...?cleanedFilter1?.aTags, ...?cleanedFilter2?.aTags]
        : null,
    dTags: (cleanedFilter1?.dTags != null || cleanedFilter2?.dTags != null)
        ? [...?cleanedFilter1?.dTags, ...?cleanedFilter2?.dTags]
        : null,
    tags: mergeTags(cleanedFilter1?.tags, cleanedFilter2?.tags),
    since: cleanedFilter1?.since ?? cleanedFilter2?.since,
    until: cleanedFilter1?.until ?? cleanedFilter2?.until,
    limit: cleanedFilter1?.limit ?? cleanedFilter2?.limit,
    search: cleanedFilter1?.search ?? cleanedFilter2?.search,
  );
}

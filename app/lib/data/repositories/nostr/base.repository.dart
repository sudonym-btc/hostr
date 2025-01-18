import 'package:dart_nostr/dart_nostr.dart';

abstract class DataResult<T> {}

class Data<T> extends DataResult<T> {
  final T value;
  Data(this.value);
}

class OK<T> extends DataResult<T> {}

class Err<T> extends DataResult<T> {
  final String message;
  Err(this.message);
}

NostrFilter getCombinedFilter(NostrFilter? filter1, NostrFilter? filter2) {
  return NostrFilter(
    ids: (filter1?.ids != null || filter2?.ids != null)
        ? [...?filter1?.ids, ...?filter2?.ids]
        : null,
    authors: (filter1?.authors != null || filter2?.authors != null)
        ? [...?filter1?.authors, ...?filter2?.authors]
        : null,
    kinds: (filter1?.kinds != null || filter2?.kinds != null)
        ? [...?filter1?.kinds, ...?filter2?.kinds]
        : null,
    e: (filter1?.e != null || filter2?.e != null)
        ? [...?filter1?.e, ...?filter2?.e]
        : null,
    p: (filter1?.p != null || filter2?.p != null)
        ? [...?filter1?.p, ...?filter2?.p]
        : null,
    t: (filter1?.t != null || filter2?.t != null)
        ? [...?filter1?.t, ...?filter2?.t]
        : null,
    a: (filter1?.a != null || filter2?.a != null)
        ? [...?filter1?.a, ...?filter2?.a]
        : null,
    since: filter1?.since ?? filter2?.since,
    until: filter1?.until ?? filter2?.until,
    limit: filter1?.limit ?? filter2?.limit,
    search: filter1?.search ?? filter2?.search,
    additionalFilters: {
      if (filter1?.additionalFilters != null) ...filter1!.additionalFilters!,
      if (filter2?.additionalFilters != null) ...filter2!.additionalFilters!
    },
  );
}

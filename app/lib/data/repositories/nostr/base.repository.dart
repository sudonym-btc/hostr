import 'package:ndk/ndk.dart';

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

Filter getCombinedFilter(Filter? filter1, Filter? filter2) {
  return Filter(
      ids: (filter1?.ids != null || filter2?.ids != null)
          ? [...?filter1?.ids, ...?filter2?.ids]
          : null,
      authors: (filter1?.authors != null || filter2?.authors != null)
          ? [...?filter1?.authors, ...?filter2?.authors]
          : null,
      kinds: (filter1?.kinds != null || filter2?.kinds != null)
          ? [...?filter1?.kinds, ...?filter2?.kinds]
          : null,
      eTags: (filter1?.eTags != null || filter2?.eTags != null)
          ? [...?filter1?.eTags, ...?filter2?.eTags]
          : null,
      pTags: (filter1?.pTags != null || filter2?.pTags != null)
          ? [...?filter1?.pTags, ...?filter2?.pTags]
          : null,
      tTags: (filter1?.tTags != null || filter2?.tTags != null)
          ? [...?filter1?.tTags, ...?filter2?.tTags]
          : null,
      aTags: (filter1?.aTags != null || filter2?.aTags != null)
          ? [...?filter1?.aTags, ...?filter2?.aTags]
          : null,
      since: filter1?.since ?? filter2?.since,
      until: filter1?.until ?? filter2?.until,
      limit: filter1?.limit ?? filter2?.limit,
      search: filter1?.search ?? filter2?.search);
}

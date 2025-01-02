import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/main.dart';
import 'package:rxdart/rxdart.dart';

class ListController<T extends Event> {
  final BehaviorSubject<NostrFilter> _preFetchFilterSubject =
      BehaviorSubject<NostrFilter>();
  final BehaviorSubject<NostrFilter?> _postFilterSubject =
      BehaviorSubject<NostrFilter?>();
  final BehaviorSubject<void> _loadNextTrigger = BehaviorSubject<void>();
  final BehaviorSubject<void> _loadPreviousTrigger = BehaviorSubject<void>();

  late final BaseRepository<T> _repo;

  final BehaviorSubject<List<T>> _fetchedResults =
      BehaviorSubject<List<T>>.seeded([]);

  bool _isLoading = false;
  StreamSubscription? _dataFetchSubscription;
  StreamSubscription? _realTimeSubscription;

  ListController(this._repo) {
    _dataFetchSubscription = Rx.combineLatest3(
      _preFetchFilterSubject.stream,
      _loadNextTrigger.stream.startWith(null),
      _loadPreviousTrigger.stream.startWith(null),
      (NostrFilter filter, _, __) => filter,
    )
        .switchMap((filter) {
          _isLoading = true;
          List<T> currentResults = _fetchedResults.value;
          return _repo.list(filter: filter).map((result) {
            if (result is Data<T>) {
              return _applyPostFilter(result);
            } else if (result is OK) {
              _isLoading = false;

              // Begin listening for real-time data
              _realTimeSubscription ??= _repo.list().listen((realTimeResult) {
                // Handle real-time data updates
                // Here, it's assumed that this stream returns the same Data, OK, Err types as fetchData
                if (realTimeResult is Data<T>) {
                  var filtered = _applyPostFilter(realTimeResult);
                  if (filtered != null) {
                    var currentList = _fetchedResults.value;
                    currentList.add(filtered);
                    _fetchedResults.add(currentList);
                  }
                }
                // Other result types can be handled similarly
              });
            } else if (result is Err) {
              _isLoading = false;
              // ... Handle error
            }
            return null;
          }).where((item) => item != null);
        })
        .whereNotNull()
        .listen((filteredItem) {
          var currentList = _fetchedResults.value;
          currentList.add(filteredItem);
          _fetchedResults.add(currentList);
        });
  }

  T? _applyPostFilter(Data<T> item) {
    var filter = _postFilterSubject.value;
    if (filter == null) return item.value;

    // Implement actual filter logic here
    if (true) {
      return item.value;
    }
    return null;
  }

  void dispose() {
    _fetchedResults.close();
    _preFetchFilterSubject.close();
    _postFilterSubject.close();
    _loadNextTrigger.close();
    _loadPreviousTrigger.close();
    _dataFetchSubscription?.cancel();
    _realTimeSubscription?.cancel();
  }
}

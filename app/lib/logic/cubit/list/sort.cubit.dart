import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef Comparator<T extends NostrEvent> = int Function(T a, T b);

class SortCubit<T extends NostrEvent> extends Cubit<ComparatorWrapper<T>> {
  SortCubit([Comparator<T>? initialComparator])
      : super(ComparatorWrapper(initialComparator ??
            (T a, T b) => b.createdAt!.compareTo(a.createdAt!)));

  void sort(Comparator<T> newOrder) {
    emit(ComparatorWrapper(newOrder));
  }
}

class ComparatorWrapper<T extends NostrEvent> {
  final Comparator<T> comparator;

  ComparatorWrapper(this.comparator);
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/main.dart';

typedef Comparator<T extends Event> = int Function(T a, T b);

class SortCubit<T extends Event> extends Cubit<ComparatorWrapper<T>> {
  SortCubit([Comparator<T>? initialComparator])
      : super(ComparatorWrapper(initialComparator ??
            (T a, T b) =>
                b.nip01Event.createdAt.compareTo(a.nip01Event.createdAt)));

  void sort(Comparator<T> newOrder) {
    emit(ComparatorWrapper(newOrder));
  }
}

class ComparatorWrapper<T extends Event> {
  final Comparator<T> comparator;

  ComparatorWrapper(this.comparator);
}

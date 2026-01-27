import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ndk/ndk.dart';

typedef Comparator<T extends Nip01Event> = int Function(T a, T b);

class SortCubit<T extends Nip01Event> extends Cubit<ComparatorWrapper<T>> {
  SortCubit([Comparator<T>? initialComparator])
    : super(
        ComparatorWrapper(
          initialComparator ?? (T a, T b) => b.createdAt.compareTo(a.createdAt),
        ),
      );

  void sort(Comparator<T> newOrder) {
    emit(ComparatorWrapper(newOrder));
  }
}

class ComparatorWrapper<T extends Nip01Event> {
  final Comparator<T> comparator;

  ComparatorWrapper(this.comparator);
}

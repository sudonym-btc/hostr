import 'package:flutter_bloc/flutter_bloc.dart';

class PostResultFilter<T> {
  final bool Function(T) filter;
  const PostResultFilter(this.filter);
}

class PostResultFilterCubit<T> extends Cubit<PostResultFilter<T>> {
  PostResultFilterCubit() : super(PostResultFilter((_) => true));

  void updateFilter(bool Function(T) newFilter) {
    emit(PostResultFilter(newFilter));
  }
}

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../crud.usecase.dart';

@Singleton()
class Reviews extends CrudUseCase<Review> {
  Reviews({required super.requests, required super.logger})
    : super(kind: Review.kinds[0]);
}

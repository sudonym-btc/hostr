import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../crud.usecase.dart';

@Singleton()
class Listings extends CrudUseCase<Listing> {
  Listings({required super.requests, required super.logger})
    : super(kind: Listing.kinds[0]);
}

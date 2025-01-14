import 'package:hostr/injection.dart';
import 'package:hostr/setup.dart';

import 'seed.dart';

void main() async {
  setup(Env.mock);
  await seed();
}

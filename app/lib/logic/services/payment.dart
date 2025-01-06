import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

@Injectable(env: Env.allButTestAndMock)
class PaymentService {
  CustomLogger logger = CustomLogger();
}

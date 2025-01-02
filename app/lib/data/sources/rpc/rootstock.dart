import 'package:hostr/config/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

abstract class Rootstock {
  Future<void> connectToRootstock();
}

@Injectable(as: Rootstock)
class RootstockImpl extends Rootstock {
  final Web3Client client =
      Web3Client(getIt<Config>().rootstockRpcUrl, Client());
  @override
  Future<void> connectToRootstock() async {
    try {
      final blockNumber = await client.getBlockNumber();
      print("Current block number: $blockNumber");
    } catch (e) {
      print("Error: $e");
    } finally {
      client.dispose();
    }
  }

  Future<double> getBalance(EthereumAddress address) async {
    return await client
        .getBalance(address)
        .then((val) => val.getInEther.toDouble());
  }
}

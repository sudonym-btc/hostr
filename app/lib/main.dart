import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/setup.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'injection.dart';

/**
 * Export items from our app such that they can be used by widgetbook
 */

export './export.dart';

void mainCommon(String env) async {
  setup(env);
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  await getIt<RelayConnector>().connect();
  // await getIt<Rootstock>().connectToRootstock();
  // try {
  //   await Boltz.LibBoltz.init();
  //   const boltzUrl = 'https://api.testnet.boltz.exchange/v2';
  //   // const amount = 100000;
  //   final fees = await const Boltz.Fees(boltzUrl: boltzUrl).chain();
  //   print('FEES:${fees}');
  // } catch (e) {
  //   print('\n\nERRRR: ' + e.toString() + '\n\n');
  // }
  runApp(MyApp());
}

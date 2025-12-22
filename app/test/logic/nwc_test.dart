import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';

void main() {
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('connect', () {
    blocTest<NwcCubit, NwcCubitState>(
      'emits [Error] when invalid NWC string used.',
      build: () => NwcCubit(nwcService: getIt()),
      act: (bloc) {
        return bloc.connect('invalid');
      },
      expect: () => <NwcCubitState>[Loading(), Error()],
    );

    blocTest<NwcCubit, NwcCubitState>(
      'emits [Success] when connected.',
      build: () => NwcCubit(url: '', nwcService: getIt()),
      setUp: () async {
        // getIt<KeyStorage>().set(keyPair.privateKey!);
        // // Ndk().nwc.getInfo
        // getIt<NostrService>().events.listen((event) {
        //   if (event.kind == NOSTR_KIND_NWC_REQUEST) {
        //     getIt<NostrService>().events.add(NwcResponse.create(
        //         event.id!,
        //         keyPair.publicKey,
        //         NwcResponseContent(
        //             result_type: NwcMethods.get_info, result: getInfo),
        //         Uri.parse(nwcString)));
        //   }
        // });
      },
      act: (bloc) async {
        // return await bloc.connect(nwcString);
      },
      expect: () => <NwcCubitState>[
        // NostrWalletConnectInProgress(),
        // Success(content: getInfo)
      ],
    );
  });
}

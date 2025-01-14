import 'package:bloc_test/bloc_test.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';

void main() {
  NostrKeyPairs keyPair = Nostr.instance.keysService.generateKeyPair();
  String nwcString =
      'nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c';
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('connect', () {
    NwcMethodGetInfoResponse getInfo = NwcMethodGetInfoResponse(
        alias: 'test',
        color: '#121212',
        pubkey: MockKeys.nwc.public,
        network: 'mainnet',
        block_height: 800000,
        block_hash: 010101010,
        methods: [],
        notifications: []);

    blocTest<NwcCubit, NwcCubitState>(
      'emits [Error] when invalid NWC string used.',
      build: () => NwcCubit(),
      act: (bloc) {
        return bloc.connect('invalid');
      },
      expect: () => <NwcCubitState>[Error()],
    );

    blocTest<NwcCubit, NwcCubitState>(
      'emits [Success] when connected.',
      build: () => NwcCubit(),
      setUp: () async {
        getIt<KeyStorage>().set(keyPair.private);
        getIt<NostrService>().events.listen((event) {
          if (event.kind == NOSTR_KIND_NWC_REQUEST) {
            getIt<NostrService>().events.add(NwcResponse.create(
                event.id!,
                keyPair.public,
                NwcResponseContent(
                    result_type: NwcMethods.get_info, result: getInfo),
                Uri.parse(nwcString)));
          }
        });
      },
      act: (bloc) async {
        return await bloc.connect(nwcString);
      },
      expect: () => <NwcCubitState>[
        NostrWalletConnectInProgress(),
        Success(content: getInfo)
      ],
    );
  });
}

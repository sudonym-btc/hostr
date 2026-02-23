import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class SignUpWidget extends StatelessWidget {
  const SignUpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomPadding(
        child: FutureBuilder<KeyPair>(
          future: _generateKeyPair(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator.large());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final keyPair = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You might want to jot this down',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Gap.vertical.md(),
                  // Text(
                  //   'Your keys allow you to log into your account. While you\ll be able to see these late, loss of these keys means loss of account information and possible loss of funds.',
                  // ),
                  Gap.vertical.lg(),
                  Text(
                    'Mnemonic',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Gap.vertical.sm(),
                  // Text(entropyToMnemonic(keyPair.privateKey!)),
                  Gap.vertical.md(),
                  Text('nsec', style: TextStyle(fontWeight: FontWeight.bold)),
                  Gap.vertical.sm(),
                  Text(keyPair.privateKey!),
                  Gap.vertical.lg(),
                  Center(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.proceed),
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: Text('Unexpected error'));
            }
          },
        ),
      ),
    );
  }

  Future<KeyPair> _generateKeyPair() async {
    return Bip340.generatePrivateKey();
  }
}

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

/// A widget that displays the user's key pair (npub, nsec) and the nsec
/// formatted as a BIP-39 24-word mnemonic so they can back it up safely.
///
/// Show as a modal bottom sheet:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => BackupKeyWidget(
///     publicKeyHex: keyPair.publicKey,
///     privateKeyHex: keyPair.privateKey!,
///   ),
/// );
/// ```
class BackupKeyWidget extends StatelessWidget {
  final String publicKeyHex;
  final String privateKeyHex;
  final String? mnemonic;

  const BackupKeyWidget({
    super.key,
    required this.publicKeyHex,
    required this.privateKeyHex,
    this.mnemonic,
  });

  @override
  Widget build(BuildContext context) {
    final npub = Helpers.encodeBech32(publicKeyHex, 'npub');
    final nsec = Helpers.encodeBech32(privateKeyHex, 'nsec');
    final recoverySentence =
        mnemonic ??
        Mnemonic(hex.decode(privateKeyHex), Language.english).sentence;
    final words = recoverySentence.split(' ');

    return ModalBottomSheet(
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
      title: 'Back up your keys',
      subtitle:
          'Your keys are your identity. If you lose them you will lose access to your account and any funds held in escrow.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KeySection(label: 'Public key (npub)', value: npub),
          Gap.vertical.md(),
          _KeySection(
            label: 'Private key (nsec)',
            value: nsec,
            sensitive: true,
          ),
          Gap.vertical.custom(kSpace5),
          Text(
            'Recovery words',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Gap.vertical.sm(),
          _MnemonicGrid(words: words),
          Gap.vertical.xs(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.copy, size: kIconSm),
              label: Text(AppLocalizations.of(context)!.copyWords),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: recoverySentence));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.recoveryWordsCopied,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _KeySection extends StatelessWidget {
  final String label;
  final String value;
  final bool sensitive;

  const _KeySection({
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Gap.vertical.custom(6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sensitive
                ? Theme.of(context).colorScheme.errorContainer.withAlpha(60)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: kIconSm),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.labelCopied(label),
                      ),
                    ),
                  );
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MnemonicGrid extends StatelessWidget {
  final List<String> words;
  const _MnemonicGrid({required this.words});

  @override
  Widget build(BuildContext context) {
    // 3 columns × 8 rows
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int col = 0; col < 3; col++) ...[
          if (col > 0) Gap.horizontal.sm(),
          Expanded(
            child: Column(
              children: [
                for (int row = 0; row < 8; row++)
                  _wordTile(context, col * 8 + row, words[col * 8 + row]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _wordTile(BuildContext context, int index, String word) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${index + 1}. $word',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

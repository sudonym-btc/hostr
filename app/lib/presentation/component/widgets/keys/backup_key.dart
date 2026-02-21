import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const BackupKeyWidget({
    super.key,
    required this.publicKeyHex,
    required this.privateKeyHex,
  });

  @override
  Widget build(BuildContext context) {
    final npub = Helpers.encodeBech32(publicKeyHex, 'npub');
    final nsec = Helpers.encodeBech32(privateKeyHex, 'nsec');
    final entropyBytes = hex.decode(privateKeyHex);
    final mnemonic = Mnemonic(entropyBytes, Language.english);
    final words = mnemonic.sentence.split(' ');

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ── Drag handle ──────────────────────────────────
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Scrollable content ───────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Back up your keys',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your keys are your identity. If you lose them you will lose access to your account and any funds held in escrow.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _KeySection(label: 'Public key (npub)', value: npub),
                      const SizedBox(height: 16),
                      _KeySection(
                        label: 'Private key (nsec)',
                        value: nsec,
                        sensitive: true,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recovery words',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _MnemonicGrid(words: words),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy words'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: mnemonic.sentence),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recovery words copied'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // ── Pinned Done button ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          );
        },
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
        const SizedBox(height: 6),
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
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$label copied')));
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
          if (col > 0) const SizedBox(width: 8),
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

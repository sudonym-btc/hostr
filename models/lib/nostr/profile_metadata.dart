import 'package:ndk/ndk.dart';

import 'event.dart';

class ProfileMetadata extends Event {
  static const List<int> kinds = [Metadata.kKind];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  ProfileMetadata.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  Metadata get metadata => Metadata.fromEvent(this);

  String? get evmAddress {
    return this
        .tags
        .firstWhere((tag) => tag[0] == 'i' && tag[1] == 'evm:address')[2];
  }

  /// Returns a new [ProfileMetadata] with the EVM address tag set.
  ///
  /// This reconstructs the underlying event so the id is recomputed.
  /// Mutating tags in-place would leave the `late final` id stale,
  /// causing relays to reject the event with "invalid id".
  ProfileMetadata withEvmAddress(String address) {
    final updatedTags = List<List<String>>.from(
      tags.where((t) => !(t[0] == 'i' && t[1] == 'evm:address')),
    )..add(['i', 'evm:address', address]);

    // Construct without id so Nip01Event auto-computes it from the new tags.
    final rebuilt = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: updatedTags,
      content: content,
      createdAt: createdAt,
    );
    return ProfileMetadata.fromNostrEvent(rebuilt);
  }

  @Deprecated('Use withEvmAddress instead — this mutates tags without '
      'recomputing the event id, causing relay rejection.')
  setEvmAddress(String address) {
    this.tags.removeWhere((t) => t[0] == 'i' && t[1] == 'evm:address');
    this.tags.add(['i', 'evm:address', address]);
  }
}

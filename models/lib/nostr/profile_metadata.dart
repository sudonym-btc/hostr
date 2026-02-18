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

  setEvmAddress(String address) {
    this.tags.removeWhere((t) => t[0] == 'i' && t[1] == 'evm:address');
    this.tags.add(['i', 'evm:address', address]);
  }
}

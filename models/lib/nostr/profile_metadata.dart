import 'package:ndk/ndk.dart';

import 'event.dart';

class ProfileMetadata extends Event {
  static const List<int> kinds = [Metadata.kKind];

  ProfileMetadata.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);

  Metadata get metadata => Metadata.fromEvent(this);

  String? get evmAddress {
    print(this.tags.where((tag) => tag[0] == 'i' && tag[1] == 'evm:address'));
    return this
        .tags
        .firstWhere((tag) => tag[0] == 'i' && tag[1] == 'evm:address')[2];
    // this.t
    // final tags = this.getTags('i');
    // print(tags);
    // return tags.firstWhere((t) => t[0] == 'evm:address')[1];
  }

  setEvmAddress(String address) {
    this.tags.removeWhere((t) => t[0] == 'i' && t[1] == 'evm:address');
    this.tags.add(['i', 'evm:address', address]);
  }
}

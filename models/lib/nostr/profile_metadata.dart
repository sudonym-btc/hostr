import 'package:ndk/ndk.dart';

import 'event.dart';

class ProfileMetadata extends Event {
  static const List<int> kinds = [Metadata.kKind];

  ProfileMetadata.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);

  Metadata get metadata => Metadata.fromEvent(this);

  String? get evmAddress =>
      this.getTags('i').firstWhere((t) => t[0] == 'evm:address')[1];

  setEvmAddress(String address) {
    this.tags.removeWhere((t) => t[0] == 'i' && t[1] == 'evm:address');
    this.tags.add(['i', 'evm:address', address]);
  }
}

import 'package:ndk/ndk.dart' show ContactList, Nip01Event;

final _hexPubkeyPattern = RegExp(r'^[0-9a-fA-F]{64}$');

class FollowListTarget {
  final String pubkey;
  final String? relayHint;
  final String? petname;

  const FollowListTarget({required this.pubkey, this.relayHint, this.petname});
}

class FollowListUpdate {
  final Nip01Event event;
  final bool createsNewList;
  final List<String> addedPubkeys;

  const FollowListUpdate({
    required this.event,
    required this.createsNewList,
    required this.addedPubkeys,
  });

  bool get changed => addedPubkeys.isNotEmpty;
}

FollowListUpdate buildFollowListUpdate({
  required String ownerPubkey,
  required Iterable<FollowListTarget> targets,
  Nip01Event? existingEvent,
  int? createdAt,
}) {
  final owner = _normalizePubkey(ownerPubkey);
  if (owner == null) {
    throw ArgumentError.value(ownerPubkey, 'ownerPubkey', 'Invalid pubkey');
  }

  final tags =
      existingEvent?.tags
          .map((tag) => List<String>.from(tag))
          .toList(growable: true) ??
      <List<String>>[];
  final existingFollows = <String>{};
  for (final tag in tags) {
    if (tag.length <= 1 || tag.first != 'p') continue;
    final pubkey = _normalizePubkey(tag[1]);
    if (pubkey != null) existingFollows.add(pubkey);
  }

  final addedPubkeys = <String>[];
  for (final target in targets) {
    final pubkey = _normalizePubkey(target.pubkey);
    if (pubkey == null || existingFollows.contains(pubkey)) continue;

    existingFollows.add(pubkey);
    addedPubkeys.add(pubkey);
    tags.add(_targetTag(target, pubkey));
  }

  return FollowListUpdate(
    event: Nip01Event(
      id: '',
      pubKey: owner,
      kind: ContactList.kKind,
      tags: tags,
      content: existingEvent?.content ?? '',
      createdAt: createdAt ?? Nip01Event.secondsSinceEpoch(),
    ),
    createsNewList: existingEvent == null,
    addedPubkeys: List.unmodifiable(addedPubkeys),
  );
}

String? normalizeFollowPubkey(String value) => _normalizePubkey(value);

String? _normalizePubkey(String value) {
  final trimmed = value.trim();
  if (!_hexPubkeyPattern.hasMatch(trimmed)) return null;
  return trimmed.toLowerCase();
}

List<String> _targetTag(FollowListTarget target, String pubkey) {
  final relayHint = target.relayHint?.trim() ?? '';
  final petname = target.petname?.trim() ?? '';
  if (relayHint.isEmpty && petname.isEmpty) return ['p', pubkey];
  if (petname.isEmpty) return ['p', pubkey, relayHint];
  return ['p', pubkey, relayHint, petname];
}

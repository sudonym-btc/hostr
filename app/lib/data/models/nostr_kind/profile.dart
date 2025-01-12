import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import 'type_json_content.dart';

class Profile extends JsonContentNostrEvent<ProfileContent> {
  static List<int> kinds = [NOSTR_KIND_PROFILE];

  Profile.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: ProfileContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class ProfileContent extends EventContent {
  final String? name;
  final String? about;
  final String? picture;
  final String? nip05;

  ProfileContent(
      {required this.name,
      required this.about,
      required this.picture,
      this.nip05});

  @override
  Map<String, dynamic> toJson() {
    return {
      if (name != null) ...{'name': name},
      if (about != null) ...{'about': about},
      if (picture != null) ...{'picture': picture},
      if (nip05 != null) ...{'nip05': nip05},
    };
  }

  static ProfileContent fromJson(Map<String, dynamic> json) {
    return ProfileContent(
      name: json['name'],
      about: json['about'],
      picture: json['picture'],
      nip05: json['nip05'],
    );
  }
}

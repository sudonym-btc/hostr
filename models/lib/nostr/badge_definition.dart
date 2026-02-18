import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

/// NIP-58 Badge Definition (kind 30009)
/// Defines a badge with metadata (replaceable by 'd' tag)
/// Can be updated by re-publishing with same 'd' tag
class BadgeDefinition
    extends JsonContentNostrEvent<BadgeDefinitionContent, EventTags> {
  static const List<int> kinds = [kNostrKindBadgeDefinition];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;
  static final EventContentParser<BadgeDefinitionContent> _contentParser =
      BadgeDefinitionContent.fromJson;

  BadgeDefinition.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  /// Get the badge identifier from 'd' tag
  String? get identifier => getFirstTag('d');

  /// Get the anchor for this badge definition (kind:pubkey:d)
  String get anchor => '${kind}:${pubKey}:${identifier ?? ''}';
}

class BadgeDefinitionContent extends EventContent {
  final String name;
  final String? description;
  final String? image;
  final List<String>? thumbs;

  BadgeDefinitionContent({
    required this.name,
    this.description,
    this.image,
    this.thumbs,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};
    if (description != null) json['description'] = description;
    if (image != null) json['image'] = image;
    if (thumbs != null) json['thumbs'] = thumbs;
    return json;
  }

  static BadgeDefinitionContent fromJson(Map<String, dynamic> json) {
    return BadgeDefinitionContent(
      name: json['name'] as String? ?? 'Unknown Badge',
      description: json['description'] as String?,
      image: json['image'] as String?,
      thumbs: (json['thumbs'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

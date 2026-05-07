import 'dart:convert';

class HostrSessionStatusInput {
  const HostrSessionStatusInput({this.includeStorageDetails = false});

  final bool includeStorageDetails;

  factory HostrSessionStatusInput.fromJson(Map<String, dynamic> json) {
    return HostrSessionStatusInput(
      includeStorageDetails: json['includeStorageDetails'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    if (includeStorageDetails) 'includeStorageDetails': true,
  };
}

class HostrSessionConnectInput {
  const HostrSessionConnectInput({
    this.wait = false,
    this.timeoutSeconds = 180,
    this.regenerate = false,
  });

  final bool wait;
  final int timeoutSeconds;
  final bool regenerate;

  factory HostrSessionConnectInput.fromJson(Map<String, dynamic> json) {
    return HostrSessionConnectInput(
      wait: json['wait'] == true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 180)
          .clamp(1, 600)
          .toInt(),
      regenerate: json['regenerate'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    if (wait) 'wait': true,
    'timeoutSeconds': timeoutSeconds,
    if (regenerate) 'regenerate': true,
  };
}

class HostrListingsSearchInput {
  const HostrListingsSearchInput({
    this.location,
    this.query,
    this.type,
    this.guests,
    this.features = const [],
    this.limit = 10,
  });

  final String? location;
  final String? query;
  final String? type;
  final int? guests;
  final List<String> features;
  final int limit;

  factory HostrListingsSearchInput.fromJson(Map<String, dynamic> json) {
    return HostrListingsSearchInput(
      location: _optionalString(json['location']),
      query: _optionalString(json['query']),
      type: _optionalString(json['type']),
      guests: _optionalInt(json['guests']),
      features: _optionalStringList(json['features']),
      limit: (_optionalInt(json['limit']) ?? 10).clamp(1, 50).toInt(),
    );
  }

  Map<String, Object?> toJson() => {
    if (location != null) 'location': location,
    if (query != null) 'query': query,
    if (type != null) 'type': type,
    if (guests != null) 'guests': guests,
    if (features.isNotEmpty) 'features': features,
    'limit': limit,
  };
}

class HostrListingsListInput {
  const HostrListingsListInput({
    this.mine = false,
    this.author,
    this.limit = 50,
  });

  final bool mine;
  final String? author;
  final int limit;

  factory HostrListingsListInput.fromJson(Map<String, dynamic> json) {
    return HostrListingsListInput(
      mine: _optionalBool(json['mine']) ?? false,
      author: _optionalString(json['author']),
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
    );
  }
}

class HostrListingImageInput {
  const HostrListingImageInput({
    this.url,
    this.path,
    this.dataUrl,
    this.base64,
    this.filename,
    this.alt,
    this.mime,
  });

  final String? url;
  final String? path;
  final String? dataUrl;
  final String? base64;
  final String? filename;
  final String? alt;
  final String? mime;

  factory HostrListingImageInput.fromJson(Map<String, dynamic> json) {
    return HostrListingImageInput(
      url: _optionalString(json['url']),
      path: _optionalString(json['path']),
      dataUrl: _optionalString(json['dataUrl'] ?? json['dataUri']),
      base64: _optionalString(json['base64'] ?? json['data']),
      filename: _optionalString(json['filename'] ?? json['name']),
      alt: _optionalString(json['alt']),
      mime: _optionalString(json['mime']),
    );
  }

  Map<String, Object?> toJson() => {
    if (url != null) 'url': url,
    if (path != null) 'path': path,
    if (dataUrl != null) 'dataUrl': dataUrl,
    if (base64 != null) 'base64': base64,
    if (filename != null) 'filename': filename,
    if (alt != null) 'alt': alt,
    if (mime != null) 'mime': mime,
  };
}

class HostrListingPriceInput {
  const HostrListingPriceInput({required this.amount, this.frequency});

  final HostrAmountInput amount;
  final String? frequency;

  factory HostrListingPriceInput.fromJson(Map<String, dynamic> json) {
    return HostrListingPriceInput(
      amount: HostrAmountInput.fromJson(
        Map<String, dynamic>.from(json['amount'] as Map),
      ),
      frequency: _optionalString(json['frequency']),
    );
  }

  Map<String, Object?> toJson() => {
    'amount': amount.toJson(),
    if (frequency != null) 'frequency': frequency,
  };
}

class HostrAmountInput {
  const HostrAmountInput({
    required this.value,
    required this.currency,
    this.unit,
    this.decimals,
  });

  final String value;
  final String currency;
  final String? unit;
  final int? decimals;

  factory HostrAmountInput.fromJson(Map<String, dynamic> json) {
    return HostrAmountInput(
      value: json['value'].toString(),
      currency: json['currency'].toString(),
      unit: _optionalString(json['unit']),
      decimals: _optionalInt(json['decimals']),
    );
  }

  Map<String, Object?> toJson() => {
    'value': value,
    'currency': currency,
    if (unit != null) 'unit': unit,
    if (decimals != null) 'decimals': decimals,
  };
}

class HostrListingsCreateInput {
  HostrListingsCreateInput({
    required this.title,
    required this.description,
    required this.address,
    required this.images,
    required this.prices,
    this.type,
    this.specifications = const {},
    this.guests,
    this.beds,
    this.bedrooms,
    this.bathrooms,
    this.active,
    this.negotiable,
    this.instantBook,
    this.minStay,
    this.checkIn,
    this.checkOut,
    this.quantity,
    this.securityDeposit,
    this.minPaymentAmount,
    this.h3FinestResolution,
    this.h3MaxTags,
    this.h3Tags = const [],
    this.dTag,
    this.dryRun = true,
  });

  final String title;
  final String description;
  final String address;
  final List<HostrListingImageInput> images;
  final List<HostrListingPriceInput> prices;
  final String? type;
  final Map<String, dynamic> specifications;
  final int? guests;
  final int? beds;
  final int? bedrooms;
  final int? bathrooms;
  final bool? active;
  final bool? negotiable;
  final bool? instantBook;
  final int? minStay;
  final String? checkIn;
  final String? checkOut;
  final int? quantity;
  final HostrAmountInput? securityDeposit;
  final HostrAmountInput? minPaymentAmount;
  final int? h3FinestResolution;
  final int? h3MaxTags;
  final List<String> h3Tags;
  final String? dTag;
  final bool dryRun;

  factory HostrListingsCreateInput.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ?? json['image'];
    final rawPrices = json['prices'] ?? json['price'];
    return HostrListingsCreateInput(
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      address: _requiredString(json, 'address'),
      images: _requiredListValue(rawImages, 'images')
          .map(
            (item) => HostrListingImageInput.fromJson(
              item is Map ? Map<String, dynamic>.from(item) : {'url': item},
            ),
          )
          .toList(),
      prices: _requiredListValue(rawPrices, 'prices')
          .map(
            (item) => HostrListingPriceInput.fromJson(
              item is Map
                  ? Map<String, dynamic>.from(item)
                  : {
                      'amount': {'value': item.toString(), 'currency': 'USD'},
                    },
            ),
          )
          .toList(),
      type: _optionalString(json['type']),
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'])
          : const {},
      guests: _optionalInt(json['guests']),
      beds: _optionalInt(json['beds']),
      bedrooms: _optionalInt(json['bedrooms']),
      bathrooms: _optionalInt(json['bathrooms']),
      active: _optionalBool(json['active']),
      negotiable: _optionalBool(json['negotiable']),
      instantBook: _optionalBool(json['instantBook']),
      minStay: _optionalInt(json['minStay']),
      checkIn: _optionalString(json['checkIn']),
      checkOut: _optionalString(json['checkOut']),
      quantity: _optionalInt(json['quantity']),
      securityDeposit: json['securityDeposit'] is Map
          ? HostrAmountInput.fromJson(
              Map<String, dynamic>.from(json['securityDeposit']),
            )
          : null,
      minPaymentAmount: json['minPaymentAmount'] is Map
          ? HostrAmountInput.fromJson(
              Map<String, dynamic>.from(json['minPaymentAmount']),
            )
          : null,
      h3FinestResolution: _optionalInt(json['h3FinestResolution']),
      h3MaxTags: _optionalInt(json['h3MaxTags']),
      h3Tags: _optionalStringList(json['h3Tags']),
      dTag: _optionalString(json['dTag']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }

  Map<String, dynamic> toListingJson() => {
    'title': title,
    'description': description,
    'address': address,
    'images': images.map((image) => image.toJson()).toList(),
    'prices': prices.map((price) => price.toJson()).toList(),
    if (type != null) 'type': type,
    if (specifications.isNotEmpty) 'specifications': specifications,
    if (guests != null) 'guests': guests,
    if (beds != null) 'beds': beds,
    if (bedrooms != null) 'bedrooms': bedrooms,
    if (bathrooms != null) 'bathrooms': bathrooms,
    if (active != null) 'active': active,
    if (negotiable != null) 'negotiable': negotiable,
    if (instantBook != null) 'instantBook': instantBook,
    if (minStay != null) 'minStay': minStay,
    if (checkIn != null) 'checkIn': checkIn,
    if (checkOut != null) 'checkOut': checkOut,
    if (quantity != null) 'quantity': quantity,
    if (securityDeposit != null) 'securityDeposit': securityDeposit!.toJson(),
    if (minPaymentAmount != null)
      'minPaymentAmount': minPaymentAmount!.toJson(),
    if (h3FinestResolution != null) 'h3FinestResolution': h3FinestResolution,
    if (h3MaxTags != null) 'h3MaxTags': h3MaxTags,
    if (h3Tags.isNotEmpty) 'h3Tags': h3Tags,
    if (dTag != null) 'dTag': dTag,
  };
}

class HostrListingsEditInput {
  HostrListingsEditInput({
    required this.anchor,
    this.patch = const {},
    this.dryRun = true,
  });

  final String anchor;
  final Map<String, dynamic> patch;
  final bool dryRun;

  factory HostrListingsEditInput.fromJson(Map<String, dynamic> json) {
    final patch =
        json['patch'] is Map
              ? Map<String, dynamic>.from(json['patch'])
              : Map<String, dynamic>.from(json)
          ..remove('anchor')
          ..remove('dryRun');
    return HostrListingsEditInput(
      anchor: _requiredString(json, 'anchor'),
      patch: patch,
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrListingsAnchorsInput {
  const HostrListingsAnchorsInput({required this.anchors, this.limit = 50});

  final List<String> anchors;
  final int limit;

  factory HostrListingsAnchorsInput.fromJson(Map<String, dynamic> json) {
    final anchors = _optionalStringList(json['anchors'] ?? json['anchor']);
    if (anchors.isEmpty) {
      throw const FormatException('Missing required anchors.');
    }
    return HostrListingsAnchorsInput(
      anchors: anchors,
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
    );
  }
}

class HostrListingsAvailabilityInput {
  const HostrListingsAvailabilityInput({
    required this.anchors,
    required this.start,
    required this.end,
  });

  final List<String> anchors;
  final DateTime start;
  final DateTime end;

  factory HostrListingsAvailabilityInput.fromJson(Map<String, dynamic> json) {
    final anchors = _optionalStringList(json['anchors'] ?? json['anchor']);
    if (anchors.isEmpty) {
      throw const FormatException('Missing required anchors.');
    }
    return HostrListingsAvailabilityInput(
      anchors: anchors,
      start: DateTime.parse(_requiredString(json, 'start')),
      end: DateTime.parse(_requiredString(json, 'end')),
    );
  }
}

class HostrReservationsOfferInput {
  const HostrReservationsOfferInput({
    this.listingAnchor,
    this.start,
    this.end,
    this.tradeId,
    this.amount,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String? listingAnchor;
  final DateTime? start;
  final DateTime? end;
  final String? tradeId;
  final HostrAmountInput? amount;
  final bool dryRun;
  final int timeoutSeconds;

  bool get isFollowUpOffer => tradeId != null;

  factory HostrReservationsOfferInput.fromJson(Map<String, dynamic> json) {
    final tradeId = _optionalString(json['tradeId']);
    final listingAnchor = _optionalString(
      json['listingAnchor'] ?? json['anchor'],
    );
    if (tradeId != null) {
      return HostrReservationsOfferInput(
        tradeId: tradeId,
        amount: json['amount'] is Map
            ? HostrAmountInput.fromJson(
                Map<String, dynamic>.from(json['amount']),
              )
            : null,
        dryRun: _optionalBool(json['dryRun']) ?? true,
        timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
            .clamp(1, 60)
            .toInt(),
      );
    }
    if (listingAnchor == null) {
      throw const FormatException('Missing required listingAnchor or tradeId.');
    }
    return HostrReservationsOfferInput(
      listingAnchor: listingAnchor,
      start: DateTime.parse(_requiredString(json, 'start')),
      end: DateTime.parse(_requiredString(json, 'end')),
      amount: json['amount'] is Map
          ? HostrAmountInput.fromJson(Map<String, dynamic>.from(json['amount']))
          : null,
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }

  Map<String, Object?> toJson() => {
    if (listingAnchor != null) 'listingAnchor': listingAnchor,
    if (start != null) 'start': start!.toUtc().toIso8601String(),
    if (end != null) 'end': end!.toUtc().toIso8601String(),
    if (tradeId != null) 'tradeId': tradeId,
    if (amount != null) 'amount': amount!.toJson(),
    if (timeoutSeconds != 12) 'timeoutSeconds': timeoutSeconds,
    if (!dryRun) 'dryRun': false,
  };
}

class HostrReservationBookAndPayInput {
  const HostrReservationBookAndPayInput({
    required this.listingAnchor,
    required this.start,
    required this.end,
    this.amount,
    this.escrowServiceId,
    this.proofTimeoutSeconds = 300,
  });

  final String listingAnchor;
  final DateTime start;
  final DateTime end;
  final HostrAmountInput? amount;
  final String? escrowServiceId;
  final int proofTimeoutSeconds;

  factory HostrReservationBookAndPayInput.fromJson(Map<String, dynamic> json) {
    return HostrReservationBookAndPayInput(
      listingAnchor: _requiredString(json, 'listingAnchor'),
      start: DateTime.parse(_requiredString(json, 'start')),
      end: DateTime.parse(_requiredString(json, 'end')),
      amount: json['amount'] is Map
          ? HostrAmountInput.fromJson(Map<String, dynamic>.from(json['amount']))
          : null,
      escrowServiceId: _optionalString(json['escrowServiceId']),
      proofTimeoutSeconds: (_optionalInt(json['proofTimeoutSeconds']) ?? 300)
          .clamp(30, 3600)
          .toInt(),
    );
  }

  Map<String, Object?> toJson() => {
    'listingAnchor': listingAnchor,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    if (amount != null) 'amount': amount!.toJson(),
    if (escrowServiceId != null) 'escrowServiceId': escrowServiceId,
    if (proofTimeoutSeconds != 300) 'proofTimeoutSeconds': proofTimeoutSeconds,
  };
}

class HostrReservationTradeInput {
  const HostrReservationTradeInput({
    required this.tradeId,
    this.amount,
    this.reason,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String tradeId;
  final HostrAmountInput? amount;
  final String? reason;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrReservationTradeInput.fromJson(Map<String, dynamic> json) {
    return HostrReservationTradeInput(
      tradeId: _requiredString(json, 'tradeId'),
      amount: json['amount'] is Map
          ? HostrAmountInput.fromJson(Map<String, dynamic>.from(json['amount']))
          : null,
      reason: _optionalString(json['reason']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrReservationPayInput {
  const HostrReservationPayInput({
    required this.tradeId,
    this.escrowServiceId,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String tradeId;
  final String? escrowServiceId;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrReservationPayInput.fromJson(Map<String, dynamic> json) {
    return HostrReservationPayInput(
      tradeId: _requiredString(json, 'tradeId'),
      escrowServiceId: _optionalString(json['escrowServiceId']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrReservationCommitInput {
  const HostrReservationCommitInput({
    required this.swapId,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String swapId;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrReservationCommitInput.fromJson(Map<String, dynamic> json) {
    return HostrReservationCommitInput(
      swapId: _requiredString(json, 'swapId'),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrUpdatesInput {
  const HostrUpdatesInput({this.limit = 10, this.timeoutSeconds = 12});

  final int limit;
  final int timeoutSeconds;

  factory HostrUpdatesInput.fromJson(Map<String, dynamic> json) {
    return HostrUpdatesInput(
      limit: (_optionalInt(json['limit']) ?? 10).clamp(1, 50).toInt(),
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrReplyInput {
  const HostrReplyInput({
    required this.content,
    required this.recipientPubkeys,
    this.conversation,
    this.dryRun = true,
  });

  final String content;
  final List<String> recipientPubkeys;
  final String? conversation;
  final bool dryRun;

  factory HostrReplyInput.fromJson(Map<String, dynamic> json) {
    final recipients = _optionalStringList(
      json['recipientPubkeys'] ?? json['recipientPubkey'],
    );
    if (recipients.isEmpty) {
      throw const FormatException('Missing required recipientPubkeys.');
    }
    return HostrReplyInput(
      content: _requiredString(json, 'content'),
      recipientPubkeys: recipients,
      conversation: _optionalString(json['conversation'] ?? json['tradeId']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrThreadViewInput {
  const HostrThreadViewInput({
    this.threadAnchor,
    this.conversation,
    this.tradeId,
    this.recipientPubkeys = const [],
    this.limit = 50,
    this.timeoutSeconds = 12,
  });

  final String? threadAnchor;
  final String? conversation;
  final String? tradeId;
  final List<String> recipientPubkeys;
  final int limit;
  final int timeoutSeconds;

  factory HostrThreadViewInput.fromJson(Map<String, dynamic> json) {
    return HostrThreadViewInput(
      threadAnchor: _optionalString(json['threadAnchor'] ?? json['anchor']),
      conversation: _optionalString(json['conversation']),
      tradeId: _optionalString(json['tradeId']),
      recipientPubkeys: _optionalStringList(
        json['recipientPubkeys'] ?? json['recipientPubkey'],
      ),
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrThreadMessageInput {
  const HostrThreadMessageInput({
    required this.content,
    this.threadAnchor,
    this.conversation,
    this.tradeId,
    this.recipientRole,
    this.recipientPubkeys = const [],
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String content;
  final String? threadAnchor;
  final String? conversation;
  final String? tradeId;
  final String? recipientRole;
  final List<String> recipientPubkeys;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrThreadMessageInput.fromJson(Map<String, dynamic> json) {
    return HostrThreadMessageInput(
      content: _requiredString(json, 'content'),
      threadAnchor: _optionalString(json['threadAnchor'] ?? json['anchor']),
      conversation: _optionalString(json['conversation']),
      tradeId: _optionalString(json['tradeId']),
      recipientRole: _optionalString(json['recipientRole'] ?? json['role']),
      recipientPubkeys: _optionalStringList(
        json['recipientPubkeys'] ?? json['recipientPubkey'],
      ),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrEscrowInvolveInput {
  const HostrEscrowInvolveInput({
    required this.tradeId,
    this.content,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String tradeId;
  final String? content;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrEscrowInvolveInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowInvolveInput(
      tradeId: _requiredString(json, 'tradeId'),
      content: _optionalString(json['content'] ?? json['message']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrProfileEditInput {
  const HostrProfileEditInput({
    this.name,
    this.about,
    this.image,
    this.lud16,
    this.nip05,
    this.dryRun = true,
  });

  final String? name;
  final String? about;
  final String? image;
  final String? lud16;
  final String? nip05;
  final bool dryRun;

  factory HostrProfileEditInput.fromJson(Map<String, dynamic> json) {
    return HostrProfileEditInput(
      name: _optionalString(json['name']),
      about: _optionalString(json['about']),
      image: _optionalString(json['image'] ?? json['picture']),
      lud16: _optionalString(json['lud16']),
      nip05: _optionalString(json['nip05']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrProfileLookupInput {
  const HostrProfileLookupInput({required this.npub});

  final String npub;

  factory HostrProfileLookupInput.fromJson(Map<String, dynamic> json) {
    return HostrProfileLookupInput(npub: _requiredString(json, 'npub'));
  }
}

class HostrReservationCollectionInput {
  const HostrReservationCollectionInput({
    this.limit = 50,
    this.tradeId,
    this.waitSeconds = 15,
  });

  final int limit;
  final String? tradeId;
  final int waitSeconds;

  factory HostrReservationCollectionInput.fromJson(Map<String, dynamic> json) {
    return HostrReservationCollectionInput(
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
      tradeId: _optionalString(json['tradeId']),
      waitSeconds: (_optionalInt(json['waitSeconds']) ?? 15)
          .clamp(0, 300)
          .toInt(),
    );
  }
}

class HostrSwapsListInput {
  const HostrSwapsListInput({this.namespace = 'all'});

  final String namespace;

  factory HostrSwapsListInput.fromJson(Map<String, dynamic> json) {
    final namespace = _optionalString(json['namespace']) ?? 'all';
    if (!const {'all', 'swap_in', 'swap_out'}.contains(namespace)) {
      throw FormatException('Unsupported swap namespace "$namespace".');
    }
    return HostrSwapsListInput(namespace: namespace);
  }
}

class HostrSwapsWatchInput {
  const HostrSwapsWatchInput({
    required this.swapId,
    this.tradeId,
    this.reservationWaitSeconds = 20,
  });

  final String swapId;
  final String? tradeId;
  final int reservationWaitSeconds;

  factory HostrSwapsWatchInput.fromJson(Map<String, dynamic> json) {
    return HostrSwapsWatchInput(
      swapId: _requiredString(json, 'swapId'),
      tradeId: _optionalString(json['tradeId']),
      reservationWaitSeconds:
          (_optionalInt(json['reservationWaitSeconds']) ?? 20)
              .clamp(0, 300)
              .toInt(),
    );
  }
}

class HostrSwapsRecoverAllInput {
  const HostrSwapsRecoverAllInput({
    this.background = false,
    this.dryRun = true,
  });

  final bool background;
  final bool dryRun;

  factory HostrSwapsRecoverAllInput.fromJson(Map<String, dynamic> json) {
    return HostrSwapsRecoverAllInput(
      background: _optionalBool(json['background']) ?? false,
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowMethodsInput {
  const HostrEscrowMethodsInput({required this.user, this.buyer});

  final String user;
  final String? buyer;

  factory HostrEscrowMethodsInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowMethodsInput(
      user: _requiredString(json, 'user'),
      buyer: _optionalString(json['buyer']),
    );
  }
}

class HostrEscrowTradesListInput {
  const HostrEscrowTradesListInput({this.limit = 25});

  final int limit;

  factory HostrEscrowTradesListInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowTradesListInput(
      limit: (_optionalInt(json['limit']) ?? 25).clamp(1, 100).toInt(),
    );
  }
}

class HostrEscrowTradeAuditInput {
  const HostrEscrowTradeAuditInput({required this.tradeId});

  final String tradeId;

  factory HostrEscrowTradeAuditInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowTradeAuditInput(
      tradeId: _requiredString(json, 'tradeId'),
    );
  }
}

class HostrEscrowTradeViewInput {
  const HostrEscrowTradeViewInput({required this.tradeId});

  final String tradeId;

  factory HostrEscrowTradeViewInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowTradeViewInput(tradeId: _requiredString(json, 'tradeId'));
  }
}

class HostrEscrowServiceListInput {
  const HostrEscrowServiceListInput({this.limit = 25});

  final int limit;

  factory HostrEscrowServiceListInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowServiceListInput(
      limit: (_optionalInt(json['limit']) ?? 25).clamp(1, 100).toInt(),
    );
  }
}

class HostrEscrowServiceGetInput {
  const HostrEscrowServiceGetInput({required this.serviceId});

  final String serviceId;

  factory HostrEscrowServiceGetInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowServiceGetInput(
      serviceId: _requiredString(json, 'serviceId'),
    );
  }
}

class HostrTokenFeeHintsInput {
  const HostrTokenFeeHintsInput({
    this.baseFee = 0,
    this.maxFee = 0,
    this.minFee = 0,
  });

  final int baseFee;
  final int maxFee;
  final int minFee;

  factory HostrTokenFeeHintsInput.fromJson(Map<String, dynamic> json) {
    return HostrTokenFeeHintsInput(
      baseFee: (_optionalInt(json['baseFee']) ?? 0).clamp(0, 1 << 62).toInt(),
      maxFee: (_optionalInt(json['maxFee']) ?? 0).clamp(0, 1 << 62).toInt(),
      minFee: (_optionalInt(json['minFee']) ?? 0).clamp(0, 1 << 62).toInt(),
    );
  }
}

class HostrEscrowServiceUpdateInput {
  const HostrEscrowServiceUpdateInput({
    this.serviceId,
    this.feePercent,
    this.maxDurationSeconds,
    this.tokenFeeHints,
    this.clearTokenFeeHints = false,
    this.dryRun = true,
  });

  final String? serviceId;
  final double? feePercent;
  final int? maxDurationSeconds;
  final Map<String, HostrTokenFeeHintsInput>? tokenFeeHints;
  final bool clearTokenFeeHints;
  final bool dryRun;

  factory HostrEscrowServiceUpdateInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowServiceUpdateInput(
      serviceId: _optionalString(json['serviceId']),
      feePercent: _optionalPercent(json['feePercent'], 'feePercent'),
      maxDurationSeconds: _optionalInt(
        json['maxDurationSeconds'],
      )?.clamp(1, 315360000).toInt(),
      tokenFeeHints: _optionalTokenFeeHints(json['tokenFeeHints']),
      clearTokenFeeHints: _optionalBool(json['clearTokenFeeHints']) ?? false,
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowServiceDeleteInput {
  const HostrEscrowServiceDeleteInput({
    required this.serviceId,
    this.reason,
    this.dryRun = true,
  });

  final String serviceId;
  final String? reason;
  final bool dryRun;

  factory HostrEscrowServiceDeleteInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowServiceDeleteInput(
      serviceId: _requiredString(json, 'serviceId'),
      reason: _optionalString(json['reason']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowArbitrateInput {
  const HostrEscrowArbitrateInput({
    required this.tradeId,
    required this.paymentForward,
    required this.bondForward,
    this.reason,
    this.dryRun = true,
  });

  final String tradeId;
  final double paymentForward;
  final double bondForward;
  final String? reason;
  final bool dryRun;

  factory HostrEscrowArbitrateInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowArbitrateInput(
      tradeId: _requiredString(json, 'tradeId'),
      paymentForward: _requiredRatio(json['paymentForward'], 'paymentForward'),
      bondForward: _requiredRatio(json['bondForward'], 'bondForward'),
      reason: _optionalString(json['reason']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowBadgeDefinitionsListInput {
  const HostrEscrowBadgeDefinitionsListInput({this.limit = 50});

  final int limit;

  factory HostrEscrowBadgeDefinitionsListInput.fromJson(
    Map<String, dynamic> json,
  ) {
    return HostrEscrowBadgeDefinitionsListInput(
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
    );
  }
}

class HostrEscrowBadgeDefinitionEditInput {
  const HostrEscrowBadgeDefinitionEditInput({
    required this.identifier,
    required this.name,
    this.description,
    this.image,
    this.dryRun = true,
  });

  final String identifier;
  final String name;
  final String? description;
  final String? image;
  final bool dryRun;

  factory HostrEscrowBadgeDefinitionEditInput.fromJson(
    Map<String, dynamic> json,
  ) {
    return HostrEscrowBadgeDefinitionEditInput(
      identifier: _requiredString(json, 'identifier'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json['description']),
      image: _optionalString(json['image']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowBadgeDefinitionDeleteInput {
  const HostrEscrowBadgeDefinitionDeleteInput({
    required this.anchor,
    this.reason,
    this.dryRun = true,
  });

  final String anchor;
  final String? reason;
  final bool dryRun;

  factory HostrEscrowBadgeDefinitionDeleteInput.fromJson(
    Map<String, dynamic> json,
  ) {
    return HostrEscrowBadgeDefinitionDeleteInput(
      anchor: _requiredString(json, 'anchor'),
      reason: _optionalString(json['reason']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowBadgeAwardsListInput {
  const HostrEscrowBadgeAwardsListInput({
    this.definitionAnchor,
    this.limit = 50,
  });

  final String? definitionAnchor;
  final int limit;

  factory HostrEscrowBadgeAwardsListInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowBadgeAwardsListInput(
      definitionAnchor: _optionalString(json['definitionAnchor']),
      limit: (_optionalInt(json['limit']) ?? 50).clamp(1, 200).toInt(),
    );
  }
}

class HostrEscrowBadgeAwardInput {
  const HostrEscrowBadgeAwardInput({
    required this.definitionAnchor,
    required this.recipientPubkey,
    this.listingAnchor,
    this.dryRun = true,
  });

  final String definitionAnchor;
  final String recipientPubkey;
  final String? listingAnchor;
  final bool dryRun;

  factory HostrEscrowBadgeAwardInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowBadgeAwardInput(
      definitionAnchor: _requiredString(json, 'definitionAnchor'),
      recipientPubkey: _requiredString(json, 'recipientPubkey'),
      listingAnchor: _optionalString(json['listingAnchor']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrEscrowBadgeRevokeInput {
  const HostrEscrowBadgeRevokeInput({
    required this.awardId,
    this.reason,
    this.dryRun = true,
  });

  final String awardId;
  final String? reason;
  final bool dryRun;

  factory HostrEscrowBadgeRevokeInput.fromJson(Map<String, dynamic> json) {
    return HostrEscrowBadgeRevokeInput(
      awardId: _requiredString(json, 'awardId'),
      reason: _optionalString(json['reason']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
    );
  }
}

class HostrActionSpec {
  const HostrActionSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.inputTypeName,
    required this.inputSchema,
    required this.typescriptInput,
    required this.readOnly,
    this.requiredRole,
  });

  final String id;
  final String title;
  final String description;
  final String inputTypeName;
  final Map<String, Object?> inputSchema;
  final String typescriptInput;
  final bool readOnly;
  final String? requiredRole;

  String get mcpToolName => id.replaceAll('.', '_');

  String get mcpDescription {
    final notes = [
      description,
      _commonDrivingNotes,
      if (requiredRole == 'escrow') _escrowRoleNotes,
      if (readOnly) _readOnlyNotes else _writeSafetyNotes,
      if (_hasTopLevelInput('dryRun')) _dryRunNotes,
      if (_hasTopLevelInput('start') || _hasTopLevelInput('end'))
        _reservationDateNotes,
      _toolSpecificDrivingNotes,
    ].where((note) => note.trim().isNotEmpty);

    return notes.join('\n\n');
  }

  bool _hasTopLevelInput(String key) {
    final properties = inputSchema['properties'];
    return properties is Map && properties.containsKey(key);
  }

  String get _commonDrivingNotes =>
      'MCP driving notes: Hostr is the canonical tool surface for Hostr marketplace state and Hostr-related Nostr state, including listings, reservations, trips, bookings, inbox threads, Nostr Connect/NIP-46 signer login, relays, npubs/naddrs, gift-wrapped messages, escrow services, swaps, and on-chain escrow trades. Do not use general web search for these live Hostr/Nostr workflows unless the user explicitly asks for public web documentation. The MCP access token selects the authenticated Hostr pubkey/session; do not invent or pass a user pubkey unless this tool has a parameter that explicitly asks for an author, buyer, seller, recipient, or escrow pubkey. Do not run preflight session/profile checks before every sensitive action. Call the intended Hostr tool first; if it returns a structured auth/profile/signature error, follow the error recovery instructions, then retry the original workflow.';

  String get _readOnlyNotes =>
      'Read-only behavior: this tool retrieves or analyzes Hostr state and is safe to call when the user asks to inspect, search, explain, debug, or choose the next action. Prefer read tools before write tools when the user intent is ambiguous or when you need concrete listing, trade, thread, or profile ids.';

  String get _writeSafetyNotes =>
      'Write behavior: this tool can create, publish, send, recover, delete, pay, arbitrate, or otherwise change state outside ChatGPT. Explain the important effect to the user before live execution, preserve user-visible previews, and require explicit user approval before any irreversible or externally visible action.';

  String get _dryRunNotes =>
      'Preview rule: dryRun defaults to true. First call with dryRun=true, show the user the returned preview or card, and only repeat with dryRun=false after the user explicitly approves that preview in the conversation. Do not treat vague acknowledgement as approval for destructive, payment, publication, messaging, cancellation, recovery, or arbitration actions.';

  String get _reservationDateNotes =>
      'Reservation date rule: Hostr reservation start/end inputs are calendar dates, not timezone instants. Preserve the dates the user requested and encode them as YYYY-MM-DDT00:00:00Z. The trailing Z is storage syntax only; do not convert from the user timezone, listing timezone, El Salvador time, check-in time, or check-out time.';

  String get _escrowRoleNotes =>
      'Escrow role notes: this tool is visible only when the authenticated Hostr pubkey is configured as an escrow service. It is for escrow-operator work, not ordinary guest/host booking flows. Keep user profile edits in hostr_profile_edit; escrow service tools only manage escrow service events/settings.';

  String get _toolSpecificDrivingNotes {
    switch (id) {
      case 'hostr.session.status':
        return 'Use when the user asks whether they are logged in, when debugging auth, or after a Hostr action returns an auth/profile/signature error. Do not call this as a routine preflight before every write; failed tools return structured recovery instructions.';
      case 'hostr.session.connect':
        return 'Two-step login flow: call with wait=false to create or reuse a Nostr Connect request, display the nostrconnect URI or QR image to the user, then immediately call this tool again with wait=true and regenerate=false to listen for approval. After authenticated=true, retry or continue the Hostr action that required sign-in.';
      case 'hostr.listings.search':
        return 'Use for marketplace discovery from natural language lodging intents such as finding a place to stay, lodging, accommodation, room, apartment, house, villa, hotel-like stay, or rental in a destination. Put city/country/place names in location; put keyword filters in query; use guests/features/type only when the user provides them. Results return listing-card Markdown and structured cards; preserve every image tag when presenting results.';
      case 'hostr.listings.list':
        return 'Use for inventory/management views: "my listings", "what am I hosting", "show my stays", or listings by a known author pubkey. Use mine=true for the authenticated user. Use author only when the user provides or selected a specific pubkey.';
      case 'hostr.listings.create':
        return 'Use when the authenticated user wants to create, publish, list, rent out, or host a room/place/stay. Collect title, description, address, at least one image URL, and at least one price before calling. The first image is the card/hero image. This MCP tool accepts image URLs only. For ChatGPT web/mobile, local development clients, or any remote MCP client with uploaded files, first call hostr_images_upload with the original image sent as the MCP file-typed argument named file so the client bridge can rewrite or stream the bytes, then pass structuredContent.usage.image.url as images[].url. If the client cannot call hostr_images_upload but can make raw HTTP requests, POST the original image bytes to /mcp/uploads/images on the same Hostr MCP origin using multipart/form-data field name file, then pass the returned upload.url as images[].url. The upload tool and endpoint do not require authorization, but when a valid MCP bearer token is present Hostr first tries the logged-in session Blossom upload path before falling back to direct upload. Do not base64-encode the uploaded image into this MCP tool call. Do not serve a temporary localhost URL for Hostr to fetch; localhost refers to the wrong machine/container. If neither upload route can be used, stop and ask for a public image URL or for the client to expose an upload capability. Do not resize, downscale, crop, recompress, transcode, or make thumbnails unless the user explicitly requests it. Never pass a local or mounted sandbox path such as /mnt/data, /mnt/shared, file://, or a ChatGPT file mount to images[].url. Use dryRun=true to upload/stage media and return the visual listing preview. When publishing the approved preview, call this tool again with dryRun=false and reuse the exact dTag from structuredContent.nextInput or structuredContent.dTag so preview, publish, and any retry update the same replaceable listing. The live path also ensures seller configuration is published.';
      case 'hostr.listings.edit':
        return 'Use when the authenticated author wants to update an existing listing. If the user has not named a concrete listing anchor, first call hostr_listings_list with mine=true and ask/choose from the returned listings. Patch only fields the user intends to change; preview with dryRun=true and publish with dryRun=false only after approval.';
      case 'hostr.listings.availability':
        return 'Use after a user has selected one or more listings and supplied dates, before booking or explaining date conflicts. Pass listing anchors from search/list results. If dates are missing, ask for them instead of guessing.';
      case 'hostr.listings.reviews':
        return 'Use when the user asks about reviews, reputation, prior guest feedback, or trust signals for one or more listings. Pass listing anchors from search/list results.';
      case 'hostr.listings.reservationGroups':
        return 'Use when the user asks why dates are unavailable, wants booking history/conflicts for a listing, or needs reservation context before changing availability-sensitive plans.';
      case 'hostr.reservations.bookAndPay':
        return 'Primary booking flow: use this when the user says book, reserve, make a reservation, create a reservation, or otherwise clearly wants an instant-book stay at or above the listed price. It creates the private offer, prepares escrow funding, returns external Lightning payment details when needed, and keeps the daemon-side book-and-pay operation alive. If invoice/QR are returned, show only the invoice string and QR image visibly in the payment prompt; keep internal tradeId and swapId hidden from the user-facing payment message. Immediately after the payment prompt is visible, call hostr_swaps_watch with swapId, tradeId, and reservationWaitSeconds to monitor payment/proof/reservation completion. When watch completes or cannot find the swap, call hostr_trips_list with the same tradeId until the committed reservation appears. Do not call hostr_reservations_commit for this normal path; proof publication is owned by the global payment proof orchestrator.';
      case 'hostr.reservations.negotiateOffer':
        return 'Negotiation-only flow: use for explicit offers, counteroffers, price/date negotiation, or non-instant-book reservation proposals. Do not use this for straightforward "book/reserve" intents on instant-book listings; use hostr_reservations_bookAndPay there. Preview with dryRun=true, then send the private negotiation event with dryRun=false only after approval.';
      case 'hostr.reservations.negotiateAccept':
        return 'Use when the user wants to accept the latest private negotiated offer in a known trade thread. If tradeId is unknown, call hostr_updates, hostr_thread_view, hostr_trips_list, or hostr_bookings_list first to identify the trade.';
      case 'hostr.reservations.pay':
        return 'Manual recovery/debug payment flow only. Normal AI-initiated instant-book payment should use hostr_reservations_bookAndPay. Use this when a negotiated or partially completed trade already exists and the user explicitly wants to create or inspect escrow funding for that trade.';
      case 'hostr.reservations.commit':
        return 'Manual recovery/debug commit flow only. Do not use after hostr_reservations_bookAndPay; that path relies on the global payment proof orchestrator. Use only when a swap proof already exists for a trade and the user explicitly needs to preview or publish the public commit-stage reservation.';
      case 'hostr.reservations.cancel':
        return 'Use to cancel a private negotiation or committed reservation for a concrete trade. If tradeId is unclear, inspect updates, trips, bookings, or thread view first. Preview the cancellation and send with dryRun=false only after explicit approval.';
      case 'hostr.updates':
        return 'Use as the inbox/home-state tool when the user asks for messages, offers, notifications, latest activity, what needs attention, or when you need trade/thread ids for negotiation or messaging. It processes gift-wrapped events and returns thread cards; present displayMarkdown, not raw event JSON.';
      case 'hostr.reply':
        return 'Legacy/general threaded reply tool. Prefer hostr_thread_message for user-facing conversation work because it returns a fixed thread-view contract. Use this when you already have the exact conversation/trade recipient context and need a simple gift-wrapped reply.';
      case 'hostr.thread.view':
        return 'Use when the user asks to see a conversation, asks whether someone messaged them, references a trip/booking thread, or you need message history before replying. Prefer tradeId when the conversation is tied to a reservation; otherwise pass a known thread/conversation anchor from updates.';
      case 'hostr.thread.message':
        return 'Use when the user asks to message a host, guest, buyer, seller, escrow, or existing Hostr thread. If they reference a trip/booking/trade, pass tradeId. Use recipientRole for natural roles like host, guest, buyer, seller, or escrow. Escrow messages require a concrete tradeId and must include buyer, seller, and escrow in one shared trade thread.';
      case 'hostr.escrow.involve':
        return 'Use when the user explicitly asks to involve/message escrow for a specific reservation trade. Always pass tradeId. This opens the shared buyer/seller/escrow trade thread; never create an escrow-only side conversation. If no message content is provided, show the thread and ask what to send.';
      case 'hostr.profile.show':
        return 'Use when the user asks who they are on Hostr, wants their current profile, or before profile/listing publishing when you need existing metadata. This reads the profile for the MCP token pubkey.';
      case 'hostr.profile.lookup':
        return 'Use when the user asks to view a specific public Nostr/Hostr profile by npub, including a host, guest, seller, buyer, or arbitrary profile that is not the authenticated MCP user. This tool is public and does not require sign-in.';
      case 'hostr.profile.edit':
        return 'Use when the user wants to update profile name, about/bio, picture, banner, website, lightning address, or other profile metadata. Preview first; publish only after approval. Publishing also refreshes Hostr seller configuration, which is useful before creating or editing listings.';
      case 'hostr.trips.list':
        return 'Use for guest-side reservations: "my trips", "my bookings as guest", "did my reservation complete", or after book-and-pay/swap watch with tradeId to wait for the committed reservation card. Do not perform fresh reservation-by-author Nostr queries for this view.';
      case 'hostr.bookings.list':
        return 'Use for host-side reservations on listings authored by the authenticated user: "my bookings", "who booked my place", "hosting reservations", or host calendar context. Do not perform fresh reservation-by-author Nostr queries for this view.';
      case 'hostr.escrow.methods':
        return 'Use before payment or when explaining how money is protected. It shows mutually compatible escrow methods/services between buyer and seller. If buyer is omitted, the authenticated token pubkey is used. Explain that Hostr swaps payment over Lightning into smart-contract escrow; the escrow service can only settle by forwarding or reversing according to trade outcome, not freely take custody.';
      case 'hostr.escrow.service.list':
        return 'Escrow-operator inventory view: list public escrow service events published by the authenticated escrow pubkey. Use before editing/deleting when the user has not selected a specific service event.';
      case 'hostr.escrow.service.get':
        return 'Escrow-operator detail view: inspect one escrow service event before explaining or editing settings. Use serviceId from hostr_escrow_service_list or user input.';
      case 'hostr.escrow.service.update':
      case 'hostr.escrow.service.edit':
        return 'Escrow-operator settings workflow: preview changes to fee percent, maximum duration, or token fee hints. Keep dryRun=true until the user approves the exact preview. Use hostr_profile_edit for public profile/identity metadata; this tool only changes escrow service parameters.';
      case 'hostr.escrow.service.delete':
        return 'Escrow-operator destructive workflow: preview deletion of a public escrow service event and require explicit deletion approval before dryRun=false. Include the reason when the user gives one.';
      case 'hostr.escrow.trades.list':
        return 'Escrow-operator dashboard: list on-chain trades assigned to the authenticated escrow pubkey. Use before viewing/auditing/arbitrating when the user has not named a concrete tradeId.';
      case 'hostr.escrow.trades.view':
        return 'Escrow-operator trade detail: inspect on-chain state, event history, participants, amounts, and reservation context for a trade before audit or arbitration.';
      case 'hostr.escrow.trades.audit':
        return 'Escrow-operator analysis: run a structured audit of reservation state and transitions for a trade before deciding whether arbitration is needed. This does not settle funds.';
      case 'hostr.escrow.trades.arbitrate':
        return 'Escrow-operator settlement workflow: preview paymentForward and bondForward fractions before execution. Fractions are 0 to 1. Explain the proposed split and reason to the user, then execute with dryRun=false only after explicit approval.';
      case 'hostr.escrow.badges.definitions.list':
        return 'Escrow-operator badge inventory: list NIP-58 badge definitions issued by the authenticated escrow. Use before editing, awarding, or deleting badges when the identifier/anchor is unclear.';
      case 'hostr.escrow.badges.definitions.edit':
        return 'Escrow-operator badge definition workflow: preview or publish a NIP-58 badge definition. Use for creating or updating the badge name, description, or image. Publish only after approval.';
      case 'hostr.escrow.badges.definitions.delete':
        return 'Escrow-operator destructive badge workflow: preview deletion of a badge definition and publish only after explicit approval. Include a reason when provided.';
      case 'hostr.escrow.badges.awards.list':
        return 'Escrow-operator badge award view: list issued badge awards, optionally filtered by definition anchor. Use before revoking when the award id is unclear.';
      case 'hostr.escrow.badges.award':
        return 'Escrow-operator award workflow: preview or publish a NIP-58 badge award to a recipient pubkey, optionally tied to a listing anchor. Publish only after approval.';
      case 'hostr.escrow.badges.revoke':
        return 'Escrow-operator destructive award workflow: preview revocation/deletion of an issued badge award and publish only after explicit approval. Include a reason when provided.';
      case 'hostr.swaps.watch':
        return 'Read-only monitor to use immediately after hostr_reservations_bookAndPay returns swapId/tradeId, or when inspecting a specific swap. It observes persisted swap/payment/proof state and optionally waits for the committed reservation by tradeId. It has no dryRun parameter and does not recover stale swaps; use hostr_swaps_recoverAll for explicit recovery.';
      case 'hostr.swaps.recoverAll':
        return 'Use when the user asks to recover stuck payments/swaps or when diagnostics show persisted swap operations need resumption. Preview first; run with dryRun=false only after approval. Use background=true only when the user wants recovery to continue asynchronously.';
      case 'hostr.swaps.list':
        return 'Use to inspect persisted swap-in and swap-out states before recovery/debugging, or when the user asks about payment status, stuck swaps, refunds, or pending Lightning/on-chain operations.';
    }
    return '';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'toolName': mcpToolName,
    'title': title,
    'description': mcpDescription,
    'inputTypeName': inputTypeName,
    'inputSchema': inputSchema,
    'typescriptInput': typescriptInput,
    'readOnly': readOnly,
    if (requiredRole != null) 'requiredRole': requiredRole,
  };
}

const Map<String, Object?> _anchorsInputSchema = {
  'type': 'object',
  'additionalProperties': false,
  'properties': {
    'anchors': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Listing anchors.',
    },
    'anchor': {'type': 'string', 'description': 'Single listing anchor.'},
    'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200, 'default': 50},
  },
};

const String _anchorsTypescriptInput = '''
export interface HostrListingsAnchorsInput {
  anchors?: string[];
  anchor?: string;
  limit?: number;
}
''';

const String _reservationDateOnlyRule =
    'Reservation start/end values are calendar dates, not timezone instants. '
    'Encode the requested date as YYYY-MM-DDT00:00:00Z; the trailing Z is storage syntax only. '
    'Do not convert from the user timezone, listing timezone, check-in time, or check-out time.';

const String _amountValueDescription =
    'Payment amount as a decimal string to avoid precision loss. If unit is sats, this value is a satoshi count, where 1 sat = 1/100,000,000 BTC.';
const String _amountCurrencyDescription =
    'Currency or denomination, such as USD or BTC. For bitcoin amounts expressed in sats, use currency BTC with unit sats.';
const String _amountUnitDescription =
    'Optional display/base unit. When unit is sats, sats means satoshis: 1 sat = 1/100,000,000 BTC. Do not interpret sats as whole BTC, cents, dollars, or any fiat subunit.';
const String _amountDecimalsDescription =
    'Optional decimal precision for raw-denomination amounts. For unit sats, use decimals 0 because satoshis are already the smallest bitcoin unit.';

const Map<String, Object?> _tradeInputSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['tradeId'],
  'properties': {
    'tradeId': {'type': 'string'},
    'amount': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['value', 'currency'],
      'properties': {
        'value': {'type': 'string', 'description': _amountValueDescription},
        'currency': {
          'type': 'string',
          'description': _amountCurrencyDescription,
        },
        'unit': {'type': 'string', 'description': _amountUnitDescription},
        'decimals': {
          'type': 'integer',
          'minimum': 0,
          'description': _amountDecimalsDescription,
        },
      },
    },
    'reason': {'type': 'string'},
    'dryRun': {'type': 'boolean', 'default': true},
    'timeoutSeconds': {
      'type': 'integer',
      'minimum': 1,
      'maximum': 60,
      'default': 12,
    },
  },
};

const String _tradeTypescriptInput = '''
export interface HostrReservationTradeInput {
  tradeId: string;
  amount?: HostrAmountInput;
  reason?: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''';

class HostrActionCatalog {
  static const sessionStatus = HostrActionSpec(
    id: 'hostr.session.status',
    title: 'Hostr Session Status',
    description:
        'Inspect the authenticated Hostr session selected by the MCP access token pubkey.',
    inputTypeName: 'HostrSessionStatusInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'includeStorageDetails': {
          'type': 'boolean',
          'description':
              'Include non-secret storage/session diagnostics useful for debugging.',
          'default': false,
        },
      },
    },
    typescriptInput: '''
export interface HostrSessionStatusInput {
  /** Include non-secret storage/session diagnostics useful for debugging. */
  includeStorageDetails?: boolean;
}
''',
  );

  static const sessionConnect = HostrActionSpec(
    id: 'hostr.session.connect',
    title: 'Start Hostr Session',
    description:
        'Create or complete an active Nostr Connect request for the MCP access token pubkey. When wait is false, show the returned QR/URI with the text "Scan this with your Nostr app to log in to your Hostr account", then immediately call this tool again with wait true to listen for the session connection and continue the intended Hostr action.',
    inputTypeName: 'HostrSessionConnectInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'wait': {
          'type': 'boolean',
          'default': false,
          'description':
              'False returns an active nostrconnect URI/QR for display. True waits for the already-shown request to connect; call it immediately after displaying the QR so the original Hostr action can continue.',
        },
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 600,
          'default': 180,
          'description': 'How long to wait for approval when wait is true.',
        },
        'regenerate': {
          'type': 'boolean',
          'default': false,
          'description':
              'Force a fresh nostrconnect request instead of reusing the pending one.',
        },
      },
    },
    typescriptInput: '''
export interface HostrSessionConnectInput {
  /** False returns an active nostrconnect URI/QR for display. True waits for the shown request to connect; call it immediately after displaying the QR so the original Hostr action can continue. */
  wait?: boolean;
  /** How long to wait for approval when wait is true. Defaults to 180, capped at 600. */
  timeoutSeconds?: number;
  /** Force a fresh nostrconnect request instead of reusing the pending one. */
  regenerate?: boolean;
}
''',
  );

  static const listingsSearch = HostrActionSpec(
    id: 'hostr.listings.search',
    title: 'Search Hostr Listings',
    description:
        'Search Hostr lodging and accommodation marketplace listings. Prefer this Hostr tool for natural travel/lodging requests such as "find a place to stay", "find somewhere to stay in San Salvador", "look for lodging", "show me accommodations", "find a room/apartment/hotel/villa", "where can I stay", "book a stay", or "find rentals". Use the location field for city/country/place names instead of doing a general web search.',
    inputTypeName: 'HostrListingsSearchInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'location': {
          'type': 'string',
          'description':
              'Human-readable destination/place to search for Hostr stays, lodging, accommodation, rentals, rooms, apartments, hotels, villas, resorts, or places to stay, such as "San Salvador", "El Salvador", or "Lisbon".',
        },
        'query': {
          'type': 'string',
          'description':
              'Client-side text filter over listing title and description.',
        },
        'type': {
          'type': 'string',
          'description':
              'Hostr listing type, for example room, house, apartment, cabin, or villa.',
        },
        'guests': {
          'type': 'integer',
          'minimum': 1,
          'description': 'Minimum guest capacity.',
        },
        'features': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Required listing specifications/features, such as wifi or kitchen.',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 50,
          'default': 10,
          'description': 'Maximum number of listings to return.',
        },
      },
    },
    typescriptInput: '''
export interface HostrListingsSearchInput {
  /** Human-readable destination/place to search for Hostr stays, lodging, accommodation, rentals, rooms, apartments, hotels, villas, resorts, or places to stay, such as "San Salvador", "El Salvador", or "Lisbon". */
  location?: string;
  /** Client-side text filter over listing title and description. */
  query?: string;
  /** Hostr listing type, for example room, house, apartment, cabin, or villa. */
  type?: string;
  /** Minimum guest capacity. */
  guests?: number;
  /** Required listing specifications/features, such as wifi or kitchen. */
  features?: string[];
  /** Maximum number of listings to return. Defaults to 10, capped at 50. */
  limit?: number;
}
''',
  );

  static const listingsList = HostrActionSpec(
    id: 'hostr.listings.list',
    title: 'List Hostr Listings',
    description:
        'List Hostr listings, optionally restricted to the authenticated user or a supplied author pubkey.',
    inputTypeName: 'HostrListingsListInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'mine': {
          'type': 'boolean',
          'default': false,
          'description':
              'Only list listings authored by the authenticated user.',
        },
        'author': {
          'type': 'string',
          'description': 'Only list listings authored by this pubkey.',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 50,
        },
      },
    },
    typescriptInput: '''
export interface HostrListingsListInput {
  mine?: boolean;
  author?: string;
  limit?: number;
}
''',
  );

  static const listingsCreate = HostrActionSpec(
    id: 'hostr.listings.create',
    title: 'Create Hostr Listing',
    description:
        'Create a Hostr listing for the authenticated token pubkey session. Listing images must be passed as images[].url. For user-uploaded files, first call hostr_images_upload with the original image sent as the MCP file-typed argument named file so the client bridge can rewrite or stream the bytes, then pass structuredContent.usage.image.url as images[].url. If the client cannot call hostr_images_upload but can make raw HTTP requests, POST the original image bytes to /mcp/uploads/images on the same Hostr MCP origin using multipart/form-data field name file, then pass the returned upload.url as images[].url. The upload tool and endpoint do not require authorization, but when a valid MCP bearer token is present Hostr first tries the logged-in session Blossom upload path before falling back to direct upload. Do not base64-encode user-uploaded images into this MCP tool call, do not serve temporary localhost URLs, and do not pass /mnt/data or file:// paths to images[].url. Set dryRun false only after explicit user approval to publish the listing event, and reuse the dryRun preview dTag so retries update the same replaceable listing.',
    inputTypeName: 'HostrListingsCreateInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['title', 'description', 'address', 'images', 'prices'],
      'properties': {
        'title': {'type': 'string', 'description': 'Public listing title.'},
        'description': {
          'type': 'string',
          'description': 'Public listing description.',
        },
        'address': {
          'type': 'string',
          'description':
              'Private-ish precise address used by Hostr to generate H3 tags.',
        },
        'type': {
          'type': 'string',
          'description':
              'Listing type, such as room, apartment, house, or villa.',
        },
        'images': {
          'type': 'array',
          'minItems': 1,
          'description':
              'Listing images. This MCP tool accepts image URLs only. Mandatory flow for user-uploaded files: first call hostr_images_upload with the original image sent as the MCP file-typed argument named file so the client bridge can rewrite or stream the bytes, then pass structuredContent.usage.image.url here as images[].url. If the client cannot call hostr_images_upload but can make raw HTTP requests, POST each original file bytes payload to /mcp/uploads/images on this same MCP server origin using multipart/form-data field name file, then pass the returned upload.url here as images[].url. The upload tool and endpoint do not require authorization, but when a valid MCP bearer token is present Hostr first tries the logged-in session Blossom upload path before falling back to direct upload. Do not base64-encode uploaded images into this tool call. Do not start or serve a temporary localhost URL for the MCP server to fetch; localhost refers to the wrong machine/container. Do not resize, downscale, crop, recompress, transcode, or make thumbnails unless the user explicitly requests it. If neither upload route can be used, stop and ask for a public image URL or for the client to expose an upload capability. Never pass client-local or mounted file paths like /mnt/data, /mnt/shared, file://, or ChatGPT file mounts to images[].url.',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['url'],
            'properties': {
              'url': {
                'type': 'string',
                'description':
                    'Required image URL. For user-uploaded files, this must be structuredContent.usage.image.url returned by hostr_images_upload, or upload.url returned by POST /mcp/uploads/images on the same Hostr MCP origin. Public HTTP(S) source URLs are also accepted; Hostr downloads non-Blossom URLs and uploads them to Blossom before publishing.',
              },
              'filename': {
                'type': 'string',
                'description':
                    'Optional original filename used for MIME detection and upload diagnostics.',
              },
              'alt': {'type': 'string', 'description': 'Image alt text.'},
              'mime': {
                'type': 'string',
                'description':
                    'Optional MIME type, for example image/jpeg or image/png.',
              },
            },
          },
        },
        'prices': {
          'type': 'array',
          'minItems': 1,
          'description':
              'Listing prices. All monetary fields must use the same currency. If a user mentions sats, they mean satoshis: 1 sat = 1/100,000,000 BTC. Represent bitcoin satoshi prices as amount.value equal to the satoshi count, amount.currency BTC, amount.unit sats, and amount.decimals 0.',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['amount'],
            'properties': {
              'amount': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['value', 'currency'],
                'properties': {
                  'value': {
                    'type': 'string',
                    'description': _amountValueDescription,
                  },
                  'currency': {
                    'type': 'string',
                    'description': _amountCurrencyDescription,
                  },
                  'unit': {
                    'type': 'string',
                    'description': _amountUnitDescription,
                  },
                  'decimals': {
                    'type': 'integer',
                    'minimum': 0,
                    'description': _amountDecimalsDescription,
                  },
                },
              },
              'frequency': {
                'type': 'string',
                'description': 'daily, weekly, monthly, yearly, or fixed.',
              },
            },
          },
        },
        'specifications': {
          'type': 'object',
          'description':
              'Additional listing specifications, for example wifi, kitchen, or workspace.',
        },
        'guests': {'type': 'integer', 'minimum': 1},
        'beds': {'type': 'integer', 'minimum': 0},
        'bedrooms': {'type': 'integer', 'minimum': 0},
        'bathrooms': {'type': 'integer', 'minimum': 0},
        'active': {'type': 'boolean'},
        'negotiable': {'type': 'boolean'},
        'instantBook': {'type': 'boolean'},
        'minStay': {'type': 'integer', 'minimum': 1},
        'checkIn': {'type': 'string'},
        'checkOut': {'type': 'string'},
        'quantity': {'type': 'integer', 'minimum': 1},
        'securityDeposit': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['value', 'currency'],
          'properties': {
            'value': {'type': 'string', 'description': _amountValueDescription},
            'currency': {
              'type': 'string',
              'description': _amountCurrencyDescription,
            },
            'unit': {'type': 'string', 'description': _amountUnitDescription},
            'decimals': {
              'type': 'integer',
              'minimum': 0,
              'description': _amountDecimalsDescription,
            },
          },
        },
        'minPaymentAmount': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['value', 'currency'],
          'properties': {
            'value': {'type': 'string', 'description': _amountValueDescription},
            'currency': {
              'type': 'string',
              'description': _amountCurrencyDescription,
            },
            'unit': {'type': 'string', 'description': _amountUnitDescription},
            'decimals': {
              'type': 'integer',
              'minimum': 0,
              'description': _amountDecimalsDescription,
            },
          },
        },
        'h3Tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Optional precomputed H3 tags. If omitted, address is geocoded.',
        },
        'h3FinestResolution': {'type': 'integer', 'minimum': 0},
        'h3MaxTags': {'type': 'integer', 'minimum': 1},
        'dTag': {
          'type': 'string',
          'description':
              'Stable Nostr d tag for this listing draft. When publishing an approved dryRun preview, reuse the dTag returned in structuredContent.nextInput.dTag or structuredContent.dTag so retries update the same replaceable listing instead of creating duplicates.',
        },
        'dryRun': {
          'type': 'boolean',
          'default': true,
          'description':
              'True uploads local images to Blossom and previews the listing card only. Set false to publish after explicit approval, reusing the preview dTag.',
        },
      },
    },
    typescriptInput: '''
export interface HostrAmountInput {
  /** Payment amount as a decimal string. If unit is sats, this is a satoshi count: 1 sat = 1/100,000,000 BTC. */
  value: string;
  /** Currency or denomination, such as USD or BTC. For sats, use BTC. */
  currency: string;
  /** Optional display/base unit. sats means satoshis: 1 sat = 1/100,000,000 BTC. */
  unit?: string;
  /** Optional decimal precision. For sats, use 0. */
  decimals?: number;
}

export interface HostrListingImageInput {
  /** Required image URL. For user-uploaded files, use the upload.url returned by POST /mcp/uploads/images on the same Hostr MCP origin. */
  url: string;
  /** Optional original filename used for MIME detection and upload diagnostics. */
  filename?: string;
  /** Alt text for the image. */
  alt?: string;
  /** Optional MIME type override. */
  mime?: string;
}

export interface HostrListingPriceInput {
  amount: HostrAmountInput;
  /** daily, weekly, monthly, yearly, or fixed. Defaults to daily. */
  frequency?: string;
}

export interface HostrListingsCreateInput {
  title: string;
  description: string;
  /** Precise address used for H3 tag generation. */
  address: string;
  images: HostrListingImageInput[];
  prices: HostrListingPriceInput[];
  type?: string;
  specifications?: Record<string, unknown>;
  guests?: number;
  beds?: number;
  bedrooms?: number;
  bathrooms?: number;
  active?: boolean;
  negotiable?: boolean;
  instantBook?: boolean;
  minStay?: number;
  checkIn?: string;
  checkOut?: string;
  quantity?: number;
  securityDeposit?: HostrAmountInput;
  minPaymentAmount?: HostrAmountInput;
  h3Tags?: string[];
  h3FinestResolution?: number;
  h3MaxTags?: number;
  /** Stable Nostr d tag for this listing draft. Reuse the dryRun preview dTag when publishing so retries update the same replaceable listing. */
  dTag?: string;
  /** True uploads local images to Blossom and previews only. Set false to publish after explicit user approval, reusing the preview dTag. */
  dryRun?: boolean;
}
''',
  );

  static const listingsEdit = HostrActionSpec(
    id: 'hostr.listings.edit',
    title: 'Edit Hostr Listing',
    description:
        'Preview or publish a patch to an existing listing authored by the authenticated user. The live path also ensures seller configuration is published before signing the listing.',
    inputTypeName: 'HostrListingsEditInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['anchor'],
      'properties': {
        'anchor': {
          'type': 'string',
          'description': 'Listing naddr/a-tag anchor.',
        },
        'patch': {
          'type': 'object',
          'description':
              'Listing fields to change. Supports title, description, address, type, images, prices, specifications, guests, beds, bedrooms, bathrooms, active, negotiable, instantBook, quantity, securityDeposit, and minPaymentAmount.',
        },
        'dryRun': {
          'type': 'boolean',
          'default': true,
          'description':
              'True previews only. Set false to publish after explicit approval.',
        },
      },
    },
    typescriptInput: '''
export interface HostrListingsEditInput {
  /** Listing naddr/a-tag anchor. */
  anchor: string;
  /** Listing fields to change. */
  patch?: Partial<HostrListingsCreateInput>;
  /** True previews only. Set false to publish after explicit approval. */
  dryRun?: boolean;
}
''',
  );

  static const listingsAvailability = HostrActionSpec(
    id: 'hostr.listings.availability',
    title: 'Check Listing Availability',
    description:
        'Check whether one or more listings are available for a requested reservation date range. $_reservationDateOnlyRule',
    inputTypeName: 'HostrListingsAvailabilityInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['start', 'end'],
      'properties': {
        'anchors': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Listing anchors to check.',
        },
        'anchor': {
          'type': 'string',
          'description': 'Single listing anchor alternative to anchors.',
        },
        'start': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Requested start calendar date encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Requested end calendar date encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
      },
    },
    typescriptInput: '''
export interface HostrListingsAvailabilityInput {
  /** Listing anchors to check. */
  anchors?: string[];
  /** Single listing anchor alternative. */
  anchor?: string;
  /** Requested start calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  start: string;
  /** Requested end calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  end: string;
}
''',
  );

  static const listingsReviews = HostrActionSpec(
    id: 'hostr.listings.reviews',
    title: 'Fetch Listing Reviews',
    description: 'Fetch review events attached to one or more listings.',
    inputTypeName: 'HostrListingsAnchorsInput',
    readOnly: true,
    inputSchema: _anchorsInputSchema,
    typescriptInput: _anchorsTypescriptInput,
  );

  static const listingsReservationGroups = HostrActionSpec(
    id: 'hostr.listings.reservationGroups',
    title: 'Fetch Listing Reservation Groups',
    description:
        'Fetch public reservation groups for one or more listings. Use this before availability-sensitive reservation workflows when the agent needs to explain conflicts.',
    inputTypeName: 'HostrListingsAnchorsInput',
    readOnly: true,
    inputSchema: _anchorsInputSchema,
    typescriptInput: _anchorsTypescriptInput,
  );

  static const reservationsOffer = HostrActionSpec(
    id: 'hostr.reservations.negotiateOffer',
    title: 'Create Reservation Negotiation Offer',
    description:
        'Create only a private negotiate-stage reservation offer. Use this for explicit negotiation/counteroffer requests, not for user intents like "book", "reserve", "make a reservation", or instant-book at the listed price; those must use hostr_reservations_bookAndPay instead.',
    inputTypeName: 'HostrReservationsOfferInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'listingAnchor': {
          'type': 'string',
          'description': 'Listing naddr/a-tag anchor for a first offer.',
        },
        'anchor': {
          'type': 'string',
          'description': 'Single listing anchor alternative to listingAnchor.',
        },
        'tradeId': {
          'type': 'string',
          'description': 'Existing reservation trade id for a follow-up offer.',
        },
        'start': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Reservation start calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Reservation end calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
        'amount': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['value', 'currency'],
          'properties': {
            'value': {'type': 'string', 'description': _amountValueDescription},
            'currency': {
              'type': 'string',
              'description': _amountCurrencyDescription,
            },
            'unit': {'type': 'string', 'description': _amountUnitDescription},
            'decimals': {
              'type': 'integer',
              'minimum': 0,
              'description': _amountDecimalsDescription,
            },
          },
          'description':
              'Optional reservation amount override. Omit to use listing price rules.',
        },
        'dryRun': {
          'type': 'boolean',
          'default': true,
          'description':
              'True only builds the offer and returns the event preview. Set false to send the gift-wrapped offer after explicit approval.',
        },
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrAmountInput {
  /** Payment amount as a decimal string. If unit is sats, this is a satoshi count: 1 sat = 1/100,000,000 BTC. */
  value: string;
  /** Currency or denomination, such as USD or BTC. For sats, use BTC. */
  currency: string;
  /** Optional display/base unit. sats means satoshis: 1 sat = 1/100,000,000 BTC. */
  unit?: string;
  /** Optional decimal precision. For sats, use 0. */
  decimals?: number;
}

export interface HostrReservationsOfferInput {
  /** Listing naddr/a-tag anchor for a first offer. */
  listingAnchor?: string;
  /** Single listing anchor alternative to listingAnchor. */
  anchor?: string;
  /** Existing reservation trade id for a follow-up offer. */
  tradeId?: string;
  /** Reservation start calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  start?: string;
  /** Reservation end calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  end?: string;
  /** Optional reservation amount override. Omit to use listing price rules. */
  amount?: HostrAmountInput;
  /** True previews only. Set false to send the gift-wrapped offer after user approval. */
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const reservationsBookAndPay = HostrActionSpec(
    id: 'hostr.reservations.bookAndPay',
    title: 'Book And Pay Reservation',
    description:
        'Use this foreground handoff tool whenever the user says to book, reserve, make, or create a reservation for an instant-book listing at or above the listed price. It creates the private reservation offer and escrow funding swap. $_reservationDateOnlyRule If external Lightning payment is required, it returns the invoice string, QR image, internal trade id, internal swap id, and continuesInBackground=true while the daemon keeps the book-and-pay operation alive. CRITICAL UI REQUIREMENT: leave only the QR image and invoice text visibly in the answer to the user; do not show internal trade id or swap id in the payment prompt, and do not replace the payment prompt with a summary. Only after that visible payment prompt is in the output, immediately call the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `reservationWaitSeconds` to monitor payment/proof/reservation completion. When watch completes or cannot find the swap, query `hostr_trips_list` with `tradeId` until the committed reservation appears, then show a reservation card. Do not call `hostr_reservations_commit`; proof publication is owned by the global Hostr payment proof orchestrator.',
    inputTypeName: 'HostrReservationBookAndPayInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['listingAnchor', 'start', 'end'],
      'properties': {
        'listingAnchor': {
          'type': 'string',
          'description': 'Listing naddr/a-tag anchor to instant-book.',
        },
        'start': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Reservation start calendar date encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Reservation end calendar date encoded as YYYY-MM-DDT00:00:00Z. $_reservationDateOnlyRule',
        },
        'amount': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['value', 'currency'],
          'properties': {
            'value': {'type': 'string', 'description': _amountValueDescription},
            'currency': {
              'type': 'string',
              'description': _amountCurrencyDescription,
            },
            'unit': {'type': 'string', 'description': _amountUnitDescription},
            'decimals': {
              'type': 'integer',
              'minimum': 0,
              'description': _amountDecimalsDescription,
            },
          },
          'description':
              'Optional reservation amount override. Must be at or above the listing price.',
        },
        'escrowServiceId': {
          'type': 'string',
          'description':
              'Optional escrow service id/pubkey/contract address. Omit to use the first compatible mutual escrow.',
        },
        'proofTimeoutSeconds': {
          'type': 'integer',
          'minimum': 30,
          'maximum': 3600,
          'default': 300,
          'description':
              'Seconds to wait for the global reservation stream to emit the committed reservation after swap completion.',
        },
      },
    },
    typescriptInput: '''
export interface HostrReservationBookAndPayInput {
  /** Listing naddr/a-tag anchor to instant-book. */
  listingAnchor: string;
  /** Reservation start calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  start: string;
  /** Reservation end calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only reservation inputs. */
  end: string;
  /** Optional reservation amount override. Must be at or above the listing price. */
  amount?: HostrAmountInput;
  /** Optional escrow service id/pubkey/contract address. */
  escrowServiceId?: string;
  /** Seconds to wait for the global reservation stream to emit the committed reservation. */
  proofTimeoutSeconds?: number;
}
''',
  );

  static const reservationsNegotiateAccept = HostrActionSpec(
    id: 'hostr.reservations.negotiateAccept',
    title: 'Accept Reservation Negotiation',
    description:
        'Accept the latest private negotiate-stage reservation offer in a trade thread by replying with a matching negotiate-stage event.',
    inputTypeName: 'HostrReservationTradeInput',
    readOnly: false,
    inputSchema: _tradeInputSchema,
    typescriptInput: _tradeTypescriptInput,
  );

  static const reservationsPay = HostrActionSpec(
    id: 'hostr.reservations.pay',
    title: 'Pay Reservation Offer',
    description:
        'Preview or create the escrow funding swap for a payable reservation trade. The live action sends the escrow selection into the private thread as an unsigned child event, prepares the escrow fund calls, creates the Boltz swap invoice, and persists the payment context for commit.',
    inputTypeName: 'HostrReservationPayInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Reservation trade id from negotiation updates.',
        },
        'escrowServiceId': {
          'type': 'string',
          'description':
              'Optional escrow service id/pubkey/contract address. Omit to use the first compatible mutual escrow.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrReservationPayInput {
  /** Reservation trade id from negotiation updates. */
  tradeId: string;
  /** Optional escrow service id/pubkey/contract address. */
  escrowServiceId?: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const reservationsCommit = HostrActionSpec(
    id: 'hostr.reservations.commit',
    title: 'Commit Paid Reservation',
    description:
        'Preview or publish the public commit-stage reservation after the escrow funding swap has completed and produced a claim transaction proof.',
    inputTypeName: 'HostrReservationCommitInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['swapId'],
      'properties': {
        'swapId': {
          'type': 'string',
          'description': 'Boltz swap id returned by hostr_reservations_pay.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrReservationCommitInput {
  /** Boltz swap id returned by hostr_reservations_pay. */
  swapId: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const reservationsCancel = HostrActionSpec(
    id: 'hostr.reservations.cancel',
    title: 'Cancel Reservation',
    description:
        'Cancel either the private negotiate-stage reservation for a trade, or the committed public reservation if one exists.',
    inputTypeName: 'HostrReservationTradeInput',
    readOnly: false,
    inputSchema: _tradeInputSchema,
    typescriptInput: _tradeTypescriptInput,
  );

  static const updates = HostrActionSpec(
    id: 'hostr.updates',
    title: 'Fetch Hostr Updates',
    description:
        'Fetch the authenticated inbox, process gift-wrapped thread events, and summarize new offers and messages for the agent.',
    inputTypeName: 'HostrUpdatesInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 50,
          'default': 10,
        },
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrUpdatesInput {
  /** Maximum inbox events to fetch. */
  limit?: number;
  /** Seconds to wait for relay history before returning partial results. */
  timeoutSeconds?: number;
}
''',
  );

  static const reply = HostrActionSpec(
    id: 'hostr.reply',
    title: 'Reply To Hostr Thread',
    description:
        'Preview or send a gift-wrapped text reply. Include conversation/tradeId to keep replies threaded.',
    inputTypeName: 'HostrReplyInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['content'],
      'properties': {
        'content': {'type': 'string'},
        'recipientPubkeys': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'recipientPubkey': {'type': 'string'},
        'conversation': {'type': 'string'},
        'tradeId': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrReplyInput {
  content: string;
  recipientPubkeys?: string[];
  recipientPubkey?: string;
  conversation?: string;
  tradeId?: string;
  dryRun?: boolean;
}
''',
  );

  static const threadView = HostrActionSpec(
    id: 'hostr.thread.view',
    title: 'View Hostr Thread',
    description:
        'Load a Hostr conversation and return a fixed thread-view contract with message history. Use this when the user asks whether a host or escrow has messaged them, asks to see a conversation, or references a trip/booking thread.',
    inputTypeName: 'HostrThreadViewInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'threadAnchor': {'type': 'string'},
        'anchor': {'type': 'string'},
        'conversation': {'type': 'string'},
        'tradeId': {'type': 'string'},
        'recipientPubkeys': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'recipientPubkey': {'type': 'string'},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200},
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrThreadViewInput {
  threadAnchor?: string;
  anchor?: string;
  conversation?: string;
  tradeId?: string;
  recipientPubkeys?: string[];
  recipientPubkey?: string;
  limit?: number;
  timeoutSeconds?: number;
}
''',
  );

  static const threadMessage = HostrActionSpec(
    id: 'hostr.thread.message',
    title: 'Message Hostr Thread',
    description:
        'Preview or send a text message in a Hostr conversation, then return the fixed thread-view contract. Use this when the user asks to message a host, guest, buyer, seller, or an existing thread. If the user references a trade/trip, pass tradeId; use recipientRole when they say host, guest, buyer, seller, or escrow. Escrow messaging always requires a concrete tradeId and must include the trade buyer, seller, and escrow participants in one thread.',
    inputTypeName: 'HostrThreadMessageInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['content'],
      'properties': {
        'content': {'type': 'string'},
        'threadAnchor': {'type': 'string'},
        'anchor': {'type': 'string'},
        'conversation': {'type': 'string'},
        'tradeId': {'type': 'string'},
        'recipientRole': {
          'type': 'string',
          'enum': ['host', 'seller', 'guest', 'buyer', 'escrow'],
        },
        'role': {'type': 'string'},
        'recipientPubkeys': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'recipientPubkey': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrThreadMessageInput {
  content: string;
  threadAnchor?: string;
  anchor?: string;
  conversation?: string;
  tradeId?: string;
  recipientRole?: "host" | "seller" | "guest" | "buyer" | "escrow";
  role?: string;
  recipientPubkeys?: string[];
  recipientPubkey?: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const escrowInvolve = HostrActionSpec(
    id: 'hostr.escrow.involve',
    title: 'Involve Hostr Escrow',
    description:
        'Open or message the escrow conversation for a specific reservation trade, then return the fixed thread-view contract. This action always requires tradeId and always resolves the trade buyer, seller, and escrow participants into one shared trade thread; it must not create an escrow-only side conversation. If content is omitted, show the escrow trade thread and ask the user what to message the escrow. If content is provided, preview by default and send only with dryRun false.',
    inputTypeName: 'HostrEscrowInvolveInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description':
              'Required reservation trade id. Escrow messages cannot be sent without a trade id because the thread must include buyer, seller, and escrow.',
        },
        'content': {'type': 'string'},
        'message': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 12,
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowInvolveInput {
  tradeId: string;
  content?: string;
  message?: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const profileShow = HostrActionSpec(
    id: 'hostr.profile.show',
    title: 'Show Hostr Profile',
    description:
        'Show profile metadata for the authenticated MCP token pubkey session.',
    inputTypeName: 'HostrEmptyInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': <String, Object?>{},
    },
    typescriptInput: '''
export interface HostrEmptyInput {}
''',
  );

  static const profileLookup = HostrActionSpec(
    id: 'hostr.profile.lookup',
    title: 'Show Hostr Profile By Npub',
    description:
        'Public read-only lookup for any Hostr/Nostr profile metadata by npub. Use this when the user asks to view a specific user, host, guest, seller, buyer, or arbitrary Nostr profile that is not necessarily their authenticated profile.',
    inputTypeName: 'HostrProfileLookupInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['npub'],
      'properties': {
        'npub': {
          'type': 'string',
          'description': 'NIP-19 npub for the profile to display.',
        },
      },
    },
    typescriptInput: '''
export interface HostrProfileLookupInput {
  npub: string;
}
''',
  );

  static const profileEdit = HostrActionSpec(
    id: 'hostr.profile.edit',
    title: 'Edit Hostr Profile',
    description:
        'Preview or publish the authenticated user profile metadata. Profile image and picture accept durable HTTP(S) image URLs only. For user-uploaded profile photos, first call hostr_images_upload with the original image sent as the MCP file-typed argument named file, then pass structuredContent.usage.image.url as image or picture. Publishing also refreshes Hostr seller configuration.',
    inputTypeName: 'HostrProfileEditInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'name': {'type': 'string'},
        'about': {'type': 'string'},
        'image': {
          'type': 'string',
          'description':
              'Profile image URL. For user-uploaded files, first call hostr_images_upload and pass structuredContent.usage.image.url here. Do not pass local paths, file:// URLs, ChatGPT upload refs, or base64 data directly.',
        },
        'picture': {
          'type': 'string',
          'description':
              'Alias for image. For user-uploaded files, first call hostr_images_upload and pass structuredContent.usage.image.url here. Do not pass local paths, file:// URLs, ChatGPT upload refs, or base64 data directly.',
        },
        'lud16': {'type': 'string'},
        'nip05': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrProfileEditInput {
  name?: string;
  about?: string;
  /** Profile image URL. For user-uploaded files, first call hostr_images_upload and pass structuredContent.usage.image.url here. */
  image?: string;
  /** Alias for image. For user-uploaded files, first call hostr_images_upload and pass structuredContent.usage.image.url here. */
  picture?: string;
  lud16?: string;
  nip05?: string;
  dryRun?: boolean;
}
''',
  );

  static const tripsList = HostrActionSpec(
    id: 'hostr.trips.list',
    title: 'List Hostr Trips',
    description:
        'List reservation groups involving the authenticated user as guest from the live userSubscriptions.myResolvedTripsList replay. Do not perform fresh Nostr reservation-by-author queries for this view. Return the fixed trip-card display contract with resolved participant profile names. Cancelled trip cards must preserve a bold Cancelled marker. Pass `tradeId` after a book-and-pay swap watch completes or cannot find the swap to wait briefly for the committed public reservation and return it for display.',
    inputTypeName: 'HostrReservationCollectionInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 50,
        },
        'tradeId': {
          'type': 'string',
          'description':
              'Optional reservation trade id to look up directly after payment/proof completion.',
        },
        'waitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 300,
          'default': 15,
          'description':
              'How long to poll for a committed public reservation when tradeId is provided.',
        },
      },
    },
    typescriptInput: '''
export interface HostrReservationCollectionInput {
  limit?: number;
  tradeId?: string;
  waitSeconds?: number;
}
''',
  );

  static const bookingsList = HostrActionSpec(
    id: 'hostr.bookings.list',
    title: 'List Hostr Bookings',
    description:
        'List reservation groups where the authenticated user is the host from the live userSubscriptions.myResolvedHostingsList replay. Do not perform fresh Nostr listing/reservation-by-author queries for this view. Return the fixed hosting-card display contract with resolved participant profile names, including "Hosting {guest} at: {stay}" text.',
    inputTypeName: 'HostrReservationCollectionInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 50,
        },
        'tradeId': {
          'type': 'string',
          'description':
              'Optional reservation trade id to look up directly after payment/proof completion.',
        },
        'waitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 300,
          'default': 15,
          'description':
              'How long to poll for a committed public reservation when tradeId is provided.',
        },
      },
    },
    typescriptInput: '''
export interface HostrReservationCollectionInput {
  limit?: number;
  tradeId?: string;
  waitSeconds?: number;
}
''',
  );

  static const escrowMethods = HostrActionSpec(
    id: 'hostr.escrow.methods',
    title: 'Show Hostr Escrow Methods',
    description:
        'Show mutual escrow methods and compatible services for a seller. If buyer is omitted, the authenticated token pubkey is used.',
    inputTypeName: 'HostrEscrowMethodsInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['user'],
      'properties': {
        'user': {
          'type': 'string',
          'description':
              'Seller/host pubkey to inspect escrow compatibility for.',
        },
        'buyer': {
          'type': 'string',
          'description':
              'Buyer pubkey. Defaults to the authenticated token pubkey.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowMethodsInput {
  /** Seller/host pubkey to inspect escrow compatibility for. */
  user: string;
  /** Buyer pubkey. Defaults to the authenticated token pubkey. */
  buyer?: string;
}
''',
  );

  static const escrowTradesList = HostrActionSpec(
    id: 'hostr.escrow.trades.list',
    title: 'List Escrow Trades',
    description:
        'Escrow-only tool. List on-chain Hostr trades where the authenticated pubkey is a configured escrow. Hidden unless the MCP token pubkey is in the daemon escrow pubkey allowlist.',
    inputTypeName: 'HostrEscrowTradesListInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 100,
          'default': 25,
          'description': 'Maximum number of escrow trades to return.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowTradesListInput {
  /** Maximum number of escrow trades to return. Defaults to 25, capped at 100. */
  limit?: number;
}
''',
  );

  static const escrowTradeAudit = HostrActionSpec(
    id: 'hostr.escrow.trades.audit',
    title: 'Audit Escrow Trade',
    description:
        'Escrow-only tool. Run a structured reservation and transition audit for a Hostr trade assigned to the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowTradeAuditInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Hostr reservation trade id to audit.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowTradeAuditInput {
  /** Hostr reservation trade id to audit. */
  tradeId: string;
}
''',
  );

  static const escrowServiceList = HostrActionSpec(
    id: 'hostr.escrow.service.list',
    title: 'List Escrow Services',
    description:
        'Escrow-only tool. List public escrow service events published by the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowServiceListInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 100,
          'default': 25,
          'description': 'Maximum number of escrow services to return.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowServiceListInput {
  /** Maximum number of escrow service events to return. Defaults to 25, capped at 100. */
  limit?: number;
}
''',
  );

  static const escrowServiceGet = HostrActionSpec(
    id: 'hostr.escrow.service.get',
    title: 'Get Escrow Service',
    description:
        'Escrow-only tool. Show one public escrow service event owned by the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowServiceGetInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['serviceId'],
      'properties': {
        'serviceId': {
          'type': 'string',
          'description': 'Escrow service event id to inspect.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowServiceGetInput {
  /** Escrow service event id to inspect. */
  serviceId: string;
}
''',
  );

  static const escrowServiceUpdate = HostrActionSpec(
    id: 'hostr.escrow.service.update',
    title: 'Update Escrow Service Settings',
    description:
        'Escrow-only tool. Preview or publish the authenticated escrow service parameters: fee percent, maximum trade duration, and per-token fee hints. Hidden unless the MCP token pubkey is in the daemon escrow pubkey allowlist. Use hostr.profile.edit for the escrow user profile; this tool only changes the public escrow service event.',
    inputTypeName: 'HostrEscrowServiceUpdateInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'serviceId': {
          'type': 'string',
          'description':
              'Optional escrow service event id to edit. Omit to edit the daemon bootstrap service.',
        },
        'feePercent': {
          'type': 'number',
          'minimum': 0,
          'maximum': 100,
          'description':
              'Proportional escrow fee as a percent, e.g. 1.5 for 1.5%.',
        },
        'maxDurationSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 315360000,
          'description':
              'Maximum supported escrow duration in seconds. Omit to preserve the current value.',
        },
        'tokenFeeHints': {
          'type': 'object',
          'description':
              'Optional full replacement map keyed by token address, or "native". Values are smallest-unit fee hints.',
          'additionalProperties': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'baseFee': {'type': 'integer', 'minimum': 0},
              'maxFee': {'type': 'integer', 'minimum': 0},
              'minFee': {'type': 'integer', 'minimum': 0},
            },
          },
        },
        'clearTokenFeeHints': {
          'type': 'boolean',
          'default': false,
          'description':
              'Clear all per-token fee hints. Ignored if tokenFeeHints is provided.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrTokenFeeHintsInput {
  /** Flat base fee in token smallest units. */
  baseFee?: number;
  /** Maximum fee cap in token smallest units. Zero means no cap. */
  maxFee?: number;
  /** Minimum fee floor in token smallest units. Zero means no floor. */
  minFee?: number;
}

export interface HostrEscrowServiceUpdateInput {
  /** Optional escrow service event id to edit. Omit to edit the daemon bootstrap service. */
  serviceId?: string;
  /** Proportional escrow fee as a percent, e.g. 1.5 for 1.5%. */
  feePercent?: number;
  /** Maximum supported escrow duration in seconds. */
  maxDurationSeconds?: number;
  /** Full replacement map keyed by token address, or "native". */
  tokenFeeHints?: Record<string, HostrTokenFeeHintsInput>;
  /** Clear all per-token fee hints. Ignored if tokenFeeHints is provided. */
  clearTokenFeeHints?: boolean;
  /** Defaults to true. Set false only after explicit approval. */
  dryRun?: boolean;
}
''',
  );

  static const escrowServiceEdit = HostrActionSpec(
    id: 'hostr.escrow.service.edit',
    title: 'Edit Escrow Service Settings',
    description:
        'Escrow-only tool. Alias of service update using the preferred user-facing wording. Preview or publish the authenticated escrow service parameters. Use hostr.profile.edit for the escrow user profile.',
    inputTypeName: 'HostrEscrowServiceUpdateInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'serviceId': {
          'type': 'string',
          'description':
              'Optional escrow service event id to edit. Omit to edit the daemon bootstrap service.',
        },
        'feePercent': {
          'type': 'number',
          'minimum': 0,
          'maximum': 100,
          'description':
              'Proportional escrow fee as a percent, e.g. 1.5 for 1.5%.',
        },
        'maxDurationSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 315360000,
          'description':
              'Maximum supported escrow duration in seconds. Omit to preserve the current value.',
        },
        'tokenFeeHints': {
          'type': 'object',
          'description':
              'Optional full replacement map keyed by token address, or "native". Values are smallest-unit fee hints.',
          'additionalProperties': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'baseFee': {'type': 'integer', 'minimum': 0},
              'maxFee': {'type': 'integer', 'minimum': 0},
              'minFee': {'type': 'integer', 'minimum': 0},
            },
          },
        },
        'clearTokenFeeHints': {
          'type': 'boolean',
          'default': false,
          'description':
              'Clear all per-token fee hints. Ignored if tokenFeeHints is provided.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrTokenFeeHintsInput {
  /** Flat base fee in token smallest units. */
  baseFee?: number;
  /** Maximum fee cap in token smallest units. Zero means no cap. */
  maxFee?: number;
  /** Minimum fee floor in token smallest units. Zero means no floor. */
  minFee?: number;
}

export interface HostrEscrowServiceUpdateInput {
  /** Optional escrow service event id to edit. Omit to edit the daemon bootstrap service. */
  serviceId?: string;
  /** Proportional escrow fee as a percent, e.g. 1.5 for 1.5%. */
  feePercent?: number;
  /** Maximum supported escrow duration in seconds. */
  maxDurationSeconds?: number;
  /** Full replacement map keyed by token address, or "native". */
  tokenFeeHints?: Record<string, HostrTokenFeeHintsInput>;
  /** Clear all per-token fee hints. Ignored if tokenFeeHints is provided. */
  clearTokenFeeHints?: boolean;
  /** Defaults to true. Set false only after explicit approval. */
  dryRun?: boolean;
}
''',
  );

  static const escrowServiceDelete = HostrActionSpec(
    id: 'hostr.escrow.service.delete',
    title: 'Delete Escrow Service',
    description:
        'Escrow-only destructive tool. Preview or publish a NIP-09 deletion for an escrow service event owned by the authenticated escrow pubkey. Keep dryRun true until the user explicitly approves deletion.',
    inputTypeName: 'HostrEscrowServiceDeleteInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['serviceId'],
      'properties': {
        'serviceId': {
          'type': 'string',
          'description': 'Escrow service event id to delete.',
        },
        'reason': {
          'type': 'string',
          'description': 'Optional deletion reason for the NIP-09 event.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowServiceDeleteInput {
  /** Escrow service event id to delete. */
  serviceId: string;
  /** Optional deletion reason for the NIP-09 event. */
  reason?: string;
  /** Defaults to true. Set false only after explicit approval. */
  dryRun?: boolean;
}
''',
  );

  static const escrowTradeView = HostrActionSpec(
    id: 'hostr.escrow.trades.view',
    title: 'View Escrow Trade',
    description:
        'Escrow-only tool. View the on-chain state, event history, and Hostr reservation context for a trade assigned to the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowTradeViewInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Hostr reservation trade id to inspect.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowTradeViewInput {
  /** Hostr reservation trade id to inspect. */
  tradeId: string;
}
''',
  );

  static const escrowBadgeDefinitionsList = HostrActionSpec(
    id: 'hostr.escrow.badges.definitions.list',
    title: 'List Escrow Badge Definitions',
    description:
        'Escrow-only tool. List NIP-58 badge definitions published by the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowBadgeDefinitionsListInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 50,
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeDefinitionsListInput {
  limit?: number;
}
''',
  );

  static const escrowBadgeDefinitionEdit = HostrActionSpec(
    id: 'hostr.escrow.badges.definitions.edit',
    title: 'Edit Escrow Badge Definition',
    description:
        'Escrow-only tool. Preview or publish a NIP-58 badge definition for the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowBadgeDefinitionEditInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['identifier', 'name'],
      'properties': {
        'identifier': {
          'type': 'string',
          'description': 'Badge definition d-tag identifier.',
        },
        'name': {'type': 'string'},
        'description': {'type': 'string'},
        'image': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeDefinitionEditInput {
  /** Badge definition d-tag identifier. */
  identifier: string;
  name: string;
  description?: string;
  image?: string;
  dryRun?: boolean;
}
''',
  );

  static const escrowBadgeDefinitionDelete = HostrActionSpec(
    id: 'hostr.escrow.badges.definitions.delete',
    title: 'Delete Escrow Badge Definition',
    description:
        'Escrow-only destructive tool. Preview or publish a NIP-09 deletion for a badge definition owned by the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowBadgeDefinitionDeleteInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['anchor'],
      'properties': {
        'anchor': {'type': 'string'},
        'reason': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeDefinitionDeleteInput {
  anchor: string;
  reason?: string;
  dryRun?: boolean;
}
''',
  );

  static const escrowBadgeAwardsList = HostrActionSpec(
    id: 'hostr.escrow.badges.awards.list',
    title: 'List Escrow Badge Awards',
    description:
        'Escrow-only tool. List NIP-58 badge awards issued by the authenticated escrow pubkey, optionally filtered by definition anchor.',
    inputTypeName: 'HostrEscrowBadgeAwardsListInput',
    readOnly: true,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'definitionAnchor': {'type': 'string'},
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 50,
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeAwardsListInput {
  definitionAnchor?: string;
  limit?: number;
}
''',
  );

  static const escrowBadgeAward = HostrActionSpec(
    id: 'hostr.escrow.badges.award',
    title: 'Award Escrow Badge',
    description:
        'Escrow-only tool. Preview or publish a NIP-58 badge award from the authenticated escrow pubkey to a recipient pubkey.',
    inputTypeName: 'HostrEscrowBadgeAwardInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['definitionAnchor', 'recipientPubkey'],
      'properties': {
        'definitionAnchor': {'type': 'string'},
        'recipientPubkey': {'type': 'string'},
        'listingAnchor': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeAwardInput {
  definitionAnchor: string;
  recipientPubkey: string;
  listingAnchor?: string;
  dryRun?: boolean;
}
''',
  );

  static const escrowBadgeRevoke = HostrActionSpec(
    id: 'hostr.escrow.badges.revoke',
    title: 'Revoke Escrow Badge Award',
    description:
        'Escrow-only destructive tool. Preview or publish a NIP-09 deletion for a badge award issued by the authenticated escrow pubkey.',
    inputTypeName: 'HostrEscrowBadgeRevokeInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['awardId'],
      'properties': {
        'awardId': {'type': 'string'},
        'reason': {'type': 'string'},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowBadgeRevokeInput {
  awardId: string;
  reason?: string;
  dryRun?: boolean;
}
''',
  );

  static const escrowArbitrate = HostrActionSpec(
    id: 'hostr.escrow.trades.arbitrate',
    title: 'Arbitrate Escrow Trade',
    description:
        'Escrow-only settlement tool. Preview or execute arbitration for a Hostr escrow trade. paymentForward and bondForward are fractions from 0 to 1. Keep dryRun true until the user explicitly approves the arbitration preview.',
    inputTypeName: 'HostrEscrowArbitrateInput',
    readOnly: false,
    requiredRole: 'escrow',
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId', 'paymentForward', 'bondForward'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Hostr reservation trade id to arbitrate.',
        },
        'paymentForward': {
          'type': 'number',
          'minimum': 0,
          'maximum': 1,
          'description':
              'Fraction of the escrowed payment to forward to the seller, from 0 to 1.',
        },
        'bondForward': {
          'type': 'number',
          'minimum': 0,
          'maximum': 1,
          'description':
              'Fraction of the escrow bond to forward according to the contract settlement rules, from 0 to 1.',
        },
        'reason': {
          'type': 'string',
          'description': 'Optional human-readable arbitration reason.',
        },
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrEscrowArbitrateInput {
  /** Hostr reservation trade id to arbitrate. */
  tradeId: string;
  /** Fraction of the escrowed payment to forward to the seller, from 0 to 1. */
  paymentForward: number;
  /** Fraction of the escrow bond to forward according to contract settlement rules, from 0 to 1. */
  bondForward: number;
  /** Optional human-readable arbitration reason. */
  reason?: string;
  /** Defaults to true. Set false only after explicit approval. */
  dryRun?: boolean;
}
''',
  );

  static const swapsList = HostrActionSpec(
    id: 'hostr.swaps.list',
    title: 'List Hostr Swaps',
    description: 'List persisted swap-in and swap-out operation states.',
    inputTypeName: 'HostrSwapsListInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'namespace': {
          'type': 'string',
          'enum': ['all', 'swap_in', 'swap_out'],
          'default': 'all',
        },
      },
    },
    typescriptInput: '''
export interface HostrSwapsListInput {
  namespace?: "all" | "swap_in" | "swap_out";
}
''',
  );

  static const swapsWatch = HostrActionSpec(
    id: 'hostr.swaps.watch',
    title: 'Watch Hostr Swap',
    description:
        'Read-only swap monitor. Inspect a persisted swap-in by id and report payment/proof/reservation state without creating, signing, publishing, or recovering anything. For book-and-pay follow-up, pass both the internal `swapId` and `tradeId` returned by `hostr_reservations_bookAndPay`. If the swap completes or cannot be found, this tool also checks public reservations by `tradeId`; if no reservation is returned yet, immediately call `hostr_trips_list` with the same `tradeId` and a short `waitSeconds`. This tool has no dryRun parameter because it is always observational; use hostr_swaps_recoverAll for explicit recovery.',
    inputTypeName: 'HostrSwapsWatchInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['swapId'],
      'properties': {
        'swapId': {'type': 'string'},
        'tradeId': {
          'type': 'string',
          'description':
              'Optional reservation trade id used to fall back to public reservation lookup after the swap completes or is not found.',
        },
        'reservationWaitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 300,
          'default': 20,
          'description':
              'How long to poll for the committed reservation after proof completion or swap-not-found fallback.',
        },
      },
    },
    typescriptInput: '''
export interface HostrSwapsWatchInput {
  swapId: string;
  tradeId?: string;
  reservationWaitSeconds?: number;
}
''',
  );

  static const swapsRecoverAll = HostrActionSpec(
    id: 'hostr.swaps.recoverAll',
    title: 'Recover Hostr Swaps',
    description:
        'Preview or run recovery for all persisted swap-in and swap-out operations.',
    inputTypeName: 'HostrSwapsRecoverAllInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'background': {'type': 'boolean', 'default': false},
        'dryRun': {'type': 'boolean', 'default': true},
      },
    },
    typescriptInput: '''
export interface HostrSwapsRecoverAllInput {
  background?: boolean;
  dryRun?: boolean;
}
''',
  );

  static const all = [
    sessionStatus,
    sessionConnect,
    listingsSearch,
    listingsList,
    listingsCreate,
    listingsEdit,
    listingsAvailability,
    listingsReviews,
    listingsReservationGroups,
    reservationsBookAndPay,
    reservationsOffer,
    reservationsNegotiateAccept,
    reservationsPay,
    reservationsCommit,
    reservationsCancel,
    updates,
    reply,
    threadView,
    threadMessage,
    escrowInvolve,
    profileShow,
    profileLookup,
    profileEdit,
    tripsList,
    bookingsList,
    escrowMethods,
    escrowServiceList,
    escrowServiceGet,
    escrowServiceUpdate,
    escrowServiceEdit,
    escrowServiceDelete,
    escrowTradesList,
    escrowTradeView,
    escrowTradeAudit,
    escrowArbitrate,
    escrowBadgeDefinitionsList,
    escrowBadgeDefinitionEdit,
    escrowBadgeDefinitionDelete,
    escrowBadgeAwardsList,
    escrowBadgeAward,
    escrowBadgeRevoke,
    swapsWatch,
    swapsRecoverAll,
    swapsList,
  ];

  static HostrActionSpec byId(String id) {
    return all.firstWhere(
      (spec) => spec.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'unknown Hostr action'),
    );
  }

  static Map<String, Object?> toJson() => {
    'version': 1,
    'actions': all.map((spec) => spec.toJson()).toList(),
  };

  static String documentationMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Hostr MCP action inputs')
      ..writeln()
      ..writeln(
        'All Hostr MCP tools are backed by typed Dart daemon actions. The MCP access token selects the user pubkey; do not include pubkeys in tool inputs.',
      )
      ..writeln()
      ..writeln(
        'Do not run routine preflight session/profile checks before sensitive tools. Call the intended Hostr tool first. If it returns auth_required, call hostr_session_connect, complete sign-in, then retry the original action. If it returns profile_required, collect the missing profile fields, call hostr_profile_edit, publish after approval, then retry the original action.',
      )
      ..writeln()
      ..writeln(
        'Hostr is also the intended tool surface for Hostr-related Nostr network work: Nostr Connect/NIP-46 sign-in, signer/bunker recovery, NIP events, relays, pubkeys/npubs, naddrs, gift-wrapped messages, inbox threads, and Hostr marketplace events. Do not use general web search for these Hostr/Nostr/NIP state workflows unless the user explicitly asks for public web documentation.',
      )
      ..writeln()
      ..writeln(
        'If the user asks how Hostr works or what happens when they send money, explain that Hostr swaps the payment over Lightning into a smart-contract escrow. The escrow service cannot freely take custody of the money; it can only settle the contract by forwarding payment to the host or reversing it according to the trade outcome.',
      )
      ..writeln()
      ..writeln(
        'Most write tools default to preview mode. Only set `dryRun: false` after the user has explicitly approved the preview returned by the same tool. `hostr_reservations_bookAndPay` is the correct foreground handoff tool when the user asks to book, reserve, make, or create a reservation for an instant-book listing at or above the listed price. If it returns external Lightning payment details, the assistant MUST leave only the invoice string and QR image visibly in the user-facing output; tradeId and swapId are internal follow-up arguments. After the QR and invoice are visible, immediately call the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `reservationWaitSeconds`. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed reservation appears, then show a reservation card. Do not call `hostr_reservations_commit`; proof publication is owned by the global Hostr payment proof orchestrator.',
      )
      ..writeln()
      ..writeln('## Reservation date semantics')
      ..writeln()
      ..writeln(
        'Reservation `start` and `end` inputs are calendar dates, not timezone-sensitive instants. Preserve the date the user requested and encode it as `YYYY-MM-DDT00:00:00Z`; the trailing `Z` is storage syntax only. Do not convert from user timezone, listing timezone, El Salvador time, check-in time, or check-out time.',
      )
      ..writeln()
      ..writeln('## Workflow playbooks')
      ..writeln()
      ..writeln('### New listing workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_profile_edit` if profile details need updating, then call `hostr_listings_create` with `dryRun: true`, show the preview, and only call it again with `dryRun: false` after explicit approval. The publish call must reuse the exact `dTag` from the preview result (`structuredContent.nextInput.dTag` or `structuredContent.dTag`) so preview, publish, and retry target the same replaceable listing. The live action ensures seller config is published.',
      )
      ..writeln()
      ..writeln('### Edit listing workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_listings_edit` with `dryRun: true`, review the returned listing/event preview, then repeat with `dryRun: false` after approval.',
      )
      ..writeln()
      ..writeln('### Search and reserve workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_listings_search`, then `hostr_listings_availability`. For user phrasing such as "book", "reserve", "make me a reservation", or "create a reservation" on an instant-book stay where the amount is at or above the listing price, call `hostr_reservations_bookAndPay`. If it returns external Lightning payment details, show only the invoice string and QR image immediately and keep them visible in the output. Do not show internal tradeId or swapId in the payment prompt. Then immediately call the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `reservationWaitSeconds` to monitor payment/proof/reservation completion. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed reservation appears, then show a reservation card. Do not call `hostr_reservations_commit`; proof publication is owned by the global Hostr payment proof orchestrator. Do not stop after `hostr_reservations_negotiateOffer` for this intent. For explicit negotiation-only requests, call `hostr_reservations_negotiateOffer` with `dryRun: true`; repeat with `dryRun: false` to send the private negotiate-stage reservation DM.',
      )
      ..writeln()
      ..writeln('### Negotiation workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_updates` to inspect thread/trade ids. Use `hostr_reservations_negotiateOffer` with `tradeId` and `amount` to send a follow-up offer, `hostr_reservations_negotiateAccept` to accept the latest offer, or `hostr_reservations_cancel` to cancel the private negotiation or committed reservation.',
      )
      ..writeln()
      ..writeln('### Payment workflow')
      ..writeln()
      ..writeln(
        'For normal AI-initiated instant-book payment, use `hostr_reservations_bookAndPay`. When the tool returns external Lightning payment details, the AI must leave only the invoice text and QR image visible to the user first. Then the AI must call the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `reservationWaitSeconds` to monitor payment/proof/reservation completion while the daemon continues the book-and-pay operation in the background. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed reservation appears, then show a reservation card. Do not call `hostr_reservations_commit`; payment proof publication is owned by the global Hostr payment proof orchestrator. Keep `hostr_reservations_pay`, `hostr_reservations_commit`, and `hostr_swaps_recoverAll` for manual recovery/debug paths.',
      )
      ..writeln()
      ..writeln('### Messaging workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_updates`, choose the thread/trade recipient pubkeys, call `hostr_reply` with `dryRun: true`, then `dryRun: false` after approval.',
      )
      ..writeln()
      ..writeln('### Swaps workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_swaps_list`, then `hostr_swaps_watch` for a specific swap id, and `hostr_swaps_recoverAll` when stale operations need recovery.',
      )
      ..writeln();

    for (final spec in all) {
      buffer
        ..writeln('## `${spec.mcpToolName}`')
        ..writeln()
        ..writeln(spec.mcpDescription)
        ..writeln()
        ..writeln('Action id: `${spec.id}`')
        ..writeln()
        ..writeln('```ts')
        ..write(spec.typescriptInput.trim())
        ..writeln()
        ..writeln('```')
        ..writeln()
        ..writeln('JSON schema:')
        ..writeln()
        ..writeln('```json')
        ..writeln(const JsonEncoder.withIndent('  ').convert(spec.inputSchema))
        ..writeln('```')
        ..writeln();
    }

    return buffer.toString();
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value == null) {
    throw FormatException('Missing required string "$key".');
  }
  return value;
}

List<dynamic> _requiredListValue(dynamic value, String key) {
  if (value is List && value.isNotEmpty) return value;
  if (value != null) return [value];
  throw FormatException('Missing required non-empty list "$key".');
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool? _optionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'no' || normalized == '0') {
    return false;
  }
  return null;
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _requiredRatio(dynamic value, String key) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || parsed < 0 || parsed > 1) {
    throw FormatException('Expected "$key" to be a number from 0 to 1.');
  }
  return parsed;
}

double? _optionalPercent(dynamic value, String key) {
  if (value == null) return null;
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || parsed < 0 || parsed > 100) {
    throw FormatException('Expected "$key" to be a number from 0 to 100.');
  }
  return parsed;
}

Map<String, HostrTokenFeeHintsInput>? _optionalTokenFeeHints(dynamic value) {
  if (value == null) return null;
  if (value is! Map) {
    throw const FormatException('Expected "tokenFeeHints" to be an object.');
  }
  final hints = <String, HostrTokenFeeHintsInput>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    if (key.isEmpty) continue;
    final raw = entry.value;
    if (raw is! Map) {
      throw FormatException('Expected tokenFeeHints["$key"] to be an object.');
    }
    hints[key] = HostrTokenFeeHintsInput.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }
  return hints;
}

List<String> _optionalStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return value
      .toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

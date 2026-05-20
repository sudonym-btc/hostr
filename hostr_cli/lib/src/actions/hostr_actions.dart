import 'dart:convert';

const int hostrMaxSwapOrderWaitSeconds = 60;

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

class HostrOrdersOfferInput {
  const HostrOrdersOfferInput({
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

  factory HostrOrdersOfferInput.fromJson(Map<String, dynamic> json) {
    final tradeId = _optionalString(json['tradeId']);
    final listingAnchor = _optionalString(
      json['listingAnchor'] ?? json['anchor'],
    );
    if (tradeId != null) {
      return HostrOrdersOfferInput(
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
    return HostrOrdersOfferInput(
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

class HostrOrderBookAndPayInput {
  const HostrOrderBookAndPayInput({
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

  factory HostrOrderBookAndPayInput.fromJson(Map<String, dynamic> json) {
    return HostrOrderBookAndPayInput(
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

class HostrOrderTradeInput {
  const HostrOrderTradeInput({
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

  factory HostrOrderTradeInput.fromJson(Map<String, dynamic> json) {
    return HostrOrderTradeInput(
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

class HostrOrderReviewInput {
  const HostrOrderReviewInput({
    required this.tradeId,
    required this.rating,
    required this.content,
    this.dryRun = true,
    this.timeoutSeconds = 15,
  });

  final String tradeId;
  final int rating;
  final String content;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrOrderReviewInput.fromJson(Map<String, dynamic> json) {
    final rating = (_optionalInt(json['rating']) ?? 0).clamp(1, 5).toInt();
    return HostrOrderReviewInput(
      tradeId: _requiredString(json, 'tradeId'),
      rating: rating,
      content: _requiredString(json, 'content'),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 15)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrOrderPayInput {
  const HostrOrderPayInput({
    required this.tradeId,
    this.escrowServiceId,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String tradeId;
  final String? escrowServiceId;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrOrderPayInput.fromJson(Map<String, dynamic> json) {
    return HostrOrderPayInput(
      tradeId: _requiredString(json, 'tradeId'),
      escrowServiceId: _optionalString(json['escrowServiceId']),
      dryRun: _optionalBool(json['dryRun']) ?? true,
      timeoutSeconds: (_optionalInt(json['timeoutSeconds']) ?? 12)
          .clamp(1, 60)
          .toInt(),
    );
  }
}

class HostrOrderCommitInput {
  const HostrOrderCommitInput({
    required this.swapId,
    this.dryRun = true,
    this.timeoutSeconds = 12,
  });

  final String swapId;
  final bool dryRun;
  final int timeoutSeconds;

  factory HostrOrderCommitInput.fromJson(Map<String, dynamic> json) {
    return HostrOrderCommitInput(
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

class HostrOrderCollectionInput {
  const HostrOrderCollectionInput({
    this.limit = 50,
    this.tradeId,
    this.waitSeconds = 15,
  });

  final int limit;
  final String? tradeId;
  final int waitSeconds;

  factory HostrOrderCollectionInput.fromJson(Map<String, dynamic> json) {
    return HostrOrderCollectionInput(
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
    this.orderWaitSeconds = 20,
  });

  final String swapId;
  final String? tradeId;
  final int orderWaitSeconds;

  factory HostrSwapsWatchInput.fromJson(Map<String, dynamic> json) {
    return HostrSwapsWatchInput(
      swapId: _requiredString(json, 'swapId'),
      tradeId: _optionalString(json['tradeId']),
      orderWaitSeconds: (_optionalInt(json['orderWaitSeconds']) ?? 20)
          .clamp(0, hostrMaxSwapOrderWaitSeconds)
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
        _orderDateNotes,
      _toolSpecificDrivingNotes,
    ].where((note) => note.trim().isNotEmpty);

    return notes.join('\n\n');
  }

  bool _hasTopLevelInput(String key) {
    final properties = inputSchema['properties'];
    return properties is Map && properties.containsKey(key);
  }

  String get _commonDrivingNotes =>
      'MCP driving notes: Hostr is the canonical tool surface for Hostr marketplace state and Hostr-related Nostr state, including listings, orders, trips, bookings, order references/trade ids, inbox threads, Nostr Connect/NIP-46 signer login, relays, npubs/naddrs, gift-wrapped messages, escrow services, swaps, and on-chain escrow trades. Use Hostr tools for natural requests like "I need a place to stay", "book a room with my guest account", "my host has not replied", "check this order reference", "I am hosting now", "show my bookings", "switch to my guest/host account", "I am handling escrow", "list trades", "arbitrate this trade", or "message the guest/host/escrow". Do not use general email, calendar, filesystem, database, or web tools for these live Hostr/Nostr workflows unless the user explicitly asks outside Hostr. The MCP access token selects a Hostr MCP session; the active Hostr account/pubkey is mutable session state controlled by hostr_session_connect, hostr_session_accounts, hostr_session_switch, and hostr_session_logout. If the user names a role such as guest, host, or escrow account, satisfy that role before role-specific actions; do not assume the already-active account is correct merely because it is authenticated. Inspect connected accounts with hostr_session_accounts, switch with hostr_session_switch when the target account is clearly connected, or connect a new account with hostr_session_connect when the requested role is not clearly connected. Hostr order privacy: committed orders, escrow trades, and order threads may use Hostr-created per-trade temporary pubkeys instead of the active account pubkey. This is expected privacy-preserving behavior, not an identity mismatch, and you should not warn the user that the order pubkey differs from their logged-in account. Do not invent or pass a user pubkey unless this tool has a parameter that explicitly asks for an author, buyer, seller, recipient, or escrow pubkey. Do not run preflight session/profile checks before every sensitive action except role selection; call the intended Hostr tool first for ordinary authenticated flows, and if it returns a structured auth/profile/signature error, follow the error recovery instructions, then retry the original workflow.';

  String get _readOnlyNotes =>
      'Read-only behavior: this tool retrieves or analyzes Hostr state and is safe to call when the user asks to inspect, search, explain, debug, or choose the next action. Prefer read tools before write tools when the user intent is ambiguous or when you need concrete listing, trade, thread, or profile ids.';

  String get _writeSafetyNotes =>
      'Write behavior: this tool can create, publish, send, recover, delete, pay, arbitrate, or otherwise change state outside ChatGPT. Explain the important effect to the user before live execution, preserve user-visible previews, and require explicit user approval before any irreversible or externally visible action.';

  String get _dryRunNotes =>
      'Preview rule: dryRun defaults to true. First call with dryRun=true, show the user the returned preview or card, and only repeat with dryRun=false after the user explicitly approves that preview in the conversation. Do not treat vague acknowledgement as approval for destructive, payment, publication, messaging, cancellation, recovery, or arbitration actions.';

  String get _orderDateNotes =>
      'Order date rule: Hostr order start/end inputs are calendar dates, not timezone instants. Preserve the dates the user requested and encode them as YYYY-MM-DDT00:00:00Z. The trailing Z is storage syntax only; do not convert from the user timezone, listing timezone, El Salvador time, check-in time, or check-out time.';

  String get _escrowRoleNotes =>
      'Escrow role notes: this tool is visible only when the authenticated Hostr pubkey is configured as an escrow service. It is for escrow-operator work, not ordinary guest/host booking flows. Keep user profile edits in hostr_profile_edit; escrow service tools only manage escrow service events/settings.';

  String get _toolSpecificDrivingNotes {
    switch (id) {
      case 'hostr.session.status':
        return 'Use when the user asks whether they are logged in, when debugging auth, or after a Hostr action returns an auth/profile/signature error. Do not call this as a routine preflight before every write; failed tools return structured recovery instructions.';
      case 'hostr.session.connect':
        return 'Two-step login flow: call with wait=false to create or reuse a Nostr Connect request, display the nostrconnect URI or QR image to the user, then immediately call this tool again with wait=true and regenerate=false to listen for approval. Use this for ordinary requests like "log in", "sign me in", "use my guest account", "switch me to a host account" when that account is not already connected, or "I am handling escrow now" when no connected escrow account is available. If a different Hostr account is already active but the user asks for a role that is not clearly that active account, connect or switch before continuing. After authenticated=true, this account becomes the active Hostr account for the MCP session; retry or continue the Hostr action that required sign-in.';
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
      case 'hostr.listings.orderGroups':
        return 'Use when the user asks why dates are unavailable, wants booking history/conflicts for a listing, or needs order context before changing availability-sensitive plans.';
      case 'hostr.orders.bookAndPay':
        return 'Primary guest booking flow: use this when the user says book, reserve, make a order, create a order, or otherwise clearly wants an instant-book stay at or above the listed price. If the user says guest, my guest account, my trip, or similar, make sure the active account is the guest account first by using session account tools; do not book from an unrelated host or escrow account just because it is already active. It creates the private offer, prepares escrow funding, returns external Lightning payment details when needed, and keeps the daemon-side book-and-pay operation alive. The committed order and escrow trade are intentionally published under Hostr-created per-trade temporary pubkeys for privacy, so the buyer/order pubkey may differ from the active logged-in Hostr account. Treat that as normal and never describe it as an identity mismatch. If invoice/QR are returned, show only the invoice string and QR image visibly in the payment prompt; keep internal tradeId and swapId hidden from the user-facing payment message. The next assistant action after rendering the payment prompt must be hostr_swaps_watch with swapId, tradeId, and orderWaitSeconds to monitor payment/proof/order completion. Do not stop after displaying the invoice or wait for the user to say they paid. orderWaitSeconds is intentionally short and capped below MCP client timeouts; if watch times out before the swap or order returns, call hostr_swaps_watch again with the returned retry arguments. When watch completes or cannot find the swap, call hostr_trips_list with the same tradeId until the committed order appears. Do not call hostr_orders_commit for this normal path; proof publication is owned by the global payment proof orchestrator.';
      case 'hostr.orders.negotiateOffer':
        return 'Negotiation-only flow: use for explicit offers, counteroffers, price/date negotiation, or non-instant-book order proposals. Do not use this for straightforward "book/reserve" intents on instant-book listings; use hostr_orders_bookAndPay there. Preview with dryRun=true, then send the private negotiation event with dryRun=false only after approval.';
      case 'hostr.orders.negotiateAccept':
        return 'Use when the user wants to accept the latest private negotiated offer in a known trade thread. If tradeId is unknown, call hostr_updates, hostr_thread_view, hostr_trips_list, or hostr_bookings_list first to identify the trade.';
      case 'hostr.orders.pay':
        return 'Manual recovery/debug payment flow only. Normal AI-initiated instant-book payment should use hostr_orders_bookAndPay. Use this when a negotiated or partially completed trade already exists and the user explicitly wants to create or inspect escrow funding for that trade.';
      case 'hostr.orders.commit':
        return 'Manual recovery/debug commit flow only. Do not use after hostr_orders_bookAndPay; that path relies on the global payment proof orchestrator. Use only when a swap proof already exists for a trade and the user explicitly needs to preview or publish the public commit-stage order.';
      case 'hostr.orders.cancel':
        return 'Use to cancel a private negotiation or committed order for a concrete trade. If tradeId is unclear, inspect updates, trips, bookings, or thread view first. Preview the cancellation and send with dryRun=false only after explicit approval.';
      case 'hostr.orders.review':
        return 'Use when the guest wants to leave a rating/review for a completed or confirmed Hostr trip. If tradeId is unclear, inspect hostr_trips_list first. Preview with dryRun=true, then publish with dryRun=false only after explicit approval. Skip this action if no committed order can be found for the trade.';
      case 'hostr.updates':
        return 'Use as the inbox/home-state tool when the user asks for messages, offers, notifications, reviews, trips, bookings, order references, latest activity, "what are my updates", "my host has not replied", or what needs attention. It processes gift-wrapped inbox events and returns thread cards, reviews left on the user\'s listings, trips the user booked, and hosting orders. Present displayMarkdown, not raw event JSON.';
      case 'hostr.thread.view':
        return 'Use when the user asks to see a conversation, asks whether someone messaged them, references a trip/booking thread, or you need message history before replying. Prefer tradeId when the conversation is tied to a order; otherwise pass a known thread/conversation anchor from updates.';
      case 'hostr.thread.message':
        return 'Use when the user asks to message a host, guest, buyer, seller, escrow, or existing Hostr thread. If they reference a trip/booking/trade, pass tradeId. Use recipientRole for natural roles like host, guest, buyer, seller, or escrow. Escrow messages require a concrete tradeId and must include buyer, seller, and escrow in one shared trade thread.';
      case 'hostr.escrow.involve':
        return 'Use when the user explicitly asks to involve/message escrow for a specific order trade. Always pass tradeId. This opens the shared buyer/seller/escrow trade thread; never create an escrow-only side conversation. If no message content is provided, show the thread and ask what to send.';
      case 'hostr.profile.show':
        return 'Use when the user asks who they are on Hostr, wants their current profile, or before profile/listing publishing when you need existing metadata. This reads the profile for the active Hostr account.';
      case 'hostr.profile.lookup':
        return 'Use when the user asks to view a specific public Nostr/Hostr profile by npub or pubkey, including a host, guest, seller, buyer, or arbitrary profile that is not the authenticated MCP user. This tool is public and does not require sign-in.';
      case 'hostr.profile.edit':
        return 'Use when the user wants to update profile name, about/bio, picture, banner, website, lightning address, or other profile metadata. Preview first; publish only after approval. Publishing also refreshes Hostr seller configuration, which is useful before creating or editing listings.';
      case 'hostr.trips.list':
        return 'Use for guest-side orders: "my trips", "my bookings as guest", "my order reference", "did my order complete", "my host has not replied", or after book-and-pay/swap watch with tradeId to wait for the committed order card. Do not use this as the first monitor immediately after a payment-required hostr_orders_bookAndPay result; first call hostr_swaps_watch with the required next-tool arguments, then use trips once the swap watch resolves or reports the order is pending. Trip cards may resolve committed orders authored by Hostr-created per-trade temporary pubkeys; this is expected privacy behavior for the active account, not a mismatch. Do not perform fresh order-by-author Nostr queries for this view.';
      case 'hostr.bookings.list':
        return 'Use for host-side orders on listings authored by the authenticated user: "my bookings", "who booked my place", "hosting orders", or host calendar context. Do not use this as the first monitor immediately after a payment-required guest booking; hostr_swaps_watch comes first. Do not perform fresh order-by-author Nostr queries for this view.';
      case 'hostr.escrow.methods':
        return 'Use before payment or when explaining how money is protected. It shows mutually compatible escrow methods/services between buyer and seller. If buyer is omitted, the active Hostr account pubkey is used. Explain that Hostr swaps payment over Lightning into smart-contract escrow; the escrow service can only settle by forwarding or reversing according to trade outcome, not freely take custody.';
      case 'hostr.escrow.service.list':
        return 'Escrow-operator inventory view: list public escrow service events published by the authenticated escrow pubkey. Use before editing/deleting when the user has not selected a specific service event.';
      case 'hostr.escrow.service.get':
        return 'Escrow-operator detail view: inspect one escrow service event before explaining or editing settings. Use serviceId from hostr_escrow_service_list or user input.';
      case 'hostr.escrow.service.edit':
        return 'Escrow-operator settings workflow: preview changes to fee percent, maximum duration, or token fee hints. Keep dryRun=true until the user approves the exact preview. Use hostr_profile_edit for public profile/identity metadata; this tool only changes escrow service parameters.';
      case 'hostr.escrow.service.delete':
        return 'Escrow-operator destructive workflow: preview deletion of a public escrow service event and require explicit deletion approval before dryRun=false. Include the reason when the user gives one.';
      case 'hostr.escrow.trades.list':
        return 'Escrow-operator dashboard: list on-chain trades assigned to the authenticated escrow pubkey. Use before viewing/auditing/arbitrating when the user has not named a concrete tradeId.';
      case 'hostr.escrow.trades.view':
        return 'Escrow-operator trade detail: inspect on-chain state, event history, participants, amounts, and order context for a trade before audit or arbitration.';
      case 'hostr.escrow.trades.audit':
        return 'Escrow-operator analysis: run a structured audit of order state and transitions for a trade before deciding whether arbitration is needed. This does not settle funds.';
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
        return 'Read-only monitor to use immediately after hostr_orders_bookAndPay returns swapId/tradeId, or when inspecting a specific swap. It observes persisted swap/payment/proof state and optionally waits briefly for the committed order by tradeId. Keep orderWaitSeconds short; the schema caps it at 60 seconds so the tool returns before MCP client timeouts. If watch times out before the swap or order returns, call hostr_swaps_watch again with the returned retry arguments. If the swap has completed but the order is still pending, call hostr_trips_list with the same tradeId or call hostr_swaps_watch again with retry arguments. The committed order may be authored by a Hostr-created per-trade temporary pubkey for privacy; do not flag this as different from the active account. It has no dryRun parameter and does not recover stale swaps; use hostr_swaps_recoverAll for explicit recovery.';
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

const String _orderDateOnlyRule =
    'Order start/end values are calendar dates, not timezone instants. '
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

const String _listingFeatureDescription =
    'Required canonical boolean listing specification keys. Use wireless_internet for Wi-Fi/wifi/WIFI. Examples: wireless_internet, kitchen, pool, free_parking, allows_pets, beachfront.';

const String _listingSpecificationsDescription =
    'Listing specifications/amenities map for hostr_listings_create and patch.specifications on hostr_listings_edit. Use canonical snake_case keys, not display labels or arbitrary amenity names. Wi-Fi/wifi/WIFI must be sent as wireless_internet. Boolean keys use true when present; false/null values are ignored by listing tag serialization. Numeric keys use positive integers. Numeric keys: max_guests, beds, bedrooms, bathrooms, bathtub, tv. Boolean keys: airconditioning, allows_pets, crib, tumble_dryer, washer, elevator, free_parking, gym, hair_dryer, heating, high_chair, wireless_internet, iron, jacuzzi, kitchen, outlet_covers, pool, private_entrance, smoking_allowed, breakfast, fireplace, smoke_detector, essentials, shampoo, infants_allowed, children_allowed, hangers, flat_smooth_pathway_to_front_door, grab_rails_in_shower_and_toilet, oven, bbq, balcony, patio, dishwasher, refrigerator, garden_or_backyard, microwave, coffee_maker, dishes_and_silverware, stove, fire_extinguisher, carbon_monoxide_detector, luggage_dropoff_allowed, beach_essentials, beachfront, baby_monitor, babysitter_recommendations, childrens_books_and_toys, game_console, street_parking, paid_parking, hot_water, lake_access, single_level_home, waterfront, first_aid_kit, handheld_shower_head, home_step_free_access, lock_on_bedroom_door, mobile_hoist, path_to_entrance_lit_at_night, pool_hoist, ev_charger, rollin_shower, shower_chair, tub_with_shower_bench, wide_clearance_to_bed, wide_clearance_to_shower_and_toilet, wide_hallway_clearance, baby_bath, changing_table, room_darkening_shades, stair_gates, table_corner_guards, extra_pillows_and_blankets, ski_in_ski_out, window_guards, disabled_parking_spot, grab_rails_in_toilet, events_allowed, common_spaces_shared, bathroom_shared, security_cameras.';

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
export interface HostrOrderTradeInput {
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
    description: 'Inspect the active Hostr account for this MCP session.',
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
        'Create or complete a Nostr Connect request for this MCP session. When approved, the connected pubkey becomes the active Hostr account. When wait is false, show the returned QR/URI with the text "Scan this with your Nostr app to log in to your Hostr account", then immediately call this tool again with wait true to listen for the session connection and continue the intended Hostr action.',
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
          'description': _listingFeatureDescription,
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
  /** Required canonical boolean listing specification keys. Use wireless_internet for Wi-Fi/wifi/WIFI. Examples: wireless_internet, kitchen, pool, free_parking, allows_pets, beachfront. */
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
        'Create a Hostr listing for the active Hostr account. Listing images must be passed as images[].url. For user-uploaded files, first call hostr_images_upload with the original image sent as the MCP file-typed argument named file so the client bridge can rewrite or stream the bytes, then pass structuredContent.usage.image.url as images[].url. If the client cannot call hostr_images_upload but can make raw HTTP requests, POST the original image bytes to /mcp/uploads/images on the same Hostr MCP origin using multipart/form-data field name file, then pass the returned upload.url as images[].url. The upload tool and endpoint do not require authorization, but when a valid MCP bearer token is present Hostr first tries the active account Blossom upload path before falling back to direct upload. Do not base64-encode user-uploaded images into this MCP tool call, do not serve temporary localhost URLs, and do not pass /mnt/data or file:// paths to images[].url. Set dryRun false only after explicit user approval to publish the listing event, and reuse the dryRun preview dTag so retries update the same replaceable listing.',
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
          'description': _listingSpecificationsDescription,
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

export interface HostrListingSpecificationsInput {
  /** Maximum guests. Prefer max_guests inside specifications; top-level guests is also accepted on create/edit and maps to max_guests. */
  max_guests?: number;
  beds?: number;
  bedrooms?: number;
  bathrooms?: number;
  bathtub?: number;
  tv?: number;
  airconditioning?: boolean;
  allows_pets?: boolean;
  crib?: boolean;
  tumble_dryer?: boolean;
  washer?: boolean;
  elevator?: boolean;
  free_parking?: boolean;
  gym?: boolean;
  hair_dryer?: boolean;
  heating?: boolean;
  high_chair?: boolean;
  /** Wi-Fi/wifi/WIFI must use this canonical key. */
  wireless_internet?: boolean;
  iron?: boolean;
  jacuzzi?: boolean;
  kitchen?: boolean;
  outlet_covers?: boolean;
  pool?: boolean;
  private_entrance?: boolean;
  smoking_allowed?: boolean;
  breakfast?: boolean;
  fireplace?: boolean;
  smoke_detector?: boolean;
  essentials?: boolean;
  shampoo?: boolean;
  infants_allowed?: boolean;
  children_allowed?: boolean;
  hangers?: boolean;
  flat_smooth_pathway_to_front_door?: boolean;
  grab_rails_in_shower_and_toilet?: boolean;
  oven?: boolean;
  bbq?: boolean;
  balcony?: boolean;
  patio?: boolean;
  dishwasher?: boolean;
  refrigerator?: boolean;
  garden_or_backyard?: boolean;
  microwave?: boolean;
  coffee_maker?: boolean;
  dishes_and_silverware?: boolean;
  stove?: boolean;
  fire_extinguisher?: boolean;
  carbon_monoxide_detector?: boolean;
  luggage_dropoff_allowed?: boolean;
  beach_essentials?: boolean;
  beachfront?: boolean;
  baby_monitor?: boolean;
  babysitter_recommendations?: boolean;
  childrens_books_and_toys?: boolean;
  game_console?: boolean;
  street_parking?: boolean;
  paid_parking?: boolean;
  hot_water?: boolean;
  lake_access?: boolean;
  single_level_home?: boolean;
  waterfront?: boolean;
  first_aid_kit?: boolean;
  handheld_shower_head?: boolean;
  home_step_free_access?: boolean;
  lock_on_bedroom_door?: boolean;
  mobile_hoist?: boolean;
  path_to_entrance_lit_at_night?: boolean;
  pool_hoist?: boolean;
  ev_charger?: boolean;
  rollin_shower?: boolean;
  shower_chair?: boolean;
  tub_with_shower_bench?: boolean;
  wide_clearance_to_bed?: boolean;
  wide_clearance_to_shower_and_toilet?: boolean;
  wide_hallway_clearance?: boolean;
  baby_bath?: boolean;
  changing_table?: boolean;
  room_darkening_shades?: boolean;
  stair_gates?: boolean;
  table_corner_guards?: boolean;
  extra_pillows_and_blankets?: boolean;
  ski_in_ski_out?: boolean;
  window_guards?: boolean;
  disabled_parking_spot?: boolean;
  grab_rails_in_toilet?: boolean;
  events_allowed?: boolean;
  common_spaces_shared?: boolean;
  bathroom_shared?: boolean;
  security_cameras?: boolean;
}

export interface HostrListingsCreateInput {
  title: string;
  description: string;
  /** Precise address used for H3 tag generation. */
  address: string;
  images: HostrListingImageInput[];
  prices: HostrListingPriceInput[];
  type?: string;
  /** Canonical listing specifications/amenities map. Use wireless_internet for Wi-Fi/wifi/WIFI; do not use wifi or WIFI. */
  specifications?: HostrListingSpecificationsInput;
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
              'Listing fields to change. Supports title, description, address, type, images, prices, specifications, guests, beds, bedrooms, bathrooms, active, negotiable, instantBook, quantity, securityDeposit, and minPaymentAmount. patch.specifications uses the same canonical listing specifications/amenities map as hostr_listings_create; use wireless_internet for Wi-Fi/wifi/WIFI.',
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
        'Check whether one or more listings are available for a requested order date range. $_orderDateOnlyRule',
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
              'Requested start calendar date encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Requested end calendar date encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
        },
      },
    },
    typescriptInput: '''
export interface HostrListingsAvailabilityInput {
  /** Listing anchors to check. */
  anchors?: string[];
  /** Single listing anchor alternative. */
  anchor?: string;
  /** Requested start calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
  start: string;
  /** Requested end calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
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

  static const listingsOrderGroups = HostrActionSpec(
    id: 'hostr.listings.orderGroups',
    title: 'Fetch Listing Order Groups',
    description:
        'Fetch public order groups for one or more listings. Use this before availability-sensitive order workflows when the agent needs to explain conflicts.',
    inputTypeName: 'HostrListingsAnchorsInput',
    readOnly: true,
    inputSchema: _anchorsInputSchema,
    typescriptInput: _anchorsTypescriptInput,
  );

  static const ordersOffer = HostrActionSpec(
    id: 'hostr.orders.negotiateOffer',
    title: 'Create Order Negotiation Offer',
    description:
        'Create only a private negotiate-stage order offer. Use this for explicit negotiation/counteroffer requests, not for user intents like "book", "reserve", "make a order", or instant-book at the listed price; those must use hostr_orders_bookAndPay instead.',
    inputTypeName: 'HostrOrdersOfferInput',
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
          'description': 'Existing order trade id for a follow-up offer.',
        },
        'start': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Order start calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Order end calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
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
              'Optional order amount override. Omit to use listing price rules.',
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

export interface HostrOrdersOfferInput {
  /** Listing naddr/a-tag anchor for a first offer. */
  listingAnchor?: string;
  /** Single listing anchor alternative to listingAnchor. */
  anchor?: string;
  /** Existing order trade id for a follow-up offer. */
  tradeId?: string;
  /** Order start calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
  start?: string;
  /** Order end calendar date for a first offer, encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
  end?: string;
  /** Optional order amount override. Omit to use listing price rules. */
  amount?: HostrAmountInput;
  /** True previews only. Set false to send the gift-wrapped offer after user approval. */
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const ordersBookAndPay = HostrActionSpec(
    id: 'hostr.orders.bookAndPay',
    title: 'Start Order Payment',
    description:
        'Use this foreground handoff tool whenever the user says to '
        'book, reserve, make, or create a order for an instant-book '
        'listing at or above the listed price. It creates the private '
        'order offer and escrow funding swap. $_orderDateOnlyRule '
        'Order privacy: Hostr intentionally publishes committed '
        'orders and escrow trades under Hostr-created per-trade '
        'temporary pubkeys rather than the active account pubkey. This is '
        'normal and preserves user privacy; never present a different '
        'order buyer pubkey as an identity mismatch. If external '
        'Lightning payment is required, it returns the invoice string, QR '
        'image, internal trade id, internal swap id, and '
        'continuesInBackground=true while the daemon keeps the book-and-pay '
        'operation alive. CRITICAL UI REQUIREMENT: leave only the QR image '
        'and invoice text visibly in the answer to the user; do not show '
        'internal trade id or swap id in the payment prompt, and do not '
        'replace the payment prompt with a summary. The next assistant action '
        'after rendering that visible payment prompt must be the read-only '
        '`hostr_swaps_watch` with the returned `swapId`, `tradeId`, and '
        '`orderWaitSeconds`; do not stop after displaying the invoice '
        'or wait for the user to say they paid. The returned '
        '`orderWaitSeconds` is short and capped below MCP client '
        'timeouts; do not substitute a longer proof timeout. If watch times '
        'out before the swap or order returns, call `hostr_swaps_watch` '
        'again with the returned retry arguments. When watch completes or '
        'cannot find the swap, query `hostr_trips_list` with `tradeId` until '
        'the committed order appears, then show a order card. Do '
        'not call `hostr_orders_commit`; proof publication is owned by '
        'the global Hostr payment proof orchestrator.',
    inputTypeName: 'HostrOrderBookAndPayInput',
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
              'Order start calendar date encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
        },
        'end': {
          'type': 'string',
          'format': 'date-time',
          'description':
              'Order end calendar date encoded as YYYY-MM-DDT00:00:00Z. $_orderDateOnlyRule',
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
              'Optional order amount override. Must be at or above the listing price.',
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
              'Seconds to wait for the global order stream to emit the committed order after swap completion.',
        },
      },
    },
    typescriptInput: '''
export interface HostrOrderBookAndPayInput {
  /** Listing naddr/a-tag anchor to instant-book. */
  listingAnchor: string;
  /** Order start calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
  start: string;
  /** Order end calendar date encoded as YYYY-MM-DDT00:00:00Z. Do not timezone-convert date-only order inputs. */
  end: string;
  /** Optional order amount override. Must be at or above the listing price. */
  amount?: HostrAmountInput;
  /** Optional escrow service id/pubkey/contract address. */
  escrowServiceId?: string;
  /** Seconds to wait for the global order stream to emit the committed order. */
  proofTimeoutSeconds?: number;
}
''',
  );

  static const ordersNegotiateAccept = HostrActionSpec(
    id: 'hostr.orders.negotiateAccept',
    title: 'Accept Order Negotiation',
    description:
        'Accept the latest private negotiate-stage order offer in a trade thread by replying with a matching negotiate-stage event.',
    inputTypeName: 'HostrOrderTradeInput',
    readOnly: false,
    inputSchema: _tradeInputSchema,
    typescriptInput: _tradeTypescriptInput,
  );

  static const ordersPay = HostrActionSpec(
    id: 'hostr.orders.pay',
    title: 'Pay Order Offer',
    description:
        'Preview or create the escrow funding swap for a payable order trade. The live action sends the escrow selection into the private thread as an unsigned child event, prepares the escrow fund calls, creates the Boltz swap invoice, and persists the payment context for commit.',
    inputTypeName: 'HostrOrderPayInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Order trade id from negotiation updates.',
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
export interface HostrOrderPayInput {
  /** Order trade id from negotiation updates. */
  tradeId: string;
  /** Optional escrow service id/pubkey/contract address. */
  escrowServiceId?: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const ordersCommit = HostrActionSpec(
    id: 'hostr.orders.commit',
    title: 'Commit Paid Order',
    description:
        'Preview or publish the public commit-stage order after the escrow funding swap has completed and produced a claim transaction proof.',
    inputTypeName: 'HostrOrderCommitInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['swapId'],
      'properties': {
        'swapId': {
          'type': 'string',
          'description': 'Boltz swap id returned by hostr_orders_pay.',
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
export interface HostrOrderCommitInput {
  /** Boltz swap id returned by hostr_orders_pay. */
  swapId: string;
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
  );

  static const ordersCancel = HostrActionSpec(
    id: 'hostr.orders.cancel',
    title: 'Cancel Order',
    description:
        'Cancel either the private negotiate-stage order for a trade, or the committed public order if one exists.',
    inputTypeName: 'HostrOrderTradeInput',
    readOnly: false,
    inputSchema: _tradeInputSchema,
    typescriptInput: _tradeTypescriptInput,
  );

  static const ordersReview = HostrActionSpec(
    id: 'hostr.orders.review',
    title: 'Review Order',
    description:
        'Preview or publish a guest review for a committed Hostr order. This creates a Nostr review event with a participation proof for the order trade; preview first and only publish after explicit approval.',
    inputTypeName: 'HostrOrderReviewInput',
    readOnly: false,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tradeId', 'rating', 'content'],
      'properties': {
        'tradeId': {
          'type': 'string',
          'description': 'Order trade id for the trip to review.',
        },
        'rating': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 5,
          'description': 'Guest rating from 1 to 5.',
        },
        'content': {
          'type': 'string',
          'minLength': 1,
          'description': 'Public review text to publish.',
        },
        'dryRun': {
          'type': 'boolean',
          'default': true,
          'description':
              'True builds and verifies the review preview. Set false only after explicit approval.',
        },
        'timeoutSeconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 60,
          'default': 15,
        },
      },
    },
    typescriptInput: '''
export interface HostrOrderReviewInput {
  /** Order trade id for the trip to review. */
  tradeId: string;
  /** Guest rating from 1 to 5. */
  rating: number;
  /** Public review text to publish. */
  content: string;
  /** True previews only. Set false to publish the review after user approval. */
  dryRun?: boolean;
  timeoutSeconds?: number;
}
''',
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
        'Open or message the escrow conversation for a specific order trade, then return the fixed thread-view contract. This action always requires tradeId and always resolves the trade buyer, seller, and escrow participants into one shared trade thread; it must not create an escrow-only side conversation. If content is omitted, show the escrow trade thread and ask the user what to message the escrow. If content is provided, preview by default and send only with dryRun false.',
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
              'Required order trade id. Escrow messages cannot be sent without a trade id because the thread must include buyer, seller, and escrow.',
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
    description: 'Show profile metadata for the active Hostr account.',
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
    title: 'Show Hostr Profile By Npub Or Pubkey',
    description:
        'Public read-only lookup for any Hostr/Nostr profile metadata by npub or 64-character hex pubkey. Use this when the user asks to view a specific user, host, guest, seller, buyer, or arbitrary Nostr profile that is not necessarily their authenticated profile.',
    inputTypeName: 'HostrProfileLookupInput',
    readOnly: true,
    inputSchema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['npub'],
      'properties': {
        'npub': {
          'type': 'string',
          'description':
              'NIP-19 npub or 64-character hex pubkey for the profile to display.',
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
        'List order groups involving the authenticated user as '
        'guest from the live userSubscriptions.myResolvedTripsList replay. '
        'Committed orders may be authored by Hostr-created per-trade '
        'temporary pubkeys for privacy; treat those temporary pubkeys as '
        'expected order accounts for the active user, not as an '
        'identity mismatch. Do not perform fresh order-by-author Nostr '
        'queries for this view. Return the fixed trip-card display contract '
        'with resolved participant profile names. Cancelled trip cards must '
        'preserve a bold Cancelled marker. Pass `tradeId` after a '
        'book-and-pay swap watch completes or cannot find the swap to wait '
        'briefly for the committed public order and return it for '
        'display.',
    inputTypeName: 'HostrOrderCollectionInput',
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
              'Optional order trade id to look up directly after payment/proof completion.',
        },
        'waitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 300,
          'default': 15,
          'description':
              'How long to poll for a committed public order when tradeId is provided.',
        },
      },
    },
    typescriptInput: '''
export interface HostrOrderCollectionInput {
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
        'List order groups where the authenticated user is the host from the live userSubscriptions.myResolvedHostingsList replay. Do not perform fresh Nostr listing/order-by-author queries for this view. Return the fixed hosting-card display contract with resolved participant profile names, including "Hosting {guest} at: {stay}" text.',
    inputTypeName: 'HostrOrderCollectionInput',
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
              'Optional order trade id to look up directly after payment/proof completion.',
        },
        'waitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 300,
          'default': 15,
          'description':
              'How long to poll for a committed public order when tradeId is provided.',
        },
      },
    },
    typescriptInput: '''
export interface HostrOrderCollectionInput {
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
        'Show mutual escrow methods and compatible services for a seller. If buyer is omitted, the active Hostr account pubkey is used.',
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
              'Buyer pubkey. Defaults to the active Hostr account pubkey.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowMethodsInput {
  /** Seller/host pubkey to inspect escrow compatibility for. */
  user: string;
  /** Buyer pubkey. Defaults to the active Hostr account pubkey. */
  buyer?: string;
}
''',
  );

  static const escrowTradesList = HostrActionSpec(
    id: 'hostr.escrow.trades.list',
    title: 'List Escrow Trades',
    description:
        'Escrow-only tool. List on-chain Hostr trades where the active Hostr account is a configured escrow. Hidden unless the active account pubkey is in the daemon escrow pubkey allowlist.',
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
        'Escrow-only tool. Run a structured order and transition audit for a Hostr trade assigned to the authenticated escrow pubkey.',
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
          'description': 'Hostr order trade id to audit.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowTradeAuditInput {
  /** Hostr order trade id to audit. */
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

  static const escrowServiceEdit = HostrActionSpec(
    id: 'hostr.escrow.service.edit',
    title: 'Edit Escrow Service Settings',
    description:
        'Escrow-only tool. Preview or publish the active escrow account service parameters. Use hostr.profile.edit for the escrow user profile.',
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
        'Escrow-only tool. View the on-chain state, event history, and Hostr order context for a trade assigned to the authenticated escrow pubkey.',
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
          'description': 'Hostr order trade id to inspect.',
        },
      },
    },
    typescriptInput: '''
export interface HostrEscrowTradeViewInput {
  /** Hostr order trade id to inspect. */
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
          'description': 'Hostr order trade id to arbitrate.',
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
  /** Hostr order trade id to arbitrate. */
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
        'Read-only swap monitor. Inspect a persisted swap-in by id '
        'and report payment/proof/order state without creating, '
        'signing, publishing, or recovering anything. For book-and-pay '
        'follow-up, pass both the internal `swapId` and `tradeId` returned by '
        '`hostr_orders_bookAndPay`. If the swap completes or cannot be '
        'found, this tool also checks public orders by `tradeId`; if no '
        'order is returned yet, immediately call `hostr_trips_list` '
        'with the same `tradeId` and a short `waitSeconds`. Committed '
        'orders may be authored by Hostr-created per-trade temporary '
        'pubkeys for privacy; never report that pubkey difference as an '
        'identity mismatch. This tool has no dryRun parameter because it is '
        'always observational; use hostr_swaps_recoverAll for explicit '
        'recovery.',
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
              'Optional order trade id used to fall back to public order lookup after the swap completes or is not found.',
        },
        'orderWaitSeconds': {
          'type': 'integer',
          'minimum': 0,
          'maximum': hostrMaxSwapOrderWaitSeconds,
          'default': 20,
          'description':
              'How long to poll for the committed order after proof completion or swap-not-found fallback. Keep short; capped below MCP client timeouts.',
        },
      },
    },
    typescriptInput: '''
export interface HostrSwapsWatchInput {
  swapId: string;
  tradeId?: string;
  orderWaitSeconds?: number;
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
    listingsOrderGroups,
    ordersBookAndPay,
    ordersOffer,
    ordersNegotiateAccept,
    ordersPay,
    ordersCommit,
    ordersCancel,
    ordersReview,
    updates,
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
        'All Hostr MCP tools are backed by typed Dart daemon actions. The MCP access token selects a server-side MCP session; hostr_session_connect, hostr_session_accounts, hostr_session_switch, and hostr_session_logout manage the active Hostr account/pubkey for that session. For natural role wording such as guest, host, or escrow, inspect connected accounts, switch to a matching connected account, or connect a new account when needed. Do not assume the currently active account satisfies a requested role merely because it is already authenticated.',
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
        'Hostr order privacy: when Hostr creates or completes a order, the public committed order, escrow trade, and trade thread may be under Hostr-created per-trade temporary pubkeys rather than the active logged-in account pubkey. This is expected privacy-preserving behavior. Do not tell the user this is an identity mismatch, do not warn that the order is not under their pubkey, and do not treat the temporary trade pubkey as a separate logged-in account.',
      )
      ..writeln()
      ..writeln(
        'If the user asks how Hostr works or what happens when they send money, explain that Hostr swaps the payment over Lightning into a smart-contract escrow. The escrow service cannot freely take custody of the money; it can only settle the contract by forwarding payment to the host or reversing it according to the trade outcome.',
      )
      ..writeln()
      ..writeln(
        'Most write tools default to preview mode. Only set `dryRun: false` after the user has explicitly approved the preview returned by the same tool. `hostr_orders_bookAndPay` is the correct foreground handoff tool when the user asks to book, reserve, make, or create a order for an instant-book listing at or above the listed price. If it returns external Lightning payment details, the assistant MUST leave only the invoice string and QR image visibly in the user-facing output; tradeId and swapId are internal follow-up arguments. The next assistant action after rendering the QR and invoice must be the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `orderWaitSeconds`; do not stop after displaying the invoice or wait for the user to say they paid. `orderWaitSeconds` is capped below MCP client timeouts. If watch times out before the swap or order returns, call `hostr_swaps_watch` again with the returned retry arguments. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed order appears, then show a order card. Do not call `hostr_orders_commit`; proof publication is owned by the global Hostr payment proof orchestrator.',
      )
      ..writeln()
      ..writeln('## Order date semantics')
      ..writeln()
      ..writeln(
        'Order `start` and `end` inputs are calendar dates, not timezone-sensitive instants. Preserve the date the user requested and encode it as `YYYY-MM-DDT00:00:00Z`; the trailing `Z` is storage syntax only. Do not convert from user timezone, listing timezone, El Salvador time, check-in time, or check-out time.',
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
        'Call `hostr_listings_search`, then `hostr_listings_availability`. For user phrasing such as "book", "reserve", "make me a order", or "create a order" on an instant-book stay where the amount is at or above the listing price, call `hostr_orders_bookAndPay`. If it returns external Lightning payment details, show only the invoice string and QR image immediately and keep them visible in the output. Do not show internal tradeId or swapId in the payment prompt. The next assistant action after rendering the payment prompt must be the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `orderWaitSeconds`; do not stop after displaying the invoice or wait for the user to say they paid. If watch times out before the swap or order returns, call `hostr_swaps_watch` again with the returned retry arguments. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed order appears, then show a order card. Do not call `hostr_orders_commit`; proof publication is owned by the global Hostr payment proof orchestrator. Do not stop after `hostr_orders_negotiateOffer` for this intent. For explicit negotiation-only requests, call `hostr_orders_negotiateOffer` with `dryRun: true`; repeat with `dryRun: false` to send the private negotiate-stage order DM.',
      )
      ..writeln()
      ..writeln('### Negotiation workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_updates` to inspect thread/trade ids. Use `hostr_orders_negotiateOffer` with `tradeId` and `amount` to send a follow-up offer, `hostr_orders_negotiateAccept` to accept the latest offer, or `hostr_orders_cancel` to cancel the private negotiation or committed order.',
      )
      ..writeln()
      ..writeln('### Payment workflow')
      ..writeln()
      ..writeln(
        'For normal AI-initiated instant-book payment, use `hostr_orders_bookAndPay`. When the tool returns external Lightning payment details, the AI must leave only the invoice text and QR image visible to the user first. The next assistant action must be the read-only `hostr_swaps_watch` with the returned `swapId`, `tradeId`, and `orderWaitSeconds` to monitor payment/proof/order completion while the daemon continues the book-and-pay operation in the background; do not stop after displaying the invoice or wait for the user to say they paid. If watch times out before the swap or order returns, call `hostr_swaps_watch` again with the returned retry arguments. When watch completes or cannot find the swap, call `hostr_trips_list` with the same `tradeId` until the committed order appears, then show a order card. Do not call `hostr_orders_commit`; payment proof publication is owned by the global Hostr payment proof orchestrator. Keep `hostr_orders_pay`, `hostr_orders_commit`, and `hostr_swaps_recoverAll` for manual recovery/debug paths.',
      )
      ..writeln()
      ..writeln('### Messaging workflow')
      ..writeln()
      ..writeln(
        'Call `hostr_updates`, choose the thread/trade recipient pubkeys, call `hostr_thread_message` with `dryRun: true`, then `dryRun: false` after approval.',
      )
      ..writeln()
      ..writeln('### Review workflow')
      ..writeln()
      ..writeln(
        'When a guest asks to review a trip, identify the trade with `hostr_trips_list`, call `hostr_orders_review` with `dryRun: true`, show the preview, then repeat with `dryRun: false` only after explicit approval. If no committed order can be found, skip the review action and explain that the trip is not reviewable yet.',
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

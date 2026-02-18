import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class ThreadContext {
  final Thread thread;
  final Listings listings;
  final MetadataUseCase metadata;

  Completer<Listing?>? _listingCompleter;
  Completer<ProfileMetadata?>? _listingProfileCompleter;

  ThreadContext({
    required this.thread,
    required this.listings,
    required this.metadata,
  });

  Future<void> load() async {
    await Future.wait([getListing(), getListingProfile()]);
  }

  Future<Listing?> getListing() {
    if (_listingCompleter != null) {
      return _listingCompleter!.future;
    }

    _listingCompleter = Completer<Listing?>();
    listings
        .getOneByAnchor(thread.getListingAnchor())
        .then(_listingCompleter!.complete)
        .catchError(_listingCompleter!.completeError);
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> getListingProfile() {
    if (_listingProfileCompleter != null) {
      return _listingProfileCompleter!.future;
    }

    _listingProfileCompleter = Completer<ProfileMetadata?>();
    getListing()
        .then((listing) async {
          if (listing == null) return null;
          return metadata.loadMetadata(listing.pubKey);
        })
        .then(_listingProfileCompleter!.complete)
        .catchError(_listingProfileCompleter!.completeError);
    return _listingProfileCompleter!.future;
  }
}

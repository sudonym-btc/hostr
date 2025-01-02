# Hostr Client

This is a client that displays and posts events related to short term accommodation lets over the nostr network.

## Getting Started

## Structure

```
/src
  /data                // What is the shape of the data? How do we fetch it
    /messages
      /
    /listing.dart
    /booking.dart
  /logic               // What operations do we need to perform on the data?
  /presentation        // How do we want to display the data?
```

## NIPs Utilized

- **NIP-01**: Basic protocol for event creation and subscription.
- **NIP-04**: Encrypted direct messages for secure communication between hosts and guests.
- **NIP-05**: Mapping Nostr keys to DNS-based internet identifiers.
- **NIP-09**: Event deletion for removing listings or messages.
- **NIP-33**: Parameterized replaceable events for creating and updating listings and bookings.

## Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application.

The `assets/images` directory contains [resolution-aware
images](https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware).

## Localization

This project generates localized messages based on arb files found in
the `lib/_localization` directory.

To support additional languages, please visit the tutorial on
[Internationalizing Flutter
apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

## Seed relay

```bash
flutter run lib/data/mock/seed_relay.dart
```

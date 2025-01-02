import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import 'keypairs.dart';

var MOCK_PROFILES = [
  NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: JsonEncoder().convert({
        'name': 'Jeremy',
        'about': 'We love weloming new guests into our home',
        'picture': [
          'https://plus.unsplash.com/premium_photo-1689530775582-83b8abdb5020?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFuZG9tJTIwcGVyc29ufGVufDB8fDB8fHww'
        ]
      }),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_PROFILE,
      tags: []),
  NostrEvent.fromPartialData(
      keyPairs: MockKeys.guest,
      content: JsonEncoder().convert({
        'name': 'Jasmine',
        'about': 'Travelling the world!',
        'picture': [
          'https://r2.starryai.com/results/1005156662/01ea57ea-66bd-4bed-a467-11bbdedb43ea.webp'
        ]
      }),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_PROFILE,
      tags: []),
  NostrEvent.fromPartialData(
      keyPairs: MockKeys.sccrow,
      content: JsonEncoder().convert({
        'name': 'Hostr Escrow',
        'about': 'Provides cheap escrow services for nostr',
        'picture': [
          'https://files.oaiusercontent.com/file-NbbHPRbFACbfS8BcAWDnju?se=2024-12-31T13%3A41%3A58Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D604800%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3D2cdcbb2c-f951-46af-91b6-547b74f2dc9d.webp&sig=advBN3XrKDJnND8EUsjJ0YKNI9OtCFTvBA4DIpOeQvA%3D'
        ]
      }),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_PROFILE,
      tags: [])
].toList();

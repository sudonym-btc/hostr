import 'dart:math';

class StubFaker {
  StubFaker({int? seed}) : _random = Random(seed);

  final Random _random;

  late final crypto = _CryptoModule(_random);
  late final lorem = _LoremModule(_random);
  late final commerce = _CommerceModule(_random);
  late final location = _LocationModule(_random);
  late final image = _ImageModule(_random);
  late final internet = _InternetModule(_random);
  late final person = _PersonModule(_random);
}

class _CryptoModule {
  _CryptoModule(this._random);

  final Random _random;

  String privateKey() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class _LoremModule {
  _LoremModule(this._random);

  final Random _random;

  static const _words = <String>[
    'cozy',
    'sunny',
    'modern',
    'quiet',
    'rustic',
    'spacious',
    'bright',
    'urban',
    'charming',
    'serene',
    'stylish',
    'elegant',
    'minimal',
    'vintage',
    'lush',
    'lofty',
  ];

  String words({int count = 3}) {
    final selected = List<String>.generate(
      count,
      (_) => _words[_random.nextInt(_words.length)],
    );
    return selected.join(' ');
  }

  String sentence({int wordCount = 12}) {
    final sentence = words(count: wordCount);
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
  }
}

class _CommerceModule {
  _CommerceModule(this._random);

  final Random _random;

  String productDescription() {
    final lorem = _LoremModule(_random);
    return '${lorem.sentence(wordCount: 10)} ${lorem.sentence(wordCount: 8)}';
  }
}

class _LocationModule {
  _LocationModule(this._random);

  final Random _random;

  static const _streets = <String>[
    'Maple',
    'Oak',
    'Pine',
    'Cedar',
    'Elm',
    'Willow',
    'Birch',
    'Ash',
  ];
  static const _cities = <String>[
    'Portland',
    'Austin',
    'Denver',
    'Seattle',
    'Boston',
    'Miami',
    'Chicago',
    'San Diego',
  ];
  static const _states = <String>[
    'CA',
    'TX',
    'CO',
    'WA',
    'MA',
    'FL',
    'IL',
    'OR',
  ];

  String fullAddress() {
    final number = _random.nextInt(9999) + 1;
    final street = _streets[_random.nextInt(_streets.length)];
    final city = _cities[_random.nextInt(_cities.length)];
    final state = _states[_random.nextInt(_states.length)];
    final zip = 10000 + _random.nextInt(89999);
    return '$number $street St, $city, $state $zip';
  }
}

class _ImageModule {
  _ImageModule(this._random);

  final Random _random;

  String abstract() {
    final seed = _random.nextInt(999999);
    return 'https://picsum.photos/seed/$seed/800/600';
  }
}

class _InternetModule {
  _InternetModule(this._random);

  final Random _random;

  String username() {
    const adjectives = ['cool', 'swift', 'brisk', 'bright', 'calm', 'bold'];
    const nouns = ['traveler', 'host', 'explorer', 'nomad', 'seeker', 'guest'];
    final adj = adjectives[_random.nextInt(adjectives.length)];
    final noun = nouns[_random.nextInt(nouns.length)];
    final number = 100 + _random.nextInt(900);
    return '$adj-$noun-$number';
  }
}

class _PersonModule {
  _PersonModule(this._random);

  final Random _random;

  static const _firstNames = <String>[
    'Alex',
    'Jordan',
    'Taylor',
    'Casey',
    'Riley',
    'Morgan',
    'Jamie',
    'Avery',
  ];

  String firstName() => _firstNames[_random.nextInt(_firstNames.length)];

  String bio() {
    final lorem = _LoremModule(_random);
    return '${lorem.sentence(wordCount: 8)} ${lorem.sentence(wordCount: 9)}';
  }
}

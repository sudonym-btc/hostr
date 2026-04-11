import 'dart:math';

import 'package:hostr_sdk/config.dart' show CoinlibEventSigner;
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'seed_context.dart';

// ─── Seed identity data ────────────────────────────────────────────────────

const _kSeedFirstNames = [
  'Alex',
  'Taylor',
  'Jordan',
  'Morgan',
  'Casey',
  'Riley',
  'Avery',
  'Jamie',
  'Cameron',
  'Skyler',
  'Quinn',
  'Parker',
  'Drew',
  'Reese',
  'Blake',
  'Kendall',
  'Rowan',
  'Logan',
  'Finley',
  'Sage',
  'Elliot',
  'Harper',
  'Emerson',
  'Dakota',
  'Sydney',
  'Charlie',
  'Phoenix',
  'Remy',
  'Micah',
  'Noel',
  'Robin',
  'Jules',
  'River',
  'Arden',
  'Lane',
  'Kai',
  'Marlowe',
  'Shawn',
  'Ari',
  'Mika',
  'Briar',
  'Rory',
  'Toby',
  'Nico',
  'Jesse',
  'Alden',
  'Shiloh',
  'Ainsley',
];

const _kSeedLastNames = [
  'Carter',
  'Brooks',
  'Hayes',
  'Morgan',
  'Parker',
  'Reed',
  'Bennett',
  'Foster',
  'Sullivan',
  'Ward',
  'Ellis',
  'Baker',
  'Turner',
  'Morris',
  'Price',
  'Coleman',
  'Bailey',
  'Griffin',
  'Hayden',
  'Wallace',
  'Bryant',
  'Stone',
  'West',
  'Keller',
  'Watson',
  'Hughes',
  'Palmer',
  'Wells',
  'Riley',
  'Bishop',
  'Warren',
  'Woods',
  'Jensen',
  'Porter',
  'Shaw',
  'Bates',
  'Flynn',
  'Sawyer',
  'Meyer',
  'Cross',
  'Brennan',
  'Nolan',
  'Holland',
  'Cruz',
  'Harper',
  'Vaughn',
  'Monroe',
  'Sloan',
];

// ─── Listing seed data ────────────────────────────────────────────────────

enum _ListingTheme { urban, cozy, family, boutique, coastal }

const Map<ListingType, _ListingTheme> _kThemeForListingType = {
  ListingType.room: _ListingTheme.cozy,
  ListingType.house: _ListingTheme.family,
  ListingType.apartment: _ListingTheme.urban,
  ListingType.villa: _ListingTheme.coastal,
  ListingType.hotel: _ListingTheme.boutique,
  ListingType.hostel: _ListingTheme.urban,
  ListingType.resort: _ListingTheme.coastal,
};

const Map<_ListingTheme, List<String>> _kThemeTitlePrefixes = {
  _ListingTheme.urban: [
    'Modern',
    'Stylish',
    'Bright',
    'Contemporary',
    'Minimalist',
    'Sleek',
    'Central',
    'Trendy',
  ],
  _ListingTheme.cozy: [
    'Cozy',
    'Charming',
    'Warm',
    'Quiet',
    'Rustic',
    'Peaceful',
    'Snug',
    'Inviting',
  ],
  _ListingTheme.family: [
    'Spacious',
    'Comfortable',
    'Relaxed',
    'Sunny',
    'Welcoming',
    'Practical',
    'Roomy',
    'Convenient',
  ],
  _ListingTheme.boutique: [
    'Elegant',
    'Design-Forward',
    'Chic',
    'Refined',
    'Upscale',
    'Curated',
    'Premium',
    'Signature',
  ],
  _ListingTheme.coastal: [
    'Seaside',
    'Oceanfront',
    'Tropical',
    'Airy',
    'Breezy',
    'Sunlit',
    'Shoreline',
    'Island-Style',
  ],
};

const Map<_ListingTheme, List<String>> _kThemeTitleNouns = {
  _ListingTheme.urban: [
    'City Apartment',
    'Downtown Loft',
    'Urban Studio',
    'Metro Retreat',
    'Skyline Flat',
    'Transit Hub Loft',
    'City View Suite',
    'Central Apartment',
  ],
  _ListingTheme.cozy: [
    'Nature Getaway',
    'Garden Room',
    'Forest Hideaway',
    'Quiet Retreat',
    'Countryside Cabin',
    'Woodland Stay',
    'Hillside Nook',
    'Mountain Hideout',
  ],
  _ListingTheme.family: [
    'Family Home',
    'Neighborhood House',
    'Greenbelt Home',
    'Weekend Escape',
    'Suburban Retreat',
    'Group-Friendly Home',
    'Parkside House',
    'Family Basecamp',
  ],
  _ListingTheme.boutique: [
    'Boutique Stay',
    'Designer Suite',
    'Stylish Room',
    'Central Guesthouse',
    'Luxury Loft',
    'City Boutique Room',
    'Executive Suite',
    'Curated Residence',
  ],
  _ListingTheme.coastal: [
    'Beach Villa',
    'Ocean Getaway',
    'Coastal Retreat',
    'Resort Escape',
    'Sea View Apartment',
    'Lagoon Hideaway',
    'Surfside Villa',
    'Harbor Retreat',
  ],
};

const Map<_ListingTheme, List<String>> _kThemeDescriptionStarts = {
  _ListingTheme.urban: [
    'Set in a lively neighborhood with cafés and transit nearby, this stay is built for easy city exploring.',
    'A thoughtfully designed city base with clean lines, natural light, and everything needed for a smooth stay.',
    'Right in the heart of the city, this apartment makes it simple to walk, ride, and explore from morning to night.',
    'Polished interiors and practical amenities create a comfortable launchpad for busy urban days.',
  ],
  _ListingTheme.cozy: [
    'Tucked into a calmer setting, this space offers a peaceful atmosphere and a slower pace.',
    'Perfect for unwinding, this stay combines warm interiors with quiet surroundings.',
    'Surrounded by natural charm, this home invites you to disconnect and settle into a restful rhythm.',
    'Soft textures, warm light, and a tranquil setting make this space ideal for recharging.',
  ],
  _ListingTheme.family: [
    'This home offers generous space for small groups and families looking for comfort and convenience.',
    'Designed for longer, easygoing stays with room to spread out and relax together.',
    'With multiple sleeping areas and shared spaces, this stay is built for family routines and group comfort.',
    'A practical home base with flexible space, ideal for family holidays and group trips.',
  ],
  _ListingTheme.boutique: [
    'Curated interiors and thoughtful details create a polished boutique-style experience.',
    'An elevated stay with refined decor, central access, and a welcoming atmosphere.',
    'Distinctive design touches and premium finishes deliver a memorable, boutique-inspired stay.',
    'Tailored decor and well-considered comfort offer a refined city escape with personality.',
  ],
  _ListingTheme.coastal: [
    'Breezy interiors and a holiday vibe make this an ideal base for a coastal break.',
    'A sun-filled retreat designed for laid-back mornings and relaxed evenings.',
    'Steps from coastal scenery, this stay pairs relaxed living with bright, beachy interiors.',
    'Ocean air, open spaces, and easy access to the water create a true getaway atmosphere.',
  ],
};

const Map<_ListingTheme, List<String>> _kThemeDescriptionEnds = {
  _ListingTheme.urban: [
    'Great for digital nomads, couples, or short city breaks.',
    'Ideal for work trips and weekend escapes alike.',
    'Close to dining, transit, and nightlife while still feeling private and comfortable.',
    'A smart choice for guests who want convenience, style, and easy mobility.',
  ],
  _ListingTheme.cozy: [
    'A great pick for couples and solo travelers seeking a restful stay.',
    'Best for guests who value comfort, privacy, and a calm setting.',
    'Perfect for reading days, nature walks, and slow mornings with coffee.',
    'Ideal for travelers looking for serenity, warmth, and a homey atmosphere.',
  ],
  _ListingTheme.family: [
    'Perfect for family trips, friend groups, and longer visits.',
    'A practical, comfortable choice for guests who need extra room.',
    'Well-suited for shared meals, flexible sleeping arrangements, and longer stays.',
    'A dependable option for groups wanting space, comfort, and easy logistics.',
  ],
  _ListingTheme.boutique: [
    'Best for travelers who appreciate design, location, and convenience.',
    'Ideal for stylish city stays with hotel-like comfort.',
    'Excellent for couples or professionals seeking a premium, design-led stay.',
    'A standout pick for guests who enjoy aesthetics and elevated comfort.',
  ],
  _ListingTheme.coastal: [
    'Perfect for beach days, sunset dinners, and slow mornings.',
    'An easy choice for guests chasing ocean air and relaxed evenings.',
    'Great for guests who want a mix of seaside adventure and laid-back comfort.',
    'Best enjoyed with beach walks, open-air dining, and sunset views.',
  ],
};

const Map<_ListingTheme, List<String>> _kThemeImageUrls = {
  _ListingTheme.urban: [
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1464890100898-a385f744067f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560440021-33f9b867899d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1630699144867-37acec97df5a?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600607687644-c7171b42498f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600566752355-35792bedcfea?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1501183638710-841dd1904471?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600121848594-d8644e57abab?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600494603989-9650cf6ddd3d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560184897-ae75f418493e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1585412727339-54e4bae3bbf9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.cozy: [
    'https://images.unsplash.com/photo-1449158743715-0a90ebb6d2d8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1470246973918-29a93221c455?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1459535653751-d571815e906b?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1472224371017-08207f84aaae?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1430285561322-7808604715df?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1518732714860-b62714ce0c59?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1587061949409-02df41d5e562?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1542718610-a1d656d1884c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1595521624992-48a59aef95e3?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1564078516393-cf04bd966897?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1588880331179-bc9b93a8cb5e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1520608421741-68228b76b6df?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1543965170-4c01a586684e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1521782462922-9318be1cfd04?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1510627489930-0c1b0bfb6785?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1517495306984-f84210f9daa8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1504615755583-2916b52192a3?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1553444836-bc6c8d340ba7?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.family: [
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1572120360610-d971b9d7767c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb3?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1613545325268-9265e1609167?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600563438938-a9a27216b4f5?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600573472550-8090b5e0745e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1523217582562-09d0def993a6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585153490-76fb20a32601?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1575517111478-7f6afd0973db?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600585152915-d208bec867a1?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1560448075-bb485b067938?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600047508006-aa8640f8e4ce?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.boutique: [
    'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1444201983204-c43cbd584d93?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1429170052398-05c242fdb399?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1559599746-8823b38544c6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1590381105924-c72589b9ef3f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1551918120-9739cb430c6d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600210491892-03d54c0aaf87?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1587874522487-fe10e954d035?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1584132915807-fd1f5fbc078f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1600011689032-8b628b8a8747?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
  _ListingTheme.coastal: [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1498503182468-3b51cbb6cb24?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1505881502353-a1986add3762?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1468413253725-0d5181091126?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1520454974749-611b7248ffdb?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1537956965359-7573183d1f57?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1544550581-5f7ceaf7f992?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1602002418816-5c0aeef426aa?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1545579133-99bb5ab189bd?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1586375300773-8384e3e4916f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1520483601560-389dff434fdf?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1559599238-308793637427?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1562245376-3f9dae9f0e73?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1596436889106-be35e843f974?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1584132905271-512c958d674a?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1501426026826-31c667bdf23d?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1590523741831-ab7e8b8f9c7f?auto=format&fit=crop&w=1200&h=800&q=80',
    'https://images.unsplash.com/photo-1551918120-9739cb430c6d?auto=format&fit=crop&w=1200&h=800&q=80',
  ],
};

const List<({String city, double latitude, double longitude})>
_kListingSeedPoints = [
  (city: 'New York', latitude: 40.7128, longitude: -74.0060),
  (city: 'Los Angeles', latitude: 34.0522, longitude: -118.2437),
  (city: 'Chicago', latitude: 41.8781, longitude: -87.6298),
  (city: 'Seattle', latitude: 47.6062, longitude: -122.3321),
  (city: 'Miami', latitude: 25.7617, longitude: -80.1918),
  (city: 'Toronto', latitude: 43.6532, longitude: -79.3832),
  (city: 'Montreal', latitude: 45.5017, longitude: -73.5673),
  (city: 'Mexico City', latitude: 19.4326, longitude: -99.1332),
  (city: 'Guadalajara', latitude: 20.6597, longitude: -103.3496),
  (city: 'Bogota', latitude: 4.7110, longitude: -74.0721),
  (city: 'Medellin', latitude: 6.2442, longitude: -75.5812),
  (city: 'Lima', latitude: -12.0464, longitude: -77.0428),
  (city: 'Santiago', latitude: -33.4489, longitude: -70.6693),
  (city: 'Sao Paulo', latitude: -23.5505, longitude: -46.6333),
  (city: 'Rio de Janeiro', latitude: -22.9068, longitude: -43.1729),
  (city: 'Buenos Aires', latitude: -34.6037, longitude: -58.3816),
  (city: 'Montevideo', latitude: -34.9011, longitude: -56.1645),
  (city: 'London', latitude: 51.5074, longitude: -0.1278),
  (city: 'Manchester', latitude: 53.4808, longitude: -2.2426),
  (city: 'Paris', latitude: 48.8566, longitude: 2.3522),
  (city: 'Lyon', latitude: 45.7640, longitude: 4.8357),
  (city: 'Berlin', latitude: 52.5200, longitude: 13.4050),
  (city: 'Munich', latitude: 48.1351, longitude: 11.5820),
  (city: 'Amsterdam', latitude: 52.3676, longitude: 4.9041),
  (city: 'Brussels', latitude: 50.8503, longitude: 4.3517),
  (city: 'Madrid', latitude: 40.4168, longitude: -3.7038),
  (city: 'Barcelona', latitude: 41.3851, longitude: 2.1734),
  (city: 'Lisbon', latitude: 38.7223, longitude: -9.1393),
  (city: 'Porto', latitude: 41.1579, longitude: -8.6291),
  (city: 'Rome', latitude: 41.9028, longitude: 12.4964),
  (city: 'Milan', latitude: 45.4642, longitude: 9.1900),
  (city: 'Stockholm', latitude: 59.3293, longitude: 18.0686),
  (city: 'Copenhagen', latitude: 55.6761, longitude: 12.5683),
  (city: 'Oslo', latitude: 59.9139, longitude: 10.7522),
  (city: 'Helsinki', latitude: 60.1699, longitude: 24.9384),
  (city: 'Warsaw', latitude: 52.2297, longitude: 21.0122),
  (city: 'Prague', latitude: 50.0755, longitude: 14.4378),
  (city: 'Budapest', latitude: 47.4979, longitude: 19.0402),
  (city: 'Vienna', latitude: 48.2082, longitude: 16.3738),
  (city: 'Frankfurt', latitude: 50.1109, longitude: 8.6821),
  (city: 'Zurich', latitude: 47.3769, longitude: 8.5417),
  (city: 'Geneva', latitude: 46.2044, longitude: 6.1432),
  (city: 'Dublin', latitude: 53.3498, longitude: -6.2603),
  (city: 'Reykjavik', latitude: 64.1466, longitude: -21.9426),
  (city: 'Athens', latitude: 37.9838, longitude: 23.7275),
  (city: 'Istanbul', latitude: 41.0082, longitude: 28.9784),
  (city: 'Bucharest', latitude: 44.4268, longitude: 26.1025),
  (city: 'Sofia', latitude: 42.6977, longitude: 23.3219),
  (city: 'Belgrade', latitude: 44.7866, longitude: 20.4489),
  (city: 'Zagreb', latitude: 45.8150, longitude: 15.9819),
  (city: 'Ljubljana', latitude: 46.0569, longitude: 14.5058),
  (city: 'Sarajevo', latitude: 43.8563, longitude: 18.4131),
  (city: 'Tirana', latitude: 41.3275, longitude: 19.8187),
  (city: 'Nicosia', latitude: 35.1856, longitude: 33.3823),
  (city: 'Cairo', latitude: 30.0444, longitude: 31.2357),
  (city: 'Alexandria', latitude: 31.2001, longitude: 29.9187),
  (city: 'Casablanca', latitude: 33.5731, longitude: -7.5898),
  (city: 'Tunis', latitude: 36.8065, longitude: 10.1815),
  (city: 'Accra', latitude: 5.6037, longitude: -0.1870),
  (city: 'Lagos', latitude: 6.5244, longitude: 3.3792),
  (city: 'Abuja', latitude: 9.0765, longitude: 7.3986),
  (city: 'Nairobi', latitude: -1.2921, longitude: 36.8219),
  (city: 'Addis Ababa', latitude: 9.0054, longitude: 38.7636),
  (city: 'Johannesburg', latitude: -26.2041, longitude: 28.0473),
  (city: 'Cape Town', latitude: -33.9249, longitude: 18.4241),
  (city: 'Dakar', latitude: 14.7167, longitude: -17.4677),
  (city: 'Riyadh', latitude: 24.7136, longitude: 46.6753),
  (city: 'Dubai', latitude: 25.2048, longitude: 55.2708),
  (city: 'Doha', latitude: 25.2854, longitude: 51.5310),
  (city: 'Tel Aviv', latitude: 32.0853, longitude: 34.7818),
  (city: 'Beirut', latitude: 33.8938, longitude: 35.5018),
  (city: 'Tehran', latitude: 35.6892, longitude: 51.3890),
  (city: 'Baghdad', latitude: 33.3152, longitude: 44.3661),
  (city: 'New Delhi', latitude: 28.6139, longitude: 77.2090),
  (city: 'Mumbai', latitude: 19.0760, longitude: 72.8777),
  (city: 'Bengaluru', latitude: 12.9716, longitude: 77.5946),
  (city: 'Chennai', latitude: 13.0827, longitude: 80.2707),
  (city: 'Kolkata', latitude: 22.5726, longitude: 88.3639),
  (city: 'Dhaka', latitude: 23.8103, longitude: 90.4125),
  (city: 'Karachi', latitude: 24.8607, longitude: 67.0011),
  (city: 'Lahore', latitude: 31.5204, longitude: 74.3587),
  (city: 'Kathmandu', latitude: 27.7172, longitude: 85.3240),
  (city: 'Colombo', latitude: 6.9271, longitude: 79.8612),
  (city: 'Bangkok', latitude: 13.7563, longitude: 100.5018),
  (city: 'Ho Chi Minh City', latitude: 10.8231, longitude: 106.6297),
  (city: 'Hanoi', latitude: 21.0278, longitude: 105.8342),
  (city: 'Kuala Lumpur', latitude: 3.1390, longitude: 101.6869),
  (city: 'Singapore', latitude: 1.3521, longitude: 103.8198),
  (city: 'Jakarta', latitude: -6.2088, longitude: 106.8456),
  (city: 'Denpasar', latitude: -8.6500, longitude: 115.2167),
  (city: 'Manila', latitude: 14.5995, longitude: 120.9842),
  (city: 'Davao', latitude: 7.1907, longitude: 125.4553),
  (city: 'Taipei', latitude: 25.0330, longitude: 121.5654),
  (city: 'Hong Kong', latitude: 22.3193, longitude: 114.1694),
  (city: 'Macau', latitude: 22.1987, longitude: 113.5439),
  (city: 'Shanghai', latitude: 31.2304, longitude: 121.4737),
  (city: 'Beijing', latitude: 39.9042, longitude: 116.4074),
  (city: 'Guangzhou', latitude: 23.1291, longitude: 113.2644),
  (city: 'Chengdu', latitude: 30.5728, longitude: 104.0668),
  (city: 'Tokyo', latitude: 35.6895, longitude: 139.6917),
  (city: 'Osaka', latitude: 34.6937, longitude: 135.5023),
  (city: 'Sapporo', latitude: 43.0621, longitude: 141.3544),
  (city: 'Seoul', latitude: 37.5665, longitude: 126.9780),
  (city: 'Busan', latitude: 35.1796, longitude: 129.0756),
  (city: 'Perth', latitude: -31.9505, longitude: 115.8605),
  (city: 'Sydney', latitude: -33.8688, longitude: 151.2093),
  (city: 'Melbourne', latitude: -37.8136, longitude: 144.9631),
  (city: 'Brisbane', latitude: -27.4698, longitude: 153.0251),
  (city: 'Auckland', latitude: -36.8485, longitude: 174.7633),
  (city: 'Wellington', latitude: -41.2866, longitude: 174.7756),
];

String _buildListingTitle(Random r, _ListingTheme theme) {
  final prefixes = _kThemeTitlePrefixes[theme]!;
  final nouns = _kThemeTitleNouns[theme]!;
  return '${prefixes[r.nextInt(prefixes.length)]} ${nouns[r.nextInt(nouns.length)]}';
}

String _buildListingDescription(Random r, _ListingTheme theme) {
  final starts = _kThemeDescriptionStarts[theme]!;
  final ends = _kThemeDescriptionEnds[theme]!;
  return '${starts[r.nextInt(starts.length)]} ${ends[r.nextInt(ends.length)]}';
}

Amenities _buildListingAmenities(Random r) {
  final amenities = Amenities();
  final appliers = <void Function(Amenities)>[
    (a) => a['airconditioning'] = true,
    (a) => a['allows_pets'] = true,
    (a) => a['bathtub'] = 1,
    (a) => a['beds'] = 1 + r.nextInt(4),
    (a) => a['bedrooms'] = 1 + r.nextInt(3),
    (a) => a['tv'] = 1,
    (a) => a['tumble_dryer'] = true,
    (a) => a['washer'] = true,
    (a) => a['elevator'] = true,
    (a) => a['free_parking'] = true,
    (a) => a['gym'] = true,
    (a) => a['heating'] = true,
    (a) => a['wireless_internet'] = true,
    (a) => a['kitchen'] = true,
    (a) => a['pool'] = true,
    (a) => a['breakfast'] = true,
    (a) => a['fireplace'] = true,
    (a) => a['essentials'] = true,
    (a) => a['oven'] = true,
    (a) => a['bbq'] = true,
    (a) => a['balcony'] = true,
    (a) => a['patio'] = true,
    (a) => a['dishwasher'] = true,
    (a) => a['refrigerator'] = true,
    (a) => a['garden_or_backyard'] = true,
    (a) => a['microwave'] = true,
    (a) => a['coffee_maker'] = true,
    (a) => a['stove'] = true,
    (a) => a['beachfront'] = true,
    (a) => a['hot_water'] = true,
    (a) => a['lake_access'] = true,
  ];

  final shuffledIndexes = List<int>.generate(appliers.length, (i) => i)
    ..shuffle(r);
  final count = 1 + r.nextInt(min(10, appliers.length));

  for (var i = 0; i < count; i++) {
    appliers[shuffledIndexes[i]](amenities);
  }

  return amenities;
}

/// Atomic factory for creating individual, signed domain entities.
///
/// **No I/O, no network, no chain.**
///
/// Every method produces a single, fully-signed entity with sensible
/// defaults for every field.  Pass optional overrides to customise only
/// the fields you care about.
///
/// Use directly in unit tests:
/// ```dart
/// final f = EntityFactory();
/// final listing = f.listing(title: 'Beach House', requiresEscrow: true);
/// final profile = await f.profile(displayName: 'Alice');
/// final reservation = f.reservation(listing: listing);
/// ```
///
/// The seed pipeline batch stages (`build_listings.dart`, etc.) delegate
/// to the same methods, passing an RNG and pipeline-specific values.
class EntityFactory {
  /// Optional [SeedContext] for deterministic timestamps and key derivation.
  /// When null, factory methods use sane static defaults.
  final SeedContext? ctx;

  /// Default signer for entities when no [KeyPair] is explicitly provided.
  final KeyPair _defaultSigner;

  /// Counter for generating unique d-tags when none is provided.
  int _dTagCounter = 0;

  EntityFactory({this.ctx, KeyPair? defaultSigner})
    : _defaultSigner = defaultSigner ?? MockKeys.hoster;

  /// Generates a unique d-tag suffix.
  String _nextDTag(String prefix) => '$prefix-${++_dTagCounter}';

  int _defaultCreatedAt() =>
      ctx?.timestampDaysAfter(_dTagCounter) ??
      (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000);

  // ═══════════════════════════════════════════════════════════════════════════
  // Listing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [Listing].
  ///
  /// All parameters are optional — unspecified fields receive sensible
  /// defaults.  Pass [rng] for seeded randomness (used by the pipeline);
  /// without it, deterministic static defaults are used.
  ///
  /// When [seed] is provided the factory derives the listing's coordinates,
  /// H3 geo-tags, listing type, theme, title, description, images, and
  /// amenities automatically.  Explicit parameter values always take
  /// precedence over seed-derived ones.
  Listing listing({
    KeyPair? signer,
    String? dTag,
    String? title,
    String? description,
    List<Price>? price,
    int? priceSats,
    String? location,
    int? quantity,
    ListingType? type,
    List<String>? images,
    Amenities? amenities,
    bool? requiresEscrow,
    bool? allowSelfSignedReservation,
    bool? allowBarter,
    int? minStay,
    String? checkIn,
    String? checkOut,
    bool? active,
    List<CancellationPolicy>? cancellationPolicy,
    List<List<String>>? extraTags,
    int? createdAt,
    Random? rng,

    /// When supplied, derives coordinates, geo-tags, type, theme, title,
    /// description, images, and amenities deterministically.
    int? seed,
  }) {
    final kp = signer ?? _defaultSigner;
    final r = rng ?? Random(seed != null ? seed * 10000 : 42);
    final resolvedDTag = dTag ?? _nextDTag('listing');
    final resolvedType =
        type ?? ListingType.values[r.nextInt(ListingType.values.length)];
    final dailySats = priceSats ?? (50 * 1000 + r.nextInt(200 * 1000));

    // ── Seed-derived attributes ─────────────────────────────────────────────
    String? seedLocation;
    String? seedTitle;
    String? seedDescription;
    List<String>? seedImages;
    Amenities? seedAmenities;
    List<List<String>> seedGeoTags = const [];

    if (seed != null) {
      final base = _kListingSeedPoints[seed % _kListingSeedPoints.length];
      const jitterDegrees = 0.7;
      final latJitter = (r.nextDouble() - 0.5) * jitterDegrees;
      final lonJitter = (r.nextDouble() - 0.5) * jitterDegrees;
      final latitude = (base.latitude + latJitter)
          .clamp(-85.0, 85.0)
          .toDouble();
      var longitude = base.longitude + lonJitter;
      if (longitude > 180) longitude -= 360;
      if (longitude < -180) longitude += 360;

      try {
        final h3Tags = H3Engine.bundled().hierarchy.hierarchyForPoint(
          latitude: latitude,
          longitude: longitude,
        );
        seedGeoTags = List<List<String>>.generate(
          h3Tags.length,
          (i) => ['g', h3Tags[i]],
        );
      } on UnsupportedError {
        // H3 native library unavailable (e.g. web/JS runtime).
        // Geo tags are search metadata; listings work without them.
      }
      seedLocation = base.city;

      final theme = _kThemeForListingType[resolvedType] ?? _ListingTheme.urban;
      seedTitle = _buildListingTitle(r, theme);
      seedDescription = _buildListingDescription(r, theme);

      final ctxSeed = ctx?.seed ?? 0;
      final imageCount = 1 + r.nextInt(6);
      seedImages = List<String>.generate(imageCount, (imageIndex) {
        final lock = ctxSeed * 100000 + seed * 10 + imageIndex;
        final options = _kThemeImageUrls[theme] ?? const <String>[];
        if (options.isEmpty) {
          return 'https://picsum.photos/seed/hostr-fallback-$lock/1200/800';
        }
        return options[lock % options.length];
      });

      seedAmenities = _buildListingAmenities(r);
    }

    final mergedExtraTags = <List<String>>[
      ...seedGeoTags,
      ...(extraTags ?? const []),
    ];

    return Listing.create(
      pubKey: kp.publicKey,
      dTag: resolvedDTag,
      title: title ?? seedTitle ?? 'Test Listing $resolvedDTag',
      description:
          description ?? seedDescription ?? 'A comfortable place to stay.',
      price:
          price ??
          [
            Price(
              amount: DenominatedAmount(
                value: BigInt.from(dailySats),
                denomination: 'BTC',
                decimals: 8,
              ),
              frequency: Frequency.daily,
            ),
          ],
      location: location ?? seedLocation ?? 'Test City',
      quantity: quantity ?? 1,
      type: resolvedType,
      images:
          images ??
          seedImages ??
          ['https://picsum.photos/seed/$resolvedDTag/1200/800'],
      amenities: amenities ?? seedAmenities ?? Amenities(),
      requiresEscrow: requiresEscrow ?? false,
      allowSelfSignedReservation: allowSelfSignedReservation ?? false,
      allowBarter: allowBarter ?? false,
      minStay: minStay ?? 1,
      checkIn: checkIn ?? '15:0',
      checkOut: checkOut ?? '11:0',
      active: active ?? true,
      cancellationPolicy: cancellationPolicy ?? const [],
      extraTags: mergedExtraTags,
      createdAt: createdAt ?? _defaultCreatedAt(),
    ).signAs(kp, Listing.fromNostrEvent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Profile
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [ProfileMetadata].
  ///
  /// If the user [hasEvm] is true, an EVM address tag is derived and added.
  Future<ProfileMetadata> profile({
    KeyPair? signer,
    String? name,
    String? displayName,
    String? about,
    String? lud16,
    String? nip05,
    String? picture,
    bool hasEvm = false,
    int? createdAt,

    /// When supplied, derives a deterministic name and portrait from the
    /// [_kSeedFirstNames] / [_kSeedLastNames] lists and randomuser.me photos.
    /// Explicit [name], [displayName], and [picture] overrides still take
    /// precedence over the seed-derived values.
    int? seed,

    /// When [seed] is set, used to generate a role-appropriate [about] blurb.
    /// Has no effect when [about] is supplied explicitly.
    bool isHost = false,
  }) async {
    final kp = signer ?? _defaultSigner;
    final ({String fullName, String displayName, String picture})? identity;
    if (seed != null) {
      final firstName = _kSeedFirstNames[seed % _kSeedFirstNames.length];
      final lastName = _kSeedLastNames[(seed * 7) % _kSeedLastNames.length];
      final photoIndex = (seed * 11 % 99) + 1;
      final pic =
          'https://randomuser.me/api/portraits/${seed.isEven ? 'women' : 'men'}/$photoIndex.jpg';
      identity = (
        fullName: '$firstName $lastName',
        displayName: firstName,
        picture: pic,
      );
    } else {
      identity = null;
    }
    final resolvedDisplayName =
        displayName ?? identity?.displayName ?? 'User${_dTagCounter + 1}';
    final resolvedName = name ?? identity?.fullName ?? resolvedDisplayName;

    String defaultAbout() {
      if (identity == null) return '$resolvedDisplayName is a test user.';
      return isHost
          ? '${identity.displayName} hosts thoughtfully designed stays and has welcomed guests since ${2015 + (seed! % 9)}.'
          : '${identity.displayName} is an avid traveler who loves local neighborhoods, great coffee, and easy check-ins.';
    }

    final metadata = Metadata(
      pubKey: kp.publicKey,
      name: resolvedName,
      displayName: resolvedDisplayName,
      about: about ?? defaultAbout(),
      lud16: lud16 ?? '${resolvedDisplayName.toLowerCase()}@lnbits.test',
      nip05: nip05 ?? '${resolvedDisplayName.toLowerCase()}@test',
      picture:
          picture ??
          identity?.picture ??
          'https://picsum.photos/seed/$resolvedName/200/200',
    ).toEvent();

    final tags = List<List<String>>.from(metadata.tags);
    if (hasEvm) {
      final evmKey = await deriveEvmKey(kp.privateKey!);
      tags.add(['i', 'evm:address', evmKey.address.eip55With0x]);
    }

    final event = Nip01Event(
      pubKey: metadata.pubKey,
      kind: metadata.kind,
      tags: tags,
      content: metadata.content,
      createdAt: createdAt ?? _defaultCreatedAt(),
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: kp.privateKey!,
      event: event,
    );

    return ProfileMetadata.fromNostrEvent(signed);
  }

  /// Build the static escrow service profile (Hostr).
  Future<ProfileMetadata> escrowProfile({
    KeyPair? signer,
    int? createdAt,
  }) async {
    final kp = signer ?? MockKeys.escrow;

    final metadata = Metadata(
      pubKey: kp.publicKey,
      name: 'Hostr',
      displayName: 'Hostr',
      about: 'Provides cheap escrow services for nostr',
      nip05: 'escrow@hostr.development',
      picture:
          'https://wp.decrypt.co/wp-content/uploads/2019/03/bitcoin-logo-bitboy.png',
    ).toEvent();

    final escrowEvmKey = await deriveEvmKey(kp.privateKey!);

    final tags = List<List<String>>.from(metadata.tags)
      ..add(['i', 'evm:address', escrowEvmKey.address.eip55With0x]);

    final event = Nip01Event(
      pubKey: metadata.pubKey,
      kind: metadata.kind,
      tags: tags,
      content: metadata.content,
      createdAt:
          createdAt ??
          (ctx != null
              ? ctx!.baseDate.millisecondsSinceEpoch ~/ 1000
              : _defaultCreatedAt()),
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: kp.privateKey!,
      event: event,
    );

    return ProfileMetadata.fromNostrEvent(signed);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Escrow Service
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build signed [EscrowService] events.
  ///
  /// By default uses [MOCK_ESCROWS] from the stubs package.
  Future<List<EscrowService>> escrowServices({
    String contractAddress = '0x0000000000000000000000000000000000000000',
    String? multiEscrowBytecodeHash,
  }) async {
    final escrowEvmKey = await deriveEvmKey(MockKeys.escrow.privateKey!);
    return MOCK_ESCROWS(
      contractAddress: contractAddress,
      evmAddress: escrowEvmKey.address.eip55With0x,
      byteCodeHash: multiEscrowBytecodeHash ?? '0xMockMultiEscrowBytecodeHash',
    ).toList(growable: false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Escrow Method
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [EscrowMethod] for a user.
  Future<EscrowMethod> escrowMethod({
    required KeyPair signer,
    String? multiEscrowBytecodeHash,
    int chainId = 412346,
    String? tbtcAddress,
    String? usdtAddress,
    int? createdAt,
  }) async {
    // Rootstock chains use native RBTC as the BTC settlement token.
    // All other chains (Arbitrum, etc.) use a wrapped ERC-20 like tBTC.
    final isRootstock = ChainIds.values
        .where((c) => c.name.toLowerCase().contains('rootstock'))
        .any((c) => c.value == chainId);

    final acceptedPaymentForms = [
      if (isRootstock)
        AcceptedPaymentForm(
          denomination: 'BTC',
          tokenTagId: Token.native(chainId).tagId,
        ),
      if (tbtcAddress != null && tbtcAddress.isNotEmpty)
        AcceptedPaymentForm(
          denomination: 'BTC',
          tokenTagId: Token(
            chainId: chainId,
            address: tbtcAddress,
            decimals: 0,
          ).tagId,
        ),
      if (usdtAddress != null && usdtAddress.isNotEmpty)
        AcceptedPaymentForm(
          denomination: 'USD',
          tokenTagId: Token(
            chainId: chainId,
            address: usdtAddress,
            decimals: 0,
          ).tagId,
        ),
    ];

    final resolvedHash =
        multiEscrowBytecodeHash ?? '0xMockMultiEscrowBytecodeHash';
    final resolvedCreatedAt =
        createdAt ??
        (ctx != null
            ? ctx!.baseDate.millisecondsSinceEpoch ~/ 1000
            : _defaultCreatedAt());

    final list =
        Nip51List(
            pubKey: signer.publicKey,
            createdAt: resolvedCreatedAt,
            kind: kNostrKindEscrowMethod,
            elements: [],
          )
          ..addElement('p', MockKeys.escrow.publicKey, false)
          ..addElement('c', resolvedHash, false);

    final listEvent = await list.toEvent(
      CoinlibEventSigner(
        privateKey: signer.privateKey,
        publicKey: signer.publicKey,
      ),
    );

    final completeTags = [
      ...listEvent.tags,
      for (final form in acceptedPaymentForms) form.toTag(),
    ];

    final completeEvent = Nip01Event(
      pubKey: listEvent.pubKey,
      kind: listEvent.kind,
      tags: completeTags,
      content: listEvent.content,
      createdAt: listEvent.createdAt,
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: signer.privateKey!,
      event: completeEvent,
    );
    return EscrowMethod.fromNostrEvent(signed);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reservation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [Reservation].
  ///
  /// Derives a tweaked key pair from [guestKeyPair] when [stage] is
  /// [ReservationStage.negotiate] (matching production behaviour).
  ///
  /// For commit-stage reservations, pass [signerOverride] to control
  /// whether the host or guest signs.  When both [dTag] *and*
  /// [signerOverride] are supplied the expensive key-derivation /
  /// tweak step is skipped entirely — useful when the caller already
  /// knows the trade ID and signer (e.g. the outcome stage).
  Future<Reservation> reservation({
    KeyPair? guestKeyPair,
    String? dTag,
    required Listing listing,
    DateTime? start,
    DateTime? end,
    ReservationStage stage = ReservationStage.negotiate,
    int? quantity,
    DenominatedAmount? amount,
    String? recipient,
    PaymentProof? proof,
    KeyPair? signerOverride,
    ReservationTweakMaterial? tweakMaterial,
    Map<String, String>? signatures,
    List<List<String>> extraTags = const [],
    List<PTag>? pTags,
    int? createdAt,
    int? accountIndex,
  }) async {
    final guest = guestKeyPair ?? _defaultSigner;
    final acctIdx = accountIndex ?? 0;

    final resolvedStart =
        start ?? DateTime.now().toUtc().add(const Duration(days: 7));
    final resolvedEnd = end ?? resolvedStart.add(const Duration(days: 3));

    // ── Fast path: commit-stage with pre-computed signer ──────────────
    // No key derivation needed — the caller supplies everything.
    if (dTag != null && signerOverride != null) {
      // Auto-compute pTags when not provided:
      // - If the signer is NOT the seller (i.e. buyer), p-tag the seller.
      // - If the signer IS the seller, no auto-compute — caller must supply.
      final isSeller = signerOverride.publicKey == listing.pubKey;
      final resolvedPTags =
          pTags ??
          <PTag>[
            PTag.seller(listing.pubKey),
            if (!isSeller) PTag.buyer(signerOverride.publicKey),
          ];
      return Reservation.create(
        pubKey: signerOverride.publicKey,
        dTag: dTag,
        listingAnchor: listing.anchor!,
        start: resolvedStart,
        end: resolvedEnd,
        stage: stage,
        quantity: quantity ?? 1,
        amount: amount ?? listing.cost(start: resolvedStart, end: resolvedEnd),
        recipient: recipient,
        tweakMaterial: tweakMaterial,
        proof: proof,
        signatures: signatures ?? const {},
        threadAnchor: stage != ReservationStage.negotiate ? dTag : null,
        pTags: resolvedPTags,
        extraTags: extraTags,
        createdAt: createdAt ?? _defaultCreatedAt(),
      ).signAs(signerOverride, Reservation.fromNostrEvent);
    }

    // ── Standard path: derive trade keys ──────────────────────────────
    final tradeId =
        dTag ?? await deriveTradeId(guest.privateKey!, accountIndex: acctIdx);
    final tradeSalt = await deriveTradeSalt(
      guest.privateKey!,
      accountIndex: acctIdx,
    );

    final tweakedGuestKey = tweakKeyPair(
      privateKey: guest.privateKey!,
      salt: tradeSalt,
    );

    final resolvedSigner =
        signerOverride ??
        (stage == ReservationStage.negotiate ? tweakedGuestKey.keyPair : guest);

    final resolvedTweakMaterial =
        tweakMaterial ??
        ReservationTweakMaterial(
          salt: tradeSalt,
          parity: tweakedGuestKey.parity,
        );

    return Reservation.create(
      pubKey: stage == ReservationStage.negotiate
          ? tweakedGuestKey.publicKey
          : resolvedSigner.publicKey,
      dTag: tradeId,
      listingAnchor: listing.anchor!,
      start: resolvedStart,
      end: resolvedEnd,
      stage: stage,
      quantity: quantity ?? 1,
      amount: amount ?? listing.cost(start: resolvedStart, end: resolvedEnd),
      recipient: recipient ?? tweakedGuestKey.publicKey,
      tweakMaterial: resolvedTweakMaterial,
      proof: proof,
      threadAnchor: stage != ReservationStage.negotiate ? tradeId : null,
      pTags:
          pTags ??
          [
            PTag.seller(listing.pubKey),
            PTag.buyer(
              stage == ReservationStage.negotiate
                  ? tweakedGuestKey.publicKey
                  : resolvedSigner.publicKey,
            ),
          ],
      extraTags: extraTags,
      createdAt: createdAt ?? _defaultCreatedAt(),
    ).signAs(resolvedSigner, Reservation.fromNostrEvent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Review
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [Review].
  Review review({
    KeyPair? signer,
    required String reservationAnchor,
    required String listingAnchor,
    required ReservationTweakMaterial tweakMaterial,
    String? dTag,
    int? rating,
    String? content,
    bool paidViaEscrow = false,
    int? createdAt,
    Random? rng,
  }) {
    final kp = signer ?? _defaultSigner;
    final r = rng ?? Random(42);
    final resolvedRating = rating ?? _pickReviewRating(r);
    final resolvedContent =
        content ??
        _buildReviewContent(
          rng: r,
          rating: resolvedRating,
          paidViaEscrow: paidViaEscrow,
        );

    return Review(
      pubKey: kp.publicKey,
      tags: ReviewTags([
        [kReservationRefTag, reservationAnchor],
        [kListingRefTag, listingAnchor],
        ['d', dTag ?? _nextDTag('review')],
      ]),
      createdAt: createdAt ?? _defaultCreatedAt(),
      content: ReviewContent(
        rating: resolvedRating,
        content: resolvedContent,
        proof: ParticipationProof(tweakMaterial: tweakMaterial),
      ),
    ).signAs(kp, Review.fromNostrEvent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reservation Transition
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [ReservationTransition].
  ReservationTransition reservationTransition({
    required KeyPair signer,
    required String tradeId,
    required String eventId,
    required String listingAnchor,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    String? commitTermsHash,
    String? previousTransitionId,
    String? reason,
    int? createdAt,
  }) {
    return ReservationTransition(
      pubKey: signer.publicKey,
      createdAt: createdAt ?? _defaultCreatedAt(),
      tags: ReservationTransitionTags([
        ['t', tradeId],
        ['e', eventId],
        if (previousTransitionId != null) ['prev', previousTransitionId],
        [kListingRefTag, listingAnchor],
      ]),
      content: ReservationTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash,
        reason: reason,
      ),
    ).signAs(signer, ReservationTransition.fromNostrEvent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Escrow Service Selected
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single signed [EscrowServiceSelected] message.
  EscrowServiceSelected escrowServiceSelected({
    required KeyPair signer,
    required String listingAnchor,
    required String threadAnchor,
    required String hostPubKey,
    required EscrowService service,
    required EscrowMethod sellerMethods,
    String? dTag,
    int? createdAt,
  }) {
    return EscrowServiceSelected(
      pubKey: signer.publicKey,
      tags: EscrowServiceSelectedTags([
        [kListingRefTag, listingAnchor],
        [kThreadRefTag, threadAnchor],
        ['p', hostPubKey],
        ['d', dTag ?? _nextDTag('escrow-selected')],
      ]),
      createdAt: createdAt ?? _defaultCreatedAt(),
      content: EscrowServiceSelectedContent(
        service: service,
        sellerMethods: sellerMethods,
      ),
    ).signAs(signer, EscrowServiceSelected.fromNostrEvent);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Zap Receipt
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a deterministic zap receipt (kind 9735).
  Nip01Event zapReceipt({
    required KeyPair hostSigner,
    required KeyPair guestSigner,
    required Reservation request,
    required Listing listing,
    String? lnurl,
    int? threadIndex,
    int? createdAt,
  }) {
    final idx = threadIndex ?? _dTagCounter;
    final tradeId = request.getDtag() ?? 'unknown';
    final amountMsats =
        (request.amount?.value ?? BigInt.zero) * BigInt.from(1000);

    final zapRequest = Nip01Utils.signWithPrivateKey(
      privateKey: guestSigner.privateKey!,
      event: Nip01Event(
        pubKey: guestSigner.publicKey,
        kind: kNostrKindZapRequest,
        tags: [
          ['p', hostSigner.publicKey],
          ['amount', amountMsats.toString()],
          ['e', tradeId],
          ['l', listing.anchor!],
          if (lnurl != null) ['lnurl', lnurl],
        ],
        content: 'Seed zap request',
        createdAt: createdAt ?? _defaultCreatedAt(),
      ),
    );

    return Nip01Utils.signWithPrivateKey(
      privateKey: hostSigner.privateKey!,
      event: Nip01Event(
        pubKey: hostSigner.publicKey,
        kind: kNostrKindZapReceipt,
        tags: [
          ['bolt11', 'lnbc-seed-$idx'],
          ['preimage', 'seed-preimage-$idx'],
          ['amount', amountMsats.toString()],
          ['p', hostSigner.publicKey],
          ['P', guestSigner.publicKey],
          ['e', zapRequest.getEId()!],
          ['l', listing.anchor!],
          if (lnurl != null) ['lnurl', lnurl],
          [
            'description',
            Nip01EventModel.fromEntity(zapRequest).toJsonString(),
          ],
        ],
        content: 'Seed zap payment',
        createdAt: (createdAt ?? _defaultCreatedAt()) + 1,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Payment Proof
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build an escrow-based [PaymentProof].
  PaymentProof escrowPaymentProof({
    required ProfileMetadata hostProfile,
    required Listing listing,
    required String txHash,
    required EscrowService escrowService,
    required EscrowMethod hostsEscrowMethod,
  }) {
    return PaymentProof(
      hoster: hostProfile,
      listing: listing,
      zapProof: null,
      escrowProof: EscrowProof(
        txHash: txHash,
        escrowService: escrowService,
        hostsEscrowMethods: hostsEscrowMethod,
      ),
    );
  }

  /// Build a zap-based [PaymentProof].
  PaymentProof zapPaymentProof({
    required ProfileMetadata hostProfile,
    required Listing listing,
    Nip01Event? zapReceiptEvent,
  }) {
    return PaymentProof(
      hoster: hostProfile,
      listing: listing,
      zapProof: zapReceiptEvent != null
          ? ZapProof(receipt: Nip01EventModel.fromEntity(zapReceiptEvent))
          : null,
      escrowProof: null,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Review helpers (extracted from build_reviews.dart)
// ═════════════════════════════════════════════════════════════════════════════

int _pickReviewRating(Random rr) {
  final roll = rr.nextDouble();
  if (roll < 0.06) return 1;
  if (roll < 0.15) return 2;
  if (roll < 0.35) return 3;
  if (roll < 0.70) return 4;
  return 5;
}

String _buildReviewContent({
  required Random rng,
  required int rating,
  required bool paidViaEscrow,
}) {
  final clampedRating = rating.clamp(1, 5);
  final templates = _reviewTemplatesByRating[clampedRating]!;
  final paymentNotes = _reviewPaymentNotesByRating[clampedRating]!;
  final base = templates[rng.nextInt(templates.length)];
  final paymentNote = paymentNotes[rng.nextInt(paymentNotes.length)];
  final paymentKind = paidViaEscrow ? 'Escrow' : 'Zap';
  return '$base $paymentKind payment: $paymentNote';
}

const Map<int, List<String>> _reviewTemplatesByRating = {
  1: [
    'Unfortunately the stay did not match the listing photos and we had several issues during check-in.',
    'Communication was difficult and the space was not as clean as expected.',
    'This booking did not work out for us due to maintenance issues and poor responsiveness.',
    'The location was fine, but overall comfort and cleanliness were below expectations.',
  ],
  2: [
    'The place was acceptable for one night, but we ran into a few avoidable issues.',
    'Some parts of the stay were okay, but check-in and communication could be much better.',
    'Decent location, though the apartment needed better upkeep and clearer instructions.',
    'Not terrible, but the stay felt overpriced for the quality we received.',
  ],
  3: [
    'Solid stay overall with a convenient location, though there is room for improvement.',
    'The listing mostly matched expectations and we had a comfortable visit.',
    'Good value for a short trip, with a few minor issues that were manageable.',
    'A generally pleasant experience with straightforward check-in and decent amenities.',
  ],
  4: [
    'Very good stay with a clean space, easy check-in, and quick host communication.',
    'Great location and comfortable setup; we would happily book again.',
    'Everything went smoothly and the home felt welcoming throughout our trip.',
    'A really enjoyable stay with thoughtful touches and clear instructions.',
  ],
  5: [
    'Excellent stay from start to finish, exactly as described and beautifully prepared.',
    'Fantastic host and a wonderful space. One of our best booking experiences.',
    'Perfect for our trip: spotless, comfortable, and in an ideal location.',
    'Absolutely loved this place. Check-in was seamless and the stay exceeded expectations.',
  ],
};

const Map<int, List<String>> _reviewPaymentNotesByRating = {
  1: [
    'Payment worked, but it did not make up for the problems during the stay.',
    'Transaction was completed, but our hosting experience was disappointing.',
  ],
  2: [
    'Payment was straightforward, though the stay itself needed improvement.',
    'No payment issues, but the hosting experience felt inconsistent.',
  ],
  3: [
    'Payment and booking flow were smooth and uncomplicated.',
    'The payment process was easy and matched what we expected.',
  ],
  4: [
    'Payment was smooth and the overall booking experience felt reliable.',
    'Everything from payment to check-out was clear and easy.',
  ],
  5: [
    'Flawless booking and payment experience from start to finish.',
    'Payment was instant and the whole process felt premium and stress-free.',
  ],
};

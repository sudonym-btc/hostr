import 'package:dart_nostr/dart_nostr.dart';

class MockKeys {
  static final NostrKeyPairs hoster = NostrKeyPairs(
      private:
          'e7a262c5d380844d24526b0e1c7bfd895a779a4315ded94257d344b648563b02');
  static final NostrKeyPairs guest = NostrKeyPairs(
      private:
          '1714ff69753ae70a91d6e1989cb1ee859b10e98239c61d28bcb0577d8d626b74');
  static final NostrKeyPairs sccrow = NostrKeyPairs(
      private:
          'a9cbe715ebaeb852bf7cc3d35f4a81b9a58f16705e4bb8434aa453093e612206');
  static final NostrKeyPairs reviewer = NostrKeyPairs(
      private:
          '5d12e1c259280034770db6dfe14609fca9c10b97c7ce79f0a32cd80b118ce9c3');
}

void main() {
  NostrKeyPairs keys = NostrKeyPairs.generate();
  print(keys.private);
}

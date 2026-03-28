@Tags(['unit'])
library;

import 'package:hostr_sdk/util/token_amount_ext.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

// ── Shared tokens ──────────────────────────────────────────────────────

/// Native RBTC token (18 decimals, chainId 30).
final _rbtc = Token.native(30);

/// BTC Lightning token (8 decimals).
final _btc = Token(chainId: 0, address: 'BTC', decimals: 8);

/// USDT-style token (6 decimals).
final _usdt = Token(
  chainId: 30,
  address: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
  decimals: 6,
);

void main() {
  group('TokenAmount — constructors', () {
    group('fromInt', () {
      test('TokenUnit.wei on 18-decimal → identity (no scaling)', () {
        final amt = TokenAmount.fromInt(TokenUnit.wei, 12345, _rbtc);
        expect(amt.value, BigInt.from(12345));
        expect(amt.token, _rbtc);
      });

      test('TokenUnit.sat on 18-decimal → scales ×10^10', () {
        final amt = TokenAmount.fromInt(TokenUnit.sat, 1, _rbtc);
        // 1 sat = 10^10 wei for an 18-decimal token.
        expect(amt.value, BigInt.from(10).pow(10));
      });

      test('TokenUnit.sat on 8-decimal → identity', () {
        final amt = TokenAmount.fromInt(TokenUnit.sat, 500, _btc);
        expect(amt.value, BigInt.from(500));
      });

      test('TokenUnit.gwei on 18-decimal → scales ×10^9', () {
        final amt = TokenAmount.fromInt(TokenUnit.gwei, 2, _rbtc);
        expect(amt.value, BigInt.from(2) * BigInt.from(10).pow(9));
      });

      test('TokenUnit.sat on 6-decimal → truncates (divides by 10^2)', () {
        // sat = 8 decimals, token = 6 decimals → diff = -2 → divide by 100.
        final amt = TokenAmount.fromInt(TokenUnit.sat, 10000, _usdt);
        expect(amt.value, BigInt.from(100)); // 10000 ~/ 100
      });
    });

    group('fromBigInt', () {
      test('same scaling as fromInt', () {
        final amt = TokenAmount.fromBigInt(
          TokenUnit.sat,
          BigInt.from(50000),
          _rbtc,
        );
        expect(amt.value, BigInt.from(50000) * BigInt.from(10).pow(10));
      });

      test('large BigInt values preserved', () {
        final big = BigInt.parse('9' * 30);
        final amt = TokenAmount.fromBigInt(TokenUnit.wei, big, _rbtc);
        expect(amt.value, big);
      });
    });

    group('fromDecimal', () {
      test('parses "0.5" for 8-decimal token', () {
        final amt = TokenAmount.fromDecimal('0.5', _btc);
        expect(amt.value, BigInt.from(50000000)); // 0.5 × 10^8
      });

      test('parses "1.0" for 18-decimal token', () {
        final amt = TokenAmount.fromDecimal('1.0', _rbtc);
        expect(amt.value, BigInt.from(10).pow(18));
      });

      test('parses "0" as zero', () {
        final amt = TokenAmount.fromDecimal('0', _rbtc);
        expect(amt.isZero, isTrue);
      });
    });

    group('fromDenominated', () {
      test('same decimals → identity', () {
        final da = DenominatedAmount(
          denomination: 'BTC',
          value: BigInt.from(100),
          decimals: 8,
        );
        final amt = TokenAmount.fromDenominated(da, _btc);
        expect(amt.value, BigInt.from(100));
      });

      test('8 → 18 decimals → scales up by 10^10', () {
        final da = DenominatedAmount(
          denomination: 'BTC',
          value: BigInt.from(100),
          decimals: 8,
        );
        final amt = TokenAmount.fromDenominated(da, _rbtc);
        expect(amt.value, BigInt.from(100) * BigInt.from(10).pow(10));
      });

      test('18 → 8 decimals → scales down by 10^10', () {
        final da = DenominatedAmount(
          denomination: 'RBTC',
          value: BigInt.from(10).pow(18),
          decimals: 18,
        );
        final amt = TokenAmount.fromDenominated(da, _btc);
        expect(amt.value, BigInt.from(10).pow(8)); // 1 BTC
      });
    });

    group('zero', () {
      test('creates zero value for token', () {
        final amt = TokenAmount.zero(_rbtc);
        expect(amt.value, BigInt.zero);
        expect(amt.token, _rbtc);
        expect(amt.isZero, isTrue);
      });
    });

    group('fromJson / toJson round-trip', () {
      test('preserves value and token', () {
        final original = TokenAmount(
          value: BigInt.from(123456789),
          token: _rbtc,
        );
        final json = original.toJson();
        final restored = TokenAmount.fromJson(json);
        expect(restored.value, original.value);
        expect(restored.token, original.token);
      });
    });
  });

  group('TokenAmount — arithmetic', () {
    test('addition', () {
      final a = TokenAmount(value: BigInt.from(100), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(200), token: _rbtc);
      expect((a + b).value, BigInt.from(300));
    });

    test('subtraction', () {
      final a = TokenAmount(value: BigInt.from(300), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(100), token: _rbtc);
      expect((a - b).value, BigInt.from(200));
    });

    test('multiplication by scalar', () {
      final a = TokenAmount(value: BigInt.from(50), token: _rbtc);
      expect((a * 3).value, BigInt.from(150));
    });

    test('scalarDiv', () {
      final a = TokenAmount(value: BigInt.from(100), token: _rbtc);
      expect(a.scalarDiv(3).value, BigInt.from(33)); // integer division
    });

    test('abs', () {
      final a = TokenAmount(value: BigInt.from(-100), token: _rbtc);
      expect(a.abs().value, BigInt.from(100));
    });

    test('isNegative', () {
      final a = TokenAmount(value: BigInt.from(-1), token: _rbtc);
      expect(a.isNegative, isTrue);
    });

    test('cross-token arithmetic throws', () {
      final a = TokenAmount(value: BigInt.from(1), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(1), token: _btc);
      expect(() => a + b, throwsArgumentError);
      expect(() => a - b, throwsArgumentError);
    });
  });

  group('TokenAmount — comparisons', () {
    test('less than', () {
      final a = TokenAmount(value: BigInt.from(1), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(2), token: _rbtc);
      expect(a < b, isTrue);
      expect(b < a, isFalse);
    });

    test('greater than', () {
      final a = TokenAmount(value: BigInt.from(5), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(3), token: _rbtc);
      expect(a > b, isTrue);
    });

    test('equality', () {
      final a = TokenAmount(value: BigInt.from(42), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(42), token: _rbtc);
      expect(a == b, isTrue);
    });

    test('max / min', () {
      final a = TokenAmount(value: BigInt.from(10), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(20), token: _rbtc);
      expect(TokenAmount.max(a, b), b);
      expect(TokenAmount.min(a, b), a);
    });

    test('cross-token comparison throws', () {
      final a = TokenAmount(value: BigInt.from(1), token: _rbtc);
      final b = TokenAmount(value: BigInt.from(1), token: _btc);
      expect(() => a.compareTo(b), throwsArgumentError);
    });
  });

  group('TokenAmountEvmExt — inSats', () {
    test('8-decimal token → identity', () {
      final amt = TokenAmount(value: BigInt.from(50000), token: _btc);
      expect(amt.inSats, BigInt.from(50000));
    });

    test('18-decimal token → divides by 10^10', () {
      final weiPerSat = BigInt.from(10).pow(10);
      final amt = TokenAmount(
        value: weiPerSat * BigInt.from(100),
        token: _rbtc,
      );
      expect(amt.inSats, BigInt.from(100));
    });

    test('18-decimal with sub-sat precision → truncates', () {
      final weiPerSat = BigInt.from(10).pow(10);
      // 1.5 sats in wei → should truncate to 1 sat.
      final amt = TokenAmount(
        value: weiPerSat + (weiPerSat ~/ BigInt.two),
        token: _rbtc,
      );
      expect(amt.inSats, BigInt.one);
    });
  });

  group('TokenAmountEvmExt — getInMSats', () {
    test('8-decimal → sats × 1000', () {
      final amt = TokenAmount(value: BigInt.from(5), token: _btc);
      expect(amt.getInMSats, BigInt.from(5000));
    });

    test('18-decimal → divides by 10^7', () {
      // 10^18 wei = 1 RBTC = 10^8 sats = 10^11 msats.
      final oneRbtc = BigInt.from(10).pow(18);
      final amt = TokenAmount(value: oneRbtc, token: _rbtc);
      expect(amt.getInMSats, BigInt.from(10).pow(11));
    });
  });

  group('TokenAmountEvmExt — rounding', () {
    test('roundDownToSats no-op for 8-decimal', () {
      final amt = TokenAmount(value: BigInt.from(123), token: _btc);
      expect(amt.roundDownToSats().value, BigInt.from(123));
    });

    test('roundDownToSats truncates sub-sat for 18-decimal', () {
      final weiPerSat = BigInt.from(10).pow(10);
      final amt = TokenAmount(
        value: weiPerSat * BigInt.from(5) + BigInt.from(999),
        token: _rbtc,
      );
      expect(amt.roundDownToSats().value, weiPerSat * BigInt.from(5));
    });

    test('roundDownToSats no-op when already exact', () {
      final weiPerSat = BigInt.from(10).pow(10);
      final amt = TokenAmount(value: weiPerSat * BigInt.from(5), token: _rbtc);
      expect(amt.roundDownToSats().value, amt.value);
    });

    test('roundUpToSats rounds up sub-sat for 18-decimal', () {
      final weiPerSat = BigInt.from(10).pow(10);
      final amt = TokenAmount(
        value: weiPerSat * BigInt.from(5) + BigInt.one,
        token: _rbtc,
      );
      expect(amt.roundUpToSats().value, weiPerSat * BigInt.from(6));
    });

    test('roundUpToSats no-op when already exact', () {
      final weiPerSat = BigInt.from(10).pow(10);
      final amt = TokenAmount(value: weiPerSat * BigInt.from(5), token: _rbtc);
      expect(amt.roundUpToSats().value, amt.value);
    });

    test('roundUpToSats no-op for 8-decimal', () {
      final amt = TokenAmount(value: BigInt.from(123), token: _btc);
      expect(amt.roundUpToSats().value, BigInt.from(123));
    });
  });

  group('Free-standing factories', () {
    test('rbtcFromWei creates correct amount', () {
      final amt = rbtcFromWei(BigInt.from(10).pow(18));
      expect(amt.value, BigInt.from(10).pow(18));
      expect(amt.token.chainId, 30);
      expect(amt.token.isNative, isTrue);
    });

    test('rbtcFromSats multiplies by 10^10', () {
      final amt = rbtcFromSats(BigInt.from(100));
      expect(amt.value, BigInt.from(100) * BigInt.from(10).pow(10));
    });

    test('rbtcFromSats with custom chainId', () {
      final amt = rbtcFromSats(BigInt.from(1), chainId: 31);
      expect(amt.token.chainId, 31);
    });

    test('tokenAmountFromSats scales via fromDenominated', () {
      final amt = tokenAmountFromSats(_rbtc, BigInt.from(100));
      // 100 sats in 18-decimal = 100 × 10^10 wei.
      expect(amt.value, BigInt.from(100) * BigInt.from(10).pow(10));
    });

    test('tokenAmountFromEvm with zero address → native', () {
      final amt = tokenAmountFromEvm(
        '0x0000000000000000000000000000000000000000',
        BigInt.from(1000),
        chainId: 30,
      );
      expect(amt.token.isNative, isTrue);
      expect(amt.token.chainId, 30);
      expect(amt.value, BigInt.from(1000));
    });

    test('tokenAmountFromEvm with non-zero address → ERC-20', () {
      final amt = tokenAmountFromEvm(
        '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        BigInt.from(5000),
        chainId: 30,
        tokenDecimals: 6,
      );
      expect(amt.token.isERC20, isTrue);
      expect(amt.token.decimals, 6);
      expect(amt.value, BigInt.from(5000));
    });

    test('tokenAmountFromEvm defaults to 18 decimals for ERC-20', () {
      final amt = tokenAmountFromEvm(
        '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        BigInt.from(5000),
        chainId: 30,
      );
      expect(amt.token.decimals, 18);
    });
  });

  group('DenominatedAmount — rescale', () {
    test('same decimals → identity', () {
      final da = DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(100),
        decimals: 8,
      );
      expect(da.rescale(8).value, BigInt.from(100));
    });

    test('8 → 18 → scales up', () {
      final da = DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(100),
        decimals: 8,
      );
      final rescaled = da.rescale(18);
      expect(rescaled.value, BigInt.from(100) * BigInt.from(10).pow(10));
      expect(rescaled.decimals, 18);
    });

    test('18 → 8 → scales down', () {
      final da = DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(10).pow(18),
        decimals: 18,
      );
      final rescaled = da.rescale(8);
      expect(rescaled.value, BigInt.from(10).pow(8));
    });
  });

  group('Token', () {
    test('native has correct defaults', () {
      final t = Token.native(30);
      expect(t.isNative, isTrue);
      expect(t.isERC20, isFalse);
      expect(t.decimals, 18);
      expect(t.chainId, 30);
    });

    test('tagId format', () {
      final t = Token(chainId: 30, address: '0xABC', decimals: 6);
      expect(t.tagId, '30:0xABC');
    });

    test('fromTagId round-trip', () {
      final original = Token(chainId: 30, address: '0xABC', decimals: 6);
      final restored = Token.fromTagId(original.tagId, decimals: 6);
      expect(restored, original);
    });

    test('fromTagId throws on invalid format', () {
      expect(
        () => Token.fromTagId('invalid', decimals: 18),
        throwsFormatException,
      );
    });

    test('equality is case-insensitive on address', () {
      final a = Token(chainId: 30, address: '0xabc', decimals: 18);
      final b = Token(chainId: 30, address: '0xABC', decimals: 18);
      expect(a, b);
    });

    test('different chainId → not equal', () {
      final a = Token(chainId: 30, address: '0xabc', decimals: 18);
      final b = Token(chainId: 31, address: '0xabc', decimals: 18);
      expect(a == b, isFalse);
    });

    test('JSON round-trip', () {
      final original = Token(chainId: 30, address: '0xABC', decimals: 6);
      final json = original.toJson();
      final restored = Token.fromJson(json);
      expect(restored.chainId, original.chainId);
      expect(restored.address, original.address);
      expect(restored.decimals, original.decimals);
    });
  });
}

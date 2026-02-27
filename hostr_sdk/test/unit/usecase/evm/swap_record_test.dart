@Tags(['unit'])
library;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:test/test.dart';

void main() {
  group('SwapRecord sealed hierarchy', () {
    group('SwapInRecord.create', () {
      test('creates a record with correct defaults', () {
        final preimage = List<int>.generate(32, (i) => i);
        final record = SwapInRecord.create(
          boltzId: 'swap-in-123',
          preimage: preimage,
          preimageHash: 'abc123',
          onchainAmountSat: 50000,
          timeoutBlockHeight: 800000,
          chainId: 31,
        );

        expect(record.id, 'swap-in-123');
        expect(record.boltzId, 'swap-in-123');
        expect(record, isA<SwapInRecord>());
        expect(record.status, SwapRecordStatus.created);
        expect(record.preimageHex, hex.encode(preimage));
        expect(record.preimageHash, 'abc123');
        expect(record.onchainAmountSat, 50000);
        expect(record.timeoutBlockHeight, 800000);
        expect(record.chainId, 31);
        expect(record.refundAddress, isNull);
      });
    });

    group('SwapOutRecord.create', () {
      test('creates a record with correct defaults', () {
        final record = SwapOutRecord.create(
          boltzId: 'swap-out-456',
          invoice: 'lnbc1000...',
          invoicePreimageHashHex: 'deadbeef',
          claimAddress: '0x1234567890abcdef1234567890abcdef12345678',
          lockedAmountWei: BigInt.from(1000000),
          lockerAddress: '0xaabbccdd',
          timeoutBlockHeight: 900000,
          chainId: 31,
        );

        expect(record.id, 'swap-out-456');
        expect(record.boltzId, 'swap-out-456');
        expect(record, isA<SwapOutRecord>());
        expect(record.status, SwapRecordStatus.created);
        expect(record.invoice, 'lnbc1000...');
        expect(record.invoicePreimageHashHex, 'deadbeef');
        expect(
          record.claimAddress,
          '0x1234567890abcdef1234567890abcdef12345678',
        );
        expect(
          record.lockedAmountWeiHex,
          BigInt.from(1000000).toRadixString(16),
        );
        expect(record.lockerAddress, '0xaabbccdd');
        expect(record.timeoutBlockHeight, 900000);
        expect(record.chainId, 31);
        expect(record.lockTxHash, isNull);
      });
    });

    group('derived getters', () {
      test('preimageBytes decodes hex correctly', () {
        final preimage = List<int>.generate(32, (i) => i);
        final record = SwapInRecord.create(
          boltzId: 'test',
          preimage: preimage,
          preimageHash: 'hash',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.preimageBytes, isA<Uint8List>());
        expect(record.preimageBytes.toList(), preimage);
      });

      test('invoicePreimageHashBytes decodes hex correctly', () {
        final hashHex = 'aabbccdd';
        final record = SwapOutRecord.create(
          boltzId: 'test',
          invoice: 'inv',
          invoicePreimageHashHex: hashHex,
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.invoicePreimageHashBytes.toList(), hex.decode(hashHex));
      });

      test('lockedAmountWei parses hex correctly', () {
        final amount = BigInt.from(123456789);
        final record = SwapOutRecord.create(
          boltzId: 'test',
          invoice: 'inv',
          invoicePreimageHashHex: 'hash',
          claimAddress: '0xaddr',
          lockedAmountWei: amount,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.lockedAmountWei, amount);
      });
    });

    group('claimParams', () {
      test('returns null when refundAddress is missing', () {
        final record = SwapInRecord.create(
          boltzId: 'test',
          preimage: [1, 2, 3],
          preimageHash: 'hash',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );
        expect(record.claimParams, isNull);
      });

      test('returns params when refundAddress is present', () {
        final record = SwapInRecord.create(
          boltzId: 'test',
          preimage: List<int>.generate(32, (i) => i),
          preimageHash: 'hash',
          onchainAmountSat: 50000,
          timeoutBlockHeight: 800000,
          chainId: 31,
        );
        record.refundAddress = '0xrefund';

        final params = record.claimParams;
        expect(params, isNotNull);
        expect(params!.onchainAmountSat, 50000);
        expect(params.refundAddress, '0xrefund');
        expect(params.timeoutBlockHeight, 800000);
      });
    });

    group('refundParams', () {
      test('always returns non-null for SwapOutRecord', () {
        final record = SwapOutRecord.create(
          boltzId: 'test',
          invoice: 'inv',
          invoicePreimageHashHex: 'deadbeef',
          claimAddress: '0xclaimaddr',
          lockedAmountWei: BigInt.from(1000000),
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 900000,
          chainId: 31,
        );

        final params = record.refundParams;
        expect(params.claimAddress, '0xclaimaddr');
        expect(params.lockedAmountWei, BigInt.from(1000000));
        expect(params.timeoutBlockHeight, 900000);
      });
    });

    group('state checks', () {
      test('isTerminal for completed, refunded, failed', () {
        for (final status in [
          SwapRecordStatus.completed,
          SwapRecordStatus.refunded,
          SwapRecordStatus.failed,
        ]) {
          final record = _makeSwapOutRecord(status: status);
          expect(
            record.isTerminal,
            isTrue,
            reason: '$status should be terminal',
          );
        }
      });

      test('isTerminal is false for non-terminal states', () {
        for (final status in [
          SwapRecordStatus.created,
          SwapRecordStatus.funded,
          SwapRecordStatus.claiming,
          SwapRecordStatus.needsAction,
          SwapRecordStatus.refunding,
        ]) {
          final record = _makeSwapOutRecord(status: status);
          expect(
            record.isTerminal,
            isFalse,
            reason: '$status should not be terminal',
          );
        }
      });

      test('needsRecovery for funded, claiming, needsAction', () {
        for (final status in [
          SwapRecordStatus.funded,
          SwapRecordStatus.claiming,
          SwapRecordStatus.needsAction,
        ]) {
          final record = _makeSwapOutRecord(status: status);
          expect(
            record.needsRecovery,
            isTrue,
            reason: '$status should need recovery',
          );
        }
      });

      test('needsRecovery false for created, completed, etc', () {
        for (final status in [
          SwapRecordStatus.created,
          SwapRecordStatus.completed,
          SwapRecordStatus.refunded,
          SwapRecordStatus.failed,
          SwapRecordStatus.refunding,
        ]) {
          final record = _makeSwapOutRecord(status: status);
          expect(
            record.needsRecovery,
            isFalse,
            reason: '$status should not need recovery',
          );
        }
      });

      test('isTimelockExpired', () {
        final record = _makeSwapOutRecord(timeoutBlockHeight: 1000);
        expect(record.isTimelockExpired(999), isFalse);
        expect(record.isTimelockExpired(1000), isTrue);
        expect(record.isTimelockExpired(1001), isTrue);
      });
    });

    group('sealed type matching', () {
      test('switch works exhaustively on sealed SwapRecord', () {
        final swapIn = SwapInRecord.create(
          boltzId: 'in-1',
          preimage: [1, 2, 3],
          preimageHash: 'hash',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );
        final swapOut = SwapOutRecord.create(
          boltzId: 'out-1',
          invoice: 'inv',
          invoicePreimageHashHex: 'hash',
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        // This compiles only because the sealed hierarchy is exhaustive
        String direction(SwapRecord r) => switch (r) {
          SwapInRecord() => 'in',
          SwapOutRecord() => 'out',
        };

        expect(direction(swapIn), 'in');
        expect(direction(swapOut), 'out');
      });
    });

    group('copyWithStatus', () {
      test('SwapInRecord preserves fields and accepts refundAddress', () {
        final record = SwapInRecord.create(
          boltzId: 'copy-test',
          preimage: [1, 2, 3],
          preimageHash: 'hash',
          onchainAmountSat: 5000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        final updated = record.copyWithStatus(
          SwapRecordStatus.funded,
          refundAddress: '0xrefund',
        );

        expect(updated, isA<SwapInRecord>());
        expect(updated.status, SwapRecordStatus.funded);
        expect(updated.refundAddress, '0xrefund');
        expect(updated.boltzId, 'copy-test');
        expect(updated.preimageHex, record.preimageHex);
        expect(updated.chainId, 31);
        expect(updated.updatedAt.isAfter(record.createdAt), isTrue);
      });

      test('SwapOutRecord preserves fields and accepts lockTxHash', () {
        final record = SwapOutRecord.create(
          boltzId: 'copy-test',
          invoice: 'inv',
          invoicePreimageHashHex: 'hash',
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        final updated = record.copyWithStatus(
          SwapRecordStatus.funded,
          lockTxHash: '0xlocktx',
        );

        expect(updated, isA<SwapOutRecord>());
        expect(updated.status, SwapRecordStatus.funded);
        expect(updated.lockTxHash, '0xlocktx');
        expect(updated.invoice, 'inv');
      });

      test('overrides optional metadata fields', () {
        final record = _makeSwapOutRecord(status: SwapRecordStatus.funded);
        final updated = record.copyWithStatus(
          SwapRecordStatus.claiming,
          resolutionTxHash: '0xresolution',
          lastBoltzStatus: 'invoice.settled',
          errorMessage: null,
        );

        expect(updated.resolutionTxHash, '0xresolution');
        expect(updated.lastBoltzStatus, 'invoice.settled');
      });
    });

    group('JSON serialization', () {
      test('roundtrip for swap-in', () {
        final original = SwapInRecord.create(
          boltzId: 'json-test-in',
          preimage: List<int>.generate(32, (i) => i),
          preimageHash: 'abc123hash',
          onchainAmountSat: 42000,
          timeoutBlockHeight: 500000,
          chainId: 31,
        );

        final json = original.toJson();
        final restored = SwapRecord.fromJson(json);

        expect(restored, isA<SwapInRecord>());
        final r = restored as SwapInRecord;
        expect(r.id, original.id);
        expect(r.boltzId, original.boltzId);
        expect(r.status, original.status);
        expect(r.preimageHex, original.preimageHex);
        expect(r.preimageHash, original.preimageHash);
        expect(r.onchainAmountSat, original.onchainAmountSat);
        expect(r.timeoutBlockHeight, original.timeoutBlockHeight);
        expect(r.chainId, original.chainId);
      });

      test('roundtrip for swap-out', () {
        final original = SwapOutRecord.create(
          boltzId: 'json-test-out',
          invoice: 'lnbc500u1...',
          invoicePreimageHashHex: 'deadbeef01020304',
          claimAddress: '0xclaimaddr',
          lockedAmountWei: BigInt.parse('123456789012345678'),
          lockerAddress: '0xlockeraddr',
          timeoutBlockHeight: 750000,
          chainId: 30,
        );

        final json = original.toJson();
        final restored = SwapRecord.fromJson(json);

        expect(restored, isA<SwapOutRecord>());
        final r = restored as SwapOutRecord;
        expect(r.invoice, original.invoice);
        expect(r.invoicePreimageHashHex, original.invoicePreimageHashHex);
        expect(r.claimAddress, original.claimAddress);
        expect(r.lockedAmountWeiHex, original.lockedAmountWeiHex);
        expect(r.lockedAmountWei, original.lockedAmountWei);
        expect(r.lockerAddress, original.lockerAddress);
      });

      test('roundtrip preserves nullable fields', () {
        final original = SwapInRecord.create(
          boltzId: 'nullable-test',
          preimage: [1],
          preimageHash: 'h',
          onchainAmountSat: 100,
          timeoutBlockHeight: 10,
          chainId: 31,
        );
        final updated = original.copyWithStatus(
          SwapRecordStatus.needsAction,
          resolutionTxHash: '0xresolved',
          lastBoltzStatus: 'transaction.confirmed',
          errorMessage: 'Something went wrong',
        );

        final json = updated.toJson();
        final restored = SwapRecord.fromJson(json);

        expect(restored.resolutionTxHash, '0xresolved');
        expect(restored.lastBoltzStatus, 'transaction.confirmed');
        expect(restored.errorMessage, 'Something went wrong');
      });

      test('swap-in JSON does not contain swap-out fields', () {
        final record = SwapInRecord.create(
          boltzId: 'omit-test',
          preimage: [1],
          preimageHash: 'h',
          onchainAmountSat: 100,
          timeoutBlockHeight: 10,
          chainId: 31,
        );
        final json = record.toJson();

        expect(json.containsKey('invoice'), isFalse);
        expect(json.containsKey('claimAddress'), isFalse);
        expect(json.containsKey('lockedAmountWeiHex'), isFalse);
        expect(json['type'], 'swapIn');
      });

      test('swap-out JSON does not contain swap-in fields', () {
        final record = SwapOutRecord.create(
          boltzId: 'omit-test',
          invoice: 'inv',
          invoicePreimageHashHex: 'hash',
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 10,
          chainId: 31,
        );
        final json = record.toJson();

        expect(json.containsKey('preimageHex'), isFalse);
        expect(json.containsKey('preimageHash'), isFalse);
        expect(json.containsKey('onchainAmountSat'), isFalse);
        expect(json['type'], 'swapOut');
      });
    });
  });
}

SwapOutRecord _makeSwapOutRecord({
  SwapRecordStatus status = SwapRecordStatus.created,
  int timeoutBlockHeight = 1000,
}) {
  final record = SwapOutRecord.create(
    boltzId: 'test-boltz-id',
    invoice: 'lnbc1000...',
    invoicePreimageHashHex: 'deadbeef',
    claimAddress: '0xclaimaddr',
    lockedAmountWei: BigInt.from(1000000),
    lockerAddress: '0xlockeraddr',
    timeoutBlockHeight: timeoutBlockHeight,
    chainId: 31,
  );
  if (status != SwapRecordStatus.created) {
    return record.copyWithStatus(status);
  }
  return record;
}

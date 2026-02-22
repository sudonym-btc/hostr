import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:test/test.dart';

void main() {
  group('SwapRecord', () {
    group('forSwapIn factory', () {
      test('creates a record with correct defaults', () {
        final preimage = List<int>.generate(32, (i) => i);
        final record = SwapRecord.forSwapIn(
          boltzId: 'swap-in-123',
          preimage: preimage,
          preimageHash: 'abc123',
          onchainAmountSat: 50000,
          timeoutBlockHeight: 800000,
          chainId: 31,
        );

        expect(record.id, 'swap-in-123');
        expect(record.boltzId, 'swap-in-123');
        expect(record.type, SwapType.swapIn);
        expect(record.status, SwapRecordStatus.created);
        expect(record.preimageHex, hex.encode(preimage));
        expect(record.preimageHash, 'abc123');
        expect(record.onchainAmountSat, 50000);
        expect(record.timeoutBlockHeight, 800000);
        expect(record.chainId, 31);
        // Swap-out fields should be null
        expect(record.invoice, isNull);
        expect(record.invoicePreimageHashHex, isNull);
        expect(record.claimAddress, isNull);
        expect(record.lockedAmountWeiHex, isNull);
        expect(record.lockerAddress, isNull);
      });
    });

    group('forSwapOut factory', () {
      test('creates a record with correct defaults', () {
        final record = SwapRecord.forSwapOut(
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
        expect(record.type, SwapType.swapOut);
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
        // Swap-in fields should be null
        expect(record.preimageHex, isNull);
        expect(record.preimageHash, isNull);
        expect(record.onchainAmountSat, isNull);
      });
    });

    group('derived getters', () {
      test('preimageBytes decodes hex correctly', () {
        final preimage = List<int>.generate(32, (i) => i);
        final record = SwapRecord.forSwapIn(
          boltzId: 'test',
          preimage: preimage,
          preimageHash: 'hash',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.preimageBytes, isNotNull);
        expect(record.preimageBytes, isA<Uint8List>());
        expect(record.preimageBytes!.toList(), preimage);
      });

      test('preimageBytes returns null when preimageHex is null', () {
        final record = SwapRecord.forSwapOut(
          boltzId: 'test',
          invoice: 'inv',
          invoicePreimageHashHex: 'hash',
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.preimageBytes, isNull);
      });

      test('invoicePreimageHashBytes decodes hex correctly', () {
        final hashHex = 'aabbccdd';
        final record = SwapRecord.forSwapOut(
          boltzId: 'test',
          invoice: 'inv',
          invoicePreimageHashHex: hashHex,
          claimAddress: '0xaddr',
          lockedAmountWei: BigInt.one,
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.invoicePreimageHashBytes, isNotNull);
        expect(record.invoicePreimageHashBytes!.toList(), hex.decode(hashHex));
      });

      test('lockedAmountWei parses hex correctly', () {
        final amount = BigInt.from(123456789);
        final record = SwapRecord.forSwapOut(
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

      test('lockedAmountWei returns null when hex is null', () {
        final record = SwapRecord.forSwapIn(
          boltzId: 'test',
          preimage: [1, 2, 3],
          preimageHash: 'hash',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        expect(record.lockedAmountWei, isNull);
      });
    });

    group('state checks', () {
      test('isTerminal for completed, refunded, failed', () {
        for (final status in [
          SwapRecordStatus.completed,
          SwapRecordStatus.refunded,
          SwapRecordStatus.failed,
        ]) {
          final record = _makeRecord(status: status);
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
          final record = _makeRecord(status: status);
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
          final record = _makeRecord(status: status);
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
          final record = _makeRecord(status: status);
          expect(
            record.needsRecovery,
            isFalse,
            reason: '$status should not need recovery',
          );
        }
      });

      test('isTimelockExpired', () {
        final record = _makeRecord(timeoutBlockHeight: 1000);
        expect(record.isTimelockExpired(999), isFalse);
        expect(record.isTimelockExpired(1000), isTrue);
        expect(record.isTimelockExpired(1001), isTrue);
      });

      test('isTimelockExpired returns false when no timelock', () {
        final record = _makeRecord(timeoutBlockHeight: null);
        expect(record.isTimelockExpired(1000), isFalse);
      });
    });

    group('copyWithStatus', () {
      test('copies with new status and preserves other fields', () {
        final record = SwapRecord.forSwapIn(
          boltzId: 'copy-test',
          preimage: [1, 2, 3],
          preimageHash: 'hash',
          onchainAmountSat: 5000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );

        final updated = record.copyWithStatus(
          SwapRecordStatus.funded,
          lockTxHash: '0xabc',
        );

        expect(updated.status, SwapRecordStatus.funded);
        expect(updated.lockTxHash, '0xabc');
        expect(updated.boltzId, 'copy-test');
        expect(updated.preimageHex, record.preimageHex);
        expect(updated.chainId, 31);
        expect(updated.updatedAt.isAfter(record.createdAt), isTrue);
      });

      test('overrides optional fields', () {
        final record = _makeRecord(status: SwapRecordStatus.funded);
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
        final original = SwapRecord.forSwapIn(
          boltzId: 'json-test-in',
          preimage: List<int>.generate(32, (i) => i),
          preimageHash: 'abc123hash',
          onchainAmountSat: 42000,
          timeoutBlockHeight: 500000,
          chainId: 31,
        );

        final json = original.toJson();
        final restored = SwapRecord.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.boltzId, original.boltzId);
        expect(restored.type, original.type);
        expect(restored.status, original.status);
        expect(restored.preimageHex, original.preimageHex);
        expect(restored.preimageHash, original.preimageHash);
        expect(restored.onchainAmountSat, original.onchainAmountSat);
        expect(restored.timeoutBlockHeight, original.timeoutBlockHeight);
        expect(restored.chainId, original.chainId);
      });

      test('roundtrip for swap-out', () {
        final original = SwapRecord.forSwapOut(
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

        expect(restored.type, SwapType.swapOut);
        expect(restored.invoice, original.invoice);
        expect(
          restored.invoicePreimageHashHex,
          original.invoicePreimageHashHex,
        );
        expect(restored.claimAddress, original.claimAddress);
        expect(restored.lockedAmountWeiHex, original.lockedAmountWeiHex);
        expect(restored.lockedAmountWei, original.lockedAmountWei);
        expect(restored.lockerAddress, original.lockerAddress);
      });

      test('roundtrip preserves nullable fields', () {
        final original = SwapRecord.forSwapIn(
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

      test('omits null fields from JSON', () {
        final record = SwapRecord.forSwapIn(
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
        expect(json.containsKey('resolutionTxHash'), isFalse);
        expect(json.containsKey('errorMessage'), isFalse);
      });
    });
  });
}

SwapRecord _makeRecord({
  SwapRecordStatus status = SwapRecordStatus.created,
  int? timeoutBlockHeight = 1000,
}) {
  return SwapRecord(
    id: 'test-id',
    boltzId: 'test-boltz-id',
    type: SwapType.swapOut,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    timeoutBlockHeight: timeoutBlockHeight,
  );
}

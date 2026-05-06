import 'dart:convert';
import 'dart:io' show ZLibEncoder;
import 'dart:typed_data';

import 'package:qr/qr.dart';

String renderQrImageDataUri(String data, {int scale = 1}) {
  final png = renderQrPng(data, scale: scale);
  return 'data:image/png;base64,${base64Encode(png)}';
}

Uint8List renderQrPng(String data, {int scale = 1}) {
  final image = QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L),
  );
  const quietZone = 2;
  final moduleSize = image.moduleCount + (quietZone * 2);
  final pixelSize = moduleSize * scale;
  final raw = BytesBuilder(copy: false);

  for (var y = 0; y < pixelSize; y++) {
    raw.addByte(0); // PNG filter type: none.
    final row = (y ~/ scale) - quietZone;
    for (var x = 0; x < pixelSize; x++) {
      final col = (x ~/ scale) - quietZone;
      raw.addByte(_qrDark(image, row, col) ? 0 : 255);
    }
  }

  final png = BytesBuilder(copy: false)
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
    ..add(
      _pngChunk('IHDR', [
        ..._uint32(pixelSize),
        ..._uint32(pixelSize),
        8, // bit depth
        0, // color type: grayscale
        0, // compression
        0, // filter
        0, // interlace
      ]),
    )
    ..add(_pngChunk('IDAT', ZLibEncoder().convert(raw.takeBytes())))
    ..add(_pngChunk('IEND', const []));
  return png.takeBytes();
}

String renderTerminalQr(String data) {
  final image = QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L),
  );
  final buffer = StringBuffer();
  const quietZone = 2;
  for (var row = -quietZone; row < image.moduleCount + quietZone; row += 2) {
    for (var col = -quietZone; col < image.moduleCount + quietZone; col++) {
      final top = _qrDark(image, row, col);
      final bottom = _qrDark(image, row + 1, col);
      if (top && bottom) {
        buffer.write('█');
      } else if (top) {
        buffer.write('▀');
      } else if (bottom) {
        buffer.write('▄');
      } else {
        buffer.write(' ');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

Uint8List _pngChunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final chunk = BytesBuilder(copy: false)
    ..add(_uint32(data.length))
    ..add(typeBytes)
    ..add(data);
  final crcInput = BytesBuilder(copy: false)
    ..add(typeBytes)
    ..add(data);
  chunk.add(_uint32(_crc32(crcInput.takeBytes())));
  return chunk.takeBytes();
}

List<int> _uint32(int value) {
  final bytes = ByteData(4)..setUint32(0, value);
  return bytes.buffer.asUint8List();
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      if ((crc & 1) == 1) {
        crc = (crc >> 1) ^ 0xedb88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

bool _qrDark(QrImage image, int row, int col) {
  if (row < 0 ||
      col < 0 ||
      row >= image.moduleCount ||
      col >= image.moduleCount) {
    return false;
  }
  return image.isDark(row, col);
}

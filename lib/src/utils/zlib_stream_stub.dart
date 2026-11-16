import 'dart:typed_data';

/// Compression needs `dart:io` (zlib); without it only `none` is offered.
class SSHZlibStream {
  SSHZlibStream.deflate() {
    throw UnsupportedError('zlib compression needs dart:io');
  }

  SSHZlibStream.inflate({int limit = 1 << 20}) {
    throw UnsupportedError('zlib compression needs dart:io');
  }

  Uint8List convert(Uint8List data) =>
      throw UnsupportedError('zlib compression needs dart:io');
}

import 'dart:io';
import 'dart:typed_data';

/// One direction of SSH zlib compression (RFC 4253 §6.2): a deflate or
/// inflate stream that lives across packets, each packet flushed so the
/// other side can read it at once.
class SSHZlibStream {
  SSHZlibStream.deflate()
      : _filter = RawZLibFilter.deflateFilter(level: 6),
        _limit = null;

  /// [limit]: the most one packet may grow to (a compression bomb stops).
  SSHZlibStream.inflate({int limit = 1 << 20})
      : _filter = RawZLibFilter.inflateFilter(),
        _limit = limit;

  final RawZLibFilter _filter;
  final int? _limit;

  Uint8List convert(Uint8List data) {
    _filter.process(data, 0, data.length);
    final out = BytesBuilder(copy: false);
    while (true) {
      final chunk = _filter.processed(flush: true);
      if (chunk == null || chunk.isEmpty) break;
      out.add(chunk);
      final limit = _limit;
      if (limit != null && out.length > limit) {
        throw const FormatException('SSH packet too large after inflate');
      }
    }
    return out.takeBytes();
  }
}

import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:dartssh2/src/utils/zlib_stream.dart';
import 'package:test/test.dart';

void main() {
  test('packets go through one stream each way, each readable at once', () {
    final out = SSHZlibStream.deflate();
    final into = SSHZlibStream.inflate();
    final packets = [
      for (var i = 0; i < 50; i++)
        Uint8List.fromList(
            utf8.encode('<?php echo "packet $i"; ?>\n' * (i + 1)))
    ];
    var sent = 0;
    for (final p in packets) {
      final c = out.convert(p);
      sent += c.length;
      expect(into.convert(c), p);
    }
    final raw = packets.fold<int>(0, (n, p) => n + p.length);
    expect(sent, lessThan(raw ~/ 5), reason: 'text compresses well');
  });

  test('an empty packet and binary data survive', () {
    final out = SSHZlibStream.deflate();
    final into = SSHZlibStream.inflate();
    final bin =
        Uint8List.fromList([for (var i = 0; i < 70000; i++) i * 31 & 0xff]);
    for (final p in [
      Uint8List(0),
      bin,
      Uint8List.fromList([1])
    ]) {
      expect(into.convert(out.convert(p)), p);
    }
  });

  test('zlib output that is not ours inflates too (another peer)', () {
    final into = SSHZlibStream.inflate();
    final data = utf8.encode('hello ' * 100);
    expect(into.convert(Uint8List.fromList(zlib.encode(data))), data);
  });

  test('a packet that would inflate past the limit stops', () {
    final out = SSHZlibStream.deflate();
    final into = SSHZlibStream.inflate(limit: 1000);
    expect(() => into.convert(out.convert(Uint8List(100000))),
        throwsFormatException);
  });
}

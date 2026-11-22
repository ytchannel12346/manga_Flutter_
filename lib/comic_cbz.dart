import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'book_import_limits.dart';
import 'comic_reader_page.dart';

class ComicCbz {
  /// Extracts image pages from a local .cbz archive into a cached folder
  /// and returns them in natural reading order.
  static Future<List<ComicPageSource>> extractPages(String cbzPath) async {
    final file = File(cbzPath);
    if (!await file.exists()) {
      throw const FileSystemException('CBZ 文件不存在');
    }

    final stat = await file.stat();
    final cacheKey = md5
        .convert('$cbzPath:${stat.size}:${stat.modified.millisecondsSinceEpoch}'.codeUnits)
        .toString();
    final tempDir = await getTemporaryDirectory();
    final outDir = Directory('${tempDir.path}/comic-cbz/$cacheKey');

    if (await outDir.exists()) {
      final cached = _sortedImageFiles(outDir);
      if (cached.isNotEmpty) {
        return [for (final f in cached) ComicPageSource.file(f)];
      }
    } else {
      await outDir.create(recursive: true);
    }

    final inputStream = InputFileStream(cbzPath);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      final entries = archive.files.where((entry) {
        if (!entry.isFile) return false;
        final name = entry.name;
        if (name.startsWith('__MACOSX/') || name.split('/').last.startsWith('._')) {
          return false;
        }
        return supportsComicImage(name);
      }).toList()
        ..sort((a, b) => _naturalCompare(a.name, b.name));

      final pages = <ComicPageSource>[];
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final ext = entry.name.split('.').last.toLowerCase();
        final outFile = File('${outDir.path}/${i.toString().padLeft(5, '0')}.$ext');
        final outStream = OutputFileStream(outFile.path);
        entry.writeContent(outStream);
        await outStream.close();
        pages.add(ComicPageSource.file(outFile));
      }
      return pages;
    } finally {
      await inputStream.close();
    }
  }

  static List<File> _sortedImageFiles(Directory dir) {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => supportsComicImage(f.path))
        .toList()
      ..sort((a, b) => _naturalCompare(a.path, b.path));
    return files;
  }

  static int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+|\D+)');
    final aParts = reg.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final bParts = reg.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
    final len = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < len; i++) {
      final aNum = int.tryParse(aParts[i]);
      final bNum = int.tryParse(bParts[i]);
      final cmp = (aNum != null && bNum != null)
          ? aNum.compareTo(bNum)
          : aParts[i].compareTo(bParts[i]);
      if (cmp != 0) return cmp;
    }
    return aParts.length.compareTo(bParts.length);
  }
}

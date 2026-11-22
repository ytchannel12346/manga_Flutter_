// 1. Add 'cbz' to bookFormatLabels
const bookFormatLabels = <String, String>{
  'epub': 'EPUB',
  'txt': 'TXT',
  'kindle': 'Kindle',
  'pdf': 'PDF',
  'fb2': 'FB2',
  'docx': 'DOCX',
  'doc': 'DOC',
  'rtf': 'RTF',
  'html': 'HTML',
  'markdown': 'Markdown',
  'zip': 'ZIP',
  'cbz': 'CBZ', // <-- Add this
};

// 2. Add cbz to supportsBookImport
bool supportsBookImport(String name) => RegExp(
  r'\.(txt|epub|mobi|azw|azw3|prc|fb2|pdf|docx?|rtf|html?|xhtml|md|markdown|zip|cbz)$',
  caseSensitive: false,
).hasMatch(name);

// 3. Add a helper for comic image streaming (WebDAV / unpacked CBZ)
bool supportsComicImage(String name) => RegExp(
  r'\.(jpe?g|png|webp|gif|avif)$',
  caseSensitive: false,
).hasMatch(name);

// 4. Add cbz to localBookByteLimit (512 MiB)
int localBookByteLimit(String name) =>
    switch (name.split('.').last.toLowerCase()) {
      'zip' || 'cbz' => maxLocalArchiveBytes,
      'epub' || 'pdf' || 'docx' => maxLocalEpubBytes,
      'mobi' || 'azw' || 'azw3' || 'prc' => 256 * 1024 * 1024,
      'html' || 'htm' || 'xhtml' || 'md' || 'markdown' => 32 * 1024 * 1024,
      _ => maxLocalTextBytes,
    };

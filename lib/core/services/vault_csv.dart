import '../models/category.dart';
import '../models/clip_item.dart';

/// ClipVal CSV migration format (phone → file → new phone).
///
/// Header row plus optional leading `# clipval_export_version=1` metadata.
/// Columns: title, value, category_name, category_system_key, language,
/// pinned, sensitive, created_at, updated_at, last_copied_at.
abstract final class VaultCsv {
  static const exportVersion = 1;
  static const versionPrefix = 'clipval_export_version=';

  static const header = [
    'title',
    'value',
    'category_name',
    'category_system_key',
    'language',
    'pinned',
    'sensitive',
    'created_at',
    'updated_at',
    'last_copied_at',
  ];

  /// Build a UTF-8 CSV string suitable for file share / iCloud save.
  static String encode({
    required List<ClipItem> items,
    required Map<String, Category> categoriesById,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# $versionPrefix$exportVersion');
    buffer.writeln(header.map(escape).join(','));

    for (final item in items) {
      final cat = item.categoryId != null
          ? categoriesById[item.categoryId]
          : null;
      final row = [
        item.title,
        item.value,
        cat?.name ?? '',
        cat?.systemKey ?? '',
        item.languageTag ?? '',
        item.isPinned ? 'true' : 'false',
        item.isSensitive ? 'true' : 'false',
        item.createdAt.toIso8601String(),
        item.updatedAt.toIso8601String(),
        item.lastCopiedAt?.toIso8601String() ?? '',
      ];
      buffer.writeln(row.map(escape).join(','));
    }
    return buffer.toString();
  }

  /// Parse CSV content into rows. Throws [FormatException] if unusable.
  static List<VaultCsvRow> decode(String content) {
    final lines = _splitLines(content);
    if (lines.isEmpty) {
      throw const FormatException('Empty CSV file');
    }

    var i = 0;
    // Skip blank / # metadata lines until header.
    while (i < lines.length) {
      final t = lines[i].trim();
      if (t.isEmpty || t.startsWith('#')) {
        i++;
        continue;
      }
      break;
    }
    if (i >= lines.length) {
      throw const FormatException('CSV has no header row');
    }

    final headerCells = parseLine(lines[i]);
    i++;
    final index = <String, int>{};
    for (var c = 0; c < headerCells.length; c++) {
      index[headerCells[c].trim().toLowerCase()] = c;
    }

    int? col(String name) => index[name];
    final titleCol = col('title');
    final valueCol = col('value');
    if (titleCol == null || valueCol == null) {
      throw const FormatException(
        'CSV must include title and value columns',
      );
    }

    final categoryNameCol = col('category_name') ?? col('category');
    final categoryKeyCol = col('category_system_key') ?? col('category_key');
    final languageCol = col('language') ?? col('language_tag');
    final pinnedCol = col('pinned') ?? col('is_pinned');
    final sensitiveCol = col('sensitive') ?? col('is_sensitive');
    final createdCol = col('created_at');
    final updatedCol = col('updated_at');
    final lastCopiedCol = col('last_copied_at');

    final rows = <VaultCsvRow>[];
    for (; i < lines.length; i++) {
      final raw = lines[i];
      if (raw.trim().isEmpty || raw.trim().startsWith('#')) continue;

      final cells = parseLine(raw);
      String at(int? c) {
        if (c == null || c >= cells.length) return '';
        return cells[c];
      }

      final title = at(titleCol).trim();
      final value = at(valueCol);
      // Skip completely empty data rows.
      if (title.isEmpty && value.isEmpty) continue;

      rows.add(
        VaultCsvRow(
          title: title,
          value: value,
          categoryName: _nullIfEmpty(at(categoryNameCol).trim()),
          categorySystemKey: _nullIfEmpty(at(categoryKeyCol).trim()),
          languageTag: _normalizeLanguage(_nullIfEmpty(at(languageCol).trim())),
          isPinned: _parseBool(at(pinnedCol)),
          isSensitive: _parseBool(at(sensitiveCol)),
          createdAt: _parseDate(at(createdCol)),
          updatedAt: _parseDate(at(updatedCol)),
          lastCopiedAt: _parseDate(at(lastCopiedCol)),
        ),
      );
    }
    return rows;
  }

  static String escape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// RFC 4180-ish line parser (handles quoted commas and newlines already split).
  static List<String> parseLine(String line) {
    final cells = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          cells.add(buf.toString());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
    }
    cells.add(buf.toString());
    return cells;
  }

  /// Split on newlines but keep quoted multi-line fields intact.
  static List<String> _splitLines(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      if (ch == '"') {
        buf.write(ch);
        // Toggle only if not an escaped quote pair handled loosely:
        // count consecutive quotes is hard here; flip when standalone " toggles.
        if (inQuotes && i + 1 < normalized.length && normalized[i + 1] == '"') {
          buf.write(normalized[i + 1]);
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == '\n' && !inQuotes) {
        lines.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) lines.add(buf.toString());
    return lines;
  }

  static String? _nullIfEmpty(String s) => s.isEmpty ? null : s;

  static String? _normalizeLanguage(String? raw) {
    if (raw == null) return null;
    final t = raw.toLowerCase();
    if (t == ClipItem.languageZh || t == ClipItem.languageEn) return t;
    return null;
  }

  static bool _parseBool(String raw) {
    final t = raw.trim().toLowerCase();
    return t == 'true' || t == '1' || t == 'yes' || t == 'y';
  }

  static DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }
}

class VaultCsvRow {
  const VaultCsvRow({
    required this.title,
    required this.value,
    this.categoryName,
    this.categorySystemKey,
    this.languageTag,
    this.isPinned = false,
    this.isSensitive = false,
    this.createdAt,
    this.updatedAt,
    this.lastCopiedAt,
  });

  final String title;
  final String value;
  final String? categoryName;
  final String? categorySystemKey;
  final String? languageTag;
  final bool isPinned;
  final bool isSensitive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastCopiedAt;
}

class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
  });

  final int imported;
  final int skipped;
  final int failed;

  int get total => imported + skipped + failed;
}

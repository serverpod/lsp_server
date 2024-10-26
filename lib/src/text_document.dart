import 'dart:math';

import 'package:lsp_server/lsp_server.dart';

// \n
const lineFeed = 10;
// \r
const carriageReturn = 13;

/// Mimics vscode-languageserver-node's
/// [TextDocument](https://github.com/microsoft/vscode-languageserver-node/blob/main/textDocument/src/main.ts)
class TextDocument {
  final Uri _uri;
  final String _languageId;
  int _version;
  String _content;
  List<int>? _lineOffsets;

  TextDocument(this._uri, this._languageId, this._version, this._content);

  /// The associated URI for this document. Most documents have the file scheme, indicating that they
  /// represent files on disk. However, some documents may have other schemes indicating that they
  /// are not available on disk.
  Uri get uri => _uri;

  /// The identifier of the language associated with this document.
  String get languageId => _languageId;

  /// The version number of this document (it will increase after each change,
  /// including undo/redo).
  int get version => _version;

  /// The number of lines in this document.
  int get lineCount => _getLineOffsets().length;

  String applyEdits(List<TextEdit> edits) {
    var sortedEdits = edits.map(_getWellformedTextEdit).toList();
    sortedEdits.sort((a, b) {
      var diff = a.range.start.line - b.range.start.line;
      if (diff == 0) {
        return a.range.start.character - b.range.start.character;
      }
      return diff;
    });

    var text = getText();
    var lastModifiedOffset = 0;
    List<String> spans = [];

    for (var edit in sortedEdits) {
      var startOffset = offsetAt(edit.range.start);
      if (startOffset < lastModifiedOffset) {
        throw 'Overlapping edit';
      } else if (startOffset > lastModifiedOffset) {
        spans.add(text.substring(lastModifiedOffset, startOffset));
      }
      if (edit.newText.isNotEmpty) {
        spans.add(edit.newText);
      }
      lastModifiedOffset = offsetAt(edit.range.end);
    }
    spans.add(text.substring(lastModifiedOffset));
    return spans.join();
  }

  /// Get the text of this document. Provide a [Range] to get a substring.
  String getText({Range? range}) {
    if (range != null) {
      var start = offsetAt(range.start);
      var end = offsetAt(range.end);
      return _content.substring(start, end);
    }
    return _content;
  }

  /// Convert a [Position] to a zero-based offset.
  int offsetAt(Position position) {
    var lineOffsets = _getLineOffsets();
    if (position.line >= lineOffsets.length) {
      return _content.length;
    } else if (position.line < 0) {
      return 0;
    }

    var lineOffset = lineOffsets[position.line];
    if (position.character <= 0) {
      return lineOffset;
    }

    var nextLineOffset = (position.line + 1 < lineOffsets.length)
        ? lineOffsets[position.line + 1]
        : _content.length;
    var offset = min(lineOffset + position.character, nextLineOffset);

    return _ensureBeforeEndOfLine(offset: offset, lineOffset: lineOffset);
  }

  /// Converts a zero-based offset to a [Position].
  Position positionAt(int offset) {
    offset = max(min(offset, _content.length), 0);
    var lineOffsets = _getLineOffsets();
    var low = 0;
    var high = lineOffsets.length;
    if (high == 0) {
      return Position(character: offset, line: 0);
    }

    while (low < high) {
      var mid = ((low + high) / 2).floor();
      if (lineOffsets[mid] > offset) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    var line = low - 1;
    offset = _ensureBeforeEndOfLine(
      offset: offset,
      lineOffset: lineOffsets[line],
    );

    return Position(character: offset - lineOffsets[line], line: line);
  }

  /// Updates this text document by modifying its content.
  void update(List<TextDocumentContentChangeEvent> changes, int version) {
    _version = version;
    for (var c in changes) {
      var change = c.map((v) => v, (v) => v);
      if (change is TextDocumentContentChangeEvent1) {
        // Incremental sync.
        var range = _getWellformedRange(change.range);
        var text = change.text;

        var startOffset = offsetAt(range.start);
        var endOffset = offsetAt(range.end);

        // Update content.
        _content = _content.substring(0, startOffset) +
            text +
            _content.substring(endOffset, _content.length);

        // Update offsets without recomputing for the whole document.
        var startLine = max(range.start.line, 0);
        var endLine = max(range.end.line, 0);
        var lineOffsets = _lineOffsets!;
        var addedLineOffsets = _computeLineOffsets(text,
            isAtLineStart: false, textOffset: startOffset);

        if (endLine - startLine == addedLineOffsets.length) {
          for (var i = 0, len = addedLineOffsets.length; i < len; i++) {
            lineOffsets[i + startLine + 1] = addedLineOffsets[i];
          }
        } else {
          // Avoid going outside the range on weird range inputs.
          lineOffsets.replaceRange(
            min(startLine + 1, lineOffsets.length),
            min(endLine + 1, lineOffsets.length),
            addedLineOffsets,
          );
        }

        var diff = text.length - (endOffset - startOffset);
        if (diff != 0) {
          for (var i = startLine + 1 + addedLineOffsets.length,
                  len = lineOffsets.length;
              i < len;
              i++) {
            lineOffsets[i] = lineOffsets[i] + diff;
          }
        }
      } else if (change is TextDocumentContentChangeEvent2) {
        // Full sync.
        _content = change.text;
        _lineOffsets = null;
      }
    }
  }

  List<int> _getLineOffsets() {
    _lineOffsets ??= _computeLineOffsets(_content, isAtLineStart: true);
    return _lineOffsets!;
  }

  List<int> _computeLineOffsets(String content,
      {required bool isAtLineStart, int textOffset = 0}) {
    List<int> result = isAtLineStart ? [textOffset] : [];

    for (var i = 0; i < content.length; i++) {
      var char = content.codeUnitAt(i);
      if (_isEndOfLine(char)) {
        if (char == carriageReturn) {
          var nextCharIsLineFeed =
              i + 1 < content.length && content.codeUnitAt(i + 1) == lineFeed;
          if (nextCharIsLineFeed) {
            i++;
          }
        }
        result.add(textOffset + i + 1);
      }
    }

    return result;
  }

  bool _isEndOfLine(int char) {
    return char == lineFeed || char == carriageReturn;
  }

  int _ensureBeforeEndOfLine({required int offset, required int lineOffset}) {
    while (
        offset > lineOffset && _isEndOfLine(_content.codeUnitAt(offset - 1))) {
      offset--;
    }
    return offset;
  }

  Range _getWellformedRange(Range range) {
    var start = range.start;
    var end = range.end;
    if (start.line > end.line ||
        (start.line == end.line && start.character > end.character)) {
      return Range(start: end, end: start);
    }
    return range;
  }

  TextEdit _getWellformedTextEdit(TextEdit textEdit) {
    var range = _getWellformedRange(textEdit.range);
    if (range != textEdit.range) {
      return TextEdit(newText: textEdit.newText, range: range);
    }
    return textEdit;
  }
}

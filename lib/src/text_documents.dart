import 'package:lsp_server/lsp_server.dart';

class TextDocumentChangeEvent {
  final TextDocument document;

  TextDocumentChangeEvent(this.document);
}

class TextDocumentWillSaveEvent {
  final TextDocument document;
  final TextDocumentSaveReason reason;

  TextDocumentWillSaveEvent(this.document, this.reason);
}

/// Helper class handling the low-level methods to sync document
/// contents from the client. Fulfills a similar role to vscode-languageserver-node's
/// [TextDocuments](https://github.com/microsoft/vscode-languageserver-node/blob/main/server/src/common/textDocuments.ts), though
/// differs slightly in the API surface.
///
/// Pass in to the constuctor your wanted event handlers, to run code when a document is opened, closed, changed or saved.
///
/// The events will run for the same LSP messages as the Node implementation.
/// The parameters are also the same as the Node implementation [TextDocument].
class TextDocuments {
  final Map<Uri, TextDocument> _syncedDocuments = {};

  TextDocuments(
    Connection connection, {
    Future<void> Function(TextDocumentChangeEvent)? onDidOpen,
    Future<void> Function(TextDocumentChangeEvent)? onDidChangeContent,
    Future<void> Function(TextDocumentChangeEvent)? onDidClose,
    Future<void> Function(TextDocumentChangeEvent)? onWillSave,
    Future<List<TextEdit>> Function(TextDocumentWillSaveEvent)?
        onWillSaveWaitUntil,
    Future<void> Function(TextDocumentChangeEvent)? onDidSave,
  }) {
    connection.onDidOpenTextDocument((event) async {
      var td = event.textDocument;
      var document = TextDocument(td.uri, td.languageId, td.version, td.text);
      _syncedDocuments[document.uri] = document;

      if (onDidOpen != null) {
        onDidOpen(TextDocumentChangeEvent(document));
      }
      if (onDidChangeContent != null) {
        onDidChangeContent(TextDocumentChangeEvent(document));
      }
    });

    connection.onDidChangeTextDocument((event) async {
      var td = event.textDocument;
      var changes = event.contentChanges;
      if (changes.isEmpty) return;

      var version = td.version;
      var syncedDocument = get(td.uri);
      if (syncedDocument == null) return;

      syncedDocument.update(changes, version);

      if (onDidChangeContent != null) {
        onDidChangeContent(TextDocumentChangeEvent(syncedDocument));
      }
    });

    connection.onDidCloseTextDocument((event) async {
      var key = event.textDocument.uri;
      var document = _syncedDocuments.remove(key);
      if (document != null && onDidClose != null) {
        onDidClose(TextDocumentChangeEvent(document));
      }
    });

    connection.onWillSaveTextDocument((event) async {
      var document = _syncedDocuments[event.textDocument.uri];
      if (document != null && onWillSave != null) {
        onWillSave(TextDocumentChangeEvent(document));
      }
    });

    if (onWillSaveWaitUntil != null) {
      connection.onWillSaveWaitUntilTextDocument((event) async {
        var document = _syncedDocuments[event.textDocument.uri];
        if (document != null) {
          return onWillSaveWaitUntil(
              TextDocumentWillSaveEvent(document, event.reason));
        } else {
          return [];
        }
      });
    }

    connection.onDidSaveTextDocument((event) async {
      var document = _syncedDocuments[event.textDocument.uri];
      if (document != null && onDidSave != null) {
        onDidSave(TextDocumentChangeEvent(document));
      }
    });
  }

  /// Get a synced [TextDocument] for [uri], if there is one.
  TextDocument? get(Uri uri) {
    return _syncedDocuments[uri];
  }

  /// Get all synced [TextDocument]s
  Iterable<TextDocument> all() {
    return _syncedDocuments.values;
  }

  /// Get an [Iterable] of [Uri]s we have synced.
  Iterable<Uri> keys() {
    return _syncedDocuments.keys;
  }
}

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:lsp_server/lsp_server.dart';

void main() async {
  // Create a connection that can read and write data to the LSP client.
  // Supply a readable and writable stream. In this case we are using stdio.
  // But you could use a socket connection or any other stream.
  var connection = Connection(stdin, stdout);

  // Register a listener for when the client initialzes the server.
  // You are suppose to respond with the capabilities of the server.
  // Some capabilities must be enabled by the client, you can see what the client
  // supports by inspecting the ClientCapabilities object, inside InitializeParams.
  connection.onInitialize((params) async {
    return InitializeResult(
      capabilities: ServerCapabilities(
        // In this example we are using the Full sync mode. This means the
        // entire document is sent in each change notification.
        textDocumentSync: const Either2.t1(TextDocumentSyncKind.Full),
      ),
    );
  });

  // Register a listener for when the client sends a notification when a text
  // document was opened.
  connection.onDidOpenTextDocument((params) async {
    // Our custom validation logic
    var diagnostics = _validateTextDocument(
      params.textDocument.text,
      params.textDocument.uri.toString(),
    );

    // Send back an event notifying the client of issues we want them to render.
    // To clear issues the server is responsible for sending an empty list.
    connection.sendDiagnostics(
      PublishDiagnosticsParams(
        diagnostics: diagnostics,
        uri: params.textDocument.uri,
      ),
    );
  });

  // Register a listener for when the client sends a notification when a text
  // document was changed.
  connection.onDidChangeTextDocument((params) async {
    // We extract the document changes.
    var contentChanges = params.contentChanges
        .map((e) => TextDocumentContentChangeEvent2.fromJson(
            e.toJson() as Map<String, dynamic>))
        .toList();

    // Our custom validation logic
    var diagnostics = _validateTextDocument(
      contentChanges.last.text,
      params.textDocument.uri.toString(),
    );

    // Send back an event notifying the client of issues we want them to render.
    // To clear issues the server is responsible for sending an empty list.
    connection.sendDiagnostics(
      PublishDiagnosticsParams(
        diagnostics: diagnostics,
        uri: params.textDocument.uri,
      ),
    );
  });

  await connection.listen();
}

// Validate the text document and return a list of diagnostics.
// Will find each occurence of more than two uppercase letters in a row.
// Each reported value will come with the indexed location in the file,
// by line and column.
List<Diagnostic> _validateTextDocument(String text, String sourcePath) {
  RegExp pattern = RegExp(r'\b[A-Z]{2,}\b');

  final lines = text.split('\n');

  final matches = lines.map((line) => pattern.allMatches(line));

  final diagnostics = matches
      .mapIndexed(
        (line, lineMatches) => _convertPatternToDiagnostic(lineMatches, line),
      )
      .reduce((aggregate, diagnostics) => [...aggregate, ...diagnostics])
      .toList();

  return diagnostics;
}

// Convert each line that has uppercase strings into a list of diagnostics.
// The line "AAA bbb CCC" would be converted into two diagnostics:
// One for "AAA".
// One for "CCC".
Iterable<Diagnostic> _convertPatternToDiagnostic(
    Iterable<RegExpMatch> matches, int line) {
  return matches.map(
    (match) => Diagnostic(
      message:
          '${match.input.substring(match.start, match.end)} is all uppercase.',
      range: Range(
        start: Position(character: match.start, line: line),
        end: Position(character: match.end, line: line),
      ),
    ),
  );
}

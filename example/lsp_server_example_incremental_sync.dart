import 'dart:io';

import 'package:collection/collection.dart';
import 'package:lsp_server/lsp_server.dart';

void main() async {
  // Create a connection that can read and write data to the LSP client.
  // Supply a readable and writable stream. In this case we are using stdio.
  // But you could use a socket connection or any other stream.
  var connection = Connection(stdin, stdout);

  // Create a TextDocuments handler. This class gives support for both full
  // and incremental sync. The document returned by this handler is the
  // TextDocument class, which has an API that matches
  // vscode-languageserver-textdocument.
  var documents = TextDocuments(connection, onDidChangeContent: (params) async {
    // onDidChangeContent is called both when a document is opened
    // and when it changes. It's a great place to run diagnostics.
    var diagnostics = _validateTextDocument(
      params.document.getText(),
      params.document.uri.toString(),
    );

    // Send back an event notifying the client of issues we want them to render.
    // To clear issues the server is responsible for sending an empty list.
    connection.sendDiagnostics(
      PublishDiagnosticsParams(
        diagnostics: diagnostics,
        uri: params.document.uri,
      ),
    );
  });

  // Register a listener for when the client initialzes the server.
  // You are suppose to respond with the capabilities of the server.
  // Some capabilities must be enabled by the client, you can see what the client
  // supports by inspecting the ClientCapabilities object, inside InitializeParams.
  connection.onInitialize((params) async {
    return InitializeResult(
      capabilities: ServerCapabilities(
        // In this example we are using the Incremental sync mode. This means
        // only the content that has changed is sent, and it's up to the server
        // to update its state accordingly. TextDocuments and TextDocument
        // handle this for you.
        textDocumentSync: const Either2.t1(TextDocumentSyncKind.Incremental),
        // Tell the client what we can do
        diagnosticProvider: Either2.t1(DiagnosticOptions(
            interFileDependencies: true, workspaceDiagnostics: false)),
        hoverProvider: Either2.t1(true),
      ),
    );
  });

  // Your other listeners likely want to get the synced TextDocument based
  // on the params' TextDocumentIdentifier.
  connection.onHover((params) async {
    var textDocument = documents.get(params.textDocument.uri);
    var lines = textDocument?.lineCount ?? 0;
    return Hover(contents: Either2.t2('Document has $lines lines'));
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

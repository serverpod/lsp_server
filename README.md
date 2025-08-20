[![Serverpod LSP Server banner](https://github.com/serverpod/lsp_server/raw/main/misc/images/banner.jpg)](https://serverpod.dev)


# LSP Server

This is a dart implementation of the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/) and comes with all serializable objects defined in the specification (v3.17).

The interface also contains the event methods for Document synchronization as well as the Language Features.

## Features

- Life cycle methods
- Language features

- Generic registration of listeners for events and methods.
- Generic methods to send events and requests

## Getting started

To get a better understanding of how this work it can be useful to look at the official documentation and the similar implementations in node.

[Full LSP spec definition](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/).

[LSP Guide](https://code.visualstudio.com/api/language-extensions/language-server-extension-guide) for vscode.

[LSP Example](https://github.com/microsoft/vscode-extension-samples/blob/61d94d731c5351531a7d82f92f775f749203e3b5/lsp-sample/README.md) for vscode.

## Usage

You can use any stream you want, stdio is commonly used and is easy to set up.

```dart
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
}
```

## Additional information

Who should use this? If you want to build a plugin for an editor that supports the LSP format, and you want to build the server in Dart, then this is the package for you. With this package you can implement features such as "linting", "go to reference", giving contextual information and more.

## Todo

Implement the missing features from the protocol:

- workspaces
- window
- notebook
- client (dynamic capabilities)
- trace

import 'dart:async';

import 'package:lsp_server/src/protocol/lsp_protocol/protocol_generated.dart';
import 'package:lsp_server/src/protocol/lsp_protocol/protocol_special.dart';
import 'package:lsp_server/src/wireformat.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

class Connection {
  late final Peer peer;

  Connection(
    Stream<List<int>> stream,
    StreamSink<List<int>> sink,
  ) {
    peer = Peer(lspChannel(stream, sink));
  }

  Future listen() => peer.listen();

  Future close() => peer.close();

  Future<R> sendRequest<R>(String method, dynamic params) async {
    return await peer.sendRequest(method, params);
  }

  Future onRequest<R>(
    String method,
    Future<R> Function(Parameters) handler,
  ) async {
    peer.registerMethod(method, (params) async {
      return await handler(params);
    });
  }

  void onNotification(
    String method,
    Future Function(Parameters) handler,
  ) {
    peer.registerMethod(method, (params) async {
      await handler(params);
    });
  }

  void sendNotification(String method, dynamic params) {
    return peer.sendNotification(method, params);
  }

  void onInitialize(
      Future<InitializeResult> Function(InitializeParams) handler) {
    peer.registerMethod('initialize', (params) async {
      var initParams = InitializeParams.fromJson(params.value);
      return await handler(initParams);
    });
  }

  void onInitialized(Future Function(InitializedParams) handler) {
    peer.registerMethod('initialized', (params) async {
      var initParams = InitializedParams.fromJson(params.value);
      handler(initParams);
    });
  }

  void onShutdown(Future Function() handler) {
    peer.registerMethod('shutdown', (params) async {
      await handler();
    });
  }

  void onExit(Future Function() handler) {
    peer.registerMethod('exit', (params) async {
      await handler();
    });
  }

  void onDidOpenTextDocument(
    Future Function(DidOpenTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didOpen', (params) async {
      var openParams = DidOpenTextDocumentParams.fromJson(params.value);
      await handler(openParams);
    });
  }

  void onDidChangeTextDocument(
    Future Function(DidChangeTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didChange', (params) async {
      var changeParams = DidChangeTextDocumentParams.fromJson(params.value);
      await handler(changeParams);
    });
  }

  void onDidCloseTextDocument(
    Future Function(DidCloseTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didClose', (params) async {
      var closeParams = DidCloseTextDocumentParams.fromJson(params.value);
      await handler(closeParams);
    });
  }

  void onWillSaveTextDocument(
    Future Function(WillSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/willSave', (params) async {
      var saveParams = WillSaveTextDocumentParams.fromJson(params.value);
      await handler(saveParams);
    });
  }

  void onWillSaveWaitUntilTextDocument(
    Future<List<TextEdit>> Function(WillSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/willSaveWaitUntil', (params) async {
      var saveParams = WillSaveTextDocumentParams.fromJson(params.value);
      return await handler(saveParams);
    });
  }

  void onDidSaveTextDocument(
    Future Function(DidSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didSave', (params) async {
      var saveParams = DidSaveTextDocumentParams.fromJson(params.value);
      await handler(saveParams);
    });
  }

  void sendDiagnostics(PublishDiagnosticsParams params) {
    peer.sendNotification('textDocument/publishDiagnostics', params.toJson());
  }

  void onHover(Future<Hover> Function(TextDocumentPositionParams) handler) {
    peer.registerMethod('textDocument/hover', (params) async {
      var hoverParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(hoverParams);
    });
  }

  void onCompletion(
    Future<CompletionList> Function(TextDocumentPositionParams) handler,
  ) {
    peer.registerMethod('textDocument/completion', (params) async {
      var completionParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(completionParams);
    });
  }

  void onCompletionResolve(
    Future<CompletionItem> Function(CompletionItem) handler,
  ) {
    peer.registerMethod('completionItem/resolve', (params) async {
      var completionItem = CompletionItem.fromJson(params.value);
      return await handler(completionItem);
    });
  }

  void onSignatureHelp(
    Future<SignatureHelp> Function(TextDocumentPositionParams) handler,
  ) {
    peer.registerMethod('textDocument/signatureHelp', (params) async {
      var signatureParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(signatureParams);
    });
  }

  void onDeclaration(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
            TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/declaration', (params) async {
      var declarationParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(declarationParams);
    });
  }

  void onDefinition(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
            TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/definition', (params) async {
      var definitionParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(definitionParams);
    });
  }

  void onTypeDefinition(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
            TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/typeDefinition', (params) async {
      var typeDefinitionParams =
          TextDocumentPositionParams.fromJson(params.value);
      return await handler(typeDefinitionParams);
    });
  }

  void onImplementation(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
            TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/implementation', (params) async {
      var implementationParams =
          TextDocumentPositionParams.fromJson(params.value);
      return await handler(implementationParams);
    });
  }

  void onReferences(
    Future<List<Location>> Function(ReferenceParams) handler,
  ) {
    peer.registerMethod('textDocument/references', (params) async {
      var referenceParams = ReferenceParams.fromJson(params.value);
      return await handler(referenceParams);
    });
  }

  void onDocumentHighlight(
    Future<List<DocumentHighlight>> Function(TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/documentHighlight', (params) async {
      var highlightParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(highlightParams);
    });
  }

  void onDocumentSymbol(
    Future<List<SymbolInformation>> Function(DocumentSymbolParams) handler,
  ) {
    peer.registerMethod('textDocument/documentSymbol', (params) async {
      var documentSymbolParams = DocumentSymbolParams.fromJson(params.value);
      return await handler(documentSymbolParams);
    });
  }

  void onWorkspaceSymbolResolve(
    Future<SymbolInformation> Function(SymbolInformation) handler,
  ) {
    peer.registerMethod('workspace/symbol/resolve', (params) async {
      var symbolInformation = SymbolInformation.fromJson(params.value);
      return await handler(symbolInformation);
    });
  }

  void onCodeAction(
    Future<List<CodeAction>> Function(CodeActionParams) handler,
  ) {
    peer.registerMethod('textDocument/codeAction', (params) async {
      var codeActionParams = CodeActionParams.fromJson(params.value);
      return await handler(codeActionParams);
    });
  }

  void onCodeActionResolve(
    Future<CodeAction> Function(CodeAction) handler,
  ) {
    peer.registerMethod('codeAction/resolve', (params) async {
      var codeAction = CodeAction.fromJson(params.value);
      return await handler(codeAction);
    });
  }

  void onCodeLens(
    Future<List<CodeLens>> Function(CodeLensParams) handler,
  ) {
    peer.registerMethod('textDocument/codeLens', (params) async {
      var codeLensParams = CodeLensParams.fromJson(params.value);
      return await handler(codeLensParams);
    });
  }

  void onCodeLensResolve(
    Future<CodeLens> Function(CodeLens) handler,
  ) {
    peer.registerMethod('codeLens/resolve', (params) async {
      var codeLens = CodeLens.fromJson(params.value);
      return await handler(codeLens);
    });
  }

  void onDocumentFormatting(
    Future<List<TextEdit>> Function(DocumentFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/formatting', (params) async {
      var formatParams = DocumentFormattingParams.fromJson(params.value);
      return await handler(formatParams);
    });
  }

  void onDocumentRangeFormatting(
    Future<List<TextEdit>> Function(DocumentRangeFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/rangeFormatting', (params) async {
      var formatParams = DocumentRangeFormattingParams.fromJson(params.value);
      return await handler(formatParams);
    });
  }

  void onDocumentOnTypeFormatting(
    Future<List<TextEdit>> Function(DocumentOnTypeFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/onTypeFormatting', (params) async {
      var formatParams = DocumentOnTypeFormattingParams.fromJson(params.value);
      return await handler(formatParams);
    });
  }

  void onRenameRequest(
    Future<WorkspaceEdit> Function(RenameParams) handler,
  ) {
    peer.registerMethod('textDocument/rename', (params) async {
      var renameParams = RenameParams.fromJson(params.value);
      return await handler(renameParams);
    });
  }

  void onPrepareRename(
    Future<Either2<Range, PrepareRenameResult>> Function(
            TextDocumentPositionParams)
        handler,
  ) {
    peer.registerMethod('textDocument/prepareRename', (params) async {
      var prepareParams = TextDocumentPositionParams.fromJson(params.value);
      return await handler(prepareParams);
    });
  }

  void onDocumentLinks(
    Future<List<DocumentLink>> Function(DocumentLinkParams) handler,
  ) {
    peer.registerMethod('textDocument/documentLink', (params) async {
      var documentLinkParams = DocumentLinkParams.fromJson(params.value);
      return await handler(documentLinkParams);
    });
  }

  void onDocumentLinkResolve(
    Future<DocumentLink> Function(DocumentLink) handler,
  ) {
    peer.registerMethod('documentLink/resolve', (params) async {
      var documentLink = DocumentLink.fromJson(params.value);
      return await handler(documentLink);
    });
  }

  void onDocumentColor(
    Future<List<ColorInformation>> Function(ColorPresentationParams) handler,
  ) {
    peer.registerMethod('textDocument/documentColor', (params) async {
      var colorParams = ColorPresentationParams.fromJson(params.value);
      return await handler(colorParams);
    });
  }

  void onColorPresentation(
    Future<List<ColorPresentation>> Function(ColorPresentationParams) handler,
  ) {
    peer.registerMethod('textDocument/colorPresentation', (params) async {
      var colorParams = ColorPresentationParams.fromJson(params.value);
      return await handler(colorParams);
    });
  }

  void onFoldingRanges(
    Future<List<FoldingRange>> Function(FoldingRangeParams) handler,
  ) {
    peer.registerMethod('textDocument/foldingRange', (params) async {
      var foldingParams = FoldingRangeParams.fromJson(params.value);
      return await handler(foldingParams);
    });
  }

  void onSelectionRanges(
    Future<List<SelectionRange>> Function(SelectionRangeParams) handler,
  ) {
    peer.registerMethod('textDocument/selectionRange', (params) async {
      var selectionParams = SelectionRangeParams.fromJson(params.value);
      return await handler(selectionParams);
    });
  }

  void onExecuteCommand(
    Future<dynamic> Function(ExecuteCommandParams) handler,
  ) {
    peer.registerMethod('workspace/executeCommand', (params) async {
      var executeParams = ExecuteCommandParams.fromJson(params.value);
      return await handler(executeParams);
    });
  }

  Future dispose() => peer.close();
}

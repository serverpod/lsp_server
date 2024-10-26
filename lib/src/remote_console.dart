import 'package:lsp_server/lsp_server.dart';

// See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.18/specification/#messageType for levels and values
const _error = 1;
const _warn = 2;
const _info = 3;
const _log = 4;
const _debug = 5;

/// Ask the client to log a message in its output console or log system.
/// Interface for [window/logMessage](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.18/specification/#window_logMessage).
class RemoteConsole {
  late Connection _connection;

  RemoteConsole(Connection connection) {
    _connection = connection;
  }

  /// Ask the client to log an error message.
  void error(String message) {
    _send(_error, message);
  }

  /// Ask the client to log a warning message.
  void warn(String message) {
    _send(_warn, message);
  }

  /// Ask the client to log an information message.
  void info(String message) {
    _send(_info, message);
  }

  /// Ask the client to log a message.
  void log(String message) {
    _send(_log, message);
  }

  /// Ask the client to log a debug message. Available since version 3.18.0 of the LSP specification.
  void debug(String message) {
    _send(_debug, message);
  }

  void _send(int type, String message) {
    try {
      _connection.sendNotification(
          'window/logMessage', {"type": type, "message": message});
    } catch (e) {
      print(e);
    }
  }
}

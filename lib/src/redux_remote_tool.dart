import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socketcluster_client/socketcluster_client.dart';

import 'status.dart';

class ReduxRemoteTool {
  ReduxRemoteTool() {
    _statusController = StreamController<RemoteDevToolsStatus>()..add(RemoteDevToolsStatus.notConnected);
    statusStream = _statusController.stream;
  }

  Socket _socket;
  String _channel;
  StreamController<RemoteDevToolsStatus> _statusController;
  Stream<RemoteDevToolsStatus> statusStream;

  /// connect to devtools server
  Future<void> connect(String url) async {
    final String resultUrl = 'ws://$url/socketcluster/';

    _setStatus(RemoteDevToolsStatus.connecting);
    _socket = await Socket.connect(resultUrl);
    _setStatus(RemoteDevToolsStatus.connected);
    _channel = await _login();
    _setStatus(RemoteDevToolsStatus.starting);
    _relay('START');

    await _waitForStart();

    _socket.on(_channel, (String name, dynamic data) {
      _handleEventFromRemote(data as Map<String, dynamic>);
    });

    _relay('ACTION', state: null, action: 'CONNECT');
  }

  /// send data to server
  void send({
    @required Object state,
    @required dynamic action,
    String nextActionId,
    @required dynamic payload,
  }) {
    final socketState = _socket?.state ?? Socket.CLOSED;

    if (socketState != Socket.OPEN) {
      debugPrint('ReduxRemoteTool. connect first');
      return;
    }

    _relay('ACTION', state: state, action: action, actionPayload: payload);
  }

  Future<dynamic> _waitForStart() {
    final completer = Completer();

    _socket.on(_channel, (String name, dynamic data) {
      if (data['type'] == 'START') {
        _setStatus(RemoteDevToolsStatus.started);

        if (!completer.isCompleted) {
          completer.complete();
        }
      } else {
        completer.completeError(data);
      }
    });

    return completer.future;
  }

  Future<String> _login() {
    Completer<String> completer = new Completer<String>();

    _socket.emit('login', 'master', (String name, dynamic error, dynamic data) {
      completer.complete(data as String);
    });

    return completer.future;
  }

  String _perfectJson(dynamic object) {
    return jsonEncode(object.toString()); //_encoder.convert(json); // jsonEncode(json);
  }

  void _relay(
    String type, {
    Object state,
    dynamic action,
    String nextActionId,
    dynamic actionPayload,
  }) {
    final message = {'type': type, 'id': _socket.id, 'name': 'flutter'};

    if (state != null) {
      try {
        message['payload'] = _perfectJson(state);
      } catch (error) {
        message['payload'] = 'Could not encode state. Ensure state is json encodable';
      }
    }

    if (type == 'ACTION') {
      message['action'] = jsonEncode({
        'type': action.toString(),
        'payload': _perfectJson(actionPayload),
      });
      message['nextActionId'] = nextActionId;
    } else if (action != null) {
      message['action'] = action as String;
    }

    _socket.emit(_socket.id != null ? 'log' : 'log-noid', message);
  }

  void _handleEventFromRemote(Map<String, dynamic> data) {
    switch (data['type'] as String) {
      case 'DISPATCH':
        _handleDispatch(data['action']);
        break;
      // The START action is a response indicating that remote devtools is up and running
      case 'START':
        _setStatus(RemoteDevToolsStatus.started);
        break;
      case 'ACTION':
        _handleRemoteAction(data['action'] as String);
        break;
      default:
      // print('Unknown type:' + data['type'].toString());
    }
  }

  void _handleDispatch(dynamic action) {
    switch (action['type'] as String) {
      case 'JUMP_TO_STATE':
        // print('[JUMP_TO_STATE] ${action['index'] as int}');
        break;
      default:
      // print("Unknown commans: ${action['type']}. Ignoring");
    }
  }

  void _handleRemoteAction(String action) {
    // print('_handleRemoteAction action: $action');
  }

  void _setStatus(RemoteDevToolsStatus value) {
    _statusController.add(value);
  }

  void dispose() {
    _statusController.close();
    _socket.unsubscribe(_channel);
  }
}

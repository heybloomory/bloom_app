import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_config.dart';
import 'logger.dart';

class AlbumChatMessage {
  final String id;
  final String albumId;
  final String text;
  final String sender;
  final DateTime createdAt;
  final String? photoId;
  final String? emoji;
  final String? clientId;
  final bool pending;

  const AlbumChatMessage({
    required this.id,
    required this.albumId,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.photoId,
    this.emoji,
    this.clientId,
    this.pending = false,
  });

  AlbumChatMessage copyWith({
    String? id,
    bool? pending,
  }) {
    return AlbumChatMessage(
      id: id ?? this.id,
      albumId: albumId,
      text: text,
      sender: sender,
      createdAt: createdAt,
      photoId: photoId,
      emoji: emoji,
      clientId: clientId,
      pending: pending ?? this.pending,
    );
  }
}

/// WebSocket client for album rooms (path `/ws/chat`).
class AlbumChatSocket {
  AlbumChatSocket._(this.albumId);

  final String albumId;
  bool _connected = false;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messagesCtrl = StreamController<AlbumChatMessage>.broadcast();
  final List<AlbumChatMessage> _localMessages = [];

  static const _uuid = Uuid();

  Stream<AlbumChatMessage> get messages => _messagesCtrl.stream;
  List<AlbumChatMessage> get history => List.unmodifiable(_localMessages);

  static final Map<String, AlbumChatSocket> _instances = {};

  static AlbumChatSocket forAlbum(String albumId) {
    return _instances.putIfAbsent(albumId, () => AlbumChatSocket._(albumId));
  }

  Future<void> connectIfNeeded() async {
    if (_connected) return;
    _connected = true;
    final wsBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final uri = Uri.parse('$wsBase/ws/chat?albumId=$albumId');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(_onFrame, onError: (e, st) {
        AppLogger.error('AlbumChatSocket', 'ws stream error album=$albumId', e, st);
      });
      AppLogger.info('AlbumChatSocket', 'connected album=$albumId');
      _channel!.sink.add(jsonEncode({
        'type': 'join_room',
        'albumId': albumId,
      }));
    } catch (e, st) {
      AppLogger.error('AlbumChatSocket', 'connect failed', e, st);
      _connected = false;
    }
  }

  void _onFrame(dynamic frame) {
    try {
      final map = jsonDecode(frame.toString()) as Map<String, dynamic>;
      final type = (map['type'] ?? '').toString();
      switch (type) {
        case 'history':
          final list = map['messages'];
          if (list is! List) return;
          for (final raw in list) {
            if (raw is! Map) continue;
            final m = _parseMessage(Map<String, dynamic>.from(
              raw.map((k, v) => MapEntry(k.toString(), v)),
            ));
            if (!_hasMessageId(m.id)) {
              _localMessages.add(m);
              _messagesCtrl.add(m);
            }
          }
          return;
        case 'receive_message':
          final m = _parseMessage(map);
          if (_hasMessageId(m.id)) return;
          final cid = m.clientId;
          if (cid != null && cid.isNotEmpty) {
            final idx = _localMessages.indexWhere(
              (x) => x.clientId == cid && x.pending,
            );
            if (idx >= 0) {
              _localMessages[idx] = m.copyWith(pending: false);
              _messagesCtrl.add(_localMessages[idx]);
              return;
            }
          }
          _localMessages.add(m);
          _messagesCtrl.add(m);
          return;
        case 'message_ack':
          final cid = map['clientId']?.toString();
          if (cid == null || cid.isEmpty) return;
          final idx = _localMessages.indexWhere(
            (x) => x.clientId == cid && x.pending,
          );
          if (idx >= 0) {
            final updated = _parseMessage(map).copyWith(pending: false);
            _localMessages[idx] = updated;
            _messagesCtrl.add(updated);
          }
          return;
        case 'pong':
        case 'connected':
          return;
        case 'error':
          AppLogger.warning(
            'AlbumChatSocket',
            map['message']?.toString() ?? 'server error',
          );
          return;
        default:
          return;
      }
    } catch (e, st) {
      AppLogger.error('AlbumChatSocket', 'frame parse', e, st);
    }
  }

  bool _hasMessageId(String id) {
    return _localMessages.any((m) => m.id == id);
  }

  AlbumChatMessage _parseMessage(Map<String, dynamic> map) {
    return AlbumChatMessage(
      id: (map['id'] ?? '').toString(),
      albumId: (map['albumId'] ?? albumId).toString(),
      text: (map['text'] ?? '').toString(),
      sender: (map['sender'] ?? 'User').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      photoId: map['photoId']?.toString(),
      emoji: map['emoji']?.toString(),
      clientId: map['clientId']?.toString(),
      pending: false,
    );
  }

  void sendMessage({
    required String sender,
    required String text,
    String? photoId,
  }) {
    final clientId = _uuid.v4();
    final optimistic = AlbumChatMessage(
      id: 'pending_$clientId',
      albumId: albumId,
      text: text,
      sender: sender,
      createdAt: DateTime.now(),
      photoId: photoId,
      clientId: clientId,
      pending: true,
    );
    _localMessages.add(optimistic);
    _messagesCtrl.add(optimistic);
    _channel?.sink.add(
      jsonEncode({
        'type': 'send_message',
        'clientId': clientId,
        'albumId': albumId,
        'text': text,
        'sender': sender,
        if (photoId != null) 'photoId': photoId,
      }),
    );
  }

  void sendReaction({required String photoId, required String emoji}) {
    final clientId = _uuid.v4();
    final optimistic = AlbumChatMessage(
      id: 'pending_$clientId',
      albumId: albumId,
      text: '',
      sender: 'You',
      createdAt: DateTime.now(),
      photoId: photoId,
      emoji: emoji,
      clientId: clientId,
      pending: true,
    );
    _localMessages.add(optimistic);
    _messagesCtrl.add(optimistic);
    _channel?.sink.add(
      jsonEncode({
        'type': 'add_reaction',
        'clientId': clientId,
        'albumId': albumId,
        'photoId': photoId,
        'emoji': emoji,
        'sender': 'You',
      }),
    );
  }

  void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _sub = null;
    _channel = null;
    _connected = false;
  }
}

// lib/features/chat/providers/chat_provider.dart
// Veloura — Chat State Management (Riverpod + Hive)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

// ── Hive box key ───────────────────────────────────────────
const _kBoxName = 'veloura_messages';

// ── Chat State ─────────────────────────────────────────────

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isPartnerTyping = false,
    this.isSending = false,
  });

  final List<Message> messages;
  final bool isPartnerTyping;
  final bool isSending;

  ChatState copyWith({
    List<Message>? messages,
    bool? isPartnerTyping,
    bool? isSending,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
        isSending: isSending ?? this.isSending,
      );
}

// ── Chat Notifier ───────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    _loadMessages();
    _simulatePartnerTyping();
  }

  final _uuid = const Uuid();
  Box? _box;

  // ── Load messages from Hive ───────────────────────────────

  Future<void> _loadMessages() async {
    _box = await Hive.openBox(_kBoxName);
    final raw = _box!.values.cast<String>().toList();
    final messages = raw.map(Message.fromJson).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Seed demo messages on first launch
    if (messages.isEmpty) {
      final demo = _demoMessages();
      for (final m in demo) {
        await _box!.put(m.id, m.toJson());
      }
      state = state.copyWith(messages: demo);
    } else {
      state = state.copyWith(messages: messages);
    }
  }

  // ── Send a message ────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msg = Message(
      id: _uuid.v4(),
      text: text.trim(),
      isMine: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, msg],
      isSending: true,
    );

    await _box?.put(msg.id, msg.toJson());

    // Simulate network delay → delivered
    await Future.delayed(const Duration(milliseconds: 600));
    _updateMessageStatus(msg.id, MessageStatus.delivered);

    // Simulate partner read
    await Future.delayed(const Duration(seconds: 2));
    _updateMessageStatus(msg.id, MessageStatus.read);

    // Simulate partner reply
    await Future.delayed(const Duration(seconds: 3));
    _simulateReply();

    state = state.copyWith(isSending: false);
  }

  // ── Add reaction to message ───────────────────────────────

  Future<void> addReaction(String messageId, String emoji) async {
    final updated = state.messages.map((m) {
      if (m.id == messageId) return m.copyWith(reaction: emoji);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    final msg = updated.firstWhere((m) => m.id == messageId);
    await _box?.put(messageId, msg.toJson());
  }

  // ── Private helpers ───────────────────────────────────────

  void _updateMessageStatus(String id, MessageStatus status) {
    final updated = state.messages.map((m) {
      if (m.id == id) return m.copyWith(status: status);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void _simulateReply() {
    state = state.copyWith(isPartnerTyping: true);
    Future.delayed(const Duration(seconds: 2), () {
      final replies = [
        'thinking of you too 🌙',
        'missing you so much right now 💜',
        'can\'t wait to see you again ✨',
        'you make everything better 🌸',
        'sending you all my love 💌',
      ];
      replies.shuffle();
      final reply = Message(
        id: _uuid.v4(),
        text: replies.first,
        isMine: false,
        timestamp: DateTime.now(),
        status: MessageStatus.read,
      );
      _box?.put(reply.id, reply.toJson());
      state = state.copyWith(
        messages: [...state.messages, reply],
        isPartnerTyping: false,
      );
    });
  }

  void _simulatePartnerTyping() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      state = state.copyWith(isPartnerTyping: true);
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        state = state.copyWith(isPartnerTyping: false);
      });
    });
  }

  List<Message> _demoMessages() {
    final now = DateTime.now();
    return [
      Message(
        id: _uuid.v4(),
        text: 'hey love 🌙',
        isMine: false,
        timestamp: now.subtract(const Duration(minutes: 42)),
        status: MessageStatus.read,
      ),
      Message(
        id: _uuid.v4(),
        text: 'just got home, thinking of you',
        isMine: false,
        timestamp: now.subtract(const Duration(minutes: 41)),
        status: MessageStatus.read,
      ),
      Message(
        id: _uuid.v4(),
        text: 'been thinking of you all day 💜',
        isMine: true,
        timestamp: now.subtract(const Duration(minutes: 40)),
        status: MessageStatus.read,
      ),
      Message(
        id: _uuid.v4(),
        text: 'the sky here looked exactly like that photo we took together ✨',
        isMine: false,
        timestamp: now.subtract(const Duration(minutes: 20)),
        status: MessageStatus.read,
        reaction: '💜',
      ),
      Message(
        id: _uuid.v4(),
        text: 'can\'t wait to see you again',
        isMine: true,
        timestamp: now.subtract(const Duration(minutes: 5)),
        status: MessageStatus.read,
      ),
    ];
  }
}

// ── Provider ────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);

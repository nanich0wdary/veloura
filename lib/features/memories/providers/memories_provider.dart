// lib/features/memories/providers/memories_provider.dart
// Veloura — Memories State Management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memory.dart';

const _kBox = 'veloura_memories';

// ── State ─────────────────────────────────────────────────────

class MemoriesState {
  const MemoriesState({
    this.memories = const [],
    this.filter = MemoryFilter.all,
    this.isAdding = false,
  });

  final List<Memory> memories;
  final MemoryFilter filter;
  final bool isAdding;

  List<Memory> get filtered {
    switch (filter) {
      case MemoryFilter.all:
        return memories;
      case MemoryFilter.favorites:
        return memories.where((m) => m.isFavorite).toList();
      case MemoryFilter.notes:
        return memories.where((m) => m.type == MemoryType.note).toList();
      case MemoryFilter.moments:
        return memories
            .where((m) => m.type == MemoryType.moment || m.type == MemoryType.milestone)
            .toList();
    }
  }

  MemoriesState copyWith({
    List<Memory>? memories,
    MemoryFilter? filter,
    bool? isAdding,
  }) =>
      MemoriesState(
        memories: memories ?? this.memories,
        filter: filter ?? this.filter,
        isAdding: isAdding ?? this.isAdding,
      );
}

enum MemoryFilter { all, favorites, notes, moments }

// ── Notifier ─────────────────────────────────────────────────

class MemoriesNotifier extends StateNotifier<MemoriesState> {
  MemoriesNotifier() : super(const MemoriesState()) {
    _load();
  }

  final _uuid = const Uuid();
  Box? _box;

  Future<void> _load() async {
    _box = await Hive.openBox(_kBox);
    final raw = _box!.values.cast<String>().toList();
    var memories = raw.map(Memory.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (memories.isEmpty) {
      memories = _demo();
      for (final m in memories) {
        await _box!.put(m.id, m.toJson());
      }
    }
    state = state.copyWith(memories: memories);
  }

  Future<void> addMemory({
    required String title,
    required String content,
    required MemoryType type,
    required String emoji,
    required int gradientIndex,
  }) async {
    state = state.copyWith(isAdding: true);
    final memory = Memory(
      id: _uuid.v4(),
      title: title,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      gradientIndex: gradientIndex,
      emoji: emoji,
    );
    final updated = [memory, ...state.memories];
    await _box?.put(memory.id, memory.toJson());
    state = state.copyWith(memories: updated, isAdding: false);
  }

  Future<void> toggleFavorite(String id) async {
    final updated = state.memories.map((m) {
      if (m.id == id) {
        final toggled = m.copyWith(isFavorite: !m.isFavorite);
        _box?.put(id, toggled.toJson());
        return toggled;
      }
      return m;
    }).toList();
    state = state.copyWith(memories: updated);
  }

  Future<void> deleteMemory(String id) async {
    final updated = state.memories.where((m) => m.id != id).toList();
    await _box?.delete(id);
    state = state.copyWith(memories: updated);
  }

  void setFilter(MemoryFilter filter) =>
      state = state.copyWith(filter: filter);

  List<Memory> _demo() {
    final now = DateTime.now();
    return [
      Memory(
        id: _uuid.v4(),
        title: 'First video call',
        content: 'We talked for 4 hours and I forgot it was past midnight. Your laugh is my favourite sound.',
        type: MemoryType.milestone,
        createdAt: now.subtract(const Duration(days: 180)),
        gradientIndex: 0,
        emoji: '✨',
        isFavorite: true,
      ),
      Memory(
        id: _uuid.v4(),
        title: 'The rainy evening',
        content: 'You sent me a voice note of the rain outside your window. I played it on repeat.',
        type: MemoryType.moment,
        createdAt: now.subtract(const Duration(days: 90)),
        gradientIndex: 1,
        emoji: '🌧️',
        isFavorite: true,
      ),
      Memory(
        id: _uuid.v4(),
        title: 'Things I love about you',
        content: 'The way you say goodnight. How you remember small details. Your voice when you\'re sleepy. The way you make everything feel okay.',
        type: MemoryType.note,
        createdAt: now.subtract(const Duration(days: 60)),
        gradientIndex: 2,
        emoji: '💌',
      ),
      Memory(
        id: _uuid.v4(),
        title: '100 days together',
        content: 'A hundred days of good morning texts, late night calls, and falling deeper every single day.',
        type: MemoryType.milestone,
        createdAt: now.subtract(const Duration(days: 45)),
        gradientIndex: 3,
        emoji: '💯',
        isFavorite: true,
      ),
      Memory(
        id: _uuid.v4(),
        title: 'Favourite playlist',
        content: 'Made a playlist of songs that remind me of you. Listened to it all of today.',
        type: MemoryType.note,
        createdAt: now.subtract(const Duration(days: 20)),
        gradientIndex: 4,
        emoji: '🎵',
      ),
      Memory(
        id: _uuid.v4(),
        title: 'Surprise message',
        content: 'Woke up to 12 messages from you describing your dream about us. I smiled all day.',
        type: MemoryType.moment,
        createdAt: now.subtract(const Duration(days: 7)),
        gradientIndex: 0,
        emoji: '🌙',
        isFavorite: true,
      ),
    ];
  }
}

// ── Provider ─────────────────────────────────────────────────

final memoriesProvider =
    StateNotifierProvider<MemoriesNotifier, MemoriesState>(
  (ref) => MemoriesNotifier(),
);

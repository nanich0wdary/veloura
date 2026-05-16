// lib/features/mood/providers/mood_provider.dart
// Veloura — Mood State Management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood.dart';

const _kBox = 'veloura_mood';
const _kMyMood = 'my_mood';
const _kPartnerMood = 'partner_mood';
const _kNote = 'mood_note';

// ── State ────────────────────────────────────────────────────

class MoodState {
  const MoodState({
    this.myMood = MoodType.romantic,
    this.partnerMood = MoodType.calm,
    this.note = '',
    this.isSyncing = false,
    this.lastSynced,
  });

  final MoodType myMood;
  final MoodType partnerMood;
  final String note;
  final bool isSyncing;
  final DateTime? lastSynced;

  MoodState copyWith({
    MoodType? myMood,
    MoodType? partnerMood,
    String? note,
    bool? isSyncing,
    DateTime? lastSynced,
  }) =>
      MoodState(
        myMood: myMood ?? this.myMood,
        partnerMood: partnerMood ?? this.partnerMood,
        note: note ?? this.note,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSynced: lastSynced ?? this.lastSynced,
      );

  Mood get myMoodData => Mood.byType(myMood);
  Mood get partnerMoodData => Mood.byType(partnerMood);

  // Combined aura = blend of both moods
  List get auraColors => [
        ...myMoodData.colors,
        ...partnerMoodData.colors,
      ];
}

// ── Notifier ─────────────────────────────────────────────────

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(const MoodState()) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = await Hive.openBox(_kBox);
    final myIdx = _box!.get(_kMyMood, defaultValue: 0) as int;
    final partnerIdx = _box!.get(_kPartnerMood, defaultValue: 1) as int;
    final note = _box!.get(_kNote, defaultValue: '') as String;
    state = state.copyWith(
      myMood: MoodType.values[myIdx],
      partnerMood: MoodType.values[partnerIdx],
      note: note,
      lastSynced: DateTime.now(),
    );
  }

  Future<void> setMyMood(MoodType mood) async {
    state = state.copyWith(myMood: mood, isSyncing: true);
    await _box?.put(_kMyMood, mood.index);

    // Simulate sync to partner
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isSyncing: false, lastSynced: DateTime.now());

    // Simulate partner reacting to your mood
    await Future.delayed(const Duration(seconds: 2));
    _simulatePartnerResponse(mood);
  }

  Future<void> setNote(String note) async {
    state = state.copyWith(note: note);
    await _box?.put(_kNote, note);
  }

  void _simulatePartnerResponse(MoodType myMood) {
    // Partner mirrors a related mood
    final responses = {
      MoodType.romantic: MoodType.romantic,
      MoodType.calm: MoodType.peaceful,
      MoodType.missing: MoodType.melancholic,
      MoodType.joyful: MoodType.joyful,
      MoodType.peaceful: MoodType.calm,
      MoodType.melancholic: MoodType.missing,
      MoodType.energetic: MoodType.joyful,
    };
    final partnerMood = responses[myMood] ?? MoodType.calm;
    state = state.copyWith(partnerMood: partnerMood);
    _box?.put(_kPartnerMood, partnerMood.index);
  }
}

// ── Provider ─────────────────────────────────────────────────

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>(
  (ref) => MoodNotifier(),
);

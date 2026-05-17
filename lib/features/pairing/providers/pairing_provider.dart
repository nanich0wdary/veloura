// lib/features/pairing/providers/pairing_provider.dart
// Veloura — Pairing State Management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pair_data.dart';

const _kBox = 'veloura_pairing';
const _kPairData = 'pair_data';

class PairingState {
  const PairingState({
    this.pairData,
    this.isLoading = false,
    this.isScanning = false,
    this.statusMessage = '',
    this.error,
  });

  final PairData? pairData;
  final bool isLoading;
  final bool isScanning;
  final String statusMessage;
  final String? error;

  bool get isPaired => pairData?.isPaired ?? false;

  PairingState copyWith({
    PairData? pairData,
    bool? isLoading,
    bool? isScanning,
    String? statusMessage,
    String? error,
  }) =>
      PairingState(
        pairData: pairData ?? this.pairData,
        isLoading: isLoading ?? this.isLoading,
        isScanning: isScanning ?? this.isScanning,
        statusMessage: statusMessage ?? this.statusMessage,
        error: error,
      );
}

class PairingNotifier extends StateNotifier<PairingState> {
  PairingNotifier() : super(const PairingState()) {
    _init();
  }

  Box? _box;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    _box = await Hive.openBox(_kBox);
    final raw = _box!.get(_kPairData) as String?;
    if (raw != null) {
      state = state.copyWith(
          pairData: PairData.fromJson(raw), isLoading: false);
    } else {
      final data = PairData(
        deviceId: PairCodeGenerator.deviceId(),
        pairCode: PairCodeGenerator.generate(),
        displayName: 'You',
      );
      await _box!.put(_kPairData, data.toJson());
      state = state.copyWith(pairData: data, isLoading: false);
    }
  }

  Future<void> connectFromQr(String qrPayload) async {
    state = state.copyWith(
        isScanning: false, isLoading: true,
        statusMessage: 'Connecting...', error: null);
    final scanned = PairData.fromQrPayload(qrPayload);
    if (scanned == null) {
      state = state.copyWith(isLoading: false,
          error: 'Invalid QR code. Please scan a Veloura code.');
      return;
    }
    if (scanned.deviceId == state.pairData?.deviceId) {
      state = state.copyWith(isLoading: false,
          error: 'You cannot pair with yourself.');
      return;
    }
    await Future.delayed(const Duration(seconds: 2));
    final updated = state.pairData!.copyWith(
      partnerId: scanned.deviceId,
      partnerName: scanned.displayName,
      status: PairingStatus.connected,
      pairedAt: DateTime.now(),
    );
    await _box?.put(_kPairData, updated.toJson());
    state = state.copyWith(
        pairData: updated, isLoading: false,
        statusMessage: 'Connected with ${scanned.displayName}!');
  }

  // Simulate demo pairing (for testing without two devices)
  Future<void> simulatePairing() async {
    state = state.copyWith(isLoading: true,
        statusMessage: 'Connecting...', error: null);
    await Future.delayed(const Duration(seconds: 2));
    final updated = state.pairData!.copyWith(
      partnerId: PairCodeGenerator.deviceId(),
      partnerName: 'Ariana',
      status: PairingStatus.connected,
      pairedAt: DateTime.now(),
    );
    await _box?.put(_kPairData, updated.toJson());
    state = state.copyWith(
        pairData: updated, isLoading: false,
        statusMessage: 'Connected with Ariana!');
  }

  Future<void> setDisplayName(String name) async {
    if (name.trim().isEmpty) return;
    final updated = PairData(
      deviceId: state.pairData!.deviceId,
      pairCode: state.pairData!.pairCode,
      displayName: name.trim(),
      partnerId: state.pairData!.partnerId,
      partnerName: state.pairData!.partnerName,
      status: state.pairData!.status,
      pairedAt: state.pairData!.pairedAt,
    );
    await _box?.put(_kPairData, updated.toJson());
    state = state.copyWith(pairData: updated);
  }

  Future<void> unpair() async {
    final reset = PairData(
      deviceId: state.pairData!.deviceId,
      pairCode: PairCodeGenerator.generate(),
      displayName: state.pairData!.displayName,
    );
    await _box?.put(_kPairData, reset.toJson());
    state = state.copyWith(
        pairData: reset, statusMessage: '', error: null);
  }

  void toggleScanning() =>
      state = state.copyWith(isScanning: !state.isScanning, error: null);

  void clearError() => state = state.copyWith(error: null);
}

final pairingProvider =
    StateNotifierProvider<PairingNotifier, PairingState>(
  (ref) => PairingNotifier(),
);
